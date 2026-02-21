import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_project_management_app/models/project_requirements.dart';
import 'package:my_project_management_app/core/services/requirements_service.dart';

/// Dashboard item configuration
/// TODO: Add validation for widgetType
/// TODO: Add position constraints/boundaries
class DashboardItem {
  final String widgetType;
  final Map<String, dynamic> position;

  const DashboardItem({
    required this.widgetType,
    required this.position,
  });

  Map<String, dynamic> toJson() => {
        'widgetType': widgetType,
        'position': position,
      };

  factory DashboardItem.fromJson(Map<String, dynamic> json) => DashboardItem(
        widgetType: json['widgetType'],
        position: json['position'],
      );
}

/// Notifier for managing dashboard configuration with persistence
/// TODO: Add undo/redo functionality
/// TODO: Add dashboard templates
/// TODO: Add collaborative dashboard sharing
class DashboardConfigNotifier extends Notifier<List<DashboardItem>> {
  @override
  List<DashboardItem> build() {
    loadConfig();
    return [];
  }

  Future<void> loadConfig() async {
    try {
      final box = await Hive.openBox<List>('dashboard_config');
      final data = box.get('config', defaultValue: []);
      if (data != null) {
        state = data.map((map) => DashboardItem.fromJson(map as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // TODO: Add error handling/logging
      state = [];
    }
  }

  Future<void> saveConfig(List<DashboardItem> items) async {
    try {
      final box = await Hive.openBox<List>('dashboard_config');
      final data = items.map((item) => item.toJson()).toList();
      await box.put('config', data);
      state = items;
    } catch (e) {
      // TODO: Add error handling/logging
      rethrow;
    }
  }

  /// Add a new dashboard item
  Future<void> addItem(DashboardItem item) async {
    final newItems = [...state, item];
    await saveConfig(newItems);
  }

  /// Remove a dashboard item by index
  Future<void> removeItem(int index) async {
    if (index < 0 || index >= state.length) return;
    final newItems = List<DashboardItem>.from(state)..removeAt(index);
    await saveConfig(newItems);
  }

  /// Update item position
  Future<void> updateItemPosition(int index, Map<String, dynamic> newPosition) async {
    if (index < 0 || index >= state.length) return;
    final newItems = List<DashboardItem>.from(state);
    newItems[index] = DashboardItem(
      widgetType: newItems[index].widgetType,
      position: newPosition,
    );
    await saveConfig(newItems);
  }
}

/// Provider for dashboard configuration
final dashboardConfigProvider = NotifierProvider<DashboardConfigNotifier, List<DashboardItem>>(
  DashboardConfigNotifier.new,
);

/// Provider for requirements service
/// TODO: Consider using an abstract interface for easy testing/swapping
final requirementsServiceProvider = Provider<RequirementsService>((ref) {
  return RequirementsService();
});

/// Provider for project requirements by project ID with error handling
/// TODO: Add caching for requirements
/// TODO: Add offline requirements storage
final projectRequirementsProvider = FutureProvider.family<ProjectRequirements, String>((ref, projectId) async {
  // TODO: Import projectsProvider when available
  // final projectsAsync = ref.watch(projectsProvider);
  // For now, return empty requirements
  return const ProjectRequirements();

  // Original implementation (commented until projectsProvider is available):
  /*
  // TODO: migrate to projectsPaginatedProvider (issue #004)
  final projectsAsync = ref.watch(projectsProvider);
  return projectsAsync.maybeWhen(
    data: (projects) {
      final project = projects.firstWhere(
        (p) => p.id == projectId,
        orElse: () => throw Exception('Project not found'),
      );

      final service = ref.read(requirementsServiceProvider);

      // If project has a category, try to fetch from API
      if (project.category != null && project.category!.isNotEmpty) {
        return service.fetchRequirements(project.category!);
      }

      // Otherwise return empty requirements
      return const ProjectRequirements();
    },
    orElse: () => const ProjectRequirements(),
  );
  */
});