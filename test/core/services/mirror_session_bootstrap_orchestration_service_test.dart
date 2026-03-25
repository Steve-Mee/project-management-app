import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/core/providers/mirror_session_bootstrap.dart';
import 'package:project_management_app/core/services/mirror_session_bootstrap_orchestration_service.dart';
import 'package:project_management_app/core/services/mirror_session_state_service.dart';

void main() {
  const service = MirrorSessionBootstrapOrchestrationService();

  group('MirrorSessionBootstrapOrchestrationService', () {
    test('parses session key into project and task id', () {
      final parsed = service.parseSessionKey('project-1::task-2');

      expect(parsed.projectId, 'project-1');
      expect(parsed.taskId, 'task-2');
    });

    test('builds repository timeout fallback payload', () {
      final fallback = service.buildRepositoryTimeoutFallback();

      expect(fallback.files, isEmpty);
      expect(
        fallback.errorMessage,
        MirrorSessionBootstrapMessages.repositoryTimeout,
      );
      expect(
        fallback.reasonCode,
        MirrorSessionBootstrapReasonCodes.repositoryTimeout,
      );
    });

    test('resolves merging source as draft only when draft files exist', () {
      expect(service.resolveMergingBootstrapSource(null), 'baseline');
      expect(
        service.resolveMergingBootstrapSource(
          const MirrorSessionBootstrapDraft(
            files: <String, String>{},
            selectedFile: 'README.md',
          ),
        ),
        'baseline',
      );
      expect(
        service.resolveMergingBootstrapSource(
          const MirrorSessionBootstrapDraft(
            files: <String, String>{'lib/main.dart': 'draft'},
            selectedFile: 'lib/main.dart',
          ),
        ),
        'draft',
      );
    });

    test('builds final assembly with fingerprinted merged files', () {
      final assembly = service.buildFinalAssembly(
        baselineFiles: const <String, String>{
          'README.md': 'baseline',
          'lib/main.dart': 'baseline-main',
        },
        baselineSelectedFile: 'lib/main.dart',
        baselineContextVersion: mirrorDraftContextVersion,
        repository: const MirrorSessionBootstrapRepository(
          files: <String, String>{'README.md': 'repo'},
          preferredSelectedFile: 'README.md',
          infoMessage: 'repo loaded',
        ),
        draft: const MirrorSessionBootstrapDraft(
          files: <String, String>{'lib/main.dart': 'draft-main'},
          selectedFile: 'lib/main.dart',
          contextVersion: 3,
        ),
      );

      expect(assembly.files['README.md'], 'repo');
      expect(assembly.files['lib/main.dart'], 'draft-main');
      expect(assembly.selectedFile, 'lib/main.dart');
      expect(assembly.contextVersion, 3);
      expect(assembly.phase, MirrorSessionBootstrapPhase.ready);
      expect(assembly.source, 'draft+repository');
      expect(assembly.reasonCode, isNull);
      expect(assembly.terminalLog, contains('repo loaded'));
      expect(
        assembly.contextFingerprint,
        const MirrorSessionStateService().computeContextFingerprint(
          assembly.files,
        ),
      );
    });

    test('loads bootstrap data and keeps both draft and repository', () async {
      final loaded = await service.loadBootstrapData(
        draftFuture: Future<MirrorSessionBootstrapDraft?>.value(
          const MirrorSessionBootstrapDraft(
            files: <String, String>{'lib/main.dart': 'draft'},
            selectedFile: 'lib/main.dart',
            contextVersion: 2,
          ),
        ),
        repositoryFuture: Future<MirrorSessionBootstrapRepository?>.value(
          const MirrorSessionBootstrapRepository(
            files: <String, String>{'README.md': 'repo'},
            preferredSelectedFile: 'README.md',
          ),
        ),
        repositoryTimeout: const Duration(seconds: 1),
      );

      expect(loaded.draft, isNotNull);
      expect(loaded.draft!.files['lib/main.dart'], 'draft');
      expect(loaded.repository, isNotNull);
      expect(loaded.repository!.files['README.md'], 'repo');
    });

    test('uses repository timeout fallback when repository load is too slow',
        () async {
      final loaded = await service.loadBootstrapData(
        draftFuture: Future<MirrorSessionBootstrapDraft?>.value(
          const MirrorSessionBootstrapDraft(
            files: <String, String>{'lib/main.dart': 'draft'},
            selectedFile: 'lib/main.dart',
          ),
        ),
        repositoryFuture: Future<MirrorSessionBootstrapRepository?>.delayed(
          const Duration(milliseconds: 50),
          () => const MirrorSessionBootstrapRepository(
            files: <String, String>{'README.md': 'repo'},
            preferredSelectedFile: 'README.md',
          ),
        ),
        repositoryTimeout: const Duration(milliseconds: 1),
      );

      expect(loaded.repository, isNotNull);
      expect(loaded.repository!.files, isEmpty);
      expect(
        loaded.repository!.reasonCode,
        MirrorSessionBootstrapReasonCodes.repositoryTimeout,
      );
      expect(
        loaded.repository!.errorMessage,
        MirrorSessionBootstrapMessages.repositoryTimeout,
      );
    });
  });
}