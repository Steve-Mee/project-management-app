// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/auth/permissions.dart';
import 'package:pma_core/providers/ai_providers.dart' show aiChatProvider;
import 'package:pma_core/providers/auth/auth_providers.dart';

import 'mirror_feature_flag_provider.dart';
import 'mirror_offline_cache_provider.dart';

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

class AiChatBridgeNotifier extends Notifier<MirrorLaunchPayload?> {
  @override
  MirrorLaunchPayload? build() => null;

  Future<MirrorLaunchPayload?> openMirrorFromTask({
    required String projectId,
    required String taskId,
    String preferredMode = 'private',
  }) async {
    // Feature-flag gate: launch requests must be blocked when Mirror is disabled.
    final mirrorEnabled = await resolveMirrorFeatureEnabled(ref);
    if (!mirrorEnabled) {
      state = null;
      return null;
    }

    final canUseMirror = ref.read(
      hasPermissionProvider(AppPermissions.useMirror),
    );
    if (!canUseMirror) {
      return null;
    }

    ref.read(aiChatProvider);

    final mirrorNotifier = ref.read(mirrorProvider.notifier);
    final safeMode = preferredMode == 'cloud' ? 'cloud' : 'private';
    await mirrorNotifier.setMode(safeMode);
    await mirrorNotifier.refreshTeamModeVariant();

    final mirrorState = ref.read(mirrorProvider);
    final payload = MirrorLaunchPayload(
      projectId: projectId,
      taskId: taskId,
      mode: mirrorState.mode,
      teamModeVariant: mirrorState.teamModeVariant,
      requestedAt: DateTime.now(),
    );

    state = payload;
    return payload;
  }

  void clearMirrorLaunchRequest() {
    state = null;
  }
}

final aiChatBridgeProvider =
    NotifierProvider<AiChatBridgeNotifier, MirrorLaunchPayload?>(
  AiChatBridgeNotifier.new,
);

