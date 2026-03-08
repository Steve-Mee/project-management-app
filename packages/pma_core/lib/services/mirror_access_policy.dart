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
  }) {
    if (requestedMode != 'private' && requestedMode != 'cloud') {
      return const MirrorAccessDecision(
        effectiveMode: 'private',
        requiresPremium: false,
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
