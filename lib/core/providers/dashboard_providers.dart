import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
import 'package:my_project_management_app/models/project_requirements.dart';
import 'package:my_project_management_app/models/project_model.dart';
import 'package:my_project_management_app/core/repository/i_dashboard_repository.dart';
import 'package:my_project_management_app/core/repository/hive_dashboard_repository.dart';
import 'project_providers.dart';
import 'package:my_project_management_app/core/services/app_logger.dart';
import 'package:my_project_management_app/core/models/dashboard_types.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'connectivity_provider.dart';
import 'package:my_project_management_app/core/models/requirements.dart';

/// DashboardItem
/// 
/// Model for dashboard items with validated widget types.
/// Supported types: metricCard, taskList, progressChart, kanbanBoard, calendar, notificationFeed, projectOverview, timeline.
/// See .github/issues/020-dashboard-validate-widget-type.md for details.
/// 
/// Validates a widget type string against supported dashboard widget types.
/// 
/// Throws InvalidWidgetTypeException if invalid, with logging.
/// Supported types: metricCard, taskList, progressChart, kanbanBoard, calendar, notificationFeed, projectOverview, timeline.
/// See .github/issues/020-dashboard-validate-widget-type.md for details.
DashboardWidgetType validateWidgetType(String value) {
  try {
    return DashboardWidgetType.fromString(value);
  } catch (e) {
    AppLogger.instance.w('Invalid widget type attempted: $value');
    throw InvalidWidgetTypeException(
      'Invalid widget type \'$value\'. Valid types are: ${DashboardWidgetType.values.map((e) => e.name).join(', ')}',
    );
  }
}

/// Notifier for managing dashboard configuration with persistence, widget type validation, and undo/redo functionality
class DashboardConfigNotifier extends Notifier<List<DashboardItem>> {
  late final IDashboardRepository _repository;
  late List<DashboardTemplate> _userTemplates;
  String? currentShareId;
  RealtimeChannel? _channel;

  /// Built-in preset dashboard templates
  static final List<DashboardTemplate> _builtInPresets = [
    DashboardTemplate(
      id: 'project-overview',
      name: 'Project Overview',
      items: [
        DashboardItem(widgetType: DashboardWidgetType.projectOverview, position: {'x': 0, 'y': 0, 'width': 600, 'height': 400}),
        DashboardItem(widgetType: DashboardWidgetType.taskList, position: {'x': 600, 'y': 0, 'width': 600, 'height': 400}),
        DashboardItem(widgetType: DashboardWidgetType.progressChart, position: {'x': 0, 'y': 400, 'width': 600, 'height': 400}),
      ],
      isPreset: true,
      createdAt: DateTime(2023, 1, 1),
    ),
    DashboardTemplate(
      id: 'task-management',
      name: 'Task Management',
      items: [
        DashboardItem(widgetType: DashboardWidgetType.taskList, position: {'x': 0, 'y': 0, 'width': 600, 'height': 400}),
        DashboardItem(widgetType: DashboardWidgetType.kanbanBoard, position: {'x': 600, 'y': 0, 'width': 600, 'height': 400}),
        DashboardItem(widgetType: DashboardWidgetType.calendar, position: {'x': 0, 'y': 400, 'width': 1200, 'height': 400}),
      ],
      isPreset: true,
      createdAt: DateTime(2023, 1, 1),
    ),
    DashboardTemplate(
      id: 'analytics',
      name: 'Analytics',
      items: [
        DashboardItem(widgetType: DashboardWidgetType.metricCard, position: {'x': 0, 'y': 0, 'width': 400, 'height': 200}),
        DashboardItem(widgetType: DashboardWidgetType.progressChart, position: {'x': 400, 'y': 0, 'width': 400, 'height': 400}),
        DashboardItem(widgetType: DashboardWidgetType.timeline, position: {'x': 800, 'y': 0, 'width': 400, 'height': 400}),
        DashboardItem(widgetType: DashboardWidgetType.projectOverview, position: {'x': 0, 'y': 400, 'width': 600, 'height': 400}),
      ],
      isPreset: true,
      createdAt: DateTime(2023, 1, 1),
    ),
    DashboardTemplate(
      id: 'notifications',
      name: 'Notifications',
      items: [
        DashboardItem(widgetType: DashboardWidgetType.notificationFeed, position: {'x': 0, 'y': 0, 'width': 600, 'height': 400}),
        DashboardItem(widgetType: DashboardWidgetType.calendar, position: {'x': 600, 'y': 0, 'width': 600, 'height': 400}),
        DashboardItem(widgetType: DashboardWidgetType.projectOverview, position: {'x': 0, 'y': 400, 'width': 1200, 'height': 400}),
      ],
      isPreset: true,
      createdAt: DateTime(2023, 1, 1),
    ),
  ];

  /// Maximum number of history entries to maintain (prevents memory bloat)
  /// See .github/issues/022-dashboard-undo-redo.md for details
  static const int _maxHistoryEntries = 50;

  /// History stack storing snapshots of dashboard state for undo/redo
  /// See .github/issues/022-dashboard-undo-redo.md for details
  final List<List<DashboardItem>> _history = [];

  /// Current position in history stack (-1 means no history)
  /// See .github/issues/022-dashboard-undo-redo.md for details
  int _currentIndex = -1;

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  @override
  List<DashboardItem> build() {
    _repository = ref.read(dashboardRepositoryProvider);
    _userTemplates = [];
    _history.clear();
    _currentIndex = -1;
    _repository.preloadCache().then((_) => _pushToHistory());
    ref.listen(connectivityProvider, (previous, next) {
      final wasOffline = _isOffline;
      _isOffline = !(next.hasValue && (next.value == ConnectivityResult.wifi || next.value == ConnectivityResult.mobile));
      if (wasOffline && !_isOffline) {
        ref.read(offlineSyncStatusProvider.notifier).state = true;
        _repository.processPendingSync().then((_) {
          ref.read(offlineSyncStatusProvider.notifier).state = false;
          ref.read(dashboardErrorProvider.notifier).state = 'offline_sync_success';
        }).catchError((error) {
          ref.read(offlineSyncStatusProvider.notifier).state = false;
          ref.read(dashboardErrorProvider.notifier).state = 'dashboard_action_failed';
        });
      }
    });
    return [];
  }

  Future<void> loadConfig() async {
    try {
      final items = await _repository.loadConfig();
      state = items;
      _userTemplates = await _repository.loadTemplates();
      _logEvent('config_loaded');
    } catch (e, st) {
      await _logError('load_config', e, st);
      state = [];
      _userTemplates = [];
      ref.read(dashboardErrorProvider.notifier).state = 'dashboard_load_error';
    }
  }

  Future<void> saveConfig(List<DashboardItem> items) async {
    try {
      await _repository.saveConfig(items);
      state = items;
      _currentIndex = _history.length - 1;

      // If shared, also push to Supabase
      if (currentShareId != null) {
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        if (currentUserId != null) {
          final existing = await _repository.fetchSharedDashboard(currentShareId!);
          final dashboard = SharedDashboard(
            id: currentShareId!,
            ownerId: existing?.ownerId ?? currentUserId,
            title: existing?.title ?? 'Shared Dashboard',
            items: items,
            permissions: existing?.permissions ?? {},
            updatedAt: DateTime.now(),
          );
          await _repository.saveSharedDashboard(dashboard);
          await _repository.saveLocalSharedDashboard(dashboard);
        }
      }
      _logEvent('config_saved');
    } catch (e, st) {
      await _logError('save_config', e, st);
      ref.read(dashboardErrorProvider.notifier).state = 'dashboard_save_error';
      rethrow;
    }
  }





  /// Adds a new dashboard item with widget type validation and position constraint enforcement.
  /// The position is validated against the dashboard's bounding box and clamped if necessary
  /// to ensure x >= 0, y >= 0, x+width <= containerWidth, y+height <= containerHeight, and minimum dimensions.
  /// See .github/issues/020-dashboard-validate-widget-type.md and .github/issues/021-dashboard-position-constraints.md
  Future<void> addItem(DashboardItem item) async {
    try {
      validateWidgetType(item.widgetType.name);
      Map<String, dynamic> position = item.position;
      if (!_isValidPosition(position, kDashboardContainerWidth, kDashboardContainerHeight)) {
        position = _clampPosition(position, containerWidth: kDashboardContainerWidth, containerHeight: kDashboardContainerHeight);
      }
      final clampedItem = DashboardItem(widgetType: item.widgetType, position: position);
      await _repository.addItem(clampedItem);
      await loadConfig(); // Refresh state
      _pushToHistory();
      _logEvent('item_added', params: {'widgetType': item.widgetType.name, 'position': position});
    } catch (e, st) {
      await _logError('add_item', e, st);
      ref.read(dashboardErrorProvider.notifier).state = 'dashboard_action_failed';
      rethrow;
    }
  }

  /// Remove a dashboard item by index
  Future<void> removeItem(int index) async {
    try {
      await _repository.removeItem(index);
      await loadConfig(); // Refresh state
      _pushToHistory();
      _logEvent('item_removed', params: {'index': index});
    } catch (e, st) {
      await _logError('remove_item', e, st);
      ref.read(dashboardErrorProvider.notifier).state = 'dashboard_action_failed';
      rethrow;
    }
  }

  /// Updates an item's position after enforcing constraints to keep it within dashboard bounds.
  /// The new position is clamped to stay within the bounding box (x >= 0, y >= 0, x+width <= containerWidth, y+height <= containerHeight)
  /// and enforce minimum dimensions before saving.
  /// See .github/issues/021-dashboard-position-constraints.md for details.
  Future<void> updateItemPosition(int index, Map<String, dynamic> newPosition) async {
    try {
      final clampedPosition = _clampPosition(newPosition, containerWidth: kDashboardContainerWidth, containerHeight: kDashboardContainerHeight);
      await _repository.updateItemPosition(index, clampedPosition);
      await loadConfig(); // Refresh state
      _pushToHistory();
      _logEvent('position_updated', params: {'index': index, 'newPosition': clampedPosition});
    } catch (e, st) {
      await _logError('update_position', e, st);
      ref.read(dashboardErrorProvider.notifier).state = 'dashboard_action_failed';
      rethrow;
    }
  }

  /// Enforces position constraints for UI drag/resize operations by clamping the proposed position
  /// to stay within the dashboard's bounding box (x >= 0, y >= 0, x+width <= containerWidth, y+height <= containerHeight)
  /// and enforcing minimum dimensions. Returns the validated and clamped position.
  /// See .github/issues/021-dashboard-position-constraints.md for details.
  Future<Map<String, dynamic>> enforcePositionConstraints(Map<String, dynamic> proposedPosition, {required double containerWidth, required double containerHeight}) {
    return Future.value(_clampPosition(proposedPosition, containerWidth: containerWidth, containerHeight: containerHeight));
  }

  /// Clamps position to stay within container bounds and enforce minimum dimensions
  /// See .github/issues/021-dashboard-position-constraints.md for details
  Map<String, dynamic> _clampPosition(Map<String, dynamic> position, {required double containerWidth, required double containerHeight}) {
    double x = (position['x'] as num?)?.toDouble() ?? 0.0;
    double y = (position['y'] as num?)?.toDouble() ?? 0.0;
    double width = (position['width'] as num?)?.toDouble() ?? kDashboardMinWidth;
    double height = (position['height'] as num?)?.toDouble() ?? kDashboardMinHeight;

    bool clamped = false;

    if (x < 0) {
      x = 0;
      clamped = true;
    }
    if (y < 0) {
      y = 0;
      clamped = true;
    }
    if (width < kDashboardMinWidth) {
      width = kDashboardMinWidth;
      clamped = true;
    }
    if (height < kDashboardMinHeight) {
      height = kDashboardMinHeight;
      clamped = true;
    }
    if (x + width > containerWidth) {
      x = containerWidth - width;
      clamped = true;
    }
    if (y + height > containerHeight) {
      y = containerHeight - height;
      clamped = true;
    }

    if (clamped) {
      AppLogger.instance.w('Position clamped to fit container: original $position, clamped x:$x y:$y w:$width h:$height');
    }

    return {'x': x, 'y': y, 'width': width, 'height': height};
  }

  // ignore: unused_element
  /// Checks if position has valid basic constraints (min values, non-negative x/y)
  /// See .github/issues/021-dashboard-position-constraints.md for details
  bool _isValidPosition(Map<String, dynamic> position, double containerWidth, double containerHeight) {
    final x = position['x'] as num?;
    final y = position['y'] as num?;
    final width = position['width'] as num?;
    final height = position['height'] as num?;
    if (x == null || y == null || width == null || height == null) return false;
    return x >= 0 && y >= 0 &&
           width >= kDashboardMinWidth && height >= kDashboardMinHeight &&
           x + width <= containerWidth && y + height <= containerHeight;
  }

  /// Creates a deep copy of the dashboard state for history snapshots
  List<DashboardItem> _deepCopyState(List<DashboardItem> state) {
    return state.map((item) => DashboardItem(
      widgetType: item.widgetType,
      position: Map<String, dynamic>.from(item.position),
    )).toList();
  }

  /// Pushes current state to history stack and trims if necessary
  void _pushToHistory([List<DashboardItem>? stateToPush]) {
    _history.add(_deepCopyState(stateToPush ?? state));
    _currentIndex = _history.length - 1;
    _trimHistory();
  }

  /// Trims history stack to maximum entries, adjusting current index
  void _trimHistory() {
    if (_history.length > _maxHistoryEntries) {
      _history.removeAt(0);
      _currentIndex--;
    }
  }

  /// Undoes the last dashboard change by restoring the previous state from history
  /// and persisting the change. Only available if canUndo is true.
  /// See .github/issues/022-dashboard-undo-redo.md for details.
  Future<void> undo() async {
    if (canUndo) {
      int targetIndex = _currentIndex - 1;
      _currentIndex = targetIndex;
      state = _deepCopyState(_history[_currentIndex]);
      await saveConfig(state);
      _currentIndex = targetIndex;
      AppLogger.instance.d('Undid dashboard change');
    }
  }

  /// Redoes the last undone dashboard change by restoring the next state from history
  /// and persisting the change. Only available if canRedo is true.
  /// See .github/issues/022-dashboard-undo-redo.md for details.
  Future<void> redo() async {
    if (canRedo) {
      int targetIndex = _currentIndex + 1;
      _currentIndex = targetIndex;
      state = _deepCopyState(_history[_currentIndex]);
      await saveConfig(state);
      _currentIndex = targetIndex;
      AppLogger.instance.d('Redid dashboard change');
    }
  }

  /// Whether an undo operation is currently available (more than one history entry exists)
  /// See .github/issues/022-dashboard-undo-redo.md for details.
  bool get canUndo => _currentIndex > 0;

  /// Whether a redo operation is currently available (not at the end of history)
  /// See .github/issues/022-dashboard-undo-redo.md for details.
  bool get canRedo => _currentIndex < _history.length - 1;

  /// Saves the current dashboard configuration as a new user template.
  /// See .github/issues/023-dashboard-templates.md for details.
  Future<void> saveAsTemplate(String name) async {
    final template = DashboardTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      items: List.from(state),
      isPreset: false,
      createdAt: DateTime.now(),
    );
    final userTemplates = await _repository.loadTemplates();
    userTemplates.add(template);
    await _repository.saveTemplates(userTemplates);
    _userTemplates = userTemplates;
    AppLogger.instance.i('Saved dashboard as template: $name');
  }

  /// Loads a dashboard template by ID and applies it to replace the current configuration.
  /// See .github/issues/023-dashboard-templates.md for details.
  Future<void> loadTemplate(String templateId) async {
    final allTemplates = getAllTemplates();
    final template = allTemplates.firstWhere(
      (t) => t.id == templateId,
      orElse: () => throw ArgumentError('Template not found: $templateId'),
    );
    await saveConfig(List.from(template.items));
    AppLogger.instance.i('Loaded dashboard template: ${template.name}');
  }

  /// Returns all available dashboard templates (built-in presets + user-created).
  /// See .github/issues/023-dashboard-templates.md for details.
  List<DashboardTemplate> getAllTemplates() {
    return [..._builtInPresets, ..._userTemplates];
  }

  /// Deletes a user-created dashboard template by ID.
  /// See .github/issues/023-dashboard-templates.md for details.
  Future<void> deleteTemplate(String templateId) async {
    final userTemplates = List<DashboardTemplate>.from(_userTemplates);
    userTemplates.removeWhere((t) => t.id == templateId && !t.isPreset);
    await _repository.saveTemplates(userTemplates);
    _userTemplates = userTemplates;
    AppLogger.instance.i('Deleted dashboard template: $templateId');
  }







  Future<bool> hasPermission(String shareId, DashboardPermission required) async {
    final dashboard = await _repository.fetchSharedDashboard(shareId);
    if (dashboard == null) return false;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return false;

    if (dashboard.ownerId == currentUserId) return true;

    final userPerm = dashboard.permissions[currentUserId];
    if (userPerm == null) return false;

    return userPerm == required.name;
  }

  Future<String> generateShareLink(String title) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    final shareId = const Uuid().v4();
    final dashboard = SharedDashboard(
      id: shareId,
      ownerId: currentUserId,
      title: title,
      items: List.from(state),
      permissions: {},
      updatedAt: DateTime.now(),
    );

    await _repository.saveSharedDashboard(dashboard);
    AppLogger.instance.i('Generated share link for dashboard: $shareId');
    return shareId;
  }

  Future<void> inviteUser(String shareId, String userId, DashboardPermission perm) async {
    final dashboard = await _repository.fetchSharedDashboard(shareId);
    if (dashboard == null) throw Exception('Shared dashboard not found');

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId != dashboard.ownerId) throw Exception('Only owner can invite users');

    final updatedPermissions = Map<String, String>.from(dashboard.permissions);
    updatedPermissions[userId] = perm.name;

    await _repository.updateSharedPermissions(shareId, updatedPermissions);
    AppLogger.event('dashboard_invite', params: {'shareId': shareId, 'userId': userId, 'permission': perm.name});
  }





  Future<void> loadSharedDashboard(String shareId) async {
    final remote = await _repository.fetchSharedDashboard(shareId);
    final local = await _repository.loadLocalSharedDashboard(shareId);

    SharedDashboard? toUse;
    if (remote != null && local != null) {
      // Last-write-wins
      toUse = remote.updatedAt.isAfter(local.updatedAt) ? remote : local;
      if (remote.updatedAt.isAfter(local.updatedAt)) {
        AppLogger.instance.i('Applied remote changes for shared dashboard $shareId (conflict resolved)');
      } else {
        AppLogger.instance.i('Kept local changes for shared dashboard $shareId (conflict resolved)');
      }
    } else {
      toUse = remote ?? local;
    }

    if (toUse != null) {
      state = toUse.items;
      currentShareId = shareId;
      // Save the merged version locally
      await _repository.saveLocalSharedDashboard(toUse);
      _pushToHistory();
      _subscribeToSharedChanges(shareId);
      AppLogger.instance.i('Loaded shared dashboard: $shareId');
    } else {
      throw Exception('Shared dashboard not found');
    }
  }

  Future<List<Requirement>> loadRequirements() async {
    try {
      return await _repository.loadRequirements();
    } catch (e, st) {
      await _logError('load_requirements', e, st);
      ref.read(dashboardErrorProvider.notifier).state = 'dashboard_load_error';
      return [];
    }
  }

  Future<void> saveRequirement(Requirement req) async {
    try {
      if (_isOffline) {
        await _repository.queuePendingChange({'type': 'save_requirement', 'data': req.toJson()});
        AppLogger.instance.i('Queued requirement save: ${req.id}');
        ref.read(dashboardErrorProvider.notifier).state = 'Working offline – changes will sync when online';
      } else {
        await _repository.saveRequirement(req);
      }
    } catch (e, st) {
      await _logError('save_requirement', e, st);
      ref.read(dashboardErrorProvider.notifier).state = 'dashboard_action_failed';
    }
  }

  void _subscribeToSharedChanges(String shareId) {
    // Unsubscribe previous
    _channel?.unsubscribe();

    _channel = Supabase.instance.client.channel('shared_dashboard_$shareId');
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'shared_dashboards',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: shareId),
      callback: (payload) {
        AppLogger.instance.d('Realtime event for shared dashboard $shareId: ${payload.eventType}');
        if (payload.eventType == PostgresChangeEvent.update) {
          final updated = SharedDashboard.fromJson(payload.newRecord);
          state = updated.items;
          _pushToHistory();
        }
      },
    ).subscribe();
  }

  /// Helper methods for error handling and logging.
  /// See .github/issues/025-dashboard-error-handling.md for details.

  /// Logs dashboard operation errors with consistent formatting
  Future<void> _logError(String operation, Object error, StackTrace? stack) async {
    await AppLogger.error('dashboard_${operation}_failed', error: error, stackTrace: stack);
  }

  /// Logs dashboard events with optional parameters
  void _logEvent(String eventName, {Map<String, dynamic>? params}) {
    AppLogger.event('dashboard_$eventName', params: params);
  }
}

/// Example usage of undo/redo API in a ConsumerWidget:
/// 
/// ```dart
/// class DashboardToolbar extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final notifier = ref.read(dashboardConfigProvider.notifier);
///     final canUndo = ref.watch(dashboardConfigProvider.notifier).canUndo;
///     final canRedo = ref.watch(dashboardConfigProvider.notifier).canRedo;
///     final l10n = AppLocalizations.of(context)!;
/// 
///     return Row(
///       children: [
///         IconButton(
///           onPressed: canUndo ? () => notifier.undo() : null,
///           icon: const Icon(Icons.undo),
///           tooltip: l10n.undoTooltip,
///         ),
///         IconButton(
///           onPressed: canRedo ? () => notifier.redo() : null,
///           icon: const Icon(Icons.redo),
///           tooltip: l10n.redoTooltip,
///         ),
///       ],
///     );
///   }
/// }
/// ```
/// 
/// Localization keys required: undo, redo, undoTooltip, redoTooltip
/// 
/// Example error handling in UI with SnackBar:
/// 
/// ```dart
/// class DashboardErrorHandler extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final errorKey = ref.watch(dashboardErrorProvider);
///     final l10n = AppLocalizations.of(context)!;
///     
///     if (errorKey != null) {
///       // Clear error after showing
///       Future.microtask(() => ref.read(dashboardErrorProvider.notifier).state = null);
///       
///       WidgetsBinding.instance.addPostFrameCallback((_) {
///         ScaffoldMessenger.of(context).showSnackBar(
///           SnackBar(
///             content: Text(_getErrorMessage(l10n, errorKey)),
///             backgroundColor: Colors.red,
///           ),
///         );
///       });
///     }
///     
///     return const SizedBox.shrink();
///   }
///   
///   String _getErrorMessage(AppLocalizations l10n, String errorKey) {
///     switch (errorKey) {
///       case 'dashboard_load_error': return l10n.dashboard_load_error;
///       case 'dashboard_save_error': return l10n.dashboard_save_error;
///       case 'dashboard_action_failed': return l10n.dashboard_action_failed;
///       default: return l10n.dashboard_action_failed;
///     }
///   }
/// }
/// ```
/// See .github/issues/022-dashboard-undo-redo.md for details

/// Provider for dashboard configuration with widget type validation
final dashboardConfigProvider = NotifierProvider<DashboardConfigNotifier, List<DashboardItem>>(
  DashboardConfigNotifier.new,
);

/// Provider for dashboard repository
/// Provides HiveDashboardRepository implementation for local and remote storage
/// See .github/issues/026-dashboard-abstract-interface.md for abstraction details
final dashboardRepositoryProvider = Provider<IDashboardRepository>((ref) {
  return HiveDashboardRepository();
});

/// Provider for dashboard error state
final dashboardErrorProvider = StateProvider<String?>((ref) => null);

/// Resolves project name by ID from projects list, with fallback "Unknown Project"
/// See .github/issues/029-dashboard-import-projects-provider.md
String _resolveProjectName(List<ProjectModel> projects, String projectId) {
  final project = projects.firstWhereOrNull((p) => p.id == projectId);
  return project?.name ?? "Unknown Project";
}

/// Provider for project requirements by project ID with error handling.
/// Couples dashboard items to projectsProvider for displaying project-specific data.
/// See .github/issues/029-dashboard-import-projects-provider.md for integration details.
/// Uses AsyncValue.maybeWhen for robust loading/error state handling.
/// Resolves project name via _resolveProjectName helper for logging and future UI needs.
final projectRequirementsProvider = Provider.family<FutureProvider<ProjectRequirements>, String>((ref, projectId) {
  return FutureProvider<ProjectRequirements>((ref) async {
    final projectsAsync = ref.watch(projectsProvider);
    return projectsAsync.maybeWhen(
      data: (projects) async {
        final projectName = _resolveProjectName(projects, projectId);
        AppLogger.instance.i('Resolving requirements for project: $projectName');
        final project = projects.firstWhereOrNull((p) => p.id == projectId);
        if (project == null) return const ProjectRequirements();

        final repository = ref.read(dashboardRepositoryProvider);

        // If project has a category, try to fetch from API
        if (project.category != null && project.category!.isNotEmpty) {
          return await repository.fetchRequirements(project.category!);
        }

        // Otherwise return empty requirements
        return const ProjectRequirements();
      },
      loading: () async => const ProjectRequirements(),
      error: (e, st) async {
        AppLogger.instance.w('Failed to load projects for requirements: $e');
        return const ProjectRequirements();
      },
      orElse: () async {
        AppLogger.instance.w('Unexpected state in projectsAsync for requirements');
        return const ProjectRequirements();
      },
    );
  });
});

/// Provider for tracking offline sync status
/// Set to true when processing pending changes, false when idle
final offlineSyncStatusProvider = StateProvider<bool>((ref) => false);

// Reusable UI example for cache status display:
// Text(AppLocalizations.of(context)!.cacheRefreshed(DateTime.now().difference(_cacheTimestamp!).inSeconds)),
// Where _cacheTimestamp is exposed from repository or notifier.

// Reusable UI example for project requirements display in dashboard items:
// See .github/issues/029-dashboard-import-projects-provider.md
// class ProjectRequirementsCard extends ConsumerWidget {
//   final String projectId;
//   final DashboardWidgetType widgetType; // Respect widgetType enum (020)
//   final Map<String, dynamic> position; // Respect position constraints (021)
//
//   const ProjectRequirementsCard({
//     required this.projectId,
//     required this.widgetType,
//     required this.position,
//   });
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final requirementsAsync = ref.watch(projectRequirementsProvider(projectId));
//     final projectsAsync = ref.watch(projectsProvider);
//
//     return requirementsAsync.when(
//       data: (requirements) {
//         final projectName = projectsAsync.maybeWhen(
//           data: (projects) => _resolveProjectName(projects, projectId),
//           orElse: () => 'Unknown Project',
//         );
//         return Card(
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(projectName, style: Theme.of(context).textTheme.titleMedium),
//                 const SizedBox(height: 8),
//                 Text('Requirements: ${requirements.items.length}'),
//               ],
//             ),
//           ),
//         );
//       },
//       loading: () => const Card(
//         child: Padding(
//           padding: EdgeInsets.all(16.0),
//           child: Center(child: CircularProgressIndicator()),
//         ),
//       ),
//       error: (e, st) => Card(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//               const Icon(Icons.error),
//               Text('Error loading requirements: $e'),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
