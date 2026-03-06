import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pma_core/repository/i_project_repository.dart';
import 'package:pma_core/services/cloud_sync_service.dart';
import 'package:pma_core/providers/connectivity/connectivity_providers.dart';
import 'package:pma_core/repository/i_dashboard_repository.dart';
import 'package:pma_core/services/app_logger.dart';
import 'package:pma_core/models/project_model.dart';
import 'package:pma_core/providers/project/project_providers.dart';
import 'package:pma_core/providers/dashboard/dashboard_providers.dart';

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
          .map(ProjectModel.fromJson)
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
