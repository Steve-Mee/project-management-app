import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/core/providers/mirror_session_bootstrap.dart';

void main() {
  group('resolveMirrorSessionBootstrap', () {
    test('merges repository files first and overlays draft files deterministically', () {
      final result = resolveMirrorSessionBootstrap(
        baselineFiles: const <String, String>{
          'README.md': 'baseline',
        },
        baselineSelectedFile: 'README.md',
        baselineContextVersion: 1,
        repository: const MirrorSessionBootstrapRepository(
          files: <String, String>{
            'README.md': 'repo',
            'context/project.json': '{"id":"p1"}',
          },
          preferredSelectedFile: 'context/project.json',
          infoMessage: 'repo loaded',
        ),
        draft: const MirrorSessionBootstrapDraft(
          files: <String, String>{
            'README.md': 'draft',
            'lib/main.dart': 'void main() {}',
          },
          selectedFile: 'lib/main.dart',
          contextVersion: 3,
        ),
      );

      expect(result.files['README.md'], 'draft');
      expect(result.files['context/project.json'], '{"id":"p1"}');
      expect(result.selectedFile, 'lib/main.dart');
      expect(result.contextVersion, 3);
      expect(result.terminalLines, <String>[
        'Mirror session restored unsaved draft from local cache.',
        'repo loaded',
      ]);
    });

    test('falls back to repository preferred file when draft selection is absent', () {
      final result = resolveMirrorSessionBootstrap(
        baselineFiles: const <String, String>{
          'README.md': 'baseline',
        },
        baselineSelectedFile: 'README.md',
        baselineContextVersion: 1,
        repository: const MirrorSessionBootstrapRepository(
          files: <String, String>{
            'README.md': 'repo',
            'context/current_task.md': 'task',
          },
          preferredSelectedFile: 'context/current_task.md',
        ),
        draft: const MirrorSessionBootstrapDraft(
          files: <String, String>{
            'lib/helper.dart': '// helper',
          },
          selectedFile: 'missing.txt',
        ),
      );

      expect(result.selectedFile, 'context/current_task.md');
    });

    test('captures repository fallback error without discarding draft files', () {
      final result = resolveMirrorSessionBootstrap(
        baselineFiles: const <String, String>{
          'README.md': 'baseline',
        },
        baselineSelectedFile: 'README.md',
        baselineContextVersion: 1,
        repository: const MirrorSessionBootstrapRepository(
          files: <String, String>{},
          preferredSelectedFile: '',
          errorMessage: 'repo failed',
        ),
        draft: const MirrorSessionBootstrapDraft(
          files: <String, String>{
            'lib/main.dart': 'draft',
          },
          selectedFile: 'lib/main.dart',
        ),
      );

      expect(result.files['lib/main.dart'], 'draft');
      expect(result.selectedFile, 'lib/main.dart');
      expect(result.terminalLines, <String>[
        'Mirror session restored unsaved draft from local cache.',
        'repo failed',
      ]);
    });
  });
}