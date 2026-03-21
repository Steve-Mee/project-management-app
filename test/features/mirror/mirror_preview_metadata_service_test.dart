import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/models/project_context.dart';
import 'package:project_management_app/features/mirror/services/mirror_preview_metadata_service.dart';

void main() {
  group('MirrorPreviewMetadataService', () {
    const service = MirrorPreviewMetadataService();

    test('computeContextFingerprint is stable across file ordering', () {
      final fingerprintA = service.computeContextFingerprint(
        <String, String>{
          'lib/b.dart': 'B',
          'lib/a.dart': 'A',
        },
      );
      final fingerprintB = service.computeContextFingerprint(
        <String, String>{
          'lib/a.dart': 'A',
          'lib/b.dart': 'B',
        },
      );

      expect(fingerprintA, equals(fingerprintB));
    });

    test('computeContextFingerprint changes when content changes', () {
      final fingerprintA = service.computeContextFingerprint(
        const <String, String>{'lib/a.dart': 'A'},
      );
      final fingerprintB = service.computeContextFingerprint(
        const <String, String>{'lib/a.dart': 'A changed'},
      );

      expect(fingerprintA, isNot(equals(fingerprintB)));
    });

    test('buildApplyMetadata without token disables preview reuse', () {
      final metadata = service.buildApplyMetadata(
        metadata: const ProjectContextMetadata(selectedFile: 'lib/main.dart'),
        previewServerVersionToken: null,
        previewCompileFingerprint: 'fp-123',
        previewCompileOutput: 'compiled output',
      );

      expect(metadata.previewCompileFingerprint, equals('fp-123'));
      expect(metadata.previewReuseRequested, isFalse);
      expect(
        metadata.previewReuseStrategy,
        equals(ProjectContextPreviewReuseStrategy.none),
      );
      expect(metadata.previewReusePayload, isNull);
      expect(metadata.previewCompileOutputSha256, isNotEmpty);
    });

    test('buildApplyMetadata with token truncates large inline output', () {
      final hugeOutput = 'x' * (70 * 1024);

      final metadata = service.buildApplyMetadata(
        metadata: const ProjectContextMetadata(selectedFile: 'lib/main.dart'),
        previewServerVersionToken: 'svt-1',
        previewCompileFingerprint: 'fp-999',
        previewCompileOutput: hugeOutput,
      );

      expect(metadata.previewReuseRequested, isTrue);
      expect(
        metadata.previewReuseStrategy,
        equals(ProjectContextPreviewReuseStrategy.serverVersionToken),
      );
      expect(metadata.previewServerVersionToken, equals('svt-1'));
      expect(metadata.previewArtifactPath, equals('svt-1'));
      expect(metadata.previewReusePayload, isNotNull);
      expect(metadata.previewReusePayload!.token, equals('svt-1'));
      expect(metadata.previewReusePayload!.fingerprint, equals('fp-999'));
      expect(metadata.previewReusePayload!.inlineOutputTruncated, isTrue);
      expect(metadata.previewReusePayload!.inlineOutput.length, equals(64 * 1024));
    });
  });
}
