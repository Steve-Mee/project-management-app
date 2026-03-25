import '../models/mirror_structured_error.dart';
import 'mirror_run_outcome_resolution_service.dart';

class MirrorRunUiStateSnapshot {
  const MirrorRunUiStateSnapshot({
    required this.isRunInProgress,
    required this.lastStructuredError,
  });

  final bool isRunInProgress;
  final MirrorStructuredError? lastStructuredError;
}

class MirrorRunUiStateTransition {
  const MirrorRunUiStateTransition({
    required this.nextState,
    this.retryFeedbackError,
  });

  final MirrorRunUiStateSnapshot nextState;
  final MirrorStructuredError? retryFeedbackError;
}

class MirrorRunUiStateTransitionService {
  const MirrorRunUiStateTransitionService();

  MirrorRunUiStateSnapshot onRunStarted(
    MirrorRunUiStateSnapshot current,
  ) {
    return MirrorRunUiStateSnapshot(
      isRunInProgress: true,
      lastStructuredError: null,
    );
  }

  MirrorRunUiStateTransition onRunFinished({
    required MirrorRunUiStateSnapshot current,
    required bool failed,
    required MirrorRunOutcomeResolution resolution,
  }) {
    if (failed) {
      return MirrorRunUiStateTransition(
        nextState: MirrorRunUiStateSnapshot(
          isRunInProgress: false,
          lastStructuredError: current.lastStructuredError,
        ),
      );
    }

    final parsed = resolution.errorToShow;
    if (parsed != null) {
      return MirrorRunUiStateTransition(
        nextState: MirrorRunUiStateSnapshot(
          isRunInProgress: false,
          lastStructuredError: parsed,
        ),
        retryFeedbackError: parsed,
      );
    }

    if (resolution.clearError) {
      return const MirrorRunUiStateTransition(
        nextState: MirrorRunUiStateSnapshot(
          isRunInProgress: false,
          lastStructuredError: null,
        ),
      );
    }

    return MirrorRunUiStateTransition(
      nextState: MirrorRunUiStateSnapshot(
        isRunInProgress: false,
        lastStructuredError: current.lastStructuredError,
      ),
    );
  }
}