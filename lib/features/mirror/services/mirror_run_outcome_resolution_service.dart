import '../models/mirror_structured_error.dart';
import 'mirror_run_execution_service.dart';

class MirrorRunOutcomeResolution {
  const MirrorRunOutcomeResolution({
    this.errorToShow,
    this.clearError = false,
  });

  final MirrorStructuredError? errorToShow;
  final bool clearError;

  bool get hasStateChange => errorToShow != null || clearError;
}

class MirrorRunOutcomeResolutionService {
  const MirrorRunOutcomeResolutionService();

  MirrorRunOutcomeResolution resolve(MirrorRunExecutionOutcome outcome) {
    if (outcome.failed) {
      return const MirrorRunOutcomeResolution();
    }

    final structured = outcome.structuredError;
    if (structured != null) {
      return MirrorRunOutcomeResolution(errorToShow: structured);
    }

    if (outcome.completed) {
      return const MirrorRunOutcomeResolution(clearError: true);
    }

    return const MirrorRunOutcomeResolution();
  }
}