import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_project_management_app/core/services/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ABTestingService {
  ABTestingService._();

  static final ABTestingService instance = ABTestingService._();
  static const String _boxName = 'ab_testing';
  static const String _configKey = 'config';
  static const String _lastFetchKey = 'last_fetch';
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    _initialized = true;
  }

  Box get _box => Hive.box(_boxName);

  Future<String> assignGroupForUser(String userId) async {
    final stored = _box.get(_groupKey(userId)) as String?;
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }
    final group = _stableGroup(userId);
    await _box.put(_groupKey(userId), group);
    AppLogger.event('ab_group_assigned', details: {'id': userId, 'group': group});
    return group;
  }

  String? getGroupForUser(String userId) {
    final stored = _box.get(_groupKey(userId)) as String?;
    return stored != null && stored.isNotEmpty ? stored : null;
  }

  Future<void> fetchRemoteConfigs() async {
    try {
      final supabase = Supabase.instance.client;
      final response =
          await supabase.from('ab_configs').select('key,value') as List<dynamic>;
      final configs = <String, Object?>{};
      for (final row in response) {
        final rowMap = Map<String, Object?>.from(row as Map);
        final key = rowMap['key'] as String?;
        final value = rowMap['value'];
        if (key != null && key.isNotEmpty) {
          configs[key] = value;
        }
      }
      await _box.put(_configKey, configs);
      await _box.put(_lastFetchKey, DateTime.now().toIso8601String());
      AppLogger.event('ab_configs_fetched', details: {'count': configs.length});
    } catch (e) {
      AppLogger.instance.w('Failed to fetch A/B configs', error: e);
    }
  }

  Map<String, Object?> getConfigs() {
    final stored = _box.get(_configKey) as Map?;
    if (stored == null) {
      return const {};
    }
    return Map<String, Object?>.from(stored);
  }

  bool isFeatureEnabled(String key, String group) {
    final configs = getConfigs();
    final value = configs[key];
    if (value is bool) {
      return value;
    }
    if (value is Map) {
      final enabled = value['enabled'];
      if (enabled is bool && enabled == false) {
        return false;
      }
      final groups = value['enabledGroups'];
      if (groups is List) {
        return groups.contains(group);
      }
    }
    return false;
  }

  String _groupKey(String userId) => 'group_$userId';

  String _stableGroup(String userId) {
    final hash = userId.hashCode.abs();
    return hash % 2 == 0 ? 'A' : 'B';
  }
}
