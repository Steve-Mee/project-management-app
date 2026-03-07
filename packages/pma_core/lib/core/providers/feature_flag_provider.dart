import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/core/feature_flags/feature_flag_resolver.dart';
import 'package:pma_core/services/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/feature_flag_service.dart';

/// Issue #071: main Riverpod provider for Supabase-backed feature flags.
///
/// Responsibilities:
/// - Load flags from [FeatureFlagService] on build
/// - Keep in-memory state as `Map<String, dynamic>` for fast lookups
/// - Auto-refresh every 30 minutes
/// - Refresh on app resume to reduce stale flags after backgrounding
class FeatureFlagNotifier extends AsyncNotifier<Map<String, dynamic>>
    with WidgetsBindingObserver {
  static const Duration _refreshInterval = Duration(minutes: 30);
  static const Duration _startupCacheTtl = Duration(minutes: 30);

  Timer? _refreshTimer;
  late final FeatureFlagServiceBase _service;

  @override
  Future<Map<String, dynamic>> build() async {
    _service = ref.read(featureFlagServiceProvider);

    WidgetsBinding.instance.addObserver(this);
    _startAutoRefresh();

    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _refreshTimer?.cancel();
    });

    final cached = await _service.getCachedFeatureFlagsByKey();
    if (cached.isNotEmpty) {
      unawaited(_refreshInBackgroundIfStale());
      return cached;
    }

    return _loadFromService();
  }

  /// Returns true when a flag is enabled.
  ///
  /// Supports common shapes:
  /// - direct bool (`{ key: true }`)
  /// - row map with `enabled` boolean
  /// - row map with nested `value.enabled`
  bool isEnabled(String key) {
    final flags = state.valueOrNull;
    if (flags == null) {
      AppLogger.event('feature_flag_default_used', params: {'key': key});
      return false;
    }
    final enabled = FeatureFlagResolver.isEnabled(flags, key, defaultValue: false);
    AppLogger.event('feature_flag_evaluated', params: {
      'key': key,
      'enabled': enabled,
      'source': 'provider_state',
    });
    return enabled;
  }

  /// Returns the raw stored value for a flag key.
  ///
  /// This may be a bool, map, list, or any JSON-serializable object
  /// depending on the `feature_flags` row data model.
  dynamic getValue(String key) {
    final flags = state.valueOrNull;
    if (flags == null) {
      return null;
    }
    return flags[key];
  }

  /// Manual refresh entry point for UI/actions.
  Future<void> refresh() async {
    final previous = state.valueOrNull;
    try {
      final flags = await _loadFromService();
      state = AsyncValue.data(flags);
    } catch (error, stackTrace) {
      // Keep last good state to avoid disabling features during transient outages.
      if (previous != null && previous.isNotEmpty) {
        state = AsyncValue.data(previous);
        return;
      }

      // Fall back to local cache if available before surfacing the error.
      final cached = await _service.getCachedFeatureFlagsByKey();
      if (cached.isNotEmpty) {
        state = AsyncValue.data(cached);
        return;
      }

      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Admin write flow for enabling/disabling a feature flag.
  ///
  /// Returns `true` when persisted remotely, otherwise rolls back and returns `false`.
  Future<bool> setFlagEnabled(String key, bool enabled) async {
    final current = state.valueOrNull ?? <String, dynamic>{};
    final previous = Map<String, dynamic>.from(current);

    final optimistic = <String, dynamic>{...current};
    final existing = optimistic[key];
    if (existing is Map) {
      optimistic[key] = {
        ...Map<String, dynamic>.from(existing),
        'enabled': enabled,
        'updated_at': DateTime.now().toIso8601String(),
      };
    } else {
      optimistic[key] = {
        'key': key,
        'enabled': enabled,
        'updated_at': DateTime.now().toIso8601String(),
      };
    }
    state = AsyncValue.data(optimistic);

    final ok = await _service.setFeatureEnabled(key, enabled);
    if (!ok) {
      state = AsyncValue.data(previous);
      return false;
    }

    await refresh();
    return true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refresh());
    }
  }

  Future<Map<String, dynamic>> _loadFromService() async {
    try {
      final rows = await _service.fetchFeatureFlags();
      return _rowsToMap(rows);
    } catch (error, stackTrace) {
      final cached = await _service.getCachedFeatureFlagsByKey();
      if (cached.isNotEmpty) {
        AppLogger.event('feature_flag_fallback_cache', params: {
          'reason': 'provider_load_remote_failed',
        });
        return cached;
      }
      AppLogger.event('feature_flag_default_used', params: {
        'key': '__provider_state__',
      });
      AppLogger.instance.w(
        'Feature flag provider failed to load remote and cache',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _refreshInBackgroundIfStale() async {
    try {
      final stale = await _service.isCacheStale(ttl: _startupCacheTtl);
      if (!stale) {
        return;
      }

      AppLogger.event('feature_flag_fallback_cache', params: {
        'reason': 'startup_stale_cache_refresh',
      });
      await refresh();
    } catch (error, stackTrace) {
      AppLogger.instance.w(
        'Feature flag stale-cache refresh failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
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

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      unawaited(refresh());
    });
  }
}

/// Issue #071: `AsyncNotifierProvider<FeatureFlagNotifier, Map<String, dynamic>>` for feature flags.
final featureFlagProvider =
    AsyncNotifierProvider<FeatureFlagNotifier, Map<String, dynamic>>(
  FeatureFlagNotifier.new,
);

final featureFlagServiceProvider = Provider<FeatureFlagServiceBase>((ref) {
  return FeatureFlagService(supabaseClient: Supabase.instance.client);
});
