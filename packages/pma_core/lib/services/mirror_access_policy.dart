class MirrorAccessDecision {
  const MirrorAccessDecision({
    required this.effectiveMode,
    required this.requiresPremium,
    this.warning,
  });

  final String effectiveMode;
  final bool requiresPremium;
  final String? warning;
}

class MirrorAccessPolicy {
  const MirrorAccessPolicy();

  MirrorAccessDecision resolveRequestedMode({
    required String requestedMode,
    required bool isPremium,
    String runnerModeVariant = 'cloud',
  }) {
    if (requestedMode != 'private' && requestedMode != 'cloud') {
      return const MirrorAccessDecision(
        effectiveMode: 'private',
        requiresPremium: false,
      );
    }

    if (requestedMode == 'cloud' && runnerModeVariant == 'local') {
      return const MirrorAccessDecision(
        effectiveMode: 'private',
        requiresPremium: false,
        warning: 'Cloud mode is disabled for this runner experiment variant.',
      );
    }

    if (requestedMode == 'cloud' && !isPremium) {
      return const MirrorAccessDecision(
        effectiveMode: 'private',
        requiresPremium: true,
        warning: 'Cloud mode requires an active Stripe premium subscription.',
      );
    }

    return MirrorAccessDecision(
      effectiveMode: requestedMode,
      requiresPremium: requestedMode == 'cloud',
    );
  }
}
