import '../mirror_signed_inputs_backend.dart';
import 'mirror_context_budget_service.dart';

class MirrorEditorPreflightService {
  const MirrorEditorPreflightService();

  String? buildBudgetPreflightMessage({
    required MirrorContextBudgetService budgetService,
    required String projectId,
    required String taskId,
    required Map<String, String> files,
  }) {
    if (files.isEmpty) {
      return null;
    }

    final draftContext = ProjectContext(
      projectId: projectId,
      taskId: taskId,
      files: files,
      metadata: const ProjectContextMetadata(),
    );
    final report = budgetService.enforce(draftContext).report;
    if (!report.wasEnforced) {
      return null;
    }

    return 'Payload budget: ${report.originalFileCount} file(s) '
        '(${_kbLabel(report.originalBytes)}) -> '
        '${report.enforcedFileCount} file(s) '
        '(${_kbLabel(report.enforcedBytes)}); '
        '${report.droppedFiles.length} dropped, '
        '${report.truncatedFiles.length} truncated.';
  }

  static String _kbLabel(int bytes) => '${(bytes / 1024).toStringAsFixed(1)} KB';
}
