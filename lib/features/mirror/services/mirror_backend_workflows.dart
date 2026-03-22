import 'dart:convert';

import '../mirror_signed_inputs_backend.dart';
import 'mirror_apply_audit_service.dart';
import 'mirror_apply_security_mode_service.dart';
import 'mirror_apply_validator_service.dart';
import 'mirror_backend_error_format.dart';
import 'mirror_observability_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mirror_patch_service.dart';
import 'mirror_preview_metadata_service.dart';
import 'mirror_secure_apply_service.dart';

class MirrorSessionPatchMutation {
  const MirrorSessionPatchMutation({
    required this.path,
    required this.content,
    required this.requiresUpsert,
  });

  final String path;
  final String content;
  final bool requiresUpsert;
}

class MirrorSessionPatchPlan {
  const MirrorSessionPatchPlan({
    required this.mutations,
    required this.restoreTarget,
  });

  final List<MirrorSessionPatchMutation> mutations;
  final String restoreTarget;
}

/// Patch plan for compile stage of interactive Mirror run.
class MirrorCompilePatchPlan {
  const MirrorCompilePatchPlan({
    required this.compileContextForPreviewAndApply,
    required this.compileContextFingerprint,
    required this.runPrompt,
  });

  final ProjectContext compileContextForPreviewAndApply;
  final String compileContextFingerprint;
  final String runPrompt;
}

/// Patch plan for apply stage of interactive Mirror run.
class MirrorApplyPatchPlan {
  const MirrorApplyPatchPlan({
    required this.patches,
    required this.previewPatch,
  });

  final List<MirrorFilePatch> patches;
  final MirrorFilePatch? previewPatch;
}

class MirrorApplyTransportResult {
  const MirrorApplyTransportResult({
    required this.success,
    this.output,
    this.errors = const <String>[],
  });

  final bool success;
  final String? output;
  final List<String> errors;
}

typedef MirrorApplyErrorFormatter = String Function({
  required MirrorBackendErrorFamily family,
  required String message,
  bool? retryable,
});

/// PR2 workflow service: keeps cross-cutting Mirror backend behaviors in one
/// place so transports/backends remain focused on IO and protocol mapping.
class MirrorBackendWorkflows {
  const MirrorBackendWorkflows();

  static const MirrorPatchService _patchService = MirrorPatchService();
  static const MirrorPreviewMetadataService _previewMetadataService =
      MirrorPreviewMetadataService();
  static const MirrorApplyValidatorService _applyValidator =
      MirrorApplyValidatorService();
  static const MirrorApplyAuditService _applyAudit = MirrorApplyAuditService();

  List<MirrorFilePatch> buildPatchesFromApplyPayload({
    required ProjectContext context,
    required String output,
    String? fallbackPath,
  }) {
    final patches = _patchService.buildPatchesFromApplyPayload(
      files: context.files,
      metadata: context.metadata,
      output: output,
      fallbackPath: fallbackPath,
    );

    return patches
        .map(
          (patch) => MirrorFilePatch(
            path: patch.path,
            originalContent: patch.originalContent,
            updatedContent: patch.updatedContent,
            diff: patch.diff,
          ),
        )
        .toList(growable: false);
  }

  /// Canonical preview-patch derivation used by UI run flows.
  ///
  /// Resolution order:
  /// 1) compile output
  /// 2) generated code fallback
  List<MirrorFilePatch> buildPreviewPatches({
    required ProjectContext context,
    required String selectedFile,
    String? compileOutput,
    String? generatedCode,
  }) {
    final normalizedCompileOutput = compileOutput?.trim() ?? '';

    if (normalizedCompileOutput.isNotEmpty) {
      final patchesFromCompile = buildPatchesFromApplyPayload(
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
      return buildPatchesFromApplyPayload(
        context: context,
        output: normalizedGeneratedCode,
        fallbackPath: selectedFile,
      );
    }

    return const <MirrorFilePatch>[];
  }

  Map<String, String> applyPatchesToFiles({
    required Map<String, String> files,
    required List<MirrorFilePatch> patches,
  }) {
    final servicePatches = patches
        .map(
          (patch) => MirrorPatch(
            path: patch.path,
            originalContent: patch.originalContent,
            updatedContent: patch.updatedContent,
            diff: patch.diff,
          ),
        )
        .toList(growable: false);

    return _patchService.applyPatchesToFiles(
      files: files,
      patches: servicePatches,
    );
  }

  MirrorSessionPatchPlan buildSessionPersistPlan({
    required Map<String, String> currentFiles,
    required String previousSelected,
    required String fallbackSelectedFile,
    required List<MirrorFilePatch> patches,
  }) {
    final mutations = patches
        .map(
          (patch) => MirrorSessionPatchMutation(
            path: patch.path,
            content: patch.updatedContent,
            requiresUpsert: !currentFiles.containsKey(patch.path),
          ),
        )
        .toList(growable: false);

    final restoreTarget = currentFiles.containsKey(previousSelected)
        ? previousSelected
        : fallbackSelectedFile;

    return MirrorSessionPatchPlan(
      mutations: mutations,
      restoreTarget: restoreTarget,
    );
  }

  /// Prepares compile plan for interactive run flow.
  /// 
  /// Computes preview patches and context fingerprint for consistency validation.
  MirrorCompilePatchPlan prepareCompilePlan({
    required ProjectContext executionContext,
    required String selectedFile,
    required String selectedContent,
    String? generatedCode,
  }) {
    final originalCompileContext = ProjectContext(
      projectId: executionContext.projectId,
      taskId: executionContext.taskId,
      files: Map<String, String>.from(executionContext.files),
      metadata: executionContext.metadata,
    );

    final generatedPatches = buildPreviewPatches(
      context: executionContext,
      selectedFile: selectedFile,
      compileOutput: generatedCode,
      generatedCode: generatedCode,
    );

    final compileContext = generatedPatches.isEmpty
        ? originalCompileContext
        : originalCompileContext.copyWith(
            files: applyPatchesToFiles(
              files: originalCompileContext.files,
              patches: generatedPatches,
            ),
          );

    final compileContextFingerprint =
        _previewMetadataService.computeContextFingerprint(compileContext.files);

    final compileContextForPreviewAndApply = compileContext.copyWith(
      files: Map<String, String>.from(compileContext.files),
      metadata: compileContext.metadata.copyWith(
        previewContextFingerprint: compileContextFingerprint,
      ),
    );

    return MirrorCompilePatchPlan(
      compileContextForPreviewAndApply: compileContextForPreviewAndApply,
      compileContextFingerprint: compileContextFingerprint,
      runPrompt:
          _firstNonEmpty(generatedCode, selectedContent) ?? selectedContent,
    );
  }

  /// Prepares apply plan for interactive run flow.
  ///
  /// Selects patches for UI review and identifies primary patch for dialog.
  MirrorApplyPatchPlan prepareApplyPlan({
    required ProjectContext compileContextForPreviewAndApply,
    required String selectedFile,
    required String compileOutput,
    String? generatedCode,
  }) {
    final patches = buildPreviewPatches(
      context: compileContextForPreviewAndApply,
      selectedFile: selectedFile,
      compileOutput: compileOutput,
      generatedCode: generatedCode,
    );

    if (patches.isEmpty) {
      return const MirrorApplyPatchPlan(
        patches: <MirrorFilePatch>[],
        previewPatch: null,
      );
    }

    final previewPatch = patches.firstWhere(
      (MirrorFilePatch patch) => patch.path == selectedFile,
      orElse: () => patches.first,
    );

    return MirrorApplyPatchPlan(
      patches: patches,
      previewPatch: previewPatch,
    );
  }

  static String? _firstNonEmpty(String? first, String? second) {
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



  ApplyResult buildNoPatchApplyFailure({
    String? message,
  }) {
    return ApplyResult(
      success: false,
      message: message ?? 'Apply failed: no patchable changes returned.',
    );
  }

  ApplyResult buildApplySuccessResult({
    required List<MirrorFilePatch> patches,
    String? backupId,
  }) {
    return ApplyResult(
      success: true,
      appliedFiles: patches.map((patch) => patch.path).toSet().toList(),
      message: backupId == null || backupId.trim().isEmpty
          ? 'Applied ${patches.length} patch(es).'
          : 'Applied ${patches.length} patch(es) with backup $backupId.',
    );
  }

  Future<ApplySecurityArtifacts> prepareSignedInputAndBackup({
    required SupabaseClient client,
    required ProjectContext context,
    Duration signedUrlTtl = MirrorSecureApplyService.defaultSignedUrlTtl,
    String signedInputBucket =
        MirrorSecureApplyService.defaultSignedInputBucket,
    String backupBucket = MirrorSecureApplyService.defaultBackupBucket,
  }) {
    final secureApplyService = MirrorSecureApplyService(supabaseClient: client);
    return secureApplyService.prepareSignedInputAndBackup(
      projectId: context.projectId,
      taskId: context.taskId,
      files: context.files,
      signedUrlTtl: signedUrlTtl,
      signedInputBucket: signedInputBucket,
      backupBucket: backupBucket,
    );
  }

  Future<ApplyResult> secureApply({
    required SupabaseClient client,
    required String prompt,
    required ProjectContext context,
    required String mode,
    required Future<ApplyResult> Function(ApplySecurityArtifacts artifacts)
        onApply,
    Duration signedUrlTtl = MirrorSecureApplyService.defaultSignedUrlTtl,
    String signedInputBucket =
        MirrorSecureApplyService.defaultSignedInputBucket,
    String backupBucket = MirrorSecureApplyService.defaultBackupBucket,
  }) async {
    final secureApplyService = MirrorSecureApplyService(supabaseClient: client);
    final result = await secureApplyService.secureApply(
      prompt: prompt,
      projectId: context.projectId,
      taskId: context.taskId,
      mode: mode,
      files: context.files,
      onApply: (artifacts) async {
        final backendResult = await onApply(artifacts);
        return MirrorSecureApplyResult(
          success: backendResult.success,
          appliedFiles: backendResult.appliedFiles,
          message: backendResult.message,
        );
      },
      signedUrlTtl: signedUrlTtl,
      signedInputBucket: signedInputBucket,
      backupBucket: backupBucket,
    );

    return ApplyResult(
      success: result.success,
      appliedFiles: result.appliedFiles,
      message: result.message,
    );
  }

  Future<ApplyResult> executeApplyFlow({
    required String backend,
    required String prompt,
    required ProjectContext context,
    required String mode,
    required Future<CompileResult> Function() preflightCompile,
    required Future<MirrorApplyTransportResult> Function(
      ApplySecurityArtifacts? artifacts,
    ) executeTransportApply,
    required MirrorApplyErrorFormatter formatError,
    SupabaseClient? secureApplyClient,
    String? compileFingerprint,
    bool allowSecureApply = true,
    bool auditLoggingEnabled = true,
    bool requireSignedApply = false,
    int userTrustScore = 100,
    MirrorObservabilityService? observabilityService,
    Duration signedUrlTtl = MirrorSecureApplyService.defaultSignedUrlTtl,
    String signedInputBucket =
        MirrorSecureApplyService.defaultSignedInputBucket,
    String backupBucket = MirrorSecureApplyService.defaultBackupBucket,
  }) async {
    final preflight = await preflightCompile();
    final preflightOutput = preflight.output?.trim() ?? '';
    if (!preflight.success || preflightOutput.isEmpty) {
      return ApplyResult(
        success: false,
        message: preflight.errors.isEmpty
            ? formatError(
                family: MirrorBackendErrorFamily.validation,
                message: 'Apply failed: compile output is empty.',
                retryable: false,
              )
            : preflight.errors.join(' | '),
      );
    }

    final normalizedCompileFingerprint = compileFingerprint?.trim() ?? '';
    if (normalizedCompileFingerprint.isNotEmpty) {
      final consistencyValidation =
          _applyValidator.validatePreviewApplyConsistency(
        prompt: prompt,
        context: context,
        mode: mode,
        expectedCompileFingerprint: normalizedCompileFingerprint,
        preflightOutput: preflightOutput,
      );
      if (!consistencyValidation.isValid) {
        return ApplyResult(
          success: false,
          message: formatError(
            family: MirrorBackendErrorFamily.consistency,
            message:
                consistencyValidation.errorMessage ?? 'Unknown consistency error',
            retryable: consistencyValidation.isRetryable,
          ),
        );
      }
    }

    final previewPatches = buildPatchesFromApplyPayload(
      context: context,
      output: preflightOutput,
    );
    if (previewPatches.isEmpty) {
      return buildNoPatchApplyFailure(
        message: formatError(
          family: MirrorBackendErrorFamily.validation,
          message: 'Apply failed: no patchable changes returned.',
          retryable: false,
        ),
      );
    }

    final factors = buildApplySecurityModeFactors(
      totalPatchBytes: _estimatePatchBytes(previewPatches),
      auditLoggingEnabled: auditLoggingEnabled,
      mode: mode,
      requireSignedApply: requireSignedApply,
      userTrustScore: userTrustScore,
    );
    final decision = allowSecureApply
        ? mirrorApplySecurityModeService.determineApplySecurityMode(factors)
        : const ApplySecurityModeDecision(
            mode: MirrorApplySecurityMode.direct,
            rationale: 'Secure apply disabled; using direct apply flow.',
            isSecurityBindingDecision: false,
          );

    mirrorApplySecurityModeService.logSecurityModeDecision(
      '${context.projectId}::${context.taskId}',
      decision,
      factors,
    );

    if (decision.mode == MirrorApplySecurityMode.signed &&
        normalizedCompileFingerprint.isEmpty) {
      return ApplyResult(
        success: false,
        message: formatError(
          family: MirrorBackendErrorFamily.validation,
          message:
              'Apply blocked: preview fingerprint missing. Re-run preview before applying.',
          retryable: false,
        ),
      );
    }

    if (decision.mode == MirrorApplySecurityMode.signed) {
      if (secureApplyClient == null) {
        return ApplyResult(
          success: false,
          message: formatError(
            family: MirrorBackendErrorFamily.config,
            message:
                'Secure apply requires an injected Supabase client for signed artifact preparation.',
            retryable: false,
          ),
        );
      }

      return secureApply(
        client: secureApplyClient,
        prompt: prompt,
        context: context,
        mode: mode,
        signedUrlTtl: signedUrlTtl,
        signedInputBucket: signedInputBucket,
        backupBucket: backupBucket,
        onApply: (ApplySecurityArtifacts artifacts) async {
          final transport = await executeTransportApply(artifacts);
          return _finalizeApplyTransport(
            backend: backend,
            prompt: prompt,
            context: context,
            mode: mode,
            transport: transport,
            artifacts: artifacts,
            formatError: formatError,
          );
        },
      );
    }

    final transport = await executeTransportApply(null);
    return _finalizeApplyTransport(
      backend: backend,
      prompt: prompt,
      context: context,
      mode: mode,
      transport: transport,
      artifacts: null,
      formatError: formatError,
    );
  }

  Future<ApplyResult> _finalizeApplyTransport({
    required String backend,
    required String prompt,
    required ProjectContext context,
    required String mode,
    required MirrorApplyTransportResult transport,
    required ApplySecurityArtifacts? artifacts,
    required MirrorApplyErrorFormatter formatError,
  }) async {
    final output = transport.output?.trim() ?? '';
    if (!transport.success || output.isEmpty) {
      return ApplyResult(
        success: false,
        message: transport.errors.isEmpty
            ? formatError(
                family: MirrorBackendErrorFamily.validation,
                message: 'Apply failed: apply output is empty.',
                retryable: false,
              )
            : transport.errors.join(' | '),
      );
    }

    final patches = buildPatchesFromApplyPayload(
      context: context,
      output: output,
    );
    if (patches.isEmpty) {
      return buildNoPatchApplyFailure(
        message: formatError(
          family: MirrorBackendErrorFamily.validation,
          message: 'Apply failed: no patchable changes returned.',
          retryable: false,
        ),
      );
    }

    if (artifacts != null) {
      final updatedFiles = applyPatchesToFiles(
        files: context.files,
        patches: patches,
      );
      await _applyAudit.persistApplyToHive(
        context: context,
        mode: mode,
        prompt: prompt,
        patches: patches,
        artifacts: artifacts,
        backend: backend,
        updatedFiles: updatedFiles,
      );
    }

    return buildApplySuccessResult(
      patches: patches,
      backupId: artifacts?.backupId,
    );
  }

  int _estimatePatchBytes(List<MirrorFilePatch> patches) {
    var totalBytes = 0;
    for (final patch in patches) {
      final payload = patch.diff.trim().isNotEmpty
          ? patch.diff
          : patch.updatedContent;
      totalBytes += utf8.encode(payload).length;
    }
    return totalBytes;
  }
}
