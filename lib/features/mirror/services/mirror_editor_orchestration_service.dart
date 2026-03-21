import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/app_localizations.dart';
import 'mirror_run_flow_service.dart';
import 'mirror_service_boundaries.dart';

class MirrorEditorOrchestrationService
    implements MirrorInteractiveRunCoordinator {
  const MirrorEditorOrchestrationService();

  static const MirrorRunFlowService _runFlowService = MirrorRunFlowService();

  @override
  Future<void> runCurrentFileInTerminal({
    required BuildContext context,
    required WidgetRef ref,
    required String projectId,
    required String taskId,
    required String selectedMode,
    required String sessionKey,
    required AppLocalizations l10n,
    required bool Function() isMounted,
    required void Function(String line) appendTerminalLine,
  }) async {
    return _runFlowService.run(
      context: context,
      ref: ref,
      projectId: projectId,
      taskId: taskId,
      selectedMode: selectedMode,
      sessionKey: sessionKey,
      l10n: l10n,
      isMounted: isMounted,
      appendTerminalLine: appendTerminalLine,
    );
  }
}
