import 'mirror_run_execution_service.dart';
import 'mirror_run_outcome_resolution_service.dart';
import 'mirror_run_ui_state_transition_service.dart';

class MirrorRunCompletionService {
  const MirrorRunCompletionService({
    MirrorRunOutcomeResolutionService outcomeResolutionService =
        const MirrorRunOutcomeResolutionService(),
    MirrorRunUiStateTransitionService uiStateTransitionService =
        const MirrorRunUiStateTransitionService(),
  }) : _outcomeResolutionService = outcomeResolutionService,
       _uiStateTransitionService = uiStateTransitionService;

  final MirrorRunOutcomeResolutionService _outcomeResolutionService;
  final MirrorRunUiStateTransitionService _uiStateTransitionService;

  MirrorRunUiStateTransition complete({
    required MirrorRunExecutionOutcome outcome,
    required MirrorRunUiStateSnapshot current,
  }) {
    final resolution = _outcomeResolutionService.resolve(outcome);
    return _uiStateTransitionService.onRunFinished(
      current: current,
      failed: outcome.failed,
      resolution: resolution,
    );
  }
}