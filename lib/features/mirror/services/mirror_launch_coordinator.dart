import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/auth/permissions.dart';
import 'package:pma_core/core/providers.dart' as core_providers;
import 'package:pma_core/core/services/analytics_events.dart';
import 'package:pma_core/providers/auth/auth_providers.dart';
import 'package:pma_core/services/app_logger.dart';
import 'package:pma_core/services/mirror_access_policy.dart';

import '../models/mirror_launch_result.dart';
import '../../../core/providers/mirror_feature_flag_provider.dart';
import '../../../core/providers/mirror_hydration_inputs_provider.dart';
import '../../../core/providers/mirror_mode_controller_provider.dart';
import '../../../core/providers/mirror_premium_provider.dart';

class MirrorLaunchCoordinator {
  const MirrorLaunchCoordinator(this._ref);

  final Ref _ref;

  Future<MirrorLaunchResult> openMirrorFromTask({
    required String projectId,
    required String taskId,
    String preferredMode = 'private',
  }) async {
    final safeMode = preferredMode == 'cloud' ? 'cloud' : 'private';
    final mirrorEnabled = await resolveMirrorFeatureEnabled(_ref);
    if (!mirrorEnabled) {
      return _recordAndReturn(
        MirrorLaunchResult.featureDisabled(requestedMode: safeMode),
        projectId: projectId,
        taskId: taskId,
      );
    }

    final canUseMirror = _ref.read(
      hasPermissionProvider(AppPermissions.useMirror),
    );
    if (!canUseMirror) {
      return _recordAndReturn(
        MirrorLaunchResult.permissionDenied(requestedMode: safeMode),
        projectId: projectId,
        taskId: taskId,
      );
    }

    if (safeMode == 'cloud') {
      final isPremium = await _ref.read(mirrorPremiumProvider.future);
      final runnerModeVariant =
          await _ref.read(mirrorRunnerModeVariantProvider.future);
      final canUsePrivateMode = await resolveMirrorPrivateModeEnabled(_ref);
      final canUseCloudMode = await resolveMirrorCloudModeEnabled(_ref);
      final allowAdminBypass = await resolveMirrorAdminBypassEnabled(_ref);
      const policy = MirrorAccessPolicy();
      final decision = policy.resolveRequestedMode(
        requestedMode: safeMode,
        isPremium: isPremium,
        runnerModeVariant: runnerModeVariant,
        allowPrivateMode: canUsePrivateMode,
        allowCloudMode: canUseCloudMode,
        allowAdminBypass: allowAdminBypass,
      );

      if (decision.effectiveMode != 'cloud' && decision.requiresPremium) {
        return _recordAndReturn(
          MirrorLaunchResult.entitlementDenied(requestedMode: safeMode),
          projectId: projectId,
          taskId: taskId,
        );
      }
    }

    await _ref.read(mirrorModeControllerProvider.notifier).setMode(safeMode);

    final mirrorState = _ref.read(mirrorResolvedStateProvider);
    final payload = MirrorLaunchPayload(
      projectId: projectId,
      taskId: taskId,
      mode: mirrorState.mode,
      teamModeVariant: mirrorState.teamModeVariant,
      requestedAt: DateTime.now(),
    );

    if (mirrorState.mode != safeMode) {
      return _recordAndReturn(
        MirrorLaunchResult.launchedWithDowngrade(
          payload: payload,
          requestedMode: safeMode,
          resolvedMode: mirrorState.mode,
        ),
        projectId: projectId,
        taskId: taskId,
        hydrationReasonCode: mirrorState.hydrationReasonCode,
        fallbackReason: mirrorState.fallbackReason,
      );
    }

    return _recordAndReturn(
      MirrorLaunchResult.launched(
        payload: payload,
        requestedMode: safeMode,
        resolvedMode: mirrorState.mode,
      ),
      projectId: projectId,
      taskId: taskId,
      hydrationReasonCode: mirrorState.hydrationReasonCode,
      fallbackReason: mirrorState.fallbackReason,
    );
  }

  Future<MirrorLaunchResult> _recordAndReturn(
    MirrorLaunchResult result, {
    required String projectId,
    required String taskId,
    String? hydrationReasonCode,
    String? fallbackReason,
  }) async {
    try {
      await _ref.read(core_providers.analyticsServiceProvider).logEvent(
        AnalyticsEventName.mirrorLaunchResolved,
        parameters: <String, dynamic>{
          'project_id': projectId,
          'task_id': taskId,
          'status': result.status.name,
          'requested_mode': result.requestedMode,
          if (result.resolvedMode != null) 'resolved_mode': result.resolvedMode,
          'is_success': result.isSuccess,
          'is_downgraded': result.isDowngraded,
          if (hydrationReasonCode != null)
            'hydration_reason_code': hydrationReasonCode,
          if (fallbackReason != null) 'fallback_reason': fallbackReason,
        },
      );
    } catch (error) {
      AppLogger.warning(
        'mirror_launch_analytics_failed',
        params: <String, Object?>{
          'status': result.status.name,
          'requestedMode': result.requestedMode,
          'resolvedMode': result.resolvedMode,
          'error': error.toString(),
        },
      );
    }

    return result;
  }
}

final mirrorLaunchCoordinatorProvider = Provider<MirrorLaunchCoordinator>((ref) {
  return MirrorLaunchCoordinator(ref);
});
