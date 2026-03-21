import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/app_localizations.dart';
import 'mirror_run_flow_service.dart';
import 'mirror_service_boundaries.dart';

@Deprecated('Use MirrorRunFlowService via mirrorInteractiveRunCoordinatorProvider')
class MirrorEditorOrchestrationService
  extends MirrorRunFlowService
  implements MirrorInteractiveRunCoordinator {
  const MirrorEditorOrchestrationService();

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
    return super.runCurrentFileInTerminal(
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
