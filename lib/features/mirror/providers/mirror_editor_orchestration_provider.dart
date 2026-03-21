import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/mirror_editor_orchestration_service.dart';
import '../services/mirror_service_boundaries.dart';

final mirrorEditorOrchestrationServiceProvider =
    Provider<MirrorEditorOrchestrationService>((Ref ref) {
  return const MirrorEditorOrchestrationService();
});

/// PR1 boundary wrapper: use this provider where UI should depend on the
/// contract instead of the concrete service.
final mirrorInteractiveRunCoordinatorProvider =
    Provider<MirrorInteractiveRunCoordinator>((Ref ref) {
  return ref.read(mirrorEditorOrchestrationServiceProvider);
});
