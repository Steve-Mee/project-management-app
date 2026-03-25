import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/services/mirror_run_execution_service.dart';
import 'package:project_management_app/features/mirror/services/mirror_run_post_execution_analysis_service.dart';
import 'package:project_management_app/features/mirror/services/mirror_structured_error_parser.dart';

void main() {
  const service = MirrorRunExecutionService();
  const analysisService = MirrorRunPostExecutionAnalysisService();
  const parser = MirrorStructuredErrorParser();

  group('MirrorRunExecutionService', () {
    test('returns structured error outcome when run writes structured error',
        () async {
      final terminalLog = <String>['before'];

      final outcome = await service.execute(
        runAction: () async {
          terminalLog.add(
            '{"error_family":"timeout","retryable":true,"message":"request timed out"}',
          );
        },
        terminalLogReader: () => terminalLog,
        beforeTerminalCount: 1,
        analysisService: analysisService,
        parser: parser,
        completedMarker: 'Run completed',
      );

      expect(outcome.failed, isFalse);
      expect(outcome.structuredError, isNotNull);
      expect(outcome.structuredError!.errorFamily, 'timeout');
      expect(outcome.completed, isFalse);
    });

    test('returns completed outcome when marker exists without error', () async {
      final terminalLog = <String>['before'];

      final outcome = await service.execute(
        runAction: () async {
          terminalLog.add('Run completed successfully');
        },
        terminalLogReader: () => terminalLog,
        beforeTerminalCount: 1,
        analysisService: analysisService,
        parser: parser,
        completedMarker: 'Run completed',
      );

      expect(outcome.failed, isFalse);
      expect(outcome.structuredError, isNull);
      expect(outcome.completed, isTrue);
    });

    test('returns failed outcome when run action throws', () async {
      final terminalLog = <String>['before'];

      final outcome = await service.execute(
        runAction: () async {
          throw StateError('run failure');
        },
        terminalLogReader: () => terminalLog,
        beforeTerminalCount: 1,
        analysisService: analysisService,
        parser: parser,
        completedMarker: 'Run completed',
      );

      expect(outcome.failed, isTrue);
      expect(outcome.structuredError, isNull);
      expect(outcome.completed, isFalse);
    });
  });
}