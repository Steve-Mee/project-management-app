// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ab_testing_service.dart';
import 'mirror_state_resolver.dart';
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
    this.hydrationPhase = MirrorHydrationPhase.hydrating,
    this.modeSource = 'default',
    this.premiumSource = MirrorValueSource.remote,
    this.teamModeVariantSource = MirrorValueSource.defaultValue,
    this.runnerModeVariantSource = MirrorValueSource.defaultValue,
    this.fallbackReason,
  });

  final String mode;
  final bool isPremium;
  final String teamModeVariant;
  final String runnerModeVariant;
  final String? offlineWarning;
  final MirrorHydrationPhase hydrationPhase;
  final String modeSource;
  final MirrorValueSource premiumSource;
  final MirrorValueSource teamModeVariantSource;
  final MirrorValueSource runnerModeVariantSource;
  final String? fallbackReason;

  bool get isTeamMode => teamModeVariant == 'team';
  bool get hasOfflineWarning =>
      offlineWarning != null && offlineWarning!.isNotEmpty;

  MirrorState copyWith({
    String? mode,
    bool? isPremium,
    String? teamModeVariant,
    String? runnerModeVariant,
    String? offlineWarning,
    MirrorHydrationPhase? hydrationPhase,
    String? modeSource,
    MirrorValueSource? premiumSource,
    MirrorValueSource? teamModeVariantSource,
    MirrorValueSource? runnerModeVariantSource,
    String? fallbackReason,
    bool clearOfflineWarning = false,
  }) {
    return MirrorState(
      mode: mode ?? this.mode,
      isPremium: isPremium ?? this.isPremium,
      teamModeVariant: teamModeVariant ?? this.teamModeVariant,
      runnerModeVariant: runnerModeVariant ?? this.runnerModeVariant,
      offlineWarning:
          clearOfflineWarning ? null : (offlineWarning ?? this.offlineWarning),
        hydrationPhase: hydrationPhase ?? this.hydrationPhase,
        modeSource: modeSource ?? this.modeSource,
        premiumSource: premiumSource ?? this.premiumSource,
        teamModeVariantSource:
          teamModeVariantSource ?? this.teamModeVariantSource,
        runnerModeVariantSource:
          runnerModeVariantSource ?? this.runnerModeVariantSource,
        fallbackReason: clearOfflineWarning
          ? null
          : (fallbackReason ?? this.fallbackReason),
    );
  }
}

class MirrorNotifier extends Notifier<MirrorState> {
  int _hydrationGeneration = 0;
  bool _bootstrapStarted = false;

  @override
  MirrorState build() {
    if (!_bootstrapStarted) {
      _bootstrapStarted = true;
      Future<void>.microtask(() {
        unawaited(_refreshFromSources());
      });
    }

    return const MirrorState(
      mode: 'private',
      isPremium: false,
      teamModeVariant: 'solo',
      runnerModeVariant: 'cloud',
      offlineWarning: null,
      hydrationPhase: MirrorHydrationPhase.hydrating,
    );
  }

  Future<void> setMode(String mode) async {
    await _refreshFromSources(
      requestedMode: mode,
      persistEffectiveMode: true,
    );
  }

  Future<void> refreshPremiumFromMetadata() async {
    ref.invalidate(mirrorPremiumProvider);
    ref.invalidate(mirrorPremiumSnapshotProvider);
    await _refreshFromSources(
      requestedMode: state.mode,
      persistEffectiveMode: true,
    );
  }

  Future<void> refreshTeamModeVariant() async {
    ref.invalidate(mirrorTeamModeVariantSnapshotProvider);
    await _refreshFromSources(requestedMode: state.mode);
  }

  Future<void> refreshRunnerModeVariant() async {
    ref.invalidate(mirrorRunnerModeVariantSnapshotProvider);
    await _refreshFromSources(requestedMode: state.mode);
  }

  void clearOfflineWarning() {
    state = state.copyWith(clearOfflineWarning: true);
  }

  Future<void> _refreshFromSources({
    String? requestedMode,
    bool persistEffectiveMode = false,
  }) async {
    final generation = ++_hydrationGeneration;
    state = state.copyWith(hydrationPhase: MirrorHydrationPhase.hydrating);
    final userId = ref.read(currentMirrorUserIdProvider);

    await MirrorOfflineCache.invalidateOnAuthChange(currentUserId: userId);
    if (!_isCurrentGeneration(generation)) {
      return;
    }

    final previousPremium = state.isPremium;
    final isPremium = await ref.read(mirrorPremiumSnapshotProvider.future);
    if (!_isCurrentGeneration(generation)) {
      return;
    }

    await MirrorOfflineCache.invalidateOnPremiumChange(
      previousPremium: previousPremium,
      currentPremium: isPremium,
    );
    if (!_isCurrentGeneration(generation)) {
      return;
    }

    final cachedMode = await MirrorOfflineCache.getMode();
    if (!_isCurrentGeneration(generation)) {
      return;
    }

    final featureGateFuture = ref.read(mirrorFeatureGateSnapshotProvider.future);
    final teamVariantFuture =
        ref.read(mirrorTeamModeVariantSnapshotProvider.future);
    final runnerVariantFuture =
        ref.read(mirrorRunnerModeVariantSnapshotProvider.future);

    final featureSnapshot = await featureGateFuture;
    if (!_isCurrentGeneration(generation)) {
      return;
    }

    final teamVariant = await teamVariantFuture;
    if (!_isCurrentGeneration(generation)) {
      return;
    }

    final runnerVariant = await runnerVariantFuture;
    if (!_isCurrentGeneration(generation)) {
      return;
    }

    final resolved = resolveMirrorHydration(
      MirrorHydrationSnapshot(
        requestedMode: requestedMode,
        cachedMode: cachedMode,
        isPremium: isPremium,
        teamModeVariant: teamVariant,
        runnerModeVariant: runnerVariant,
        featureGates: featureSnapshot,
      ),
    );

    state = state.copyWith(
      mode: resolved.mode,
      isPremium: resolved.isPremium,
      teamModeVariant: resolved.teamModeVariant,
      runnerModeVariant: resolved.runnerModeVariant,
      offlineWarning: resolved.offlineWarning,
      hydrationPhase: resolved.provenance.phase,
      modeSource: resolved.provenance.modeSource,
      premiumSource: resolved.provenance.premiumSource,
      teamModeVariantSource: resolved.provenance.teamModeVariantSource,
      runnerModeVariantSource: resolved.provenance.runnerModeVariantSource,
      fallbackReason: resolved.provenance.fallbackReason,
    );

    if (persistEffectiveMode) {
      unawaited(MirrorOfflineCache.saveMode(resolved.mode));
    }
  }

  bool _isCurrentGeneration(int generation) {
    return generation == _hydrationGeneration;
  }
}

final mirrorProvider =
    NotifierProvider<MirrorNotifier, MirrorState>(MirrorNotifier.new);

final mirrorModeProvider = Provider<String>((ref) {
  return ref.watch(mirrorProvider).mode;
});

final mirrorOfflineWarningProvider = Provider<String?>((ref) {
  return ref.watch(mirrorProvider).offlineWarning;
});

final currentMirrorUserIdProvider = Provider<String>((ref) {
  try {
    return ref.read(supabaseClientProvider).auth.currentUser?.id ?? 'anonymous';
  } catch (_) {
    return 'anonymous';
  }
});

final mirrorPremiumSnapshotProvider = FutureProvider<bool>((ref) async {
  return ref.read(mirrorPremiumProvider.future);
});

final mirrorFeatureGateSnapshotProvider =
    FutureProvider<MirrorFeatureGateSnapshot>((ref) async {
  return MirrorFeatureGateSnapshot(
    mirrorEnabled: await resolveMirrorFeatureEnabled(ref),
    allowPrivateMode: await resolveMirrorPrivateModeEnabled(ref),
    allowCloudMode: await resolveMirrorCloudModeEnabled(ref),
    allowAdminBypass: await resolveMirrorAdminBypassEnabled(ref),
  );
});

final mirrorTeamModeVariantSnapshotProvider =
    FutureProvider<MirrorVariantSnapshot>((ref) async {
  final userId = _resolveCurrentMirrorUserId(ref);

  try {
    final variant = await ABTestingService.instance.assignVariant(
      experimentKey: 'mirror_team_mode',
      userId: userId,
      variants: const <String>['solo', 'team'],
    ).timeout(const Duration(seconds: 3));

    await MirrorOfflineCache.saveTeamModeVariant(userId, variant);
    return MirrorVariantSnapshot(
      value: variant,
      source: MirrorValueSource.remote,
    );
  } catch (_) {
    final cached = await MirrorOfflineCache.getTeamModeVariant(userId);
    if (cached != null) {
      return MirrorVariantSnapshot(
        value: cached,
        source: MirrorValueSource.cache,
        warningKey: MirrorOfflineWarningKeys.teamVariantLoadedFromCache,
      );
    }

    return const MirrorVariantSnapshot(
      value: 'solo',
      source: MirrorValueSource.fallback,
      warningKey: MirrorOfflineWarningKeys.teamVariantFallbackSolo,
    );
  }
});

final mirrorTeamModeVariantProvider = FutureProvider<String>((ref) async {
  final snapshot = await ref.watch(mirrorTeamModeVariantSnapshotProvider.future);
  return snapshot.value;
});

final mirrorRunnerModeVariantSnapshotProvider =
    FutureProvider<MirrorVariantSnapshot>((ref) async {
  final userId = _resolveCurrentMirrorUserId(ref);

  try {
    final variant = await ABTestingService.instance.assignVariant(
      experimentKey: 'mirror_runner_mode',
      userId: userId,
      variants: const <String>['local', 'cloud'],
    ).timeout(const Duration(seconds: 3));

    await MirrorOfflineCache.saveRunnerModeVariant(userId, variant);
    return MirrorVariantSnapshot(
      value: variant,
      source: MirrorValueSource.remote,
    );
  } catch (_) {
    final cached = await MirrorOfflineCache.getRunnerModeVariant(userId);
    if (cached != null) {
      return MirrorVariantSnapshot(
        value: cached,
        source: MirrorValueSource.cache,
        warningKey: MirrorOfflineWarningKeys.runnerVariantLoadedFromCache,
      );
    }

    return const MirrorVariantSnapshot(
      value: 'cloud',
      source: MirrorValueSource.fallback,
      warningKey: MirrorOfflineWarningKeys.runnerVariantFallbackCloud,
    );
  }
});

final mirrorRunnerModeVariantProvider = FutureProvider<String>((ref) async {
  final snapshot =
      await ref.watch(mirrorRunnerModeVariantSnapshotProvider.future);
  return snapshot.value;
});

String _resolveCurrentMirrorUserId(Ref ref) {
  return ref.read(currentMirrorUserIdProvider);
}
