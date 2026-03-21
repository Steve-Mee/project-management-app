import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'models/project_context.dart';
import 'services/mirror_audit_history_service.dart';
import 'services/mirror_patch_service.dart';
import 'services/mirror_prompt_builder_service.dart';
import 'services/mirror_secure_apply_service.dart';

export 'models/project_context.dart';

class GenerateResult {
  const GenerateResult({
    required this.success,
    this.code,
    this.message,
    this.diagnostics = const <String>[],
  });

  final bool success;
  final String? code;
  final String? message;
  final List<String> diagnostics;
}

class CompileResult {
  const CompileResult({
    required this.success,
    this.output,
    this.serverVersionToken,
    this.errors = const <String>[],
    this.warnings = const <String>[],
  });

  final bool success;
  final String? output;
  final String? serverVersionToken;
  final List<String> errors;
  final List<String> warnings;
}

class ApplyResult {
  const ApplyResult({
    required this.success,
    this.appliedFiles = const <String>[],
    this.message,
  });

  final bool success;
  final List<String> appliedFiles;
  final String? message;
}

typedef ApplySecurityArtifacts = MirrorSecureApplyArtifacts;
typedef ApplyUploadFailure = MirrorSecureApplyUploadFailure;
typedef ApplyUploadFailureCode = MirrorSecureApplyUploadFailureCode;

class MirrorFilePatch {
  const MirrorFilePatch({
    required this.path,
    required this.originalContent,
    required this.updatedContent,
    required this.diff,
  });

  final String path;
  final String originalContent;
  final String updatedContent;
  final String diff;
}

const MirrorPatchService _mirrorPatchService = MirrorPatchService();
final MirrorSecureApplyService _mirrorSecureApplyService =
    MirrorSecureApplyService();
const MirrorAuditHistoryService _mirrorAuditHistoryService =
    MirrorAuditHistoryService();
const MirrorPromptBuilderService _mirrorPromptBuilderService =
    MirrorPromptBuilderService();

abstract class MirrorComputeBackend {
  Future<GenerateResult> generate({
    required String prompt,
    required ProjectContext context,
    required String mode,
  });

  Future<CompileResult> compile({
    required String prompt,
    required ProjectContext context,
    required String mode,
  });

  Future<ApplyResult> apply({
    required String prompt,
    required ProjectContext context,
    required String mode,
    String? compileFingerprint,
  });
}

String computeCompileResultFingerprint({
  required String prompt,
  required ProjectContext context,
  required String mode,
  required String output,
}) {
  final files = context.files.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  final filesPayload =
      files.map((entry) => '${entry.key}:${entry.value}').join('|');
  final payload = <String>[
    prompt,
    context.projectId,
    context.taskId,
    mode,
    filesPayload,
    output,
  ].join('||');
  return sha256.convert(utf8.encode(payload)).toString();
}

extension MirrorPatchTools on MirrorComputeBackend {
  // Compatibility API: retained to avoid breaking callsites while
  // responsibilities are migrated toward dedicated workflow services.
  List<MirrorFilePatch> buildPatchesFromApplyPayload({
    required ProjectContext context,
    required String output,
    String? fallbackPath,
  }) {
    final patches = _mirrorPatchService.buildPatchesFromApplyPayload(
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
    return _mirrorPatchService.applyPatchesToFiles(
      files: files,
      patches: servicePatches,
    );
  }

  Future<void> persistApplyToHive({
    required ProjectContext context,
    required String mode,
    required String prompt,
    required List<MirrorFilePatch> patches,
    required ApplySecurityArtifacts artifacts,
    String backend = 'unknown',
    Map<String, String> updatedFiles = const <String, String>{},
  }) async {
    await _mirrorAuditHistoryService.persistApplyHistory(
      projectId: context.projectId,
      taskId: context.taskId,
      mode: mode,
      prompt: prompt,
      backupId: artifacts.backupId,
      signedInputUrls: artifacts.signedInputUrls,
      backupSignedUrls: artifacts.backupSignedUrls,
      patches: patches
          .map(
            (patch) => MirrorAuditHistoryPatchEntry(
              path: patch.path,
              diff: patch.diff,
            ),
          )
          .toList(growable: false),
      backend: backend,
      updatedFiles: updatedFiles,
    );
  }
}

extension MirrorApplySecurity on MirrorComputeBackend {
  // Compatibility API: retained to avoid breaking callsites while
  // responsibilities are migrated toward dedicated workflow services.
  Future<ApplySecurityArtifacts> prepareSignedInputAndBackup({
    required ProjectContext context,
    Duration signedUrlTtl = MirrorSecureApplyService.defaultSignedUrlTtl,
    String signedInputBucket = MirrorSecureApplyService.defaultSignedInputBucket,
    String backupBucket = MirrorSecureApplyService.defaultBackupBucket,
  }) async {
    return _mirrorSecureApplyService.prepareSignedInputAndBackup(
      projectId: context.projectId,
      taskId: context.taskId,
      files: context.files,
      signedUrlTtl: signedUrlTtl,
      signedInputBucket: signedInputBucket,
      backupBucket: backupBucket,
    );
  }

  Future<ApplyResult> secureApply({
    required String prompt,
    required ProjectContext context,
    required String mode,
    required Future<ApplyResult> Function(ApplySecurityArtifacts artifacts)
        onApply,
    Duration signedUrlTtl = MirrorSecureApplyService.defaultSignedUrlTtl,
    String signedInputBucket = MirrorSecureApplyService.defaultSignedInputBucket,
    String backupBucket = MirrorSecureApplyService.defaultBackupBucket,
  }) async {
    final result = await _mirrorSecureApplyService.secureApply(
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
}

extension MirrorPromptBuilder on MirrorComputeBackend {
  // Compatibility API: retained to avoid breaking callsites while
  // responsibilities are migrated toward dedicated workflow services.
  Future<String> buildFullContext({
    required String prompt,
    required ProjectContext context,
    int maxFiles = 24,
    int maxFileChars = 6000,
    int maxTotalChars = 64000,
  }) async {
    return _mirrorPromptBuilderService.buildFullContext(
      prompt: prompt,
      projectId: context.projectId,
      taskId: context.taskId,
      files: context.files,
      metadata: context.metadata,
      maxFiles: maxFiles,
      maxFileChars: maxFileChars,
      maxTotalChars: maxTotalChars,
    );
  }
}
