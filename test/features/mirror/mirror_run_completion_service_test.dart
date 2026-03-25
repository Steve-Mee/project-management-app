import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/models/mirror_structured_error.dart';
import 'package:project_management_app/features/mirror/services/mirror_run_completion_service.dart';
import 'package:project_management_app/features/mirror/services/mirror_run_execution_service.dart';
import 'package:project_management_app/features/mirror/services/mirror_run_ui_state_transition_service.dart';

void main() {
  const service = MirrorRunCompletionService();

  group('MirrorRunCompletionService', () {
    test('keeps existing error on failed outcome and stops progress', () {
      const current = MirrorRunUiStateSnapshot(
        isRunInProgress: true,
        lastStructuredError: MirrorStructuredError(
          errorFamily: 'timeout',
          retryable: true,
        ),
      );
      const outcome = MirrorRunExecutionOutcome(failed: true);

      final transition = service.complete(outcome: outcome, current: current);

      expect(transition.nextState.isRunInProgress, isFalse);
      expect(transition.nextState.lastStructuredError, isNotNull);
      expect(transition.retryFeedbackError, isNull);
    });

    test('returns retry feedback when structured error is present', () {
      const current = MirrorRunUiStateSnapshot(
        isRunInProgress: true,
        lastStructuredError: null,
      );
      const error = MirrorStructuredError(
        errorFamily: 'timeout',
        retryable: true,
        message: 'request timed out',
      );
      const outcome = MirrorRunExecutionOutcome(
        failed: false,
        structuredError: error,
      );

      final transition = service.complete(outcome: outcome, current: current);

      expect(transition.nextState.isRunInProgress, isFalse);
      expect(transition.nextState.lastStructuredError, error);
      expect(transition.retryFeedbackError, error);
    });

    test('clears error on completed successful outcome', () {
      const current = MirrorRunUiStateSnapshot(
        isRunInProgress: true,
        lastStructuredError: MirrorStructuredError(
          errorFamily: 'timeout',
          retryable: true,
        ),
      );
      const outcome = MirrorRunExecutionOutcome(
        failed: false,
        completed: true,
      );

      final transition = service.complete(outcome: outcome, current: current);

      expect(transition.nextState.isRunInProgress, isFalse);
      expect(transition.nextState.lastStructuredError, isNull);
      expect(transition.retryFeedbackError, isNull);
    });
  });
}