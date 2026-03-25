import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/core/providers/mirror_session_bootstrap.dart';
import 'package:project_management_app/core/providers/mirror_session_provider.dart';
import 'package:project_management_app/core/services/mirror_session_state_mutation_service.dart';
import 'package:project_management_app/core/services/mirror_session_state_service.dart';

void main() {
  const service = MirrorSessionStateMutationService();

  MirrorSessionState buildState({
    Map<String, String>? files,
    String selectedFile = 'lib/main.dart',
    List<String>? liveOutput,
    List<String>? terminalLog,
  }) {
    final sourceFiles = files ??
        const <String, String>{
          'README.md': 'readme',
          'lib/main.dart': 'void main() {}',
        };
    return MirrorSessionState(
      projectId: 'project-1',
      taskId: 'task-1',
      files: sourceFiles,
      selectedFile: selectedFile,
      liveOutput: liveOutput ?? <String>[],
      terminalLog: terminalLog ?? <String>[],
      contextFingerprint:
          const MirrorSessionStateService().computeContextFingerprint(sourceFiles),
      contextVersion: mirrorDraftContextVersion,
      bootstrapPhase: MirrorSessionBootstrapPhase.ready,
      bootstrapSource: 'baseline',
    );
  }

  group('MirrorSessionStateMutationService', () {
    test('selectFile returns null when file does not exist', () {
      final next = service.selectFile(buildState(), 'missing.dart');
      expect(next, isNull);
    });

    test('selectFile updates selected file when it exists', () {
      final next = service.selectFile(buildState(), 'README.md');
      expect(next, isNotNull);
      expect(next!.selectedFile, 'README.md');
    });

    test('updateSelectedFileContent updates file and fingerprint', () {
      final initial = buildState();
      final next = service.updateSelectedFileContent(initial, 'new content');

      expect(next.files['lib/main.dart'], 'new content');
      expect(next.contextVersion, mirrorDraftContextVersion);
      expect(next.contextFingerprint, isNot(initial.contextFingerprint));
    });

    test('upsertFileContent adds new file and updates fingerprint', () {
      final initial = buildState();
      final next = service.upsertFileContent(
        initial,
        path: 'lib/extra.dart',
        content: 'class Extra {}',
      );

      expect(next.files['lib/extra.dart'], 'class Extra {}');
      expect(next.contextFingerprint, isNot(initial.contextFingerprint));
    });

    test('appendLiveOutput returns null for empty lines', () {
      final next = service.appendLiveOutput(buildState(), const <String>[]);
      expect(next, isNull);
    });

    test('appendLiveOutput keeps only latest capped lines', () {
      final initial = buildState(liveOutput: <String>['a', 'b']);
      final next = service.appendLiveOutput(
        initial,
        <String>['c', 'd'],
        maxLines: 3,
      );

      expect(next, isNotNull);
      expect(next!.liveOutput, <String>['b', 'c', 'd']);
    });

    test('appendTerminalLine ignores blank lines', () {
      final next = service.appendTerminalLine(buildState(), '   ');
      expect(next, isNull);
    });

    test('appendTerminalLine caps terminal log size', () {
      final initial = buildState(terminalLog: <String>['1', '2']);
      final next = service.appendTerminalLine(initial, '3', maxLines: 2);

      expect(next, isNotNull);
      expect(next!.terminalLog, <String>['2', '3']);
    });

    test('setCompileValidationArtifacts rejects blank fingerprint', () {
      final next = service.setCompileValidationArtifacts(
        buildState(),
        compileFingerprint: '   ',
      );
      expect(next, isNull);
    });

    test('setCompileValidationArtifacts normalizes token and stores fingerprint',
        () {
      final next = service.setCompileValidationArtifacts(
        buildState(),
        compileFingerprint: ' fp-1 ',
        serverVersionToken: ' token-1 ',
      );

      expect(next, isNotNull);
      expect(next!.compileFingerprint, 'fp-1');
      expect(next.compileServerVersionToken, 'token-1');
    });

    test('setCompileValidationArtifacts clears empty token', () {
      final next = service.setCompileValidationArtifacts(
        buildState(),
        compileFingerprint: 'fp-2',
        serverVersionToken: '   ',
      );

      expect(next, isNotNull);
      expect(next!.compileFingerprint, 'fp-2');
      expect(next.compileServerVersionToken, isNull);
    });
  });
}