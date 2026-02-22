import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:my_project_management_app/models/project_requirements.dart';
import 'package:my_project_management_app/core/repository/i_dashboard_repository.dart';
import 'package:my_project_management_app/core/repository/dashboard_repository.dart';
import 'project_providers.dart';
import 'package:my_project_management_app/core/services/app_logger.dart';
import 'package:my_project_management_app/core/models/dashboard_types.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

  @override
  List<DashboardItem> build() {
    _repository = ref.read(dashboardRepositoryProvider);
    _userTemplates = [];
    _history.clear();
    _currentIndex = -1;
    loadConfig().then((_) => _pushToHistory());
    return [];
  }

  Future<void> loadConfig() async {
    try {
      final items = await _repository.loadDashboardConfig();
      state = items;
      _userTemplates = await _loadTemplates();
      _logEvent('config_loaded');
    } catch (e, st) {
      _logError('load_config', e, st);
      state = [];
      _userTemplates = [];
      ref.read(dashboardErrorProvider.notifier).state = 'dashboard_load_error';
    }
  }

  Future<void> saveConfig(List<DashboardItem> items) async {
    try {
      await _repository.saveDashboardConfig(items);
      state = items;
      _currentIndex = _history.length - 1;

      // If shared, also push to Supabase
      if (currentShareId != null) {
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        if (currentUserId != null) {
          final existing = await _fetchSharedDashboard(currentShareId!);
          final dashboard = SharedDashboard(
            id: currentShareId!,
            ownerId: existing?.ownerId ?? currentUserId,
            title: existing?.title ?? 'Shared Dashboard',
            items: items,
            permissions: existing?.permissions ?? {},
            updatedAt: DateTime.now(),
          );
          await _saveSharedDashboard(dashboard);
          await _saveLocalSharedDashboard(dashboard);
        }
      }
      _logEvent('config_saved');
    } catch (e, st) {
      _logError('save_config', e, st);
      ref.read(dashboardErrorProvider.notifier).state = 'dashboard_save_error';
      rethrow;
    }
  }

  /// Loads user-created dashboard templates from Hive storage
  Future<List<DashboardTemplate>> _loadTemplates() async {
    try {
      final box = await Hive.openBox<List>('dashboard_templates');
      final data = box.get('templates', defaultValue: []);
      if (data != null) {
        return data.map((map) => DashboardTemplate.fromJson(map as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Saves user-created dashboard templates to Hive storage
  Future<void> _saveTemplates(List<DashboardTemplate> templates) async {
    try {
      final box = await Hive.openBox<List>('dashboard_templates');
      final data = templates.map((template) => template.toJson()).toList();
      await box.put('templates', data);
    } catch (e) {
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
      await _repository.addDashboardItem(clampedItem);
      await loadConfig(); // Refresh state
      _pushToHistory();
      _logEvent('item_added', params: {'widgetType': item.widgetType.name, 'position': position});
    } catch (e, st) {
      _logError('add_item', e, st);
      ref.read(dashboardErrorProvider.notifier).state = 'dashboard_action_failed';
      rethrow;
    }
  }

  /// Remove a dashboard item by index
  Future<void> removeItem(int index) async {
    try {
      await _repository.removeDashboardItem(index);
      await loadConfig(); // Refresh state
      _pushToHistory();
      _logEvent('item_removed', params: {'index': index});
    } catch (e, st) {
      _logError('remove_item', e, st);
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
      await _repository.updateDashboardItemPosition(index, clampedPosition);
      await loadConfig(); // Refresh state
      _pushToHistory();
      _logEvent('position_updated', params: {'index': index, 'newPosition': clampedPosition});
    } catch (e, st) {
      _logError('update_position', e, st);
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
    final userTemplates = await _loadTemplates();
    userTemplates.add(template);
    await _saveTemplates(userTemplates);
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
    await _saveTemplates(userTemplates);
    _userTemplates = userTemplates;
    AppLogger.instance.i('Deleted dashboard template: $templateId');
  }

  Future<SharedDashboard?> _fetchSharedDashboard(String shareId) async {
    try {
      final response = await Supabase.instance.client.from('shared_dashboards').select().eq('id', shareId).single();
      AppLogger.instance.i('Fetched shared dashboard: $shareId');
      return SharedDashboard.fromJson(response);
    } catch (e) {
      AppLogger.instance.w('Failed to fetch shared dashboard: $shareId', error: e);
      return null;
    }
  }

  Future<void> _saveSharedDashboard(SharedDashboard dashboard) async {
    await Supabase.instance.client.from('shared_dashboards').upsert(dashboard.toJson());
    AppLogger.instance.i('Saved shared dashboard: ${dashboard.id}');
  }

  Future<void> _updatePermissions(String shareId, Map<String, String> permissions) async {
    await Supabase.instance.client.from('shared_dashboards').update({'permissions': permissions}).eq('id', shareId);
    AppLogger.instance.i('Updated permissions for shared dashboard: $shareId');
  }

  Future<bool> hasPermission(String shareId, DashboardPermission required) async {
    final dashboard = await _fetchSharedDashboard(shareId);
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

    await _saveSharedDashboard(dashboard);
    AppLogger.instance.i('Generated share link for dashboard: $shareId');
    return shareId;
  }

  Future<void> inviteUser(String shareId, String userId, DashboardPermission perm) async {
    final dashboard = await _fetchSharedDashboard(shareId);
    if (dashboard == null) throw Exception('Shared dashboard not found');

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId != dashboard.ownerId) throw Exception('Only owner can invite users');

    final updatedPermissions = Map<String, String>.from(dashboard.permissions);
    updatedPermissions[userId] = perm.name;

    await _updatePermissions(shareId, updatedPermissions);
    AppLogger.event('dashboard_invite', details: {'shareId': shareId, 'userId': userId, 'permission': perm.name});
  }

  Future<SharedDashboard?> _loadLocalSharedDashboard(String shareId) async {
    try {
      final box = await Hive.openBox<Map>('shared_dashboards');
      final data = box.get('shared_$shareId');
      if (data != null) {
        return SharedDashboard.fromJson(data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveLocalSharedDashboard(SharedDashboard dashboard) async {
    try {
      final box = await Hive.openBox<Map>('shared_dashboards');
      await box.put('shared_${dashboard.id}', dashboard.toJson());
    } catch (e) {
      // Ignore local save errors
    }
  }

  Future<void> loadSharedDashboard(String shareId) async {
    final remote = await _fetchSharedDashboard(shareId);
    final local = await _loadLocalSharedDashboard(shareId);

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
      await _saveLocalSharedDashboard(toUse);
      _pushToHistory();
      _subscribeToSharedChanges(shareId);
      AppLogger.instance.i('Loaded shared dashboard: $shareId');
    } else {
      throw Exception('Shared dashboard not found');
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
  void _logError(String operation, Object error, StackTrace? stack) {
    AppLogger.instance.e('dashboard_${operation}_failed', error: error, stackTrace: stack);
  }

  /// Logs dashboard events with optional parameters
  void _logEvent(String eventName, {Map<String, dynamic>? params}) {
    AppLogger.event('dashboard_$eventName', details: params);
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
final dashboardRepositoryProvider = Provider<IDashboardRepository>((ref) {
  return DashboardRepository();
});

/// Provider for dashboard error state
final dashboardErrorProvider = StateProvider<String?>((ref) => null);

/// Provider for project requirements by project ID with error handling
/// TODO: Add caching for requirements
/// TODO: Add offline requirements storage
final projectRequirementsProvider = Provider.family<FutureProvider<ProjectRequirements>, String>((ref, projectId) {
  return FutureProvider<ProjectRequirements>((ref) async {
    final projectAsync = ref.watch(projectByIdProvider(projectId));
    return projectAsync.maybeWhen(
      data: (project) {
        if (project == null) return const ProjectRequirements();

        final repository = ref.read(dashboardRepositoryProvider);

        // If project has a category, try to fetch from API
        if (project.category != null && project.category!.isNotEmpty) {
          return repository.fetchRequirements(project.category!);
        }

        // Otherwise return empty requirements
        return const ProjectRequirements();
      },
      orElse: () => const ProjectRequirements(),
    );
  });
});
