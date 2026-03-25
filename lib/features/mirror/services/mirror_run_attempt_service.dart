import 'mirror_run_completion_service.dart';
import 'mirror_run_execution_service.dart';
import 'mirror_run_post_execution_analysis_service.dart';
import 'mirror_run_ui_state_transition_service.dart';
import 'mirror_structured_error_parser.dart';

class MirrorRunAttemptService {
  const MirrorRunAttemptService({
    MirrorRunExecutionService runExecutionService =
        const MirrorRunExecutionService(),
    MirrorRunCompletionService runCompletionService =
        const MirrorRunCompletionService(),
  }) : _runExecutionService = runExecutionService,
       _runCompletionService = runCompletionService;

  final MirrorRunExecutionService _runExecutionService;
  final MirrorRunCompletionService _runCompletionService;

  Future<MirrorRunUiStateTransition> execute({
    required Future<void> Function() runAction,
    required List<String> Function() terminalLogReader,
    required int beforeTerminalCount,
    required MirrorRunPostExecutionAnalysisService analysisService,
    required MirrorStructuredErrorParser parser,
    required String completedMarker,
    required MirrorRunUiStateSnapshot currentState,
  }) async {
    final outcome = await _runExecutionService.execute(
      runAction: runAction,
      terminalLogReader: terminalLogReader,
      beforeTerminalCount: beforeTerminalCount,
      analysisService: analysisService,
      parser: parser,
      completedMarker: completedMarker,
    );

    return _runCompletionService.complete(
      outcome: outcome,
      current: currentState,
    );
  }
}