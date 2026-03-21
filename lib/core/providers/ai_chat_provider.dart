// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/mirror/services/mirror_launch_coordinator.dart';

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
    final payload = await ref.read(mirrorLaunchCoordinatorProvider).openMirrorFromTask(
          projectId: projectId,
          taskId: taskId,
          preferredMode: preferredMode,
        );

    if (payload == null) {
      state = null;
      return null;
    }

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
