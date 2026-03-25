import '../providers/mirror_session_bootstrap.dart';
import 'mirror_session_state_service.dart';

class MirrorSessionKeyParts {
  const MirrorSessionKeyParts({
    required this.projectId,
    required this.taskId,
  });

  final String projectId;
  final String taskId;
}

class MirrorSessionBootstrapAssembly {
  const MirrorSessionBootstrapAssembly({
    required this.files,
    required this.selectedFile,
    required this.contextFingerprint,
    required this.contextVersion,
    required this.terminalLog,
    required this.phase,
    required this.source,
    this.reasonCode,
  });

  final Map<String, String> files;
  final String selectedFile;
  final String contextFingerprint;
  final int contextVersion;
  final List<String> terminalLog;
  final MirrorSessionBootstrapPhase phase;
  final String source;
  final String? reasonCode;
}

class MirrorSessionBootstrapLoadedData {
  const MirrorSessionBootstrapLoadedData({
    required this.draft,
    required this.repository,
  });

  final MirrorSessionBootstrapDraft? draft;
  final MirrorSessionBootstrapRepository? repository;
}

class MirrorSessionBootstrapOrchestrationService {
  const MirrorSessionBootstrapOrchestrationService({
    this.stateService = const MirrorSessionStateService(),
  });

  final MirrorSessionStateService stateService;

  MirrorSessionKeyParts parseSessionKey(String sessionKey) {
    final parts = sessionKey.split('::');
    return MirrorSessionKeyParts(
      projectId: parts.isNotEmpty ? parts[0] : '',
      taskId: parts.length > 1 ? parts[1] : '',
    );
  }

  MirrorSessionBootstrapRepository buildRepositoryTimeoutFallback() {
    return const MirrorSessionBootstrapRepository(
      files: <String, String>{},
      preferredSelectedFile: '',
      errorMessage: MirrorSessionBootstrapMessages.repositoryTimeout,
      reasonCode: MirrorSessionBootstrapReasonCodes.repositoryTimeout,
    );
  }

  String resolveMergingBootstrapSource(MirrorSessionBootstrapDraft? draft) {
    return draft != null && draft.files.isNotEmpty ? 'draft' : 'baseline';
  }

  Future<MirrorSessionBootstrapLoadedData> loadBootstrapData({
    required Future<MirrorSessionBootstrapDraft?> draftFuture,
    required Future<MirrorSessionBootstrapRepository?> repositoryFuture,
    required Duration repositoryTimeout,
  }) async {
    final repository = await repositoryFuture.timeout(
      repositoryTimeout,
      onTimeout: buildRepositoryTimeoutFallback,
    );
    final draft = await draftFuture;

    return MirrorSessionBootstrapLoadedData(
      draft: draft,
      repository: repository,
    );
  }

  MirrorSessionBootstrapAssembly buildFinalAssembly({
    required Map<String, String> baselineFiles,
    required String baselineSelectedFile,
    required int baselineContextVersion,
    MirrorSessionBootstrapDraft? draft,
    MirrorSessionBootstrapRepository? repository,
  }) {
    final bootstrap = resolveMirrorSessionBootstrap(
      baselineFiles: baselineFiles,
      baselineSelectedFile: baselineSelectedFile,
      baselineContextVersion: baselineContextVersion,
      draft: draft,
      repository: repository,
    );

    return MirrorSessionBootstrapAssembly(
      files: bootstrap.files,
      selectedFile: bootstrap.selectedFile,
      contextFingerprint: stateService.computeContextFingerprint(bootstrap.files),
      contextVersion: bootstrap.contextVersion,
      terminalLog: bootstrap.terminalLines,
      phase: bootstrap.phase,
      source: bootstrap.sourceSummary,
      reasonCode: bootstrap.reasonCode,
    );
  }
}