import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/auth/permissions.dart';
import 'package:pma_core/providers/auth/auth_providers.dart';

import '../../../core/providers/ai_chat_provider.dart';
import '../../../core/providers/mirror_feature_flag_provider.dart';
import '../../../core/providers/mirror_provider.dart';

class MirrorLaunchCoordinator {
  const MirrorLaunchCoordinator(this._ref);

  final Ref _ref;

  Future<MirrorLaunchPayload?> openMirrorFromTask({
    required String projectId,
    required String taskId,
    String preferredMode = 'private',
  }) async {
    final mirrorEnabled = await resolveMirrorFeatureEnabled(_ref);
    if (!mirrorEnabled) {
      return null;
    }

    final canUseMirror = _ref.read(
      hasPermissionProvider(AppPermissions.useMirror),
    );
    if (!canUseMirror) {
      return null;
    }

    final safeMode = preferredMode == 'cloud' ? 'cloud' : 'private';
    await _ref.read(mirrorProvider.notifier).setMode(safeMode);

    final mirrorState = _ref.read(mirrorProvider);
    return MirrorLaunchPayload(
      projectId: projectId,
      taskId: taskId,
      mode: mirrorState.mode,
      teamModeVariant: mirrorState.teamModeVariant,
      requestedAt: DateTime.now(),
    );
  }
}

final mirrorLaunchCoordinatorProvider = Provider<MirrorLaunchCoordinator>((ref) {
  return MirrorLaunchCoordinator(ref);
});
