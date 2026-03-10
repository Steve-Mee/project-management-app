import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/mirror_editor_orchestration_service.dart';

final mirrorEditorOrchestrationServiceProvider =
    Provider<MirrorEditorOrchestrationService>((Ref ref) {
  return const MirrorEditorOrchestrationService();
});
