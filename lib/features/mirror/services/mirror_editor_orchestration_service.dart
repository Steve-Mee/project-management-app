import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/app_localizations.dart';
import '../../../core/providers/mirror_provider.dart';
import '../../../core/providers/mirror_session_provider.dart';
import '../apply_dialog.dart';
import 'mirror_orchestrator_service.dart';

class MirrorEditorOrchestrationService {
  const MirrorEditorOrchestrationService();

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
    final sessionNotifier = ref.read(mirrorSessionProvider(sessionKey).notifier);
    final sessionState = ref.read(mirrorSessionProvider(sessionKey));
    final selectedFile = sessionState.selectedFile;
    final selectedContent = sessionState.files[selectedFile]?.trim() ?? '';

    if (selectedContent.isEmpty) {
      appendTerminalLine(l10n.mirrorRunAbortedFileEmpty(selectedFile));
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
      final orchestrator = MirrorOrchestratorService(backend: backend);

      final originalFiles = Map<String, String>.from(sessionState.files);
      final originalMetadata = <String, dynamic>{
        'selectedFile': selectedFile,
        'trigger': 'run_button',
      };

      final executionContext = ProjectContext(
        projectId: projectId,
        taskId: taskId,
        files: originalFiles,
        metadata: originalMetadata,
      );

      final originalCompileContext = ProjectContext(
        projectId: executionContext.projectId,
        taskId: executionContext.taskId,
        files: Map<String, String>.from(executionContext.files),
        metadata: Map<String, dynamic>.from(executionContext.metadata),
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
        final errorText =
            _firstNonEmpty(generateResult.message, generateResult.diagnostics.join(' | ')) ??
                l10n.mirrorUnknownGenerateError;
        appendTerminalLine(l10n.mirrorGenerateFailedTerminal(errorText));
        _showSnackBar(messenger, l10n.mirrorGenerateFailed(errorText));
        return;
      }

      appendTerminalLine(l10n.mirrorStepGenerateCompleted);
      if (generateResult.diagnostics.isNotEmpty) {
        appendTerminalLine(
          l10n.mirrorGenerateDiagnostics(generateResult.diagnostics.join(' | ')),
        );
      }

      final generatedPatches = _buildPreviewPatches(
        backend: backend,
        context: executionContext,
        selectedFile: selectedFile,
        compileOutput: generateResult.code,
        generatedCode: generateResult.code,
      );

      final compileContext = generatedPatches.isEmpty
          ? originalCompileContext
          : ProjectContext(
              projectId: originalCompileContext.projectId,
              taskId: originalCompileContext.taskId,
              files: backend.applyPatchesToFiles(
                files: originalCompileContext.files,
                patches: generatedPatches,
              ),
              metadata: originalCompileContext.metadata,
            );

      final compileContextFingerprint =
          _computeContextFingerprint(compileContext.files);
      final compileMetadata = <String, dynamic>{
        ...compileContext.metadata,
        'previewContextFingerprint': compileContextFingerprint,
      };
      final compileContextForPreviewAndApply = ProjectContext(
        projectId: compileContext.projectId,
        taskId: compileContext.taskId,
        files: Map<String, String>.from(compileContext.files),
        metadata: compileMetadata,
      );

      final runPrompt = _firstNonEmpty(generateResult.code, selectedContent) ?? selectedContent;

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
        final errorText =
            _firstNonEmpty(compileResult.errors.join(' | '), l10n.mirrorUnknownCompileError)!;
        appendTerminalLine(l10n.mirrorCompileFailedTerminal(errorText));
        _showSnackBar(messenger, l10n.mirrorCompileFailed(errorText));
        return;
      }

      appendTerminalLine(l10n.mirrorStepCompileCompleted);
      final compileOutput = compileResult.output;
      if (compileOutput == null || compileOutput.trim().isEmpty) {
        final errorText = l10n.mirrorUnknownCompileError;
        appendTerminalLine(l10n.mirrorCompileFailedTerminal(errorText));
        _showSnackBar(messenger, l10n.mirrorCompileFailed(errorText));
        return;
      }

      final compileFingerprint = computeCompileResultFingerprint(
        prompt: runPrompt,
        context: compileContextForPreviewAndApply,
        mode: selectedMode,
        output: compileOutput,
      );

      if (compileResult.warnings.isNotEmpty) {
        appendTerminalLine(
          l10n.mirrorCompileWarnings(compileResult.warnings.join(' | ')),
        );
      }

      appendTerminalLine(l10n.mirrorStepPreviewBuilding);
      final patches = _buildPreviewPatches(
        backend: backend,
        context: compileContextForPreviewAndApply,
        selectedFile: selectedFile,
        compileOutput: compileOutput,
        generatedCode: generateResult.code,
      );

      if (patches.isEmpty) {
        appendTerminalLine(l10n.mirrorNoPatchPreviewTerminal);
        _showSnackBar(messenger, l10n.mirrorNoChangesAfterCompile);
        return;
      }

      appendTerminalLine(l10n.mirrorStepPreviewReady(patches.length));

      final previewPatch = patches.firstWhere(
        (MirrorFilePatch patch) => patch.path == selectedFile,
        orElse: () => patches.first,
      );

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

      final applyApproved = applyDecision?.apply == true && applyDecision?.acceptRisk == true;
      if (!applyApproved) {
        appendTerminalLine(l10n.mirrorStepApplyCanceled);
        _showSnackBar(messenger, l10n.mirrorApplyCanceled);
        return;
      }

      appendTerminalLine(l10n.mirrorStepApplySent);
      final applyContext = ProjectContext(
        projectId: compileContextForPreviewAndApply.projectId,
        taskId: compileContextForPreviewAndApply.taskId,
        files: Map<String, String>.from(compileContextForPreviewAndApply.files),
        metadata: Map<String, dynamic>.from(
          compileContextForPreviewAndApply.metadata,
        ),
      );
      final applyResult = await orchestrator.apply(
        ref: ref,
        sessionKey: sessionKey,
        prompt: runPrompt,
        context: applyContext,
        mode: selectedMode,
        compileFingerprint: applyDecision?.compileFingerprint,
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
          appendTerminalLine(l10n.mirrorAppliedFiles(applyResult.appliedFiles.join(', ')));
        }
        appendTerminalLine(l10n.mirrorRunCompletedTerminal);
        _showSnackBar(messenger, l10n.mirrorRunSuccess);
        return;
      }

      final errorText = applyResult.message ?? l10n.mirrorUnknownApplyError;
      appendTerminalLine(l10n.mirrorApplyFailedTerminal(errorText));
      _showSnackBar(messenger, l10n.mirrorApplyFailed(errorText));
    } catch (error) {
      appendTerminalLine(l10n.mirrorRunCrashedTerminal(error.toString()));
      if (!isMounted()) {
        return;
      }
      _showSnackBar(messenger, l10n.mirrorRunCrashed(error.toString()));
    }
  }

  List<MirrorFilePatch> _buildPreviewPatches({
    required MirrorComputeBackend backend,
    required ProjectContext context,
    required String selectedFile,
    required String? compileOutput,
    required String? generatedCode,
  }) {
    final normalizedCompileOutput = compileOutput?.trim() ?? '';

    if (normalizedCompileOutput.isNotEmpty) {
      final patchesFromCompile = backend.buildPatchesFromApplyPayload(
        context: context,
        output: normalizedCompileOutput,
        fallbackPath: selectedFile,
      );
      if (patchesFromCompile.isNotEmpty) {
        return patchesFromCompile;
      }
    }

    final normalizedGeneratedCode = generatedCode?.trim() ?? '';
    if (normalizedGeneratedCode.isNotEmpty) {
      return backend.buildPatchesFromApplyPayload(
        context: context,
        output: normalizedGeneratedCode,
        fallbackPath: selectedFile,
      );
    }

    return const <MirrorFilePatch>[];
  }

  void _applyPreviewPatchesToSession({
    required WidgetRef ref,
    required MirrorSessionNotifier sessionNotifier,
    required String sessionKey,
    required List<MirrorFilePatch> patches,
    required String fallbackSelectedFile,
  }) {
    final previousSelected = ref.read(mirrorSessionProvider(sessionKey)).selectedFile;

    for (final patch in patches) {
      final existsInSession = ref.read(mirrorSessionProvider(sessionKey)).files.containsKey(patch.path);
      if (!existsInSession) {
        sessionNotifier.upsertFileContent(
          path: patch.path,
          content: patch.updatedContent,
        );
        continue;
      }

      sessionNotifier.selectFile(patch.path);
      sessionNotifier.updateSelectedFileContent(patch.updatedContent);
    }

    final restoreTarget = ref.read(mirrorSessionProvider(sessionKey)).files.containsKey(previousSelected)
        ? previousSelected
        : fallbackSelectedFile;
    sessionNotifier.selectFile(restoreTarget);
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
    messenger.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _computeContextFingerprint(Map<String, String> files) {
    final entries = files.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final buffer = StringBuffer();
    for (final entry in entries) {
      buffer
        ..write(entry.key)
        ..write('::')
        ..write(entry.value)
        ..write('\n');
    }

    return sha256.convert(utf8.encode(buffer.toString())).toString();
  }
}
