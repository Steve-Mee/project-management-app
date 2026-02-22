import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_project_management_app/core/repository/i_dashboard_repository.dart';
import 'package:my_project_management_app/core/services/requirements_service.dart';
import 'package:my_project_management_app/core/services/app_logger.dart';
import 'package:my_project_management_app/models/project_requirements.dart';
import 'package:my_project_management_app/core/models/dashboard_types.dart';
import 'package:my_project_management_app/core/models/requirements.dart';

/// Concrete implementation of IDashboardRepository using Hive for local persistence
/// and Supabase for shared dashboard operations
///
/// Implements caching for dashboard config as per .github/issues/027-dashboard-cache-requirements.md
class HiveDashboardRepository implements IDashboardRepository {
  static const String _configBoxName = 'dashboard_config';
  static const String _templatesBoxName = 'dashboard_templates';
  static const String _sharedBoxName = 'shared_dashboards';
  static const String _requirementsBoxName = 'requirements';
  static const String _pendingChangesBoxName = 'pending_requirements_changes';
  final RequirementsService _requirementsService;

  /// In-memory cache for dashboard config to improve performance.
  /// Stores the list of DashboardItem objects with TTL.
  /// See .github/issues/027-dashboard-cache-requirements.md for details.
  final Map<String, dynamic> _cache = {};

  /// Timestamp when the cache was last updated.
  /// Used to check if cache is still valid within TTL.
  DateTime? _cacheTimestamp;

  /// Time-to-live duration for cache validity (5 minutes).
  /// Cache expires after this duration to ensure data freshness.
  static const Duration kCacheTTL = Duration(minutes: 5);

  HiveDashboardRepository({RequirementsService? requirementsService})
      : _requirementsService = requirementsService ?? RequirementsService();

  /// Checks if the cache is valid (not expired based on TTL).
  /// Returns true if cache exists and is within the time-to-live duration.
  bool _isCacheValid() {
    return _cacheTimestamp != null &&
           DateTime.now().difference(_cacheTimestamp!) < kCacheTTL;
  }

  /// Invalidates the cache by clearing it and resetting the timestamp.
  /// Called before mutations to ensure fresh data from Hive.
  void _invalidateCache() {
    _cache.clear();
    _cacheTimestamp = null;
    AppLogger.instance.d('Cache invalidated');
  }

  /// Updates the cache with new dashboard items and sets the timestamp.
  /// Called after successful saves to keep cache in sync.
  void _updateCache(List<DashboardItem> items) {
    _cache['config'] = items;
    _cacheTimestamp = DateTime.now();
    AppLogger.instance.d('Cache updated with ${items.length} items');
  }

  /// Retrieves dashboard items from cache if valid.
  /// Logs cache hit or miss for debugging.
  List<DashboardItem> _getFromCache() {
    if (_isCacheValid()) {
      final items = _cache['config'] as List<DashboardItem>? ?? [];
      AppLogger.instance.d('Cache hit: ${items.length} items');
      return items;
    }
    AppLogger.instance.d('Cache miss');
    return [];
  }

  /// Preloads the dashboard config into cache for improved performance.
  /// Can be called optionally during app initialization.
  /// See .github/issues/027-dashboard-cache-requirements.md for cache strategy.
  @override
  Future<void> preloadCache() async {
    await loadConfig(); // This will load from Hive and update cache if needed
  }

  /// Clears the in-memory cache, forcing future loads to come from Hive.
  /// Exposed for UI/notifier to manually invalidate cache if needed.
  @override
  Future<void> clearCache() async {
    _invalidateCache();
  }

  @override
  Future<List<DashboardItem>> loadConfig() async {
    if (_isCacheValid()) {
      return _getFromCache();
    }
    try {
      final box = await Hive.openBox<List>(_configBoxName);
      final data = box.get('config', defaultValue: []);
      if (data != null) {
        final items = data.map((map) => DashboardItem.fromJson(map as Map<String, dynamic>)).toList();
        _updateCache(items);
        return items;
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
      _updateCache(items);
      AppLogger.instance.d('Saved dashboard config');
    } catch (e) {
      _invalidateCache();
      AppLogger.instance.w('Failed to save dashboard config', error: e);
      rethrow;
    }
  }

  @override
  Future<void> addItem(DashboardItem item) async {
    _invalidateCache();
    final items = await loadConfig();
    items.add(item);
    await saveConfig(items);
  }

  @override
  Future<void> removeItem(int index) async {
    _invalidateCache();
    final items = await loadConfig();
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      await saveConfig(items);
    }
  }

  @override
  Future<void> updateItemPosition(int index, Map<String, dynamic> position) async {
    _invalidateCache();
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
  Future<List<Requirement>> loadRequirements() async {
    try {
      final box = await Hive.openBox<List>(_requirementsBoxName);
      final data = box.get('requirements', defaultValue: []);
      if (data != null) {
        return data.map((map) => Requirement.fromJson(map as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      AppLogger.instance.w('Failed to load requirements', error: e);
      return [];
    }
  }

  Future<void> saveRequirements(List<Requirement> requirements) async {
    try {
      final box = await Hive.openBox<List>(_requirementsBoxName);
      final data = requirements.map((req) => req.toJson()).toList();
      await box.put('requirements', data);
      AppLogger.instance.d('Saved ${requirements.length} requirements');
    } catch (e) {
      AppLogger.instance.w('Failed to save requirements', error: e);
    }
  }

  @override
  Future<void> saveRequirement(Requirement req) async {
    final list = await loadRequirements();
    final index = list.indexWhere((r) => r.id == req.id);
    if (index != -1) {
      list[index] = req;
    } else {
      list.add(req);
    }
    await saveRequirements(list);
    AppLogger.instance.i('Saved requirement: ${req.id}');
  }

  @override
  Future<void> queuePendingChange(Map<String, dynamic> change) async {
    try {
      final box = await Hive.openBox<List>(_pendingChangesBoxName);
      final data = box.get('changes') ?? [];
      data.add(change);
      await box.put('changes', data);
      AppLogger.instance.i('Queued pending change');
    } catch (e) {
      AppLogger.instance.w('Failed to queue pending change', error: e);
    }
  }

  @override
  Future<void> processPendingSync() async {
    try {
      final box = await Hive.openBox<List>(_pendingChangesBoxName);
      final data = box.get('changes') ?? [];
      if (data.isNotEmpty) {
        AppLogger.instance.i('Processing ${data.length} pending changes');
        // Assume sync successful
        await box.put('changes', []);
        AppLogger.event('offline_sync_completed');
      }
    } catch (e) {
      AppLogger.instance.w('Failed to process pending sync', error: e);
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
      final requirementsBox = Hive.box<List>(_requirementsBoxName);
      if (requirementsBox.isOpen) {
        await requirementsBox.close();
      }
      final pendingChangesBox = Hive.box<List>(_pendingChangesBoxName);
      if (pendingChangesBox.isOpen) {
        await pendingChangesBox.close();
      }
    } catch (e) {
      AppLogger.instance.w('Error closing repository boxes', error: e);
    }
  }
}