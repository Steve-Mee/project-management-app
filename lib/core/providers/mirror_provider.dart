library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../ab_testing_service.dart';
import '../services/mirror_premium_service.dart';
import '../../features/mirror/cloud_fly_backend.dart';
import '../../features/mirror/edge_function_backend.dart';
import '../../features/mirror/mirror_compute_backend.dart';
import '../../features/mirror/private_grpc_backend.dart';

export '../../features/mirror/cloud_fly_backend.dart';
export '../../features/mirror/edge_function_backend.dart';
export '../../features/mirror/mirror_compute_backend.dart';
export '../../features/mirror/private_grpc_backend.dart';

class MirrorState {
  const MirrorState({
    required this.mode,
    required this.isPremium,
    required this.teamModeVariant,
    required this.offlineWarning,
  });

  final String mode;
  final bool isPremium;
  final String teamModeVariant;
  final String? offlineWarning;

  bool get isTeamMode => teamModeVariant == 'team';
  bool get hasOfflineWarning => offlineWarning != null && offlineWarning!.isNotEmpty;

  MirrorState copyWith({
    String? mode,
    bool? isPremium,
    String? teamModeVariant,
    String? offlineWarning,
    bool clearOfflineWarning = false,
  }) {
    return MirrorState(
      mode: mode ?? this.mode,
      isPremium: isPremium ?? this.isPremium,
      teamModeVariant: teamModeVariant ?? this.teamModeVariant,
      offlineWarning: clearOfflineWarning
          ? null
          : (offlineWarning ?? this.offlineWarning),
    );
  }
}

final mirrorModeProvider = StateProvider<String>((ref) => 'private');

final mirrorOfflineWarningProvider = StateProvider<String?>((ref) => null);

final mirrorPremiumServiceProvider = Provider<MirrorPremiumService>((ref) {
  return MirrorPremiumService();
});

final mirrorPremiumProvider = FutureProvider<bool>((ref) async {
  final premiumService = ref.watch(mirrorPremiumServiceProvider);
  return premiumService.isPremium();
});

final mirrorTeamModeVariantProvider = FutureProvider<String>((ref) async {
  final warningNotifier = ref.read(mirrorOfflineWarningProvider.notifier);
  final user = Supabase.instance.client.auth.currentUser;
  final userId = user?.id ?? 'anonymous';

  try {
    final variant = await ABTestingService.instance
        .assignVariant(
          experimentKey: 'mirror_team_mode',
          userId: userId,
          variants: const <String>['solo', 'team'],
        )
        .timeout(const Duration(seconds: 3));

    await _MirrorOfflineCache.saveTeamModeVariant(userId, variant);
    warningNotifier.state = null;
    return variant;
  } catch (_) {
    final cached = await _MirrorOfflineCache.getTeamModeVariant(userId);
    if (cached != null) {
      warningNotifier.state =
          'Offline mode: Team Mode variant loaded from local cache.';
      return cached;
    }

    warningNotifier.state =
        'Offline mode: Team Mode unavailable, switched to solo fallback.';
    return 'solo';
  }
});

final mirrorTeamModeEnabledProvider = Provider<bool>((ref) {
  final variant = ref.watch(mirrorTeamModeVariantProvider).valueOrNull ?? 'solo';
  return variant == 'team';
});

final mirrorBackendProvider = FutureProvider<MirrorComputeBackend>((ref) async {
  final mode = ref.watch(mirrorModeProvider);
  final isPremium = await ref.watch(mirrorPremiumProvider.future);

  if (mode == 'cloud' && isPremium) {
    return CloudFlyBackend();
  }

  if (mode == 'cloud' && !isPremium) {
    return EdgeFunctionBackend();
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
    final offlineWarning = ref.watch(mirrorOfflineWarningProvider);
    return MirrorState(
      mode: mode,
      isPremium: isPremium,
      teamModeVariant: teamModeVariant,
      offlineWarning: offlineWarning,
    );
  }

  Future<void> setMode(String mode) async {
    if (mode != 'private' && mode != 'cloud') {
      return;
    }

    if (mode == 'cloud') {
      final hasPremium = await ref.read(mirrorPremiumProvider.future);
      if (!hasPremium) {
        ref.read(mirrorModeProvider.notifier).state = 'private';
        ref.read(mirrorOfflineWarningProvider.notifier).state =
            'Cloud mode requires an active Stripe premium subscription.';
        state = state.copyWith(
          mode: 'private',
          isPremium: false,
          offlineWarning:
              'Cloud mode requires an active Stripe premium subscription.',
        );
        return;
      }
    }

    ref.read(mirrorModeProvider.notifier).state = mode;
    state = state.copyWith(mode: mode);
    unawaited(_MirrorOfflineCache.saveMode(mode));
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
        offlineWarning:
            'Cloud mode requires an active Stripe premium subscription.',
      );
      unawaited(_MirrorOfflineCache.saveMode('private'));
    }
  }

  Future<void> refreshTeamModeVariant() async {
    ref.invalidate(mirrorTeamModeVariantProvider);
    final teamModeVariant = await ref.read(mirrorTeamModeVariantProvider.future);
    state = state.copyWith(teamModeVariant: teamModeVariant);
  }

  void clearOfflineWarning() {
    ref.read(mirrorOfflineWarningProvider.notifier).state = null;
    state = state.copyWith(clearOfflineWarning: true);
  }

  Future<void> _hydrateFromCache() async {
    final user = Supabase.instance.client.auth.currentUser;
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

    await refreshPremiumFromMetadata();
  }
}

final mirrorProvider = NotifierProvider<MirrorNotifier, MirrorState>(MirrorNotifier.new);

class _MirrorOfflineCache {
  static const String _boxName = 'mirror_offline_cache';
  static const String _schemaVersionKey = '__schema_version__';
  static const String _authUserKey = '__auth_user_id__';
  static const String _premiumSnapshotKey = '__premium_snapshot__';
  static const int _schemaVersion = 2;
  static const Duration _ttl = Duration(days: 7);
  static const String _modeKey = 'mode';

  static Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      final box = Hive.box<dynamic>(_boxName);
      await _ensureSchema(box);
      return box;
    }
    final box = await Hive.openBox<dynamic>(_boxName);
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

  static Future<void> saveTeamModeVariant(String userId, String variant) async {
    final box = await _openBox();
    await box.put(_variantKey(userId), _CacheEnvelope.wrap(variant));
  }

  static Future<String?> getTeamModeVariant(String userId) async {
    final box = await _openBox();
    final key = _variantKey(userId);
    final value = _CacheEnvelope.unwrap<String>(box.get(key), ttl: _ttl);
    if (value == null) {
      await box.delete(key);
    }
    return value;
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
    final previousCachedPremium = previousSnapshot is bool
        ? previousSnapshot
        : previousPremium;

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
