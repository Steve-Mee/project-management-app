// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pma_core/core/feature_flags/feature_flag_resolver.dart';
import 'package:pma_core/core/providers.dart';
import 'package:pma_core/repository/encrypted_hive_box.dart';
import 'package:pma_core/services/mirror_access_policy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../ab_testing_service.dart';
import '../services/mirror_premium_service.dart';
import '../../features/mirror/mirror_compute_backend.dart';
import '../../features/mirror/mirror_gateway_backend.dart';
import '../../features/mirror/private_grpc_backend.dart';
import '../../features/mirror/services/mirror_context_budget_service.dart';

export '../../features/mirror/mirror_compute_backend.dart';
export '../../features/mirror/mirror_gateway_backend.dart';
export '../../features/mirror/private_grpc_backend.dart';
export '../../features/mirror/services/mirror_context_budget_service.dart';

class MirrorOfflineWarningKeys {
  const MirrorOfflineWarningKeys._();

  static const String teamVariantLoadedFromCache =
    'mirrorOfflineTeamVariantLoadedFromCacheWarning';
  static const String teamVariantFallbackSolo =
    'mirrorOfflineTeamVariantFallbackSoloWarning';
  static const String runnerVariantLoadedFromCache =
    'mirrorOfflineRunnerVariantLoadedFromCacheWarning';
  static const String runnerVariantFallbackCloud =
    'mirrorOfflineRunnerVariantFallbackCloudWarning';
  static const String cloudModeRequiresPremium =
    'mirrorCloudModeRequiresPremiumWarning';
}

class MirrorState {
  const MirrorState({
    required this.mode,
    required this.isPremium,
    required this.teamModeVariant,
    this.runnerModeVariant = 'cloud',
    required this.offlineWarning,
  });

  final String mode;
  final bool isPremium;
  final String teamModeVariant;
  final String runnerModeVariant;
  final String? offlineWarning;

  bool get isTeamMode => teamModeVariant == 'team';
  bool get hasOfflineWarning =>
      offlineWarning != null && offlineWarning!.isNotEmpty;

  MirrorState copyWith({
    String? mode,
    bool? isPremium,
    String? teamModeVariant,
    String? runnerModeVariant,
    String? offlineWarning,
    bool clearOfflineWarning = false,
  }) {
    return MirrorState(
      mode: mode ?? this.mode,
      isPremium: isPremium ?? this.isPremium,
      teamModeVariant: teamModeVariant ?? this.teamModeVariant,
      runnerModeVariant: runnerModeVariant ?? this.runnerModeVariant,
      offlineWarning:
          clearOfflineWarning ? null : (offlineWarning ?? this.offlineWarning),
    );
  }
}

final mirrorModeProvider = StateProvider<String>((ref) => 'private');

final mirrorOfflineWarningProvider = StateProvider<String?>((ref) => null);

final mirrorPremiumServiceProvider = Provider<MirrorPremiumService>((ref) {
  return MirrorPremiumService();
});

final mirrorContextBudgetServiceProvider =
    Provider<MirrorContextBudgetService>((ref) {
  return const MirrorContextBudgetService();
});

final mirrorPremiumProvider = FutureProvider<bool>((ref) async {
  final premiumService = ref.watch(mirrorPremiumServiceProvider);
  return premiumService.isPremium();
});

final mirrorTeamModeVariantProvider = FutureProvider<String>((ref) async {
  final warningNotifier = ref.read(mirrorOfflineWarningProvider.notifier);
  final user = _currentSupabaseUserOrNull();
  final userId = user?.id ?? 'anonymous';

  try {
    final variant = await ABTestingService.instance.assignVariant(
      experimentKey: 'mirror_team_mode',
      userId: userId,
      variants: const <String>['solo', 'team'],
    ).timeout(const Duration(seconds: 3));

    await _MirrorOfflineCache.saveTeamModeVariant(userId, variant);
    warningNotifier.state = null;
    return variant;
  } catch (_) {
    final cached = await _MirrorOfflineCache.getTeamModeVariant(userId);
    if (cached != null) {
      warningNotifier.state = MirrorOfflineWarningKeys.teamVariantLoadedFromCache;
      return cached;
    }

    warningNotifier.state = MirrorOfflineWarningKeys.teamVariantFallbackSolo;
    return 'solo';
  }
});

final mirrorRunnerModeVariantProvider = FutureProvider<String>((ref) async {
  final warningNotifier = ref.read(mirrorOfflineWarningProvider.notifier);
  final user = _currentSupabaseUserOrNull();
  final userId = user?.id ?? 'anonymous';

  try {
    final variant = await ABTestingService.instance.assignVariant(
      experimentKey: 'mirror_runner_mode',
      userId: userId,
      variants: const <String>['local', 'cloud'],
    ).timeout(const Duration(seconds: 3));

    await _MirrorOfflineCache.saveRunnerModeVariant(userId, variant);
    warningNotifier.state = null;
    return variant;
  } catch (_) {
    final cached = await _MirrorOfflineCache.getRunnerModeVariant(userId);
    if (cached != null) {
      warningNotifier.state =
          MirrorOfflineWarningKeys.runnerVariantLoadedFromCache;
      return cached;
    }

    warningNotifier.state = MirrorOfflineWarningKeys.runnerVariantFallbackCloud;
    return 'cloud';
  }
});

final mirrorGatewayBackendProvider = Provider<MirrorGatewayBackend>((ref) {
  final budgetService = ref.read(mirrorContextBudgetServiceProvider);
  return MirrorGatewayBackend(
    client: Supabase.instance.client,
    budgetService: budgetService,
  );
});

final mirrorBackendProvider = FutureProvider<MirrorComputeBackend>((ref) async {
  final isMirrorEnabled = await _isMirrorFeatureEnabled(ref, useWatch: true);
  if (!isMirrorEnabled) {
    return const _MirrorDisabledBackend();
  }

  final mode = ref.watch(mirrorModeProvider);
  final isPremium = await ref.watch(mirrorPremiumProvider.future);
  final runnerModeVariant =
      await ref.watch(mirrorRunnerModeVariantProvider.future);
  const policy = MirrorAccessPolicy();
  final decision = policy.resolveRequestedMode(
    requestedMode: mode,
    isPremium: isPremium,
    runnerModeVariant: runnerModeVariant,
  );

  if (decision.effectiveMode == 'cloud' && isPremium) {
    return ref.watch(mirrorGatewayBackendProvider);
  }

  return PrivateGrpcBackend();
});

class MirrorNotifier extends Notifier<MirrorState> {
  bool _cacheHydrated = false;

  @override
  MirrorState build() {
    if (!_cacheHydrated) {
      _cacheHydrated = true;
      unawaited(_hydrateFromCache());
    }

    final mode = ref.watch(mirrorModeProvider);
    final isPremium = ref.watch(mirrorPremiumProvider).valueOrNull ?? false;
    final teamModeVariant =
        ref.watch(mirrorTeamModeVariantProvider).valueOrNull ?? 'solo';
    final runnerModeVariant =
        ref.watch(mirrorRunnerModeVariantProvider).valueOrNull ?? 'cloud';
    final offlineWarning = ref.watch(mirrorOfflineWarningProvider);
    return MirrorState(
      mode: mode,
      isPremium: isPremium,
      teamModeVariant: teamModeVariant,
      runnerModeVariant: runnerModeVariant,
      offlineWarning: offlineWarning,
    );
  }

  Future<void> setMode(String mode) async {
    final isMirrorEnabled = await _isMirrorFeatureEnabled(ref);
    if (!isMirrorEnabled) {
      ref.read(mirrorModeProvider.notifier).state = 'private';
      ref.read(mirrorOfflineWarningProvider.notifier).state = null;
      state = state.copyWith(
        mode: 'private',
        offlineWarning: null,
      );
      unawaited(_MirrorOfflineCache.saveMode('private'));
      return;
    }

    final hasPremium = await ref.read(mirrorPremiumProvider.future);
    final runnerModeVariant =
        await ref.read(mirrorRunnerModeVariantProvider.future);
    const policy = MirrorAccessPolicy();
    final decision = policy.resolveRequestedMode(
      requestedMode: mode,
      isPremium: hasPremium,
      runnerModeVariant: runnerModeVariant,
    );

    ref.read(mirrorModeProvider.notifier).state = decision.effectiveMode;
    ref.read(mirrorOfflineWarningProvider.notifier).state = decision.warning;
    state = state.copyWith(
      mode: decision.effectiveMode,
      isPremium: hasPremium,
      runnerModeVariant: runnerModeVariant,
      offlineWarning: decision.warning,
    );
    unawaited(_MirrorOfflineCache.saveMode(decision.effectiveMode));
  }

  Future<void> refreshPremiumFromMetadata() async {
    final previousPremium = state.isPremium;
    ref.invalidate(mirrorPremiumProvider);
    final isPremium = await ref.read(mirrorPremiumProvider.future);
    state = state.copyWith(isPremium: isPremium);

    await _MirrorOfflineCache.invalidateOnPremiumChange(
      previousPremium: previousPremium,
      currentPremium: isPremium,
    );

    if (!isPremium && state.mode == 'cloud') {
      ref.read(mirrorModeProvider.notifier).state = 'private';
      state = state.copyWith(
        mode: 'private',
        offlineWarning: MirrorOfflineWarningKeys.cloudModeRequiresPremium,
      );
      unawaited(_MirrorOfflineCache.saveMode('private'));
    }
  }

  Future<void> refreshTeamModeVariant() async {
    ref.invalidate(mirrorTeamModeVariantProvider);
    final teamModeVariant =
        await ref.read(mirrorTeamModeVariantProvider.future);
    state = state.copyWith(teamModeVariant: teamModeVariant);
  }

  Future<void> refreshRunnerModeVariant() async {
    ref.invalidate(mirrorRunnerModeVariantProvider);
    final runnerModeVariant =
        await ref.read(mirrorRunnerModeVariantProvider.future);
    state = state.copyWith(runnerModeVariant: runnerModeVariant);
  }

  void clearOfflineWarning() {
    ref.read(mirrorOfflineWarningProvider.notifier).state = null;
    state = state.copyWith(clearOfflineWarning: true);
  }

  Future<void> _hydrateFromCache() async {
    final user = _currentSupabaseUserOrNull();
    final userId = user?.id ?? 'anonymous';

    await _MirrorOfflineCache.invalidateOnAuthChange(currentUserId: userId);

    final cachedMode = await _MirrorOfflineCache.getMode();
    if (cachedMode == 'private' || cachedMode == 'cloud') {
      ref.read(mirrorModeProvider.notifier).state = cachedMode!;
    }

    final cachedVariant = await _MirrorOfflineCache.getTeamModeVariant(userId);
    if (cachedVariant != null) {
      state = state.copyWith(teamModeVariant: cachedVariant);
    }

    final cachedRunnerVariant =
        await _MirrorOfflineCache.getRunnerModeVariant(userId);
    if (cachedRunnerVariant != null) {
      state = state.copyWith(runnerModeVariant: cachedRunnerVariant);
    }

    await refreshPremiumFromMetadata();
  }
}

User? _currentSupabaseUserOrNull() {
  try {
    return Supabase.instance.client.auth.currentUser;
  } catch (_) {
    return null;
  }
}

final mirrorProvider =
    NotifierProvider<MirrorNotifier, MirrorState>(MirrorNotifier.new);

Future<bool> _isMirrorFeatureEnabled(Ref ref, {bool useWatch = false}) async {
  final flagsAsync = useWatch
      ? ref.watch(featureFlagProvider)
      : ref.read(featureFlagProvider);
  final syncResolved = flagsAsync.maybeWhen(
    data: (flags) =>
        FeatureFlagResolver.isEnabled(flags, 'mirror_enabled', defaultValue: true),
    orElse: () => null,
  );

  if (syncResolved != null) {
    return syncResolved;
  }

  try {
    if (useWatch) {
      await ref.watch(featureFlagProvider.future);
    } else {
      await ref.read(featureFlagProvider.future);
    }
    return ref.read(featureFlagProvider.notifier).isEnabled('mirror_enabled');
  } catch (_) {
    // Fail-open when flags are temporarily unavailable.
    return true;
  }
}

class _MirrorDisabledBackend implements MirrorComputeBackend {
  const _MirrorDisabledBackend();

  static const String _message =
      'Mirror is disabled by feature flag: mirror_enabled';

  @override
  Future<GenerateResult> generate({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    return const GenerateResult(
      success: false,
      message: _message,
      diagnostics: <String>[_message],
    );
  }

  @override
  Future<CompileResult> compile({
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    return const CompileResult(
      success: false,
      errors: <String>[_message],
    );
  }

  @override
  Future<ApplyResult> apply({
    required String prompt,
    required ProjectContext context,
    required String mode,
    String? compileFingerprint,
  }) async {
    return const ApplyResult(
      success: false,
      message: _message,
    );
  }
}

class _MirrorOfflineCache {
  static const String _boxName = 'mirror_offline_cache';
  static const String _schemaVersionKey = '__schema_version__';
  static const String _authUserKey = '__auth_user_id__';
  static const String _premiumSnapshotKey = '__premium_snapshot__';
  static const int _schemaVersion = 4;
  static const int _variantMetadataVersion = 1;
  static const Duration _ttl = Duration(days: 7);
  static const String _modeKey = 'mode';
  static const String _encryptionKeyName =
      'hive_encryption_key_mirror_offline_cache';
  static const bool _failClosedOnEncryptionError = bool.fromEnvironment(
    'MIRROR_FAIL_CLOSED_ON_ENCRYPTION_ERROR',
    defaultValue: bool.fromEnvironment('dart.vm.product'),
  );

  static Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      final box = Hive.box<dynamic>(_boxName);
      await _ensureSchema(box);
      return box;
    }

    late final Box<dynamic> box;
    try {
      box = await EncryptedHiveBox<dynamic>(
        boxName: _boxName,
        encryptionKey: _encryptionKeyName,
      ).open();
    } catch (error) {
      if (_failClosedOnEncryptionError) {
        throw StateError(
          'Encrypted mirror offline cache is unavailable: $error',
        );
      }
      box = await Hive.openBox<dynamic>(_boxName);
    }

    await _ensureSchema(box);
    return box;
  }

  static Future<void> _ensureSchema(Box<dynamic> box) async {
    final version = box.get(_schemaVersionKey);
    if (version is int && version == _schemaVersion) {
      return;
    }

    await box.clear();
    await box.put(_schemaVersionKey, _schemaVersion);
  }

  static Future<void> saveMode(String mode) async {
    final box = await _openBox();
    await box.put(_modeKey, _CacheEnvelope.wrap(mode));
  }

  static Future<String?> getMode() async {
    final box = await _openBox();
    final value = _CacheEnvelope.unwrap<String>(box.get(_modeKey), ttl: _ttl);
    if (value == null) {
      await box.delete(_modeKey);
    }
    return value;
  }

  static String _variantKey(String userId) => 'team_mode_variant::$userId';
  static String _runnerVariantKey(String userId) =>
      'runner_mode_variant::$userId';

  static Future<void> saveTeamModeVariant(String userId, String variant) async {
    await _saveVariant(_variantKey(userId), variant);
  }

  static Future<String?> getTeamModeVariant(String userId) async {
    return _getVariant(_variantKey(userId));
  }

  static Future<void> saveRunnerModeVariant(
      String userId, String variant) async {
    await _saveVariant(_runnerVariantKey(userId), variant);
  }

  static Future<String?> getRunnerModeVariant(String userId) async {
    return _getVariant(_runnerVariantKey(userId));
  }

  static Future<void> _saveVariant(String key, String variant) async {
    final box = await _openBox();
    final now = DateTime.now().toUtc();
    await box.put(
      key,
      _CacheEnvelope.wrap(<String, dynamic>{
        'variant': variant,
        'variant_timestamp': now.toIso8601String(),
        'variant_version': _variantMetadataVersion,
      }),
    );
  }

  static Future<String?> _getVariant(String key) async {
    final box = await _openBox();
    final raw = _CacheEnvelope.unwrap<Map>(box.get(key), ttl: _ttl);
    if (raw == null) {
      await box.delete(key);
      return null;
    }

    final map = Map<String, dynamic>.from(raw);
    final version = map['variant_version'];
    final timestampRaw = map['variant_timestamp'];
    final variant = map['variant'];

    final versionValid = version is int && version == _variantMetadataVersion;
    final timestampValid =
        timestampRaw is String && DateTime.tryParse(timestampRaw) != null;
    final variantValid = variant is String && variant.isNotEmpty;

    if (!versionValid || !timestampValid || !variantValid) {
      await box.delete(key);
      return null;
    }

    return variant;
  }

  static Future<void> invalidateOnAuthChange({
    required String currentUserId,
  }) async {
    final box = await _openBox();
    final previousUserId = box.get(_authUserKey)?.toString();
    if (previousUserId == null || previousUserId == currentUserId) {
      await box.put(_authUserKey, currentUserId);
      return;
    }

    await _clearStateCache(box);
    await box.put(_authUserKey, currentUserId);
  }

  static Future<void> invalidateOnPremiumChange({
    required bool previousPremium,
    required bool currentPremium,
  }) async {
    final box = await _openBox();
    final previousSnapshot = box.get(_premiumSnapshotKey);
    final previousCachedPremium =
        previousSnapshot is bool ? previousSnapshot : previousPremium;

    if (previousCachedPremium == currentPremium) {
      await box.put(_premiumSnapshotKey, currentPremium);
      return;
    }

    await _clearStateCache(box);
    await box.put(_premiumSnapshotKey, currentPremium);
  }

  static Future<void> _clearStateCache(Box<dynamic> box) async {
    final keys = box.keys.map((key) => key.toString()).toList();
    for (final key in keys) {
      if (key == _schemaVersionKey ||
          key == _authUserKey ||
          key == _premiumSnapshotKey) {
        continue;
      }
      await box.delete(key);
    }
  }
}

class _CacheEnvelope {
  static Map<String, dynamic> wrap(dynamic value) {
    return <String, dynamic>{
      'v': value,
      'savedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
      'schema': 1,
    };
  }

  static T? unwrap<T>(dynamic raw, {required Duration ttl}) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final savedAtMs = map['savedAt'];
      final value = map['v'];
      final savedAt = savedAtMs is int
          ? DateTime.fromMillisecondsSinceEpoch(savedAtMs, isUtc: true)
          : null;
      if (savedAt == null) {
        return null;
      }
      final expired = DateTime.now().toUtc().difference(savedAt) > ttl;
      if (expired) {
        return null;
      }
      return value is T ? value : null;
    }

    return raw is T ? raw : null;
  }
}
