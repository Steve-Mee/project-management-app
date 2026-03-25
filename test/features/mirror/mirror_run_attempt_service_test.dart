import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/models/mirror_structured_error.dart';
import 'package:project_management_app/features/mirror/services/mirror_run_attempt_service.dart';
import 'package:project_management_app/features/mirror/services/mirror_run_post_execution_analysis_service.dart';
import 'package:project_management_app/features/mirror/services/mirror_run_ui_state_transition_service.dart';
import 'package:project_management_app/features/mirror/services/mirror_structured_error_parser.dart';

void main() {
  const service = MirrorRunAttemptService();
  const analysisService = MirrorRunPostExecutionAnalysisService();
  const parser = MirrorStructuredErrorParser();

  group('MirrorRunAttemptService', () {
    test('returns transition that preserves previous error on failed run',
        () async {
      final terminalLog = <String>['before'];

      final transition = await service.execute(
        runAction: () async {
          throw StateError('run failure');
        },
        terminalLogReader: () => terminalLog,
        beforeTerminalCount: 1,
        analysisService: analysisService,
        parser: parser,
        completedMarker: 'Run completed',
        currentState: const MirrorRunUiStateSnapshot(
          isRunInProgress: true,
          lastStructuredError: MirrorStructuredError(
            errorFamily: 'timeout',
            retryable: true,
          ),
        ),
      );

      expect(transition.nextState.isRunInProgress, isFalse);
      expect(transition.nextState.lastStructuredError, isNotNull);
      expect(transition.retryFeedbackError, isNull);
    });

    test('returns transition with retry feedback on structured error', () async {
      final terminalLog = <String>['before'];

      final transition = await service.execute(
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
        currentState: const MirrorRunUiStateSnapshot(
          isRunInProgress: true,
          lastStructuredError: null,
        ),
      );

      expect(transition.nextState.isRunInProgress, isFalse);
      expect(transition.nextState.lastStructuredError, isNotNull);
      expect(transition.retryFeedbackError, isNotNull);
    });

    test('returns transition that clears error when run completes', () async {
      final terminalLog = <String>['before'];

      final transition = await service.execute(
        runAction: () async {
          terminalLog.add('Run completed successfully');
        },
        terminalLogReader: () => terminalLog,
        beforeTerminalCount: 1,
        analysisService: analysisService,
        parser: parser,
        completedMarker: 'Run completed',
        currentState: const MirrorRunUiStateSnapshot(
          isRunInProgress: true,
          lastStructuredError: MirrorStructuredError(
            errorFamily: 'timeout',
            retryable: true,
          ),
        ),
      );

      expect(transition.nextState.isRunInProgress, isFalse);
      expect(transition.nextState.lastStructuredError, isNull);
      expect(transition.retryFeedbackError, isNull);
    });
  });
}