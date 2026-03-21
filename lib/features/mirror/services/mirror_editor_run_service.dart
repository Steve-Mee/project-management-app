import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/mirror_entitlement_provider.dart';
import '../../../core/providers/mirror_session_provider.dart';
import '../../../generated/app_localizations.dart';
import '../providers/mirror_editor_orchestration_provider.dart';
import 'mirror_editor_preflight_service.dart';

class MirrorEditorRunService {
  const MirrorEditorRunService();

  static const MirrorEditorPreflightService _preflightService =
      MirrorEditorPreflightService();

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

    // Budget preflight: warn in the terminal if the context will be trimmed
    // before being sent to the backend (enforcement happens in the gateway).
    final sessionState = ref.read(mirrorSessionProvider(sessionKey));
    final budgetService = ref.read(mirrorContextBudgetServiceProvider);
    final budgetMessage = _preflightService.buildBudgetPreflightMessage(
      budgetService: budgetService,
      projectId: projectId,
      taskId: taskId,
      files: sessionState.files,
    );
    if (budgetMessage != null) {
      appendTerminalLine(budgetMessage);
    }

    setRunInProgress(true);

    try {
      final coordinator = ref.read(mirrorInteractiveRunCoordinatorProvider);
      await coordinator.runCurrentFileInTerminal(
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
