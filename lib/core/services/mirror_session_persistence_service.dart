import 'mirror_session_state_service.dart';

class MirrorSessionPersistSnapshot {
  const MirrorSessionPersistSnapshot({
    required this.sessionKey,
    required this.files,
    required this.selectedFile,
    required this.mode,
    required this.offlineWarningKey,
    required this.contextFingerprint,
    required this.contextVersion,
  });

  final String sessionKey;
  final Map<String, String> files;
  final String selectedFile;
  final String? mode;
  final String? offlineWarningKey;
  final String contextFingerprint;
  final int contextVersion;
}

class MirrorSessionPersistenceService {
  const MirrorSessionPersistenceService({
    this.stateService = const MirrorSessionStateService(),
  });

  final MirrorSessionStateService stateService;

  MirrorSessionPersistSnapshot? buildPersistSnapshot({
    required String sessionKey,
    required Map<String, String> files,
    required String selectedFile,
    String? mode,
    String? offlineWarningKey,
    String? contextFingerprint,
    int? contextVersion,
  }) {
    if (sessionKey.isEmpty || files.isEmpty) {
      return null;
    }

    return MirrorSessionPersistSnapshot(
      sessionKey: sessionKey,
      files: Map<String, String>.from(files),
      selectedFile: selectedFile,
      mode: mode,
      offlineWarningKey: offlineWarningKey,
      contextFingerprint:
          contextFingerprint ?? stateService.computeContextFingerprint(files),
      contextVersion: contextVersion ?? mirrorDraftContextVersion,
    );
  }

  bool shouldReplayPersist({
    required String? latestSessionKey,
    required String sessionKey,
    required int generation,
    required int currentGeneration,
  }) {
    return latestSessionKey != null &&
        latestSessionKey == sessionKey &&
        generation != currentGeneration;
  }
}