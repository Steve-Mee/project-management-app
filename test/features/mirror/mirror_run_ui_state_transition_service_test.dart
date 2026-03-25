import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/models/mirror_structured_error.dart';
import 'package:project_management_app/features/mirror/services/mirror_run_outcome_resolution_service.dart';
import 'package:project_management_app/features/mirror/services/mirror_run_ui_state_transition_service.dart';

void main() {
  const service = MirrorRunUiStateTransitionService();

  group('MirrorRunUiStateTransitionService', () {
    test('onRunStarted sets in-progress and clears previous error', () {
      const current = MirrorRunUiStateSnapshot(
        isRunInProgress: false,
        lastStructuredError: MirrorStructuredError(
          errorFamily: 'timeout',
          retryable: true,
        ),
      );

      final next = service.onRunStarted(current);

      expect(next.isRunInProgress, isTrue);
      expect(next.lastStructuredError, isNull);
    });

    test('onRunFinished keeps current error on failure and stops progress', () {
      const current = MirrorRunUiStateSnapshot(
        isRunInProgress: true,
        lastStructuredError: MirrorStructuredError(
          errorFamily: 'timeout',
          retryable: true,
        ),
      );

      const resolution = MirrorRunOutcomeResolution();
      final transition = service.onRunFinished(
        current: current,
        failed: true,
        resolution: resolution,
      );

      expect(transition.nextState.isRunInProgress, isFalse);
      expect(transition.nextState.lastStructuredError, isNotNull);
      expect(transition.retryFeedbackError, isNull);
    });

    test('onRunFinished sets retry feedback error when resolution has error',
        () {
      const current = MirrorRunUiStateSnapshot(
        isRunInProgress: true,
        lastStructuredError: null,
      );
      const error = MirrorStructuredError(
        errorFamily: 'timeout',
        retryable: true,
        message: 'request timed out',
      );

      const resolution = MirrorRunOutcomeResolution(errorToShow: error);
      final transition = service.onRunFinished(
        current: current,
        failed: false,
        resolution: resolution,
      );

      expect(transition.nextState.isRunInProgress, isFalse);
      expect(transition.nextState.lastStructuredError, error);
      expect(transition.retryFeedbackError, error);
    });

    test('onRunFinished clears error when resolution requests clear', () {
      const current = MirrorRunUiStateSnapshot(
        isRunInProgress: true,
        lastStructuredError: MirrorStructuredError(
          errorFamily: 'timeout',
          retryable: true,
        ),
      );

      const resolution = MirrorRunOutcomeResolution(clearError: true);
      final transition = service.onRunFinished(
        current: current,
        failed: false,
        resolution: resolution,
      );

      expect(transition.nextState.isRunInProgress, isFalse);
      expect(transition.nextState.lastStructuredError, isNull);
      expect(transition.retryFeedbackError, isNull);
    });
  });
}