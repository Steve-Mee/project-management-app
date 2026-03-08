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
    ref.invalidate(mirrorPremiumProvider);
    final isPremium = await ref.read(mirrorPremiumProvider.future);
    state = state.copyWith(isPremium: isPremium);

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
    final cachedMode = await _MirrorOfflineCache.getMode();
    if (cachedMode == 'private' || cachedMode == 'cloud') {
      ref.read(mirrorModeProvider.notifier).state = cachedMode!;
    }

    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id ?? 'anonymous';
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
  static const String _modeKey = 'mode';

  static Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<dynamic>(_boxName);
    }
    return Hive.openBox<dynamic>(_boxName);
  }

  static Future<void> saveMode(String mode) async {
    final box = await _openBox();
    await box.put(_modeKey, mode);
  }

  static Future<String?> getMode() async {
    final box = await _openBox();
    final value = box.get(_modeKey);
    return value is String ? value : null;
  }

  static String _variantKey(String userId) => 'team_mode_variant::$userId';

  static Future<void> saveTeamModeVariant(String userId, String variant) async {
    final box = await _openBox();
    await box.put(_variantKey(userId), variant);
  }

  static Future<String?> getTeamModeVariant(String userId) async {
    final box = await _openBox();
    final value = box.get(_variantKey(userId));
    return value is String ? value : null;
  }
}
