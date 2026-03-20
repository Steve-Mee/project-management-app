class MirrorAccessDecision {
  const MirrorAccessDecision({
    required this.effectiveMode,
    required this.requiresPremium,
    this.usedAdminBypass = false,
    this.warning,
  });

  final String effectiveMode;
  final bool requiresPremium;
  final bool usedAdminBypass;
  final String? warning;
}

class MirrorAccessPolicy {
  const MirrorAccessPolicy();

  MirrorAccessDecision resolveRequestedMode({
    required String requestedMode,
    required bool isPremium,
    String runnerModeVariant = 'cloud',
    bool allowPrivateMode = true,
    bool allowCloudMode = true,
    bool allowAdminBypass = false,
  }) {
    final normalizedRequestedMode =
        requestedMode == 'cloud' ? 'cloud' : 'private';
    final hasAnyModeEnabled = allowPrivateMode || allowCloudMode;

    if (!hasAnyModeEnabled) {
      return const MirrorAccessDecision(
        effectiveMode: 'private',
        requiresPremium: false,
        warning: 'Mirror access is disabled by policy.',
      );
    }

    if (normalizedRequestedMode == 'private') {
      if (allowPrivateMode) {
        return const MirrorAccessDecision(
          effectiveMode: 'private',
          requiresPremium: false,
        );
      }

      if (!allowCloudMode) {
        return const MirrorAccessDecision(
          effectiveMode: 'private',
          requiresPremium: false,
          warning: 'Private mode is disabled by policy.',
        );
      }

      if (runnerModeVariant == 'local' && !allowAdminBypass) {
        return const MirrorAccessDecision(
          effectiveMode: 'private',
          requiresPremium: false,
          warning: 'Cloud mode is disabled for this runner experiment variant.',
        );
      }

      if (!isPremium && !allowAdminBypass) {
        return const MirrorAccessDecision(
          effectiveMode: 'private',
          requiresPremium: true,
          warning: 'Cloud mode requires an active Stripe premium subscription.',
        );
      }

      return MirrorAccessDecision(
        effectiveMode: 'cloud',
        requiresPremium: !allowAdminBypass,
        usedAdminBypass: allowAdminBypass,
        warning: allowAdminBypass
            ? 'Cloud mode enabled via admin testing bypass.'
            : 'Private mode is restricted; using cloud mode instead.',
      );
    }

    if (!allowCloudMode && !allowAdminBypass) {
      if (!allowPrivateMode) {
        return const MirrorAccessDecision(
          effectiveMode: 'private',
          requiresPremium: false,
          warning: 'Cloud mode is disabled by policy.',
        );
      }

      return const MirrorAccessDecision(
        effectiveMode: 'private',
        requiresPremium: false,
        warning: 'Cloud mode is disabled by policy.',
      );
    }

    if (runnerModeVariant == 'local' && !allowAdminBypass) {
      return const MirrorAccessDecision(
        effectiveMode: 'private',
        requiresPremium: false,
        warning: 'Cloud mode is disabled for this runner experiment variant.',
      );
    }

    if (!isPremium && !allowAdminBypass) {
      return const MirrorAccessDecision(
        effectiveMode: 'private',
        requiresPremium: true,
        warning: 'Cloud mode requires an active Stripe premium subscription.',
      );
    }

    if (!allowCloudMode && allowAdminBypass) {
      return const MirrorAccessDecision(
        effectiveMode: 'cloud',
        requiresPremium: false,
        usedAdminBypass: true,
        warning: 'Cloud mode enabled via admin testing bypass.',
      );
    }

    return MirrorAccessDecision(
      effectiveMode: 'cloud',
      requiresPremium: !allowAdminBypass,
      usedAdminBypass: allowAdminBypass,
      warning:
          allowAdminBypass ? 'Cloud mode enabled via admin testing bypass.' : null,
    );
  }
}
