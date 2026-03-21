import '../mirror_signed_inputs_backend.dart';
import 'mirror_audit_history_service.dart';

/// Encapsulates apply audit history persistence for Mirror workflows.
///
/// Pure domain service: wraps audit history service for orchestration layer.
class MirrorApplyAuditService {
  static const MirrorAuditHistoryService _auditHistoryService =
      MirrorAuditHistoryService();

  const MirrorApplyAuditService();

  /// Records apply operation to audit history in Hive.
  ///
  /// Persists:
  /// - Project + task context
  /// - Applied patches and diffs
  /// - Security artifacts (backup ID, signed URLs)
  /// - Backend identifier
  /// - Updated files snapshot
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
}
