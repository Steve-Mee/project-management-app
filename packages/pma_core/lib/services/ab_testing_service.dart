import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:pma_core/core/services/feature_flag_service.dart';
import 'package:pma_core/services/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MirrorRunnerQuotaConfig {
  const MirrorRunnerQuotaConfig({
    required this.maxFiles,
    required this.maxWorkspaceBytes,
    required this.maxExecutionWindowSeconds,
  });

  final int maxFiles;
  final int maxWorkspaceBytes;
  final int maxExecutionWindowSeconds;
}

@Deprecated('AB-only checks are phased out. Use FeatureFlagService/featureFlagProvider.')
class ABTestingService {
  ABTestingService._();

  static const String mirrorRunnerModeExperimentKey = 'mirror_runner_mode';
  static const String mirrorRunnerModeFlagKey = 'mirror_runner_mode';
  static const String mirrorQuotaMaxFilesFlagKey = 'mirror_runner_quota_max_files';
  static const String mirrorQuotaMaxBytesFlagKey =
      'mirror_runner_quota_max_workspace_bytes';
  static const String mirrorQuotaMaxExecutionWindowFlagKey =
      'mirror_runner_quota_max_execution_window_seconds';

  static const int defaultMirrorQuotaMaxFiles = 500;
  static const int defaultMirrorQuotaMaxWorkspaceBytes = 50 * 1024 * 1024;
  static const int defaultMirrorQuotaMaxExecutionWindowSeconds = 300;

  static final ABTestingService instance = ABTestingService._();
  final FeatureFlagService _featureFlags =
      FeatureFlagService(supabaseClient: Supabase.instance.client);
  final Map<String, String> _assignedVariants = <String, String>{};

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

  Future<String> assignVariant({
    required String experimentKey,
    required String userId,
    List<String> variants = const <String>['A', 'B'],
  }) async {
    if (variants.isEmpty) {
      return 'A';
    }

    final cacheKey = '$experimentKey::$userId';
    final existing = _assignedVariants[cacheKey];
    if (existing != null) {
      return existing;
    }

    final normalizedUserId = userId.trim().isEmpty ? 'anonymous' : userId.trim();
    final input = utf8.encode('$experimentKey::$normalizedUserId');
    final digest = sha256.convert(input).bytes;
    final bucket = digest.first;
    final index = bucket % variants.length;
    final assigned = variants[index];
    _assignedVariants[cacheKey] = assigned;
    return assigned;
  }

  Future<String> getMirrorRunnerModeVariant({
    required String userId,
    String defaultVariant = 'cloud',
  }) async {
    await _featureFlags.initialize();
    await _featureFlags.refresh();

    final flags = await _featureFlags.getCachedFeatureFlagsByKey();
    final raw = flags[mirrorRunnerModeFlagKey];
    final remoteVariant = _readVariant(raw);
    if (remoteVariant == 'local' || remoteVariant == 'cloud') {
      return remoteVariant!;
    }

    return assignVariant(
      experimentKey: mirrorRunnerModeExperimentKey,
      userId: userId,
      variants: const <String>['local', 'cloud'],
    );
  }

  Future<MirrorRunnerQuotaConfig> getMirrorRunnerQuotaConfig() async {
    await _featureFlags.initialize();
    await _featureFlags.refresh();

    final flags = await _featureFlags.getCachedFeatureFlagsByKey();
    return MirrorRunnerQuotaConfig(
      maxFiles: _readPositiveInt(
        flags[mirrorQuotaMaxFilesFlagKey],
        defaultValue: defaultMirrorQuotaMaxFiles,
      ),
      maxWorkspaceBytes: _readPositiveInt(
        flags[mirrorQuotaMaxBytesFlagKey],
        defaultValue: defaultMirrorQuotaMaxWorkspaceBytes,
      ),
      maxExecutionWindowSeconds: _readPositiveInt(
        flags[mirrorQuotaMaxExecutionWindowFlagKey],
        defaultValue: defaultMirrorQuotaMaxExecutionWindowSeconds,
      ),
    );
  }

  String? _readVariant(dynamic raw) {
    if (raw is String) {
      return raw.trim().toLowerCase();
    }

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final direct = map['variant'];
      if (direct is String) {
        return direct.trim().toLowerCase();
      }

      final value = map['value'];
      if (value is String) {
        return value.trim().toLowerCase();
      }
      if (value is Map) {
        final nested = value['variant'];
        if (nested is String) {
          return nested.trim().toLowerCase();
        }
      }
    }

    return null;
  }

  int _readPositiveInt(dynamic raw, {required int defaultValue}) {
    final resolved = _extractInt(raw);
    if (resolved == null || resolved <= 0) {
      return defaultValue;
    }
    return resolved;
  }

  int? _extractInt(dynamic raw) {
    if (raw is int) {
      return raw;
    }
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw.trim());
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return _extractInt(map['value'] ?? map['max'] ?? map['limit']);
    }
    return null;
  }
}
