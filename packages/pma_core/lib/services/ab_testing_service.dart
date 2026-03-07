import 'dart:async';

import 'package:pma_core/core/services/feature_flag_service.dart';
import 'package:pma_core/services/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@Deprecated('AB-only checks are phased out. Use FeatureFlagService/featureFlagProvider.')
class ABTestingService {
  ABTestingService._();

  static final ABTestingService instance = ABTestingService._();
  final FeatureFlagService _featureFlags =
      FeatureFlagService(supabaseClient: Supabase.instance.client);

  @Deprecated('No-op compatibility method. AB groups are no longer used.')
  Future<void> initialize() async {
    await _featureFlags.initialize();
    AppLogger.event('ab_service_initialize_compat_noop');
  }

  @Deprecated('No-op compatibility method. AB groups are no longer used.')
  Future<String> assignGroupForUser(String userId) async {
    AppLogger.event('ab_group_assign_compat_noop', params: {'id': userId});
    return 'A';
  }

  @Deprecated('No-op compatibility method. AB groups are no longer used.')
  String? getGroupForUser(String userId) {
    AppLogger.event('ab_group_get_compat_noop', params: {'id': userId});
    return 'A';
  }

  @Deprecated('No-op compatibility method. Use FeatureFlagService.refresh().')
  Future<void> fetchRemoteConfigs() async {
    await _featureFlags.refresh();
    AppLogger.event('ab_fetch_configs_compat_refresh_feature_flags');
  }

  @Deprecated('No-op compatibility method. AB configs are no longer used.')
  Map<String, Object?> getConfigs() {
    return const <String, Object?>{};
  }

  @Deprecated('Use isFeatureEnabledCompat or FeatureFlagService.getFlag.')
  bool isFeatureEnabled(String key, String group) {
    // Safe fail-open to avoid disabling existing app behavior during migration.
    return true;
  }

  /// Backward-compatibility example for issue #071 feature flags migration.
  ///
  /// Resolution order:
  /// 1) New `feature_flags` table via cache-first [FeatureFlagService.getFlag]
  /// 2) Provided default value
  Future<bool> isFeatureEnabledCompat(
    String key, {
    String? userId,
    bool defaultValue = false,
  }) async {
    final _ = userId; // Maintained for backward-compatible signature.

    try {
      final resolved = await _featureFlags.getFlag(
        key,
        defaultValue: defaultValue,
      );
      return resolved;
    } catch (e, stackTrace) {
      AppLogger.instance.w(
        'Feature flag service lookup failed, using default value',
        error: e,
        stackTrace: stackTrace,
      );
    }

    return defaultValue;
  }
}
