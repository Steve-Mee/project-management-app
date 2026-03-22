// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/providers/task/task_providers.dart';
import 'package:pma_core/services/app_logger.dart';
import '../../../core/providers/mirror_session_provider.dart';

import '../mirror_signed_inputs_backend.dart';
import 'mirror_apply_post_hooks_service.dart';
import 'mirror_backend_workflows.dart';
import 'mirror_preview_metadata_service.dart';
import 'mirror_service_boundaries.dart';

/// Stages of the apply flow state machine.
///
/// ```
/// Idle → Generating → Compiling → Previewing → Validating → Applying → Done
/// ```
///
/// Transitions are one-way. Any failure short-circuits to the result without
/// advancing the stage (the caller receives a [MirrorApplyFlowResult] whose
/// [MirrorApplyFlowResult.success] is false and whose [MirrorApplyFlowResult.stage]
/// indicates where the failure occurred).
enum MirrorApplyFlowStage {
  idle,
  generating,
  compiling,
  previewing,
  validating,
  applying,
  done,
}

/// Immutable snapshot emitted via [MirrorApplyFlowCoordinator.executeApplyFlow]'s
/// `onStateChange` callback at each stage transition.
class MirrorApplyFlowState {
  const MirrorApplyFlowState({
    required this.stage,
    this.patches = const [],
    this.compileFingerprint,
    this.compileOutput,
    this.previewServerVersionToken,
    this.previewPatchPath,
    this.generateDiagnostics = const [],
    this.compileWarnings = const [],
  });

  final MirrorApplyFlowStage stage;

  /// Populated from [MirrorApplyFlowStage.previewing] onwards.
  final List<MirrorFilePatch> patches;

  /// Consistency token linking compile output to the apply request.
  /// Populated from [MirrorApplyFlowStage.previewing] onwards.
  final String? compileFingerprint;

  /// Raw compile output text. Populated from [MirrorApplyFlowStage.previewing] onwards.
  final String? compileOutput;

  /// Server version token from the compile response.
  /// Populated from [MirrorApplyFlowStage.previewing] onwards.
  final String? previewServerVersionToken;

  /// Path of the primary patch for display in diff dialogs and log lines.
  /// Populated from [MirrorApplyFlowStage.previewing] onwards.
  final String? previewPatchPath;

  /// Diagnostics from the generate step. Populated at [MirrorApplyFlowStage.compiling].
  final List<String> generateDiagnostics;

  /// Warnings from the compile step. Populated at [MirrorApplyFlowStage.previewing].
  final List<String> compileWarnings;
}

/// Data passed to [MirrorApplyFlowCoordinator.executeApplyFlow]'s
/// `onApprovalRequired` callback so the caller can show a diff dialog.
class MirrorApplyFlowPreviewData {
  const MirrorApplyFlowPreviewData({
    required this.patches,
    required this.compileFingerprint,
    required this.compileOutput,
    required this.previewServerVersionToken,
    required this.previewPatch,
  });

  final List<MirrorFilePatch> patches;
  final String compileFingerprint;
  final String compileOutput;
  final String previewServerVersionToken;

  /// Primary patch shown in the diff dialog.
  final MirrorFilePatch previewPatch;
}

/// Returned by [MirrorApplyFlowCoordinator.executeApplyFlow].
class MirrorApplyFlowResult {
  const MirrorApplyFlowResult({
    required this.success,
    required this.stage,
    this.appliedFiles = const [],
    this.patches,
    this.error,
  });

  final bool success;

  /// The stage at which the flow completed (or failed).
  final MirrorApplyFlowStage stage;

  /// Files reported as applied by the backend. Populated only on [success].
  final List<String> appliedFiles;

  /// Available on [success] for post-apply session patching in the UI layer.
  final List<MirrorFilePatch>? patches;

  /// Sentinel values:
  /// - `'cancelled'`  – user dismissed the diff dialog.
  /// - `'no_patches'` – compile produced no patchable output.
  /// - Otherwise a backend error message.
  final String? error;
}

/// Coordinates the full generate → compile → preview → apply pipeline.
///
/// This class owns all backend orchestration logic. It has no dependency on
/// Flutter widgets or [BuildContext]; those stay in the calling layer
/// ([MirrorRunFlowService]).
///
/// State transitions are communicated via [executeApplyFlow]'s `onStateChange`
/// callback, and user approval is requested via `onApprovalRequired`.
class MirrorApplyFlowCoordinator {
  MirrorApplyFlowCoordinator({
    MirrorApplyPostHooksService? postHooksService,
  }) : _postHooksService = postHooksService ?? const MirrorApplyPostHooksService();

  static const MirrorBackendWorkflows _workflows = MirrorBackendWorkflows();
  static const MirrorPreviewMetadataService _previewMetadataService =
      MirrorPreviewMetadataService();
  final MirrorApplyPostHooksService _postHooksService;

  /// Runs the apply pipeline from generate through to apply.
  ///
  /// [prompt] is the content of the currently selected file (the "run prompt").
  /// [context] must have [ProjectContextMetadata.selectedFile] populated.
  ///
  /// [onStateChange] is called synchronously before each stage begins so the
  /// caller can emit progress lines.
  ///
  /// [onApprovalRequired] is awaited at the [MirrorApplyFlowStage.previewing]
  /// stage. Return `true` to proceed, `false` to cancel.
  Future<MirrorApplyFlowResult> executeApplyFlow({
    required MirrorExecutionOrchestrator orchestrator,
    required WidgetRef ref,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
    MirrorSessionNotifier? sessionNotifier,
    required void Function(MirrorApplyFlowState state) onStateChange,
    required Future<bool> Function(MirrorApplyFlowPreviewData preview)
        onApprovalRequired,
  }) async {
    // ── Stage: generating ──────────────────────────────────────────────────
    onStateChange(const MirrorApplyFlowState(
      stage: MirrorApplyFlowStage.generating,
    ));

    final generateResult = await orchestrator.generate(
      ref: ref,
      sessionKey: sessionKey,
      prompt: prompt,
      context: context,
      mode: mode,
    );

    if (!generateResult.success) {
      return MirrorApplyFlowResult(
        success: false,
        stage: MirrorApplyFlowStage.generating,
        error: generateResult.message ?? generateResult.diagnostics.join(' | '),
      );
    }

    if (sessionNotifier != null) {
      await _postHooksService.persistOnCompileStart(
        sessionNotifier: sessionNotifier,
      );
    }

    // ── Stage: compiling ───────────────────────────────────────────────────
    final selectedFile = context.metadata.selectedFile ?? '';
    final compilePlan = _workflows.prepareCompilePlan(
      executionContext: context,
      selectedFile: selectedFile,
      selectedContent: prompt,
      generatedCode: generateResult.code,
    );
    final compileContext = compilePlan.compileContextForPreviewAndApply;
    final runPrompt = compilePlan.runPrompt;

    onStateChange(MirrorApplyFlowState(
      stage: MirrorApplyFlowStage.compiling,
      generateDiagnostics: generateResult.diagnostics,
    ));

    final compileResult = await orchestrator.compile(
      ref: ref,
      sessionKey: sessionKey,
      prompt: runPrompt,
      context: compileContext,
      mode: mode,
    );

    if (!compileResult.success) {
      return MirrorApplyFlowResult(
        success: false,
        stage: MirrorApplyFlowStage.compiling,
        error: compileResult.errors.join(' | '),
      );
    }

    final compileOutput = compileResult.output;
    if (compileOutput == null || compileOutput.trim().isEmpty) {
      return MirrorApplyFlowResult(
        success: false,
        stage: MirrorApplyFlowStage.compiling,
        error: compileResult.errors.isNotEmpty
            ? compileResult.errors.join(' | ')
            : 'Compile output was empty.',
      );
    }

    final compileFingerprint = computeCompileResultFingerprint(
      prompt: runPrompt,
      context: compileContext,
      mode: mode,
      output: compileOutput,
    );
    final previewServerVersionToken =
        _previewMetadataService.normalizeServerVersionToken(
              compileResult.serverVersionToken,
            ) ??
            '';

    final applyPlan = _workflows.prepareApplyPlan(
      compileContextForPreviewAndApply: compileContext,
      selectedFile: selectedFile,
      compileOutput: compileOutput,
      generatedCode: generateResult.code,
    );
    final patches = applyPlan.patches;

    if (patches.isEmpty) {
      return const MirrorApplyFlowResult(
        success: false,
        stage: MirrorApplyFlowStage.compiling,
        error: 'no_patches',
      );
    }

    final previewPatch = applyPlan.previewPatch!;

    // ── Stage: previewing – emit state, then await user approval ──────────
    onStateChange(MirrorApplyFlowState(
      stage: MirrorApplyFlowStage.previewing,
      patches: patches,
      compileFingerprint: compileFingerprint,
      compileOutput: compileOutput,
      previewServerVersionToken: previewServerVersionToken,
      previewPatchPath: previewPatch.path,
      compileWarnings: compileResult.warnings,
    ));

    final approved = await onApprovalRequired(
      MirrorApplyFlowPreviewData(
        patches: patches,
        compileFingerprint: compileFingerprint,
        compileOutput: compileOutput,
        previewServerVersionToken: previewServerVersionToken,
        previewPatch: previewPatch,
      ),
    );

    if (!approved) {
      return MirrorApplyFlowResult(
        success: false,
        stage: MirrorApplyFlowStage.previewing,
        patches: patches,
        error: 'cancelled',
      );
    }

    // ── Stage: validating – build apply metadata ───────────────────────────
    onStateChange(MirrorApplyFlowState(
      stage: MirrorApplyFlowStage.validating,
      patches: patches,
      compileFingerprint: compileFingerprint,
    ));

    final builtApplyMetadata = _previewMetadataService.buildApplyMetadata(
      metadata: compileContext.metadata,
      previewServerVersionToken: previewServerVersionToken,
      previewCompileFingerprint: compileFingerprint,
      previewCompileOutput: compileOutput,
    );

    // Embed compileFingerprint so that if apply is queued in the outbox,
    // the replay path can perform its consistency check.
    final applyContext = compileContext.copyWith(
      files: Map<String, String>.from(compileContext.files),
      metadata: builtApplyMetadata.copyWith(
        compileFingerprint: compileFingerprint,
      ),
    );

    // ── Stage: applying ────────────────────────────────────────────────────
    onStateChange(MirrorApplyFlowState(
      stage: MirrorApplyFlowStage.applying,
      patches: patches,
      compileFingerprint: compileFingerprint,
    ));

    final applyResult = await orchestrator.apply(
      ref: ref,
      sessionKey: sessionKey,
      prompt: runPrompt,
      context: applyContext,
      mode: mode,
      compileFingerprint: compileFingerprint,
    );

    if (applyResult.success) {
      await _refreshCaches(
        ref: ref,
        context: applyContext,
        sessionKey: sessionKey,
      );
      if (sessionNotifier != null) {
        await _postHooksService.persistOnApplyComplete(
          sessionNotifier: sessionNotifier,
          projectId: context.projectId,
          taskId: context.taskId,
        );
      }
    }

    // ── Stage: done ────────────────────────────────────────────────────────
    onStateChange(MirrorApplyFlowState(
      stage: MirrorApplyFlowStage.done,
      patches: patches,
      compileFingerprint: compileFingerprint,
    ));

    return MirrorApplyFlowResult(
      success: applyResult.success,
      stage: MirrorApplyFlowStage.done,
      appliedFiles: applyResult.appliedFiles,
      patches: patches,
      error: applyResult.success ? null : applyResult.message,
    );
  }

  Future<void> _refreshCaches({
    required WidgetRef ref,
    required ProjectContext context,
    required String sessionKey,
  }) async {
    final parts = sessionKey.split('::');
    final projectId = context.projectId.isNotEmpty
        ? context.projectId
        : (parts.isNotEmpty ? parts.first : '');
    final taskId = context.taskId.isNotEmpty
        ? context.taskId
        : (parts.length > 1 ? parts[1] : '');

    if (projectId.isEmpty) {
      return;
    }

    try {
      await ref.read(tasksProvider.notifier).loadTasks(projectId);
      if (taskId.isNotEmpty) {
        ref.invalidate(subTasksByTaskProvider(taskId));
      }
    } catch (error) {
      AppLogger.instance.w(
        'Mirror apply succeeded but task/subtask cache refresh failed',
        error: error,
      );
    }
  }
}
