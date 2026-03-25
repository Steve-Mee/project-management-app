library;

enum MirrorLaunchStatus {
  launched,
  launchedWithDowngrade,
  featureDisabled,
  permissionDenied,
  entitlementDenied,
}

class MirrorLaunchPayload {
  const MirrorLaunchPayload({
    required this.projectId,
    required this.taskId,
    required this.mode,
    required this.teamModeVariant,
    required this.requestedAt,
  });

  final String projectId;
  final String taskId;
  final String mode;
  final String teamModeVariant;
  final DateTime requestedAt;

  bool get isTeamMode => teamModeVariant == 'team';
}

class MirrorLaunchResult {
  const MirrorLaunchResult._({
    required this.status,
    required this.requestedMode,
    this.payload,
    this.resolvedMode,
  });

  const MirrorLaunchResult.launched({
    required MirrorLaunchPayload payload,
    required String requestedMode,
    required String resolvedMode,
  }) : this._(
          status: MirrorLaunchStatus.launched,
          payload: payload,
          requestedMode: requestedMode,
          resolvedMode: resolvedMode,
        );

  const MirrorLaunchResult.launchedWithDowngrade({
    required MirrorLaunchPayload payload,
    required String requestedMode,
    required String resolvedMode,
  }) : this._(
          status: MirrorLaunchStatus.launchedWithDowngrade,
          payload: payload,
          requestedMode: requestedMode,
          resolvedMode: resolvedMode,
        );

  const MirrorLaunchResult.featureDisabled({
    required String requestedMode,
  }) : this._(
          status: MirrorLaunchStatus.featureDisabled,
          requestedMode: requestedMode,
        );

  const MirrorLaunchResult.permissionDenied({
    required String requestedMode,
  }) : this._(
          status: MirrorLaunchStatus.permissionDenied,
          requestedMode: requestedMode,
        );

  const MirrorLaunchResult.entitlementDenied({
    required String requestedMode,
  }) : this._(
          status: MirrorLaunchStatus.entitlementDenied,
          requestedMode: requestedMode,
        );

  final MirrorLaunchStatus status;
  final MirrorLaunchPayload? payload;
  final String requestedMode;
  final String? resolvedMode;

  bool get isSuccess =>
      status == MirrorLaunchStatus.launched ||
      status == MirrorLaunchStatus.launchedWithDowngrade;

  bool get isDowngraded => status == MirrorLaunchStatus.launchedWithDowngrade;
}
