import '../models/mirror_structured_error.dart';
import 'mirror_structured_error_parser.dart';

class MirrorRunPostExecutionAnalysis {
  const MirrorRunPostExecutionAnalysis({
    this.structuredError,
    required this.isCompleted,
  });

  final MirrorStructuredError? structuredError;
  final bool isCompleted;
}

class MirrorRunPostExecutionAnalysisService {
  const MirrorRunPostExecutionAnalysisService();

  MirrorRunPostExecutionAnalysis analyze({
    required List<String> recentTerminalLines,
    required String completedMarker,
    required MirrorStructuredErrorParser parser,
  }) {
    final parsed = parser.findLatest(recentTerminalLines);
    if (parsed != null) {
      return MirrorRunPostExecutionAnalysis(
        structuredError: parsed,
        isCompleted: false,
      );
    }

    final completed = recentTerminalLines.any(
      (String line) => line.contains(completedMarker),
    );
    return MirrorRunPostExecutionAnalysis(
      isCompleted: completed,
    );
  }
}