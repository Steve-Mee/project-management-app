import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_project_management_app/models/project_requirements.dart';
import 'package:my_project_management_app/core/repository/i_dashboard_repository.dart';
import 'package:my_project_management_app/core/repository/dashboard_repository.dart';
import 'project_providers.dart';

/// Notifier for managing dashboard configuration with persistence
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

/// Provider for dashboard configuration
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