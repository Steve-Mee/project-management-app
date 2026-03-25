import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/services/mirror_run_post_execution_analysis_service.dart';
import 'package:project_management_app/features/mirror/services/mirror_structured_error_parser.dart';

void main() {
  const service = MirrorRunPostExecutionAnalysisService();
  const parser = MirrorStructuredErrorParser();

  group('MirrorRunPostExecutionAnalysisService', () {
    test('returns structured error when recent lines contain retryable payload', () {
      const errorLine =
          '{"error_family":"timeout","retryable":true,"message":"request timed out"}';
      final analysis = service.analyze(
        recentTerminalLines: const <String>[
          'some output',
          errorLine,
        ],
        completedMarker: 'Run completed',
        parser: parser,
      );

      expect(analysis.structuredError, isNotNull);
      expect(analysis.structuredError!.errorFamily, 'timeout');
      expect(analysis.isCompleted, isFalse);
    });

    test('returns completed when no structured error exists and marker is found', () {
      final analysis = service.analyze(
        recentTerminalLines: const <String>[
          'booting',
          'Run completed successfully',
        ],
        completedMarker: 'Run completed',
        parser: parser,
      );

      expect(analysis.structuredError, isNull);
      expect(analysis.isCompleted, isTrue);
    });

    test('returns neutral state when no error and no completion marker', () {
      final analysis = service.analyze(
        recentTerminalLines: const <String>[
          'still running',
          'stream output',
        ],
        completedMarker: 'Run completed',
        parser: parser,
      );

      expect(analysis.structuredError, isNull);
      expect(analysis.isCompleted, isFalse);
    });
  });
}