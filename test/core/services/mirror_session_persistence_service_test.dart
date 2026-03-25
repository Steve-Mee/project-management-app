import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/core/services/mirror_session_persistence_service.dart';
import 'package:project_management_app/core/services/mirror_session_state_service.dart';

void main() {
  const service = MirrorSessionPersistenceService();

  group('MirrorSessionPersistenceService', () {
    test('builds persist snapshot with fallback fingerprint and context version',
        () {
      final snapshot = service.buildPersistSnapshot(
        sessionKey: 'project-1::task-1',
        files: const <String, String>{
          'lib/main.dart': 'void main() {}',
        },
        selectedFile: 'lib/main.dart',
        mode: 'private',
        offlineWarningKey: 'offline_warning',
      );

      expect(snapshot, isNotNull);
      expect(snapshot!.sessionKey, 'project-1::task-1');
      expect(snapshot.selectedFile, 'lib/main.dart');
      expect(snapshot.mode, 'private');
      expect(snapshot.offlineWarningKey, 'offline_warning');
      expect(snapshot.contextVersion, mirrorDraftContextVersion);
      expect(
        snapshot.contextFingerprint,
        const MirrorSessionStateService().computeContextFingerprint(
          const <String, String>{'lib/main.dart': 'void main() {}'},
        ),
      );
    });

    test('preserves provided fingerprint and context version', () {
      final snapshot = service.buildPersistSnapshot(
        sessionKey: 'project-1::task-1',
        files: const <String, String>{'README.md': 'hello'},
        selectedFile: 'README.md',
        contextFingerprint: 'known-hash',
        contextVersion: 9,
      );

      expect(snapshot, isNotNull);
      expect(snapshot!.contextFingerprint, 'known-hash');
      expect(snapshot.contextVersion, 9);
    });

    test('returns null for empty session or empty files', () {
      expect(
        service.buildPersistSnapshot(
          sessionKey: '',
          files: const <String, String>{'README.md': 'x'},
          selectedFile: 'README.md',
        ),
        isNull,
      );
      expect(
        service.buildPersistSnapshot(
          sessionKey: 'project-1::task-1',
          files: const <String, String>{},
          selectedFile: 'README.md',
        ),
        isNull,
      );
    });

    test('replays persist only for same session with newer generation', () {
      expect(
        service.shouldReplayPersist(
          latestSessionKey: 'project-1::task-1',
          sessionKey: 'project-1::task-1',
          generation: 1,
          currentGeneration: 2,
        ),
        isTrue,
      );
      expect(
        service.shouldReplayPersist(
          latestSessionKey: 'project-1::task-2',
          sessionKey: 'project-1::task-1',
          generation: 1,
          currentGeneration: 2,
        ),
        isFalse,
      );
      expect(
        service.shouldReplayPersist(
          latestSessionKey: 'project-1::task-1',
          sessionKey: 'project-1::task-1',
          generation: 2,
          currentGeneration: 2,
        ),
        isFalse,
      );
    });
  });
}