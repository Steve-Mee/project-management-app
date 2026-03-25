import '../models/mirror_structured_error.dart';
import 'mirror_run_post_execution_analysis_service.dart';
import 'mirror_structured_error_parser.dart';

class MirrorRunExecutionOutcome {
  const MirrorRunExecutionOutcome({
    required this.failed,
    this.structuredError,
    this.completed = false,
  });

  final bool failed;
  final MirrorStructuredError? structuredError;
  final bool completed;
}

class MirrorRunExecutionService {
  const MirrorRunExecutionService();

  Future<MirrorRunExecutionOutcome> execute({
    required Future<void> Function() runAction,
    required List<String> Function() terminalLogReader,
    required int beforeTerminalCount,
    required MirrorRunPostExecutionAnalysisService analysisService,
    required MirrorStructuredErrorParser parser,
    required String completedMarker,
  }) async {
    try {
      await runAction();

      final recentTerminalLines = terminalLogReader()
          .skip(beforeTerminalCount)
          .toList(growable: false);
      final analysis = analysisService.analyze(
        recentTerminalLines: recentTerminalLines,
        completedMarker: completedMarker,
        parser: parser,
      );

      return MirrorRunExecutionOutcome(
        failed: false,
        structuredError: analysis.structuredError,
        completed: analysis.isCompleted,
      );
    } catch (_) {
      return const MirrorRunExecutionOutcome(failed: true);
    }
  }
}