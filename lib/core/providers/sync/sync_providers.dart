import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:project_management_app/core/repository/i_project_repository.dart';
import 'package:project_management_app/core/services/cloud_sync_service.dart';
import 'package:project_management_app/core/providers/connectivity/connectivity_provider.dart';
import 'package:project_management_app/core/repository/i_dashboard_repository.dart';
import 'package:project_management_app/core/services/app_logger.dart';
import 'package:project_management_app/models/project_model.dart';
import 'package:project_management_app/core/providers/project/project_providers.dart';
import 'package:project_management_app/core/providers/dashboard/dashboard_providers.dart';

/// Sync status model
class SyncStatus {
  final String status; // 'idle', 'syncing', 'success', 'error', 'offline'
  final String? message;
  final DateTime? lastSync;
  final int? projectsSynced;

  const SyncStatus({
    required this.status,
    this.message,
    this.lastSync,
    this.projectsSynced,
  });

  factory SyncStatus.idle() => const SyncStatus(status: 'idle');
  factory SyncStatus.syncing({String? message}) => SyncStatus(status: 'syncing', message: message);
  factory SyncStatus.success({DateTime? lastSync, int? projectsSynced}) =>
      SyncStatus(status: 'success', lastSync: lastSync, projectsSynced: projectsSynced);
  factory SyncStatus.error(String message) => SyncStatus(status: 'error', message: message);
  factory SyncStatus.offline() => const SyncStatus(status: 'offline');
}

/// Sync notifier for managing Supabase synchronization
class SyncNotifier extends StateNotifier<AsyncValue<SyncStatus>> {
  final Ref _ref;
  final IProjectRepository _projectRepository;
  final IDashboardRepository _dashboardRepository;
  final CloudSyncService _cloudSyncService;

  SyncNotifier(this._ref)
      : _projectRepository = _ref.read(projectRepositoryProvider),
        _dashboardRepository = _ref.read(dashboardRepositoryProvider),
        _cloudSyncService = CloudSyncService(),
        super(AsyncValue.data(SyncStatus.idle())) {
    // Listen to connectivity changes and auto-sync when online
    _ref.listen(connectivityProvider, (previous, next) {
      next.whenData((connectivity) {
        if (connectivity == ConnectivityResult.none) {
          // Update status to offline
          state = AsyncValue.data(SyncStatus.offline());
        } else {
          // Back online, process offline queue
          state = AsyncValue.data(SyncStatus.idle());
          _processOfflineQueue();
        }
      });
    });

    // Subscribe to real-time project changes
    _cloudSyncService.getProjectsStream().listen((changes) {
      AppLogger.debug('Realtime projects update: ${changes.length} changes');
      _handleRealtimeUpdate(changes);
    });
  }

  /// Compare local and remote project and sync differences
  Future<void> _compareAndSync(Map<String, dynamic> remoteJson) async {
    final remote = ProjectModel.fromJson(remoteJson);
    try {
      final local = await _projectRepository.getProjectById(remote.id);
      // Existing project, compare and sync
      await _syncProjectDifferences(local, remote);
    } catch (e) {
      // New remote project, add to local
      await _projectRepository.updateProject(remote.id, remote, userId: 'realtime-sync');
      return;
    }
  }

  /// Sync differences between local and remote projects
  Future<void> _syncProjectDifferences(ProjectModel local, ProjectModel remote) async {
    final remoteTime = remote.lastUpdated;
    final localTime = local.lastUpdated;

    if (remoteTime.isAfter(localTime)) {
      // Remote is newer, download
      await _projectRepository.updateProject(remote.id, remote, userId: 'realtime-sync');
    } else if (localTime.isAfter(remoteTime)) {
      // Local is newer, upload to resolve conflict
      await _cloudSyncService.syncProjectUpdate(remote.id, metadata: local.toJson());
    }
    // If equal, no action needed
  }

  // Fully implemented in 040-supabase-sync-cleanup.md

  /// Handle real-time updates from Supabase
  Future<void> _handleRealtimeUpdate(List<Map<String, dynamic>> changes) async {
    try {
      // Invalidate cache (027)
      await _dashboardRepository.clearCache();

      // Compare and sync each change
      for (final change in changes) {
        await _compareAndSync(change);
      }

      // Notify listeners via Riverpod (invalidate projects provider)
      // This will trigger a refresh of any listening widgets
      _ref.invalidate(projectRepositoryProvider);

      AppLogger.event('sync_realtime_update', params: {
        'changes_count': changes.length,
      });
    } catch (e) {
      AppLogger.instance.w('Failed to handle realtime update', error: e);
    }
  }

  /// Sync a specific project
  Future<void> syncProject(String projectId) async {
    state = const AsyncValue.loading();

    try {
      await _projectRepository.syncProject(projectId);
      state = AsyncValue.data(SyncStatus.success(lastSync: DateTime.now()));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Sync all projects
  Future<void> syncAllProjects() async {
    state = const AsyncValue.loading();

    try {
      await _projectRepository.syncAllProjects();
      await _dashboardRepository.processPendingSync();
      state = AsyncValue.data(SyncStatus.success(lastSync: DateTime.now()));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Process offline queue when connectivity is restored
  Future<void> _processOfflineQueue() async {
    try {
      await _dashboardRepository.processPendingSync();
      AppLogger.instance.i('Processed offline queue');
    } catch (e) {
      AppLogger.instance.w('Failed to process offline queue', error: e);
    }
  }

  /// Watch for project changes (Supabase real-time stream)
  Stream<List<ProjectModel>> watchProjectChanges(String projectId) {
    return _cloudSyncService.getProjectsStream().map((changes) {
      // Filter for specific project and map to ProjectModel
      return changes
          .where((change) => change['id'] == projectId)
          .map((json) => ProjectModel.fromJson(json))
          .toList();
    });
  }
}

/// Provider for sync operations
final syncProvider = StateNotifierProvider<SyncNotifier, AsyncValue<SyncStatus>>((ref) {
  return SyncNotifier(ref);
});

/// Provider for tracking last sync timestamp
final lastSyncProvider = StateProvider<DateTime?>((ref) => null);

/// Provider for sync status (idle, syncing, error) - legacy, use syncProvider instead
final syncStatusProvider = StateProvider<String>((ref) => 'idle');

/*
// Reusable UI Example Code for Sync Features (039-supabase-sync-implementation.md)

// 1. Sync Status Indicator Widget
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final l10n = AppLocalizations.of(context)!;

    return syncState.when(
      data: (status) {
        IconData icon;
        String text;
        Color color;

        switch (status.status) {
          case 'idle':
            icon = Icons.cloud_done;
            text = l10n.sync_status_online;
            color = Colors.green;
            break;
          case 'syncing':
            icon = Icons.sync;
            text = l10n.syncing_projects;
            color = Colors.blue;
            break;
          case 'offline':
            icon = Icons.cloud_off;
            text = l10n.sync_status_offline;
            color = Colors.orange;
            break;
          case 'error':
            icon = Icons.error;
            text = l10n.sync_error;
            color = Colors.red;
            break;
          default:
            icon = Icons.help;
            text = 'Unknown';
            color = Colors.grey;
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(text, style: TextStyle(color: color, fontSize: 12)),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => const Icon(Icons.error, color: Colors.red),
    );
  }
}

// 2. Manual Sync Now Button
class SyncNowButton extends ConsumerWidget {
  const SyncNowButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final l10n = AppLocalizations.of(context)!;

    final isLoading = syncState.isLoading;
    final isOffline = syncState.maybeWhen(
      data: (status) => status.status == 'offline',
      orElse: () => false,
    );

    return ElevatedButton.icon(
      onPressed: isLoading || isOffline ? null : () async {
        try {
          await ref.read(syncProvider.notifier).syncAllProjects();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.offline_sync_success)),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.sync_error)),
          );
        }
      },
      icon: isLoading ? const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ) : const Icon(Icons.sync),
      label: Text(isLoading ? l10n.syncing_projects : 'Sync Now'),
    );
  }
}

// 3. Conflict Resolution Dialog
Future<void> showConflictResolutionDialog(
  BuildContext context,
  ProjectModel local,
  ProjectModel remote,
) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Sync Conflict'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose which version to keep:'),
          const SizedBox(height: 16),
          Text('Local: ${local.name} (${local.progress}%)'),
          Text('Remote: ${remote.name} (${remote.progress}%)'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false), // Keep local
          child: const Text('Keep Local'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true), // Use remote
          child: const Text('Use Remote'),
        ),
      ],
    ),
  );

  if (result != null) {
    // Call resolveConflict with the chosen version
    // await ref.read(syncProvider.notifier).resolveConflict(
    //   result ? remote : local,
    //   result ? local : remote,
    // );
  }
}
*/
