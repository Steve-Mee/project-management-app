// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/services/mirror_access_policy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../ab_testing_service.dart';
import 'mirror_feature_flag_provider.dart';
import 'mirror_offline_cache_provider.dart';
import 'mirror_premium_provider.dart';
import 'supabase_client_provider.dart';
export 'mirror_premium_provider.dart';

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
    final isMirrorEnabled = await resolveMirrorFeatureEnabled(ref);
    if (!isMirrorEnabled) {
      ref.read(mirrorModeProvider.notifier).state = 'private';
      ref.read(mirrorOfflineWarningProvider.notifier).state = null;
      state = state.copyWith(
        mode: 'private',
        offlineWarning: null,
      );
      unawaited(MirrorOfflineCache.saveMode('private'));
      return;
    }

    final hasPremium = await ref.read(mirrorPremiumProvider.future);
    final runnerModeVariant =
        await ref.read(mirrorRunnerModeVariantProvider.future);
    final canUsePrivateMode = await resolveMirrorPrivateModeEnabled(ref);
    final canUseCloudMode = await resolveMirrorCloudModeEnabled(ref);
    final allowAdminBypass = await resolveMirrorAdminBypassEnabled(ref);
    const policy = MirrorAccessPolicy();
    final decision = policy.resolveRequestedMode(
      requestedMode: mode,
      isPremium: hasPremium,
      runnerModeVariant: runnerModeVariant,
      allowPrivateMode: canUsePrivateMode,
      allowCloudMode: canUseCloudMode,
      allowAdminBypass: allowAdminBypass,
    );

    ref.read(mirrorModeProvider.notifier).state = decision.effectiveMode;
    ref.read(mirrorOfflineWarningProvider.notifier).state = decision.warning;
    state = state.copyWith(
      mode: decision.effectiveMode,
      isPremium: hasPremium,
      runnerModeVariant: runnerModeVariant,
      offlineWarning: decision.warning,
    );
    unawaited(MirrorOfflineCache.saveMode(decision.effectiveMode));
  }

  Future<void> refreshPremiumFromMetadata() async {
    final previousPremium = state.isPremium;
    ref.invalidate(mirrorPremiumProvider);
    final isPremium = await ref.read(mirrorPremiumProvider.future);
    state = state.copyWith(isPremium: isPremium);

    await MirrorOfflineCache.invalidateOnPremiumChange(
      previousPremium: previousPremium,
      currentPremium: isPremium,
    );

    if (!isPremium && state.mode == 'cloud') {
      ref.read(mirrorModeProvider.notifier).state = 'private';
      state = state.copyWith(
        mode: 'private',
        offlineWarning: MirrorOfflineWarningKeys.cloudModeRequiresPremium,
      );
      unawaited(MirrorOfflineCache.saveMode('private'));
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

    await MirrorOfflineCache.invalidateOnAuthChange(currentUserId: userId);

    final cachedMode = await MirrorOfflineCache.getMode();
    if (cachedMode == 'private' || cachedMode == 'cloud') {
      ref.read(mirrorModeProvider.notifier).state = cachedMode!;
    }

    final cachedVariant = await MirrorOfflineCache.getTeamModeVariant(userId);
    if (cachedVariant != null) {
      state = state.copyWith(teamModeVariant: cachedVariant);
    }

    final cachedRunnerVariant =
        await MirrorOfflineCache.getRunnerModeVariant(userId);
    if (cachedRunnerVariant != null) {
      state = state.copyWith(runnerModeVariant: cachedRunnerVariant);
    }

    await refreshPremiumFromMetadata();
  }

  User? _currentSupabaseUserOrNull() {
    try {
      return ref.read(supabaseClientProvider).auth.currentUser;
    } catch (_) {
      return null;
    }
  }
}

final mirrorProvider =
    NotifierProvider<MirrorNotifier, MirrorState>(MirrorNotifier.new);

final mirrorModeProvider = StateProvider<String>((ref) => 'private');

final mirrorOfflineWarningProvider = StateProvider<String?>((ref) => null);

final mirrorTeamModeVariantProvider = FutureProvider<String>((ref) async {
  final warningNotifier = ref.read(mirrorOfflineWarningProvider.notifier);
  User? user;
  try {
    user = ref.read(supabaseClientProvider).auth.currentUser;
  } catch (_) {
    user = null;
  }
  final userId = user?.id ?? 'anonymous';

  try {
    final variant = await ABTestingService.instance.assignVariant(
      experimentKey: 'mirror_team_mode',
      userId: userId,
      variants: const <String>['solo', 'team'],
    ).timeout(const Duration(seconds: 3));

    await MirrorOfflineCache.saveTeamModeVariant(userId, variant);
    warningNotifier.state = null;
    return variant;
  } catch (_) {
    final cached = await MirrorOfflineCache.getTeamModeVariant(userId);
    if (cached != null) {
      warningNotifier.state =
          MirrorOfflineWarningKeys.teamVariantLoadedFromCache;
      return cached;
    }

    warningNotifier.state = MirrorOfflineWarningKeys.teamVariantFallbackSolo;
    return 'solo';
  }
});

final mirrorRunnerModeVariantProvider = FutureProvider<String>((ref) async {
  final warningNotifier = ref.read(mirrorOfflineWarningProvider.notifier);
  User? user;
  try {
    user = ref.read(supabaseClientProvider).auth.currentUser;
  } catch (_) {
    user = null;
  }
  final userId = user?.id ?? 'anonymous';

  try {
    final variant = await ABTestingService.instance.assignVariant(
      experimentKey: 'mirror_runner_mode',
      userId: userId,
      variants: const <String>['local', 'cloud'],
    ).timeout(const Duration(seconds: 3));

    await MirrorOfflineCache.saveRunnerModeVariant(userId, variant);
    warningNotifier.state = null;
    return variant;
  } catch (_) {
    final cached = await MirrorOfflineCache.getRunnerModeVariant(userId);
    if (cached != null) {
      warningNotifier.state =
          MirrorOfflineWarningKeys.runnerVariantLoadedFromCache;
      return cached;
    }

    warningNotifier.state = MirrorOfflineWarningKeys.runnerVariantFallbackCloud;
    return 'cloud';
  }
});
