library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mirror_hydration_inputs_provider.dart';
import 'mirror_offline_cache_provider.dart';
import 'mirror_premium_provider.dart';
import 'mirror_state_resolver.dart';

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
    this.hydrationReasonCode,
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
  final String? hydrationReasonCode;
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
    String? hydrationReasonCode,
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
      hydrationReasonCode: hydrationReasonCode ?? this.hydrationReasonCode,
      fallbackReason: clearOfflineWarning
          ? null
          : (fallbackReason ?? this.fallbackReason),
    );
  }
}

class MirrorModeController extends Notifier<MirrorState> {
  int _hydrationGeneration = 0;
  bool _bootstrapStarted = false;
  bool _refreshInFlight = false;
  bool _refreshPending = false;
  String? _pendingRequestedMode;
  bool _pendingPersistEffectiveMode = false;
  bool _pendingRefreshPremium = false;
  bool _pendingRefreshTeamVariant = false;
  bool _pendingRefreshRunnerVariant = false;
  Future<void>? _activeRefreshFuture;

  @override
  MirrorState build() {
    if (!_bootstrapStarted) {
      _bootstrapStarted = true;
      Future<void>.microtask(() {
        unawaited(_queueRefresh());
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
    await _queueRefresh(
      requestedMode: mode,
      persistEffectiveMode: true,
    );
  }

  Future<void> refreshPremiumFromMetadata() async {
    await _queueRefresh(
      requestedMode: state.mode,
      persistEffectiveMode: true,
      refreshPremium: true,
    );
  }

  Future<void> refreshTeamModeVariant() async {
    await _queueRefresh(
      requestedMode: state.mode,
      refreshTeamVariant: true,
    );
  }

  Future<void> refreshRunnerModeVariant() async {
    await _queueRefresh(
      requestedMode: state.mode,
      refreshRunnerVariant: true,
    );
  }

  void clearOfflineWarning() {
    state = state.copyWith(clearOfflineWarning: true);
  }

  Future<void> _queueRefresh({
    String? requestedMode,
    bool persistEffectiveMode = false,
    bool refreshPremium = false,
    bool refreshTeamVariant = false,
    bool refreshRunnerVariant = false,
  }) async {
    if (_refreshInFlight) {
      _refreshPending = true;
      if (requestedMode != null) {
        _pendingRequestedMode = requestedMode;
      }
      _pendingPersistEffectiveMode =
          _pendingPersistEffectiveMode || persistEffectiveMode;
      _pendingRefreshPremium = _pendingRefreshPremium || refreshPremium;
      _pendingRefreshTeamVariant =
          _pendingRefreshTeamVariant || refreshTeamVariant;
      _pendingRefreshRunnerVariant =
          _pendingRefreshRunnerVariant || refreshRunnerVariant;
      return _activeRefreshFuture ?? Future<void>.value();
    }

    _refreshInFlight = true;
    var effectiveRequestedMode = requestedMode ?? state.mode;
    var effectivePersistEffectiveMode = persistEffectiveMode;
    var effectiveRefreshPremium = refreshPremium;
    var effectiveRefreshTeamVariant = refreshTeamVariant;
    var effectiveRefreshRunnerVariant = refreshRunnerVariant;
    final refreshFuture = () async {
      try {
        while (true) {
          await _refreshFromSources(
            requestedMode: effectiveRequestedMode,
            persistEffectiveMode: effectivePersistEffectiveMode,
            refreshPremium: effectiveRefreshPremium,
            refreshTeamVariant: effectiveRefreshTeamVariant,
            refreshRunnerVariant: effectiveRefreshRunnerVariant,
          );

          if (!_refreshPending) {
            break;
          }

          effectiveRequestedMode = _pendingRequestedMode ?? state.mode;
          effectivePersistEffectiveMode = _pendingPersistEffectiveMode;
          effectiveRefreshPremium = _pendingRefreshPremium;
          effectiveRefreshTeamVariant = _pendingRefreshTeamVariant;
          effectiveRefreshRunnerVariant = _pendingRefreshRunnerVariant;
          _refreshPending = false;
          _pendingRequestedMode = null;
          _pendingPersistEffectiveMode = false;
          _pendingRefreshPremium = false;
          _pendingRefreshTeamVariant = false;
          _pendingRefreshRunnerVariant = false;
        }
      } finally {
        _refreshInFlight = false;
        _activeRefreshFuture = null;
      }
    }();

    _activeRefreshFuture = refreshFuture;
    return refreshFuture;
  }

  Future<void> _refreshFromSources({
    String? requestedMode,
    bool persistEffectiveMode = false,
    bool refreshPremium = false,
    bool refreshTeamVariant = false,
    bool refreshRunnerVariant = false,
  }) async {
    if (refreshPremium) {
      ref.invalidate(mirrorPremiumProvider);
      ref.invalidate(mirrorPremiumSnapshotProvider);
    }
    if (refreshTeamVariant) {
      ref.invalidate(mirrorTeamModeVariantSnapshotProvider);
    }
    if (refreshRunnerVariant) {
      ref.invalidate(mirrorRunnerModeVariantSnapshotProvider);
    }

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
      hydrationReasonCode: resolved.provenance.reasonCode,
      fallbackReason: resolved.provenance.fallbackReason,
    );

    if (persistEffectiveMode && _isCurrentGeneration(generation)) {
      unawaited(MirrorOfflineCache.saveMode(resolved.mode));
    }
  }

  bool _isCurrentGeneration(int generation) {
    return generation == _hydrationGeneration;
  }
}

final mirrorModeControllerProvider =
    NotifierProvider<MirrorModeController, MirrorState>(
  MirrorModeController.new,
);

final mirrorResolvedStateProvider = Provider<MirrorState>((ref) {
  return ref.watch(mirrorModeControllerProvider);
});

final mirrorResolvedModeProvider = Provider<String>((ref) {
  return ref.watch(mirrorResolvedStateProvider).mode;
});

final mirrorResolvedOfflineWarningProvider = Provider<String?>((ref) {
  return ref.watch(mirrorResolvedStateProvider).offlineWarning;
});
