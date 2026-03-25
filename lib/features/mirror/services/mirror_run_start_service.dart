import 'mirror_context_budget_service.dart';
import 'mirror_editor_preflight_service.dart';

class MirrorRunStartPreparation {
  const MirrorRunStartPreparation({
    required this.beforeTerminalCount,
    this.budgetMessage,
  });

  final int beforeTerminalCount;
  final String? budgetMessage;
}

class MirrorRunStartService {
  const MirrorRunStartService({
    MirrorEditorPreflightService preflightService =
        const MirrorEditorPreflightService(),
  }) : _preflightService = preflightService;

  final MirrorEditorPreflightService _preflightService;

  MirrorRunStartPreparation prepare({
    required MirrorContextBudgetService budgetService,
    required String projectId,
    required String taskId,
    required Map<String, String> files,
    required List<String> terminalLog,
  }) {
    return MirrorRunStartPreparation(
      beforeTerminalCount: terminalLog.length,
      budgetMessage: _preflightService.buildBudgetPreflightMessage(
        budgetService: budgetService,
        projectId: projectId,
        taskId: taskId,
        files: files,
      ),
    );
  }
}