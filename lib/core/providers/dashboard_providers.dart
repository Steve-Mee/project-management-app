import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_project_management_app/models/project_requirements.dart';
import 'package:my_project_management_app/core/repository/i_dashboard_repository.dart';
import 'package:my_project_management_app/core/repository/dashboard_repository.dart';
import 'project_providers.dart';
import 'package:my_project_management_app/core/services/app_logger.dart';
import 'package:my_project_management_app/core/models/dashboard_types.dart';

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
/// TODO: Add dashboard templates
/// TODO: Add collaborative dashboard sharing
class DashboardConfigNotifier extends Notifier<List<DashboardItem>> {
  late final IDashboardRepository _repository;

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
    _history.clear();
    _currentIndex = -1;
    loadConfig().then((_) => _pushToHistory());
    return [];
  }

  Future<void> loadConfig() async {
    try {
      final items = await _repository.loadDashboardConfig();
      state = items;
    } catch (e) {
      // TODO: Add error handling/logging
      state = [];
    }
  }

  Future<void> saveConfig(List<DashboardItem> items) async {
    try {
      await _repository.saveDashboardConfig(items);
      state = items;
      _currentIndex = _history.length - 1;
    } catch (e) {
      // TODO: Add error handling/logging
      rethrow;
    }
  }

  /// Adds a new dashboard item with widget type validation and position constraint enforcement.
  /// The position is validated against the dashboard's bounding box and clamped if necessary
  /// to ensure x >= 0, y >= 0, x+width <= containerWidth, y+height <= containerHeight, and minimum dimensions.
  /// See .github/issues/020-dashboard-validate-widget-type.md and .github/issues/021-dashboard-position-constraints.md
  Future<void> addItem(DashboardItem item) async {
    validateWidgetType(item.widgetType.name);
    Map<String, dynamic> position = item.position;
    if (!_isValidPosition(position, kDashboardContainerWidth, kDashboardContainerHeight)) {
      position = _clampPosition(position, containerWidth: kDashboardContainerWidth, containerHeight: kDashboardContainerHeight);
    }
    final clampedItem = DashboardItem(widgetType: item.widgetType, position: position);
    await _repository.addDashboardItem(clampedItem);
    await loadConfig(); // Refresh state
    _pushToHistory();
  }

  /// Remove a dashboard item by index
  Future<void> removeItem(int index) async {
    await _repository.removeDashboardItem(index);
    await loadConfig(); // Refresh state
    _pushToHistory();
  }

  /// Updates an item's position after enforcing constraints to keep it within dashboard bounds.
  /// The new position is clamped to stay within the bounding box (x >= 0, y >= 0, x+width <= containerWidth, y+height <= containerHeight)
  /// and enforce minimum dimensions before saving.
  /// See .github/issues/021-dashboard-position-constraints.md for details.
  Future<void> updateItemPosition(int index, Map<String, dynamic> newPosition) async {
    final clampedPosition = _clampPosition(newPosition, containerWidth: kDashboardContainerWidth, containerHeight: kDashboardContainerHeight);
    await _repository.updateDashboardItemPosition(index, clampedPosition);
    await loadConfig(); // Refresh state
    _pushToHistory();
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
/// See .github/issues/022-dashboard-undo-redo.md for details

/// Provider for dashboard configuration with widget type validation
final dashboardConfigProvider = NotifierProvider<DashboardConfigNotifier, List<DashboardItem>>(
  DashboardConfigNotifier.new,
);

/// Provider for dashboard repository
final dashboardRepositoryProvider = Provider<IDashboardRepository>((ref) {
  return DashboardRepository();
});

/// Provider for project requirements by project ID with error handling
/// TODO: Add caching for requirements
/// TODO: Add offline requirements storage
final projectRequirementsProvider = FutureProvider.family<ProjectRequirements, String>((ref, projectId) async {
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