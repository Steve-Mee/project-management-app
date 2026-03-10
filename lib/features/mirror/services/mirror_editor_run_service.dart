import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/app_localizations.dart';
import '../providers/mirror_editor_orchestration_provider.dart';

class MirrorEditorRunService {
  const MirrorEditorRunService();

  Future<void> runCurrentFileInTerminal({
    required BuildContext context,
    required WidgetRef ref,
    required String projectId,
    required String taskId,
    required String selectedMode,
    required String sessionKey,
    required AppLocalizations l10n,
    required bool isRunInProgress,
    required bool Function() isMounted,
    required void Function(bool inProgress) setRunInProgress,
    required void Function(String line) appendTerminalLine,
  }) async {
    if (isRunInProgress) {
      return;
    }

    setRunInProgress(true);

    try {
      final orchestrationService =
          ref.read(mirrorEditorOrchestrationServiceProvider);
      await orchestrationService.runCurrentFileInTerminal(
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
    } finally {
      if (isMounted()) {
        setRunInProgress(false);
      }
    }
  }
}
