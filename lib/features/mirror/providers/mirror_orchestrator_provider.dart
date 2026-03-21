import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mirror_signed_inputs_backend.dart';
import '../services/mirror_orchestrator_service.dart';
import '../services/mirror_service_boundaries.dart';

typedef MirrorExecutionOrchestratorFactory = MirrorExecutionOrchestrator
    Function(MirrorComputeBackend backend);

/// PR1 boundary wrapper: keeps construction centralized and swappable.
final mirrorExecutionOrchestratorFactoryProvider =
    Provider<MirrorExecutionOrchestratorFactory>((Ref ref) {
  return (MirrorComputeBackend backend) {
    return MirrorOrchestratorService(backend: backend);
  };
});
