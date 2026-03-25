import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/models/mirror_structured_error.dart';
import 'package:project_management_app/features/mirror/services/mirror_run_execution_service.dart';
import 'package:project_management_app/features/mirror/services/mirror_run_outcome_resolution_service.dart';

void main() {
  const service = MirrorRunOutcomeResolutionService();

  group('MirrorRunOutcomeResolutionService', () {
    test('returns no state change for failed outcome', () {
      const outcome = MirrorRunExecutionOutcome(failed: true);

      final resolution = service.resolve(outcome);

      expect(resolution.hasStateChange, isFalse);
      expect(resolution.errorToShow, isNull);
      expect(resolution.clearError, isFalse);
    });

    test('returns error to show for structured error outcome', () {
      const withError = MirrorRunExecutionOutcome(
        failed: false,
        structuredError: MirrorStructuredError(
          errorFamily: 'timeout',
          retryable: true,
          message: 'request timed out',
        ),
      );

      final resolution = service.resolve(withError);

      expect(resolution.hasStateChange, isTrue);
      expect(resolution.errorToShow, isNotNull);
      expect(resolution.clearError, isFalse);
    });

    test('returns clear signal for completed outcome without error', () {
      const outcome = MirrorRunExecutionOutcome(
        failed: false,
        completed: true,
      );

      final resolution = service.resolve(outcome);

      expect(resolution.hasStateChange, isTrue);
      expect(resolution.errorToShow, isNull);
      expect(resolution.clearError, isTrue);
    });

    test('returns no change for neutral successful outcome', () {
      const outcome = MirrorRunExecutionOutcome(
        failed: false,
        completed: false,
      );

      final resolution = service.resolve(outcome);

      expect(resolution.hasStateChange, isFalse);
      expect(resolution.errorToShow, isNull);
      expect(resolution.clearError, isFalse);
    });
  });
}
