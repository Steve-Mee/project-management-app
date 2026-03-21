import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/mirror_entitlement_provider.dart';
import '../../../core/providers/mirror_session_provider.dart';
import '../../../generated/app_localizations.dart';
import '../apply_dialog.dart';
import '../mirror_signed_inputs_backend.dart';
import '../providers/mirror_orchestrator_provider.dart';
import 'mirror_backend_workflows.dart';
import 'mirror_preview_metadata_service.dart';
import 'mirror_service_boundaries.dart';

class MirrorRunFlowService implements MirrorInteractiveRunCoordinator {
  const MirrorRunFlowService();

  static const MirrorBackendWorkflows _workflows = MirrorBackendWorkflows();
  static const MirrorPreviewMetadataService _previewMetadataService =
      MirrorPreviewMetadataService();

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

      appendTerminalLine(l10n.mirrorStepGenerateSent);
      final generateResult = await orchestrator.generate(
        ref: ref,
        sessionKey: sessionKey,
        prompt: selectedContent,
        context: executionContext,
        mode: selectedMode,
      );

      if (!isMounted()) {
        return;
      }

      if (!generateResult.success) {
        final errorText = _firstNonEmpty(
              generateResult.message,
              generateResult.diagnostics.join(' | '),
            ) ??
            l10n.mirrorUnknownGenerateError;
        _showSnackBar(messenger, l10n.mirrorGenerateFailed(errorText));
        return;
      }

      appendTerminalLine(l10n.mirrorStepGenerateCompleted);
      if (generateResult.diagnostics.isNotEmpty) {
        appendTerminalLine(
          l10n.mirrorGenerateDiagnostics(
              generateResult.diagnostics.join(' | ')),
        );
      }

      final compilePlan = _workflows.prepareCompilePlan(
        executionContext: executionContext,
        selectedFile: selectedFile,
        selectedContent: selectedContent,
        generatedCode: generateResult.code,
      );
      final compileContextForPreviewAndApply =
          compilePlan.compileContextForPreviewAndApply;
      final runPrompt = compilePlan.runPrompt;

      appendTerminalLine(l10n.mirrorStepCompileSent);
      final compileResult = await orchestrator.compile(
        ref: ref,
        sessionKey: sessionKey,
        prompt: runPrompt,
        context: compileContextForPreviewAndApply,
        mode: selectedMode,
      );

      if (!isMounted()) {
        return;
      }

      if (!compileResult.success) {
        final errorText = _firstNonEmpty(
          compileResult.errors.join(' | '),
          l10n.mirrorUnknownCompileError,
        )!;
        _showSnackBar(messenger, l10n.mirrorCompileFailed(errorText));
        return;
      }

      appendTerminalLine(l10n.mirrorStepCompileCompleted);
      final compileOutput = compileResult.output;
      if (compileOutput == null || compileOutput.trim().isEmpty) {
        _showSnackBar(messenger,
            l10n.mirrorCompileFailed(l10n.mirrorUnknownCompileError));
        return;
      }

      final compileFingerprint = computeCompileResultFingerprint(
        prompt: runPrompt,
        context: compileContextForPreviewAndApply,
        mode: selectedMode,
        output: compileOutput,
      );
      final previewServerVersionToken =
          _previewMetadataService.normalizeServerVersionToken(
        compileResult.serverVersionToken,
      );

      if (compileResult.warnings.isNotEmpty) {
        appendTerminalLine(
          l10n.mirrorCompileWarnings(compileResult.warnings.join(' | ')),
        );
      }

      appendTerminalLine(l10n.mirrorStepPreviewBuilding);
      final applyPlan = _workflows.prepareApplyPlan(
        compileContextForPreviewAndApply: compileContextForPreviewAndApply,
        selectedFile: selectedFile,
        compileOutput: compileOutput,
        generatedCode: generateResult.code,
      );
      final patches = applyPlan.patches;

      if (patches.isEmpty) {
        appendTerminalLine(l10n.mirrorNoPatchPreviewTerminal);
        return;
      }

      appendTerminalLine(l10n.mirrorStepPreviewReady(patches.length));

      final previewPatch = applyPlan.previewPatch!;

      appendTerminalLine(l10n.mirrorStepApplyWaiting(previewPatch.path));
      if (!context.mounted) {
        return;
      }
      final applyDecision = await ApplyDialog.show(
        context,
        title: l10n.mirrorApplyChangesTitle(previewPatch.path),
        originalContent: previewPatch.originalContent,
        updatedContent: previewPatch.updatedContent,
        compileFingerprint: compileFingerprint,
        suggestedBranch: 'mirror/$projectId-$taskId',
      );

      if (!isMounted()) {
        return;
      }

      final applyApproved =
          applyDecision?.apply == true && applyDecision?.acceptRisk == true;
      if (!applyApproved) {
        appendTerminalLine(l10n.mirrorStepApplyCanceled);
        return;
      }

      appendTerminalLine(l10n.mirrorStepApplySent);
      final builtApplyMetadata = _previewMetadataService.buildApplyMetadata(
        metadata: compileContextForPreviewAndApply.metadata,
        previewServerVersionToken: previewServerVersionToken,
        previewCompileFingerprint: compileFingerprint,
        previewCompileOutput: compileOutput,
      );
      final applyContext = compileContextForPreviewAndApply.copyWith(
        files: Map<String, String>.from(compileContextForPreviewAndApply.files),
        metadata: builtApplyMetadata,
      );
      final applyResult = await orchestrator.apply(
        ref: ref,
        sessionKey: sessionKey,
        prompt: runPrompt,
        context: applyContext,
        mode: selectedMode,
        compileFingerprint: compileFingerprint,
      );

      if (!isMounted()) {
        return;
      }

      if (applyResult.success) {
        _applyPreviewPatchesToSession(
          ref: ref,
          sessionNotifier: sessionNotifier,
          sessionKey: sessionKey,
          patches: patches,
          fallbackSelectedFile: selectedFile,
        );
        if (applyResult.appliedFiles.isNotEmpty) {
          appendTerminalLine(
            l10n.mirrorAppliedFiles(applyResult.appliedFiles.join(', ')),
          );
        }
        appendTerminalLine(l10n.mirrorRunCompletedTerminal);
        return;
      }

      final errorText = applyResult.message ?? l10n.mirrorUnknownApplyError;
      _showSnackBar(messenger, l10n.mirrorApplyFailed(errorText));
    } catch (error) {
      if (!isMounted()) {
        return;
      }
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

  String? _firstNonEmpty(String? first, String? second) {
    final firstValue = first?.trim();
    if (firstValue != null && firstValue.isNotEmpty) {
      return firstValue;
    }

    final secondValue = second?.trim();
    if (secondValue != null && secondValue.isNotEmpty) {
      return secondValue;
    }

    return null;
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
