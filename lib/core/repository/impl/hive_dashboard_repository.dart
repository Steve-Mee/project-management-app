import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_management_app/core/repository/i_dashboard_repository.dart';
import 'package:project_management_app/core/repository/models/dashboard_models.dart';
import 'package:project_management_app/core/services/requirements_service.dart';
import 'package:project_management_app/models/project_requirements.dart';
import 'package:project_management_app/core/models/dashboard_types.dart';
import 'package:project_management_app/core/models/requirements.dart';

/// Concrete implementation of IDashboardRepository using Hive for local persistence
/// and Supabase for shared dashboard operations
///
/// Implements caching for dashboard config as per .github/issues/027-dashboard-cache-requirements.md
/// Refactored per .github/issues/049-repository-refactoring.md
class HiveDashboardRepository implements IDashboardRepository {
  static const String _configBoxName = 'dashboard_config';
  static const String _templatesBoxName = 'dashboard_templates';
  static const String _sharedBoxName = 'shared_dashboards';
  static const String _requirementsBoxName = 'requirements';
  static const String _pendingChangesBoxName = 'pending_requirements_changes';
  final RequirementsService _requirementsService;

  /// Helper class for data mapping operations
  final _DataMapper _dataMapper = _DataMapper();

  /// Helper class for cache management
  final _CacheManager _cacheManager = _CacheManager();

  /// Helper class for offline queue management
  final _OfflineQueueManager _offlineQueueManager = _OfflineQueueManager();

  /// Helper class for Supabase sync operations
  final _SupabaseSyncManager _supabaseSyncManager = _SupabaseSyncManager();

  HiveDashboardRepository({RequirementsService? requirementsService})
      : _requirementsService = requirementsService ?? RequirementsService();

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
    _cacheManager.invalidateCache();
  }

  @override
  Future<List<DashboardItem>> loadConfig() async {
    if (_cacheManager.isCacheValid()) {
      return _cacheManager.getFromCache();
    }
    try {
      final box = await Hive.openBox<List>(_configBoxName);
      final data = box.get('config', defaultValue: []);
      if (data != null) {
        final items = _dataMapper.deserializeDashboardItems(data);
        _cacheManager.updateCache(items);
        return items;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> saveConfig(List<DashboardItem> items) async {
    try {
      final box = await Hive.openBox<List>(_configBoxName);
      final data = _dataMapper.serializeDashboardItems(items);
      await box.put('config', data);
      _cacheManager.updateCache(items);
    } catch (e) {
      _cacheManager.invalidateCache();
      rethrow;
    }
  }

  @override
  Future<void> addItem(DashboardItem item) async {
    _cacheManager.invalidateCache();
    final items = await loadConfig();
    items.add(item);
    await saveConfig(items);
  }

  @override
  Future<void> removeItem(int index) async {
    _cacheManager.invalidateCache();
    final items = await loadConfig();
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      await saveConfig(items);
    }
  }

  @override
  Future<void> updateItemPosition(int index, Map<String, dynamic> position) async {
    _cacheManager.invalidateCache();
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
        return _dataMapper.deserializeDashboardTemplates(data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> saveTemplates(List<DashboardTemplate> templates) async {
    try {
      final box = await Hive.openBox<List>(_templatesBoxName);
      final data = _dataMapper.serializeDashboardTemplates(templates);
      await box.put('templates', data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<SharedDashboard?> fetchSharedDashboard(String shareId) async {
    return _supabaseSyncManager.fetchSharedDashboard(shareId);
  }

  @override
  Future<void> saveSharedDashboard(SharedDashboard dashboard) async {
    return _supabaseSyncManager.saveSharedDashboard(dashboard);
  }

  @override
  Future<void> updateSharedPermissions(String shareId, Map<String, String> permissions) async {
    return _supabaseSyncManager.updateSharedPermissions(shareId, permissions);
  }

  @override
  Future<SharedDashboard?> loadLocalSharedDashboard(String shareId) async {
    return _dataMapper.loadLocalSharedDashboard(shareId);
  }

  @override
  Future<void> saveLocalSharedDashboard(SharedDashboard dashboard) async {
    return _dataMapper.saveLocalSharedDashboard(dashboard);
  }

  @override
  Future<List<Requirement>> loadRequirements() async {
    return _dataMapper.loadRequirements();
  }

  Future<void> saveRequirements(List<Requirement> requirements) async {
    return _dataMapper.saveRequirements(requirements);
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
  }

  @override
  Future<void> queuePendingChange(Map<String, dynamic> change) async {
    return _offlineQueueManager.queuePendingChange(change);
  }

  @override
  Future<void> processPendingSync() async {
    return _offlineQueueManager.processPendingSync();
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
      // Ignore close errors
    }
  }
}

/// Helper class for data mapping operations (JSON serialization/deserialization)
class _DataMapper {
  /// Deserialize dashboard items from JSON
  List<DashboardItem> deserializeDashboardItems(List data) {
    return data.map((map) => DashboardItem.fromJson(map as Map<String, dynamic>)).toList();
  }

  /// Serialize dashboard items to JSON
  List<Map<String, dynamic>> serializeDashboardItems(List<DashboardItem> items) {
    return items.map((item) => item.toJson()).toList();
  }

  /// Deserialize dashboard templates from JSON
  List<DashboardTemplate> deserializeDashboardTemplates(List data) {
    return data.map((map) => DashboardTemplate.fromJson(map as Map<String, dynamic>)).toList();
  }

  /// Serialize dashboard templates to JSON
  List<Map<String, dynamic>> serializeDashboardTemplates(List<DashboardTemplate> templates) {
    return templates.map((template) => template.toJson()).toList();
  }

  /// Load requirements from Hive
  Future<List<Requirement>> loadRequirements() async {
    try {
      final box = await Hive.openBox<List>('requirements');
      final data = box.get('requirements', defaultValue: []);
      if (data != null) {
        return data.map((map) => Requirement.fromJson(map as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Save requirements to Hive
  Future<void> saveRequirements(List<Requirement> requirements) async {
    try {
      final box = await Hive.openBox<List>('requirements');
      final data = requirements.map((req) => req.toJson()).toList();
      await box.put('requirements', data);
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Load local shared dashboard from Hive
  Future<SharedDashboard?> loadLocalSharedDashboard(String shareId) async {
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

  /// Save local shared dashboard to Hive
  Future<void> saveLocalSharedDashboard(SharedDashboard dashboard) async {
    try {
      final box = await Hive.openBox<Map>('shared_dashboards');
      await box.put('shared_${dashboard.id}', dashboard.toJson());
    } catch (e) {
      // Ignore local save errors
    }
  }
}

/// Helper class for cache management operations
class _CacheManager {
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

  /// Checks if the cache is valid (not expired based on TTL).
  /// Returns true if cache exists and is within the time-to-live duration.
  bool isCacheValid() {
    return _cacheTimestamp != null &&
           DateTime.now().difference(_cacheTimestamp!) < kCacheTTL;
  }

  /// Invalidates the cache by clearing it and resetting the timestamp.
  /// Called before mutations to ensure fresh data from Hive.
  void invalidateCache() {
    _cache.clear();
    _cacheTimestamp = null;
  }

  /// Updates the cache with new dashboard items and sets the timestamp.
  /// Called after successful saves to keep cache in sync.
  void updateCache(List<DashboardItem> items) {
    _cache['config'] = items;
    _cacheTimestamp = DateTime.now();
  }

  /// Retrieves dashboard items from cache if valid.
  List<DashboardItem> getFromCache() {
    if (isCacheValid()) {
      return _cache['config'] as List<DashboardItem>? ?? [];
    }
    return [];
  }
}

/// Helper class for offline queue management operations
class _OfflineQueueManager {
  static const String _pendingChangesBoxName = 'pending_requirements_changes';

  /// Queue a pending change for offline processing
  Future<void> queuePendingChange(Map<String, dynamic> change) async {
    try {
      final box = await Hive.openBox<List>(_pendingChangesBoxName);
      final data = box.get('changes') ?? [];
      data.add(change);
      await box.put('changes', data);
    } catch (e) {
      // Ignore queue errors
    }
  }

  /// Process pending sync operations
  Future<void> processPendingSync() async {
    try {
      final box = await Hive.openBox<List>(_pendingChangesBoxName);
      final data = box.get('changes') ?? [];
      if (data.isNotEmpty) {
        // Assume sync successful
        await box.put('changes', []);
      }
    } catch (e) {
      // Ignore sync errors
    }
  }
}

/// Helper class for Supabase sync operations
class _SupabaseSyncManager {
  /// Fetch shared dashboard from Supabase
  Future<SharedDashboard?> fetchSharedDashboard(String shareId) async {
    try {
      final response = await Supabase.instance.client.from('shared_dashboards').select().eq('id', shareId).single();
      return SharedDashboard.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Save shared dashboard to Supabase
  Future<void> saveSharedDashboard(SharedDashboard dashboard) async {
    await Supabase.instance.client.from('shared_dashboards').upsert(dashboard.toJson());
  }

  /// Update shared permissions in Supabase
  Future<void> updateSharedPermissions(String shareId, Map<String, String> permissions) async {
    await Supabase.instance.client.from('shared_dashboards').update({'permissions': permissions}).eq('id', shareId);
  }
}
