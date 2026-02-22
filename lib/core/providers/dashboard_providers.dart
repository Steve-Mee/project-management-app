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

/// Notifier for managing dashboard configuration with persistence and widget type validation
/// TODO: Add undo/redo functionality
/// TODO: Add dashboard templates
/// TODO: Add collaborative dashboard sharing
class DashboardConfigNotifier extends Notifier<List<DashboardItem>> {
  late final IDashboardRepository _repository;

  @override
  List<DashboardItem> build() {
    _repository = ref.read(dashboardRepositoryProvider);
    loadConfig();
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
    } catch (e) {
      // TODO: Add error handling/logging
      rethrow;
    }
  }

  /// Add a new dashboard item
  Future<void> addItem(DashboardItem item) async {
    validateWidgetType(item.widgetType.name);
    await _repository.addDashboardItem(item);
    await loadConfig(); // Refresh state
  }

  /// Remove a dashboard item by index
  Future<void> removeItem(int index) async {
    await _repository.removeDashboardItem(index);
    await loadConfig(); // Refresh state
  }

  /// Update item position
  Future<void> updateItemPosition(int index, Map<String, dynamic> newPosition) async {
    await _repository.updateDashboardItemPosition(index, newPosition);
    await loadConfig(); // Refresh state
  }
}

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