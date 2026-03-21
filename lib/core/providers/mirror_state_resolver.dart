import 'package:pma_core/services/mirror_access_policy.dart';

enum MirrorValueSource {
  remote,
  cache,
  fallback,
  defaultValue,
}

enum MirrorHydrationPhase {
  hydrating,
  resolved,
  degraded,
}

class MirrorHydrationProvenance {
  const MirrorHydrationProvenance({
    required this.phase,
    required this.modeSource,
    required this.premiumSource,
    required this.teamModeVariantSource,
    required this.runnerModeVariantSource,
    this.fallbackReason,
  });

  final MirrorHydrationPhase phase;
  final String modeSource;
  final MirrorValueSource premiumSource;
  final MirrorValueSource teamModeVariantSource;
  final MirrorValueSource runnerModeVariantSource;
  final String? fallbackReason;
}

class MirrorVariantSnapshot {
  const MirrorVariantSnapshot({
    required this.value,
    required this.source,
    this.warningKey,
  });

  final String value;
  final MirrorValueSource source;
  final String? warningKey;
}

class MirrorFeatureGateSnapshot {
  const MirrorFeatureGateSnapshot({
    required this.mirrorEnabled,
    required this.allowPrivateMode,
    required this.allowCloudMode,
    required this.allowAdminBypass,
  });

  final bool mirrorEnabled;
  final bool allowPrivateMode;
  final bool allowCloudMode;
  final bool allowAdminBypass;
}

class MirrorHydrationSnapshot {
  const MirrorHydrationSnapshot({
    required this.requestedMode,
    required this.cachedMode,
    required this.isPremium,
    required this.teamModeVariant,
    required this.runnerModeVariant,
    required this.featureGates,
  });

  final String? requestedMode;
  final String? cachedMode;
  final bool isPremium;
  final MirrorVariantSnapshot teamModeVariant;
  final MirrorVariantSnapshot runnerModeVariant;
  final MirrorFeatureGateSnapshot featureGates;
}

class MirrorResolvedSnapshot {
  const MirrorResolvedSnapshot({
    required this.mode,
    required this.isPremium,
    required this.teamModeVariant,
    required this.runnerModeVariant,
    required this.offlineWarning,
    required this.provenance,
  });

  final String mode;
  final bool isPremium;
  final String teamModeVariant;
  final String runnerModeVariant;
  final String? offlineWarning;
  final MirrorHydrationProvenance provenance;
}

MirrorResolvedSnapshot resolveMirrorHydration(
  MirrorHydrationSnapshot snapshot,
) {
  final normalizedTeamVariant = snapshot.teamModeVariant.value == 'team'
      ? 'team'
      : 'solo';
  final normalizedRunnerVariant = snapshot.runnerModeVariant.value == 'local'
      ? 'local'
      : 'cloud';

  if (!snapshot.featureGates.mirrorEnabled) {
    return MirrorResolvedSnapshot(
      mode: 'private',
      isPremium: snapshot.isPremium,
      teamModeVariant: normalizedTeamVariant,
      runnerModeVariant: normalizedRunnerVariant,
      offlineWarning: null,
      provenance: const MirrorHydrationProvenance(
        phase: MirrorHydrationPhase.resolved,
        modeSource: 'feature_gate',
        premiumSource: MirrorValueSource.remote,
        teamModeVariantSource: MirrorValueSource.remote,
        runnerModeVariantSource: MirrorValueSource.remote,
      ),
    );
  }

  final modeSource = snapshot.requestedMode != null
      ? 'requested'
      : snapshot.cachedMode != null
          ? 'cache'
          : 'default';
  final requestedMode = _normalizeMode(
    snapshot.requestedMode ?? snapshot.cachedMode ?? 'private',
  );
  const policy = MirrorAccessPolicy();
  final decision = policy.resolveRequestedMode(
    requestedMode: requestedMode,
    isPremium: snapshot.isPremium,
    runnerModeVariant: normalizedRunnerVariant,
    allowPrivateMode: snapshot.featureGates.allowPrivateMode,
    allowCloudMode: snapshot.featureGates.allowCloudMode,
    allowAdminBypass: snapshot.featureGates.allowAdminBypass,
  );

  final fallbackReason = decision.warning ??
      snapshot.runnerModeVariant.warningKey ??
      snapshot.teamModeVariant.warningKey;
  final isDegraded = snapshot.teamModeVariant.source != MirrorValueSource.remote ||
      snapshot.runnerModeVariant.source != MirrorValueSource.remote ||
      fallbackReason != null;

  return MirrorResolvedSnapshot(
    mode: _normalizeMode(decision.effectiveMode),
    isPremium: snapshot.isPremium,
    teamModeVariant: normalizedTeamVariant,
    runnerModeVariant: normalizedRunnerVariant,
    offlineWarning: fallbackReason,
    provenance: MirrorHydrationProvenance(
      phase: isDegraded
          ? MirrorHydrationPhase.degraded
          : MirrorHydrationPhase.resolved,
      modeSource: modeSource,
      premiumSource: MirrorValueSource.remote,
      teamModeVariantSource: snapshot.teamModeVariant.source,
      runnerModeVariantSource: snapshot.runnerModeVariant.source,
      fallbackReason: fallbackReason,
    ),
  );
}

String _normalizeMode(String rawMode) {
  return rawMode == 'cloud' ? 'cloud' : 'private';
}