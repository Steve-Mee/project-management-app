import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/core/services/mirror_session_state_service.dart';

void main() {
  const service = MirrorSessionStateService();

  group('MirrorSessionStateService', () {
    test('builds deterministic baseline for a session', () {
      final baseline = service.buildBaseline(
        projectId: 'project-123',
        taskId: 'task-456',
      );

      expect(baseline.selectedFile, 'lib/main.dart');
      expect(baseline.contextVersion, mirrorDraftContextVersion);
      expect(
        baseline.files['README.md'],
        '# Mirror Session\n\nProject: project-123\nTask: task-456\n',
      );
      expect(
        baseline.files['lib/main.dart'],
        "void main() {\n  print('Mirror session: project-123::task-456');\n}\n",
      );
      expect(
        baseline.contextFingerprint,
        service.computeContextFingerprint(baseline.files),
      );
    });

    test('computes same fingerprint regardless of map insertion order', () {
      final fingerprintA = service.computeContextFingerprint({
        'b.txt': 'beta',
        'a.txt': 'alpha',
      });
      final fingerprintB = service.computeContextFingerprint({
        'a.txt': 'alpha',
        'b.txt': 'beta',
      });

      expect(fingerprintA, fingerprintB);
    });

    test('changes fingerprint when file contents change', () {
      final original = service.computeContextFingerprint({
        'lib/main.dart': 'void main() {}',
      });
      final updated = service.computeContextFingerprint({
        'lib/main.dart': 'void main() { print(1); }',
      });

      expect(updated, isNot(original));
    });
  });
}