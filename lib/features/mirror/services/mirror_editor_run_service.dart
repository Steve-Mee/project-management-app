import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/mirror_provider.dart';
import '../../../core/providers/mirror_session_provider.dart';
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

    // Budget preflight: warn in the terminal if the context will be trimmed
    // before being sent to the backend (enforcement happens in the gateway).
    final sessionState = ref.read(mirrorSessionProvider(sessionKey));
    if (sessionState.files.isNotEmpty) {
      final budgetService = ref.read(mirrorContextBudgetServiceProvider);
      final draftContext = ProjectContext(
        projectId: projectId,
        taskId: taskId,
        files: sessionState.files,
        metadata: const ProjectContextMetadata(),
      );
      final report = budgetService.enforce(draftContext).report;
      if (report.wasEnforced) {
        appendTerminalLine(
          'Payload budget: ${report.originalFileCount} file(s) '
          '(${_kbLabel(report.originalBytes)}) → '
          '${report.enforcedFileCount} file(s) '
          '(${_kbLabel(report.enforcedBytes)}); '
          '${report.droppedFiles.length} dropped, '
          '${report.truncatedFiles.length} truncated.',
        );
      }
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

  static String _kbLabel(int bytes) =>
      '${(bytes / 1024).toStringAsFixed(1)} KB';
}
