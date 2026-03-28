import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:pma_core/core/feature_flags/feature_flag.dart';
import 'package:pma_core/core/feature_flags/feature_flag_resolver.dart';
import 'package:pma_core/core/services/analytics_events.dart';
import 'package:pma_core/core/services/analytics_service.dart';
import 'package:pma_core/services/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class FeatureFlagServiceBase {
  Future<List<Map>> fetchFeatureFlags();
  Future<List<Map>> getCachedFeatureFlags();
  Future<Map<String, dynamic>> getCachedFeatureFlagsByKey();
  Future<bool> isCacheStale({Duration ttl});
  Future<void> refresh();
  Future<bool> setFeatureEnabled(String key, bool enabled);
  Future<bool> getFlag(String key, {bool defaultValue = false});
}

/// Fetches and caches feature flags from Supabase.
///
/// Caching strategy mirrors the existing A/B testing pattern:
/// - flags are stored in a local Hive box
/// - the last successful fetch timestamp is stored for diagnostics
/// - reads prefer cache and gracefully fall back to defaults on failures
class FeatureFlagService implements FeatureFlagServiceBase {
  FeatureFlagService({
    required SupabaseClient supabaseClient,
    AnalyticsService? analyticsService,
    Future<List<Map>> Function()? remoteFetchOverride,
    bool useFlutterHiveInit = true,
  })  : _supabase = supabaseClient,
        _analyticsService =
            analyticsService ??
          SupabaseAnalyticsService(supabaseClient),
      _remoteFetchOverride = remoteFetchOverride,
      _useFlutterHiveInit = useFlutterHiveInit;

  final SupabaseClient _supabase;
  final AnalyticsService _analyticsService;
  final Future<List<Map>> Function()? _remoteFetchOverride;
  final bool _useFlutterHiveInit;

  static const String _boxName = 'feature_flags';
  static const String _flagsCacheKey = 'flags';
  static const String _lastFetchKey = 'last_fetch';
  static const Duration defaultCacheTtl = Duration(minutes: 30);
  static const Map<String, bool> _defaultBootstrapFlags =
      <String, bool>{
        'three_d_visualization_enabled': true,
      };

  bool _initialized = false;

  /// Opens the local Hive cache box.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    if (_useFlutterHiveInit) {
      await Hive.initFlutter();
    }
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }

    _initialized = true;
  }

  Box get _box => Hive.box(_boxName);

  Future<DateTime?> getLastFetchAt() async {
    await initialize();
    final raw = _box.get(_lastFetchKey);
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  @override
  Future<bool> isCacheStale({Duration ttl = defaultCacheTtl}) async {
    final lastFetch = await getLastFetchAt();
    if (lastFetch == null) {
      return true;
    }
    return DateTime.now().difference(lastFetch) > ttl;
  }

  /// Loads all feature flags from Supabase and writes them to cache.
  ///
  /// Returns a normalized list of map rows.
  /// Throws if the remote fetch fails.
  @override
  Future<List<Map>> fetchFeatureFlags() async {
    await initialize();

    final rows = _remoteFetchOverride != null
        ? await _remoteFetchOverride!()
        : _normalizeRows(await _supabase.from('feature_flags').select());
    final mergedRows = _mergeDefaultFlags(rows);

    await _box.put(_flagsCacheKey, mergedRows);
    await _box.put(_lastFetchKey, DateTime.now().toIso8601String());

    AppLogger.event('feature_flags_fetched', params: {'count': mergedRows.length});
    return mergedRows;
  }

  /// Returns cached rows from Hive without making a network request.
  @override
  Future<List<Map>> getCachedFeatureFlags() async {
    await initialize();
    final cached = _readCachedFlags();
    final merged = _mergeDefaultFlags(cached);
    if (merged.length != cached.length) {
      await _box.put(_flagsCacheKey, merged);
    }
    return merged;
  }

  /// Returns cached feature flags keyed by flag `key`.
  @override
  Future<Map<String, dynamic>> getCachedFeatureFlagsByKey() async {
    final rows = await getCachedFeatureFlags();
    return _rowsToMap(rows);
  }

  /// Attempts to refresh feature flags from Supabase.
  ///
  /// Errors are logged and swallowed so callers can safely refresh in
  /// background without crashing UI flows.
  @override
  Future<void> refresh() async {
    try {
      await fetchFeatureFlags();
    } catch (error, stackTrace) {
      AppLogger.instance.w(
        'Failed to refresh feature flags',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Persists a feature flag row to Supabase and updates local cache on success.
  ///
  /// Returns `true` when the remote write succeeds, `false` otherwise.
  Future<bool> upsertFeatureFlag({
    required String key,
    required bool enabled,
    Object? value,
    String? description,
  }) async {
    await initialize();
    final nowIso = DateTime.now().toIso8601String();

    final previousRow = _readCachedFlagByKey(key);
    final previousEnabled = previousRow == null
        ? null
        : FeatureFlagResolver.resolveEnabled(
            previousRow,
            defaultValue: false,
          );
    final previousValue = previousRow?['value'];

    try {
      await _supabase.from('feature_flags').upsert({
        'key': key,
        'enabled': enabled,
        'value': value,
        if (description != null) 'description': description,
        'updated_at': nowIso,
      });

      final rows = _readCachedFlags();
      final next = <Map>[];
      var replaced = false;

      for (final row in rows) {
        final rowKey = row['key'];
        if (rowKey == key) {
          replaced = true;
          next.add({
            ...Map<String, dynamic>.from(row),
            'enabled': enabled,
            'value': value,
            if (description != null) 'description': description,
            'updated_at': nowIso,
          });
        } else {
          next.add(row);
        }
      }

      if (!replaced) {
        next.add({
          'key': key,
          'enabled': enabled,
          'value': value,
          if (description != null) 'description': description,
          'updated_at': nowIso,
        });
      }

      await _box.put(_flagsCacheKey, next);
      await _box.put(_lastFetchKey, nowIso);

      await _recordFeatureFlagAuditLog(
        key: key,
        previousEnabled: previousEnabled,
        nextEnabled: enabled,
        previousValue: previousValue,
        nextValue: value,
      );

      AppLogger.event('feature_flag_upserted', params: {'key': key, 'enabled': enabled});
      return true;
    } catch (error, stackTrace) {
      AppLogger.instance.w(
        'Failed to upsert feature flag: $key',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Future<bool> setFeatureEnabled(String key, bool enabled) {
    return upsertFeatureFlag(key: key, enabled: enabled);
  }

  /// Reads a single feature flag by [key].
  ///
  /// Returns [defaultValue] when:
  /// - the flag is not found
  /// - data is malformed
  /// - both remote fetch and cache lookup fail
  @override
  Future<bool> getFlag(String key, {bool defaultValue = false}) async {
    await initialize();

    var source = 'default';

    try {
      final cachedRows = _readCachedFlags();
      final cachedValue = _resolveFlagFromRows(cachedRows, key);
      if (cachedValue != null) {
        source = 'cache';
        AppLogger.event('feature_flag_evaluated', params: {
          'key': key,
          'enabled': cachedValue,
          'source': source,
        });
        return cachedValue;
      }

      try {
        final remoteRows = await fetchFeatureFlags();
        final remoteValue = _resolveFlagFromRows(remoteRows, key);
        if (remoteValue != null) {
          source = 'remote';
          AppLogger.event('feature_flag_evaluated', params: {
            'key': key,
            'enabled': remoteValue,
            'source': source,
          });
          return remoteValue;
        }
      } catch (error, stackTrace) {
        AppLogger.instance.w(
          'Feature flag fetch failed, using cached/default value',
          error: error,
          stackTrace: stackTrace,
        );

        final fallbackRows = _readCachedFlags();
        final fallbackValue = _resolveFlagFromRows(fallbackRows, key);
        if (fallbackValue != null) {
          source = 'cache_fallback';
          AppLogger.event('feature_flag_fallback_cache', params: {'key': key});
          AppLogger.event('feature_flag_evaluated', params: {
            'key': key,
            'enabled': fallbackValue,
            'source': source,
          });
          return fallbackValue;
        }
      }
    } catch (error, stackTrace) {
      AppLogger.instance.w(
        'Failed to resolve feature flag: $key',
        error: error,
        stackTrace: stackTrace,
      );
    }

    AppLogger.event('feature_flag_default_used', params: {'key': key});
    AppLogger.event('feature_flag_evaluated', params: {
      'key': key,
      'enabled': defaultValue,
      'source': source,
    });
    return defaultValue;
  }

  List<Map> _readCachedFlags() {
    final cached = _box.get(_flagsCacheKey);
    return _normalizeRows(cached);
  }

  Map<String, dynamic>? _readCachedFlagByKey(String key) {
    final rows = _readCachedFlags();
    for (final row in rows) {
      final rowKey = row['key'];
      if (rowKey is String && rowKey == key && row is Map<String, dynamic>) {
        return row;
      }
    }

    return null;
  }

  List<Map> _normalizeRows(Object? source) {
    if (source is! List) {
      return const <Map>[];
    }

    final rows = <Map>[];
    for (final item in source) {
      if (item is Map) {
        final parsed = FeatureFlag.tryParse(item);
        if (parsed != null) {
          rows.add(parsed.toMap());
        }
      }
    }
    return rows;
  }

  List<Map> _mergeDefaultFlags(List<Map> rows) {
    if (_defaultBootstrapFlags.isEmpty) {
      return rows;
    }

    final merged = rows
      .map(Map<String, dynamic>.from)
        .toList(growable: true);

    for (final entry in _defaultBootstrapFlags.entries) {
      final exists = merged.any((row) => row['key'] == entry.key);
      if (!exists) {
        merged.add(<String, dynamic>{
          'key': entry.key,
          'enabled': entry.value,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    }

    return merged;
  }

  bool? _resolveFlagFromRows(List<Map> rows, String key) {
    for (final row in rows) {
      final rowKey = row['key'];
      if (rowKey is String && rowKey == key) {
        return _extractFlagValue(row, false);
      }
    }
    return null;
  }

  bool _extractFlagValue(Map row, bool defaultValue) {
    if (row is Map<String, dynamic>) {
      return FeatureFlagResolver.resolveEnabled(row, defaultValue: defaultValue);
    }

    return defaultValue;
  }

  Map<String, dynamic> _rowsToMap(List<Map> rows) {
    final mapped = <String, dynamic>{};
    for (final row in rows) {
      final key = row['key'];
      if (key is String && key.isNotEmpty) {
        mapped[key] = row;
      }
    }
    return mapped;
  }

  Future<void> _recordFeatureFlagAuditLog({
    required String key,
    required bool? previousEnabled,
    required bool nextEnabled,
    required Object? previousValue,
    required Object? nextValue,
  }) async {
    try {
      await _analyticsService.logEvent(
        AnalyticsEventName.featureFlagChanged,
        parameters: {
          'flag_key': key,
          'previous_enabled': previousEnabled,
          'next_enabled': nextEnabled,
          'previous_value': previousValue,
          'next_value': nextValue,
        },
      );

      AppLogger.event('feature_flag_audit_logged', params: {
        'key': key,
      });
    } catch (error, stackTrace) {
      // Audit logging must never block successful flag writes.
      AppLogger.instance.w(
        'Failed to write feature flag audit log: $key',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
