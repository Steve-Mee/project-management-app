import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_project_management_app/core/repository/i_dashboard_repository.dart';
import 'package:my_project_management_app/core/services/requirements_service.dart';

/// Concrete implementation of IDashboardRepository using Hive for persistence
class DashboardRepository implements IDashboardRepository {
  static const String _boxName = 'dashboard_config';
  final RequirementsService _requirementsService;

  DashboardRepository({RequirementsService? requirementsService})
      : _requirementsService = requirementsService ?? RequirementsService();

  @override
  Future<List<DashboardItem>> loadDashboardConfig() async {
    try {
      final box = await Hive.openBox<List>(_boxName);
      final data = box.get('config', defaultValue: []);
      if (data != null) {
        return data.map((map) => DashboardItem.fromJson(map as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> saveDashboardConfig(List<DashboardItem> items) async {
    try {
      final box = await Hive.openBox<List>(_boxName);
      final data = items.map((item) => item.toJson()).toList();
      await box.put('config', data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> addDashboardItem(DashboardItem item) async {
    final items = await loadDashboardConfig();
    items.add(item);
    await saveDashboardConfig(items);
  }

  @override
  Future<void> removeDashboardItem(int index) async {
    final items = await loadDashboardConfig();
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      await saveDashboardConfig(items);
    }
  }

  @override
  Future<void> updateDashboardItemPosition(int index, Map<String, dynamic> newPosition) async {
    final items = await loadDashboardConfig();
    if (index >= 0 && index < items.length) {
      items[index] = DashboardItem(
        widgetType: items[index].widgetType,
        position: newPosition,
      );
      await saveDashboardConfig(items);
    }
  }

  @override
  Future<ProjectRequirements> fetchRequirements(String projectCategory) async {
    return _requirementsService.fetchRequirements(projectCategory);
  }

  @override
  ProjectRequirements parseRequirementsString(String requirementsString) {
    return _requirementsService.parseRequirementsString(requirementsString);
  }

  @override
  Future<void> close() async {
    try {
      final box = Hive.box<List>(_boxName);
      if (box.isOpen) {
        await box.close();
      }
    } catch (e) {
      // Ignore errors during close
    }
  }
}