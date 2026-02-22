import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_project_management_app/core/repository/i_dashboard_repository.dart';
import 'package:my_project_management_app/core/services/requirements_service.dart';
import 'package:my_project_management_app/core/services/app_logger.dart';
import 'package:my_project_management_app/models/project_requirements.dart';
import 'package:my_project_management_app/core/models/dashboard_types.dart';

/// Concrete implementation of IDashboardRepository using Hive for local persistence
/// and Supabase for shared dashboard operations
class HiveDashboardRepository implements IDashboardRepository {
  static const String _configBoxName = 'dashboard_config';
  static const String _templatesBoxName = 'dashboard_templates';
  static const String _sharedBoxName = 'shared_dashboards';
  final RequirementsService _requirementsService;

  HiveDashboardRepository({RequirementsService? requirementsService})
      : _requirementsService = requirementsService ?? RequirementsService();

  @override
  Future<List<DashboardItem>> loadConfig() async {
    try {
      final box = await Hive.openBox<List>(_configBoxName);
      final data = box.get('config', defaultValue: []);
      if (data != null) {
        return data.map((map) => DashboardItem.fromJson(map as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      AppLogger.instance.w('Failed to load dashboard config', error: e);
      return [];
    }
  }

  @override
  Future<void> saveConfig(List<DashboardItem> items) async {
    try {
      final box = await Hive.openBox<List>(_configBoxName);
      final data = items.map((item) => item.toJson()).toList();
      await box.put('config', data);
      AppLogger.instance.d('Saved dashboard config');
    } catch (e) {
      AppLogger.instance.w('Failed to save dashboard config', error: e);
      rethrow;
    }
  }

  @override
  Future<void> addItem(DashboardItem item) async {
    final items = await loadConfig();
    items.add(item);
    await saveConfig(items);
  }

  @override
  Future<void> removeItem(int index) async {
    final items = await loadConfig();
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      await saveConfig(items);
    }
  }

  @override
  Future<void> updateItemPosition(int index, Map<String, dynamic> position) async {
    final items = await loadConfig();
    if (index >= 0 && index < items.length) {
      items[index] = DashboardItem(
        widgetType: items[index].widgetType,
        position: position,
      );
      await saveConfig(items);
    }
  }

  @override
  Future<List<DashboardTemplate>> loadTemplates() async {
    try {
      final box = await Hive.openBox<List>(_templatesBoxName);
      final data = box.get('templates', defaultValue: []);
      if (data != null) {
        return data.map((map) => DashboardTemplate.fromJson(map as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      AppLogger.instance.w('Failed to load dashboard templates', error: e);
      return [];
    }
  }

  @override
  Future<void> saveTemplates(List<DashboardTemplate> templates) async {
    try {
      final box = await Hive.openBox<List>(_templatesBoxName);
      final data = templates.map((template) => template.toJson()).toList();
      await box.put('templates', data);
      AppLogger.instance.d('Saved dashboard templates');
    } catch (e) {
      AppLogger.instance.w('Failed to save dashboard templates', error: e);
      rethrow;
    }
  }

  @override
  Future<SharedDashboard?> fetchSharedDashboard(String shareId) async {
    try {
      final response = await Supabase.instance.client.from('shared_dashboards').select().eq('id', shareId).single();
      AppLogger.instance.i('Fetched shared dashboard: $shareId');
      return SharedDashboard.fromJson(response);
    } catch (e) {
      AppLogger.instance.w('Failed to fetch shared dashboard: $shareId', error: e);
      return null;
    }
  }

  @override
  Future<void> saveSharedDashboard(SharedDashboard dashboard) async {
    await Supabase.instance.client.from('shared_dashboards').upsert(dashboard.toJson());
    AppLogger.instance.i('Saved shared dashboard: ${dashboard.id}');
  }

  @override
  Future<void> updateSharedPermissions(String shareId, Map<String, String> permissions) async {
    await Supabase.instance.client.from('shared_dashboards').update({'permissions': permissions}).eq('id', shareId);
    AppLogger.instance.i('Updated permissions for shared dashboard: $shareId');
  }

  @override
  Future<SharedDashboard?> loadLocalSharedDashboard(String shareId) async {
    try {
      final box = await Hive.openBox<Map>(_sharedBoxName);
      final data = box.get('shared_$shareId');
      if (data != null) {
        return SharedDashboard.fromJson(data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      AppLogger.instance.w('Failed to load local shared dashboard: $shareId', error: e);
      return null;
    }
  }

  @override
  Future<void> saveLocalSharedDashboard(SharedDashboard dashboard) async {
    try {
      final box = await Hive.openBox<Map>(_sharedBoxName);
      await box.put('shared_${dashboard.id}', dashboard.toJson());
      AppLogger.instance.d('Saved local shared dashboard: ${dashboard.id}');
    } catch (e) {
      AppLogger.instance.w('Failed to save local shared dashboard: ${dashboard.id}', error: e);
      // Ignore local save errors
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
      final configBox = Hive.box<List>(_configBoxName);
      if (configBox.isOpen) {
        await configBox.close();
      }
      final templatesBox = Hive.box<List>(_templatesBoxName);
      if (templatesBox.isOpen) {
        await templatesBox.close();
      }
      final sharedBox = Hive.box<Map>(_sharedBoxName);
      if (sharedBox.isOpen) {
        await sharedBox.close();
      }
    } catch (e) {
      AppLogger.instance.w('Error closing repository boxes', error: e);
    }
  }
}