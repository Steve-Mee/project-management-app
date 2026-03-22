import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/mirror_entitlement_provider.dart';
import '../../../core/providers/mirror_session_provider.dart';
import '../../../generated/app_localizations.dart';
import '../apply_dialog.dart';
import '../mirror_signed_inputs_backend.dart';
import '../providers/mirror_orchestrator_provider.dart';
import 'mirror_backend_workflows.dart';
import 'mirror_apply_flow_coordinator.dart';
import 'mirror_service_boundaries.dart';

/// UI-facing run flow wrapper.
///
/// This service owns widget concerns only: reading session state, opening the
/// approval dialog, mapping coordinator states to terminal lines, and applying
/// accepted preview patches back into the local session.
class MirrorRunFlowService implements MirrorInteractiveRunCoordinator {
  const MirrorRunFlowService();

  static const MirrorBackendWorkflows _workflows = MirrorBackendWorkflows();
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
    final messenger = ScaffoldMessenger.of(context);
    final sessionNotifier =
        ref.read(mirrorSessionProvider(sessionKey).notifier);
    final sessionState = ref.read(mirrorSessionProvider(sessionKey));
    final selectedFile = sessionState.selectedFile;
    final selectedContent = sessionState.files[selectedFile]?.trim() ?? '';

    if (selectedContent.isEmpty) {
      if (!isMounted()) {
        return;
      }
      _showSnackBar(messenger, l10n.mirrorSelectedFileEmpty);
      return;
    }

    appendTerminalLine(l10n.mirrorRunStarting(selectedFile));
    appendTerminalLine(l10n.mirrorRunFlowLine);

    try {
      // Resolve the current backend once per run so the full flow stays on one
      // execution path (cloud or private) from generate through apply.
      final backend = await ref.read(mirrorBackendProvider.future);
      final orchestratorFactory = ref.read(
        mirrorExecutionOrchestratorFactoryProvider,
      );
      final orchestrator = orchestratorFactory(backend);

      final originalFiles = Map<String, String>.from(sessionState.files);
      final executionContext = ProjectContext(
        projectId: projectId,
        taskId: taskId,
        files: originalFiles,
        metadata: ProjectContextMetadata(
          selectedFile: selectedFile,
          trigger: 'run_button',
        ),
      );

      final coordinator = MirrorApplyFlowCoordinator();
      final flowResult = await coordinator.executeApplyFlow(
        orchestrator: orchestrator,
        ref: ref,
        sessionKey: sessionKey,
        prompt: selectedContent,
        context: executionContext,
        mode: selectedMode,
        sessionNotifier: sessionNotifier,
        onStateChange: (state) =>
            _handleFlowState(state, appendTerminalLine, l10n),
        onApprovalRequired: (preview) async {
          // The coordinator stays UI-free. Approval is injected here so the
          // dialog lifecycle remains in the widget-facing layer.
          if (!isMounted()) return false;
          if (!context.mounted) return false;
          final decision = await ApplyDialog.show(
            context,
            title: l10n.mirrorApplyChangesTitle(preview.previewPatch.path),
            originalContent: preview.previewPatch.originalContent,
            updatedContent: preview.previewPatch.updatedContent,
            compileFingerprint: preview.compileFingerprint,
            suggestedBranch: 'mirror/$projectId-$taskId',
          );
          if (!isMounted()) return false;
          return decision?.apply == true && decision?.acceptRisk == true;
        },
      );

      if (!isMounted()) return;

      if (flowResult.success) {
        // The backend already applied the change remotely; this mirrors the
        // accepted preview locally so the open editor/session stays in sync.
        _applyPreviewPatchesToSession(
          ref: ref,
          sessionNotifier: sessionNotifier,
          sessionKey: sessionKey,
          patches: flowResult.patches ?? const [],
          fallbackSelectedFile: selectedFile,
        );
        if (flowResult.appliedFiles.isNotEmpty) {
          appendTerminalLine(
            l10n.mirrorAppliedFiles(flowResult.appliedFiles.join(', ')),
          );
        }
        appendTerminalLine(l10n.mirrorRunCompletedTerminal);
        return;
      }

      switch (flowResult.error) {
        case 'cancelled':
          appendTerminalLine(l10n.mirrorStepApplyCanceled);
        case 'no_patches':
          appendTerminalLine(l10n.mirrorNoPatchPreviewTerminal);
        default:
          _showSnackBar(messenger, _errorMessageForStage(flowResult, l10n));
      }
    } catch (error) {
      if (!isMounted()) return;
      _showSnackBar(messenger, l10n.mirrorRunCrashed(error.toString()));
    }
  }

  Future<void> run({
    required BuildContext context,
    required WidgetRef ref,
    required String projectId,
    required String taskId,
    required String selectedMode,
    required String sessionKey,
    required AppLocalizations l10n,
    required bool Function() isMounted,
    required void Function(String line) appendTerminalLine,
  }) {
    return runCurrentFileInTerminal(
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

  // Maps coordinator state transitions to terminal log lines.
  void _handleFlowState(
    MirrorApplyFlowState state,
    void Function(String) appendTerminalLine,
    AppLocalizations l10n,
  ) {
    switch (state.stage) {
      case MirrorApplyFlowStage.generating:
        appendTerminalLine(l10n.mirrorStepGenerateSent);
      case MirrorApplyFlowStage.compiling:
        appendTerminalLine(l10n.mirrorStepGenerateCompleted);
        if (state.generateDiagnostics.isNotEmpty) {
          appendTerminalLine(l10n.mirrorGenerateDiagnostics(
              state.generateDiagnostics.join(' | ')));
        }
        appendTerminalLine(l10n.mirrorStepCompileSent);
      case MirrorApplyFlowStage.previewing:
        appendTerminalLine(l10n.mirrorStepCompileCompleted);
        if (state.compileWarnings.isNotEmpty) {
          appendTerminalLine(
              l10n.mirrorCompileWarnings(state.compileWarnings.join(' | ')));
        }
        appendTerminalLine(l10n.mirrorStepPreviewBuilding);
        appendTerminalLine(l10n.mirrorStepPreviewReady(state.patches.length));
        if (state.previewPatchPath != null) {
          appendTerminalLine(
              l10n.mirrorStepApplyWaiting(state.previewPatchPath!));
        }
      case MirrorApplyFlowStage.applying:
        appendTerminalLine(l10n.mirrorStepApplySent);
      default:
        break;
    }
  }

  String _errorMessageForStage(
    MirrorApplyFlowResult flowResult,
    AppLocalizations l10n,
  ) {
    final error = flowResult.error ?? l10n.mirrorUnknownApplyError;
    return switch (flowResult.stage) {
      MirrorApplyFlowStage.generating =>
        l10n.mirrorGenerateFailed(
            flowResult.error ?? l10n.mirrorUnknownGenerateError),
      MirrorApplyFlowStage.compiling =>
        l10n.mirrorCompileFailed(
            flowResult.error ?? l10n.mirrorUnknownCompileError),
      _ => l10n.mirrorApplyFailed(error),
    };
  }

  void _applyPreviewPatchesToSession({
    required WidgetRef ref,
    required MirrorSessionNotifier sessionNotifier,
    required String sessionKey,
    required List<MirrorFilePatch> patches,
    required String fallbackSelectedFile,
  }) {
    final previousSelected =
        ref.read(mirrorSessionProvider(sessionKey)).selectedFile;
    final currentFiles = ref.read(mirrorSessionProvider(sessionKey)).files;

    // Reuse the workflow helper so session mutation follows the same patch
    // ordering and restore-target rules as the backend planning code.
    final patchPlan = _workflows.buildSessionPersistPlan(
      currentFiles: currentFiles,
      previousSelected: previousSelected,
      fallbackSelectedFile: fallbackSelectedFile,
      patches: patches,
    );

    for (final mutation in patchPlan.mutations) {
      if (mutation.requiresUpsert) {
        sessionNotifier.upsertFileContent(
          path: mutation.path,
          content: mutation.content,
        );
        continue;
      }

      sessionNotifier.selectFile(mutation.path);
      sessionNotifier.updateSelectedFileContent(mutation.content);
    }

    sessionNotifier.selectFile(patchPlan.restoreTarget);
  }

  void _showSnackBar(ScaffoldMessengerState messenger, String message) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
