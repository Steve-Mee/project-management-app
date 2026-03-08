library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/providers/ai_providers.dart' show aiChatProvider;
import 'package:pma_core/providers/auth/auth_providers.dart';

import '../auth/permissions.dart';
import 'mirror_provider.dart';

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
    final canUseMirror = ref.read(
      hasPermissionProvider(AppPermissions.useMirror),
    );
    if (!canUseMirror) {
      return null;
    }

    // Ensure the AI chat state is initialized before switching into Mirror flow.
    ref.read(aiChatProvider);

    final mirrorNotifier = ref.read(mirrorProvider.notifier);
    final safeMode = preferredMode == 'cloud' ? 'cloud' : 'private';
    mirrorNotifier.setMode(safeMode);
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
