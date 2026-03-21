import '../mirror_signed_inputs_backend.dart';
import 'mirror_audit_history_service.dart';
import 'mirror_patch_service.dart';
import 'mirror_prompt_builder_service.dart';
import 'mirror_secure_apply_service.dart';

/// PR2 workflow service: keeps cross-cutting Mirror backend behaviors in one
/// place so transports/backends remain focused on IO and protocol mapping.
class MirrorBackendWorkflows {
  const MirrorBackendWorkflows();

  static const MirrorPatchService _patchService = MirrorPatchService();
  static const MirrorSecureApplyService _secureApplyService =
      MirrorSecureApplyService();
  static const MirrorAuditHistoryService _auditHistoryService =
      MirrorAuditHistoryService();
  static const MirrorPromptBuilderService _promptBuilderService =
      MirrorPromptBuilderService();

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

  Future<void> persistApplyToHive({
    required ProjectContext context,
    required String mode,
    required String prompt,
    required List<MirrorFilePatch> patches,
    required ApplySecurityArtifacts artifacts,
    String backend = 'unknown',
    Map<String, String> updatedFiles = const <String, String>{},
  }) async {
    await _auditHistoryService.persistApplyHistory(
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

  Future<ApplySecurityArtifacts> prepareSignedInputAndBackup({
    required ProjectContext context,
    Duration signedUrlTtl = MirrorSecureApplyService.defaultSignedUrlTtl,
    String signedInputBucket = MirrorSecureApplyService.defaultSignedInputBucket,
    String backupBucket = MirrorSecureApplyService.defaultBackupBucket,
  }) {
    return _secureApplyService.prepareSignedInputAndBackup(
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
    final result = await _secureApplyService.secureApply(
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

  Future<String> buildFullContext({
    required String prompt,
    required ProjectContext context,
    int maxFiles = 24,
    int maxFileChars = 6000,
    int maxTotalChars = 64000,
  }) {
    return Future<String>.value(
      _promptBuilderService.buildFullContext(
        prompt: prompt,
        projectId: context.projectId,
        taskId: context.taskId,
        files: context.files,
        metadata: context.metadata,
        maxFiles: maxFiles,
        maxFileChars: maxFileChars,
        maxTotalChars: maxTotalChars,
      ),
    );
  }
}
