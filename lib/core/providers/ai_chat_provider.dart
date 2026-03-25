// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/mirror/models/mirror_launch_result.dart';
import '../../features/mirror/services/mirror_launch_coordinator.dart';

class AiChatBridgeNotifier extends Notifier<MirrorLaunchPayload?> {
  @override
  MirrorLaunchPayload? build() => null;

  Future<MirrorLaunchResult> openMirrorFromTask({
    required String projectId,
    required String taskId,
    String preferredMode = 'private',
  }) async {
    final result = await ref.read(mirrorLaunchCoordinatorProvider).openMirrorFromTask(
          projectId: projectId,
          taskId: taskId,
          preferredMode: preferredMode,
        );

    if (!result.isSuccess || result.payload == null) {
      state = null;
      return result;
    }

    state = result.payload;
    return result;
  }

  void clearMirrorLaunchRequest() {
    state = null;
  }
}

final aiChatBridgeProvider =
    NotifierProvider<AiChatBridgeNotifier, MirrorLaunchPayload?>(
  AiChatBridgeNotifier.new,
);
