// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mirror preview/apply consistency contract', () {
    test('editor freezes mutable run inputs while run is active', () {
      final source = _readRepoFile('lib/features/mirror/mirror_editor_screen.dart');

      expect(source, contains('isEnabled: !_isRunInProgress'));
      expect(source, contains('if (_isRunInProgress) {'));
      expect(source, contains('onChanged: (String content) {'));
    });

    test('orchestration carries previewContextFingerprint from compile snapshot', () {
      final source = _readRepoFile(
        'lib/features/mirror/services/mirror_editor_orchestration_service.dart',
      );

      expect(source, contains("'previewContextFingerprint': compileContextFingerprint"));
      expect(source, contains('context: compileContextForPreviewAndApply'));
      expect(source, contains('metadata: Map<String, dynamic>.from('));
    });

    test('gateway apply requires compile fingerprint and validates context fingerprint', () {
      final source = _readRepoFile('lib/features/mirror/mirror_gateway_backend.dart');

      expect(source, contains('preview fingerprint missing'));
      expect(source, contains('preview fingerprint mismatch'));
      expect(source, contains('preview context mismatch'));
      expect(source, contains("context.metadata['previewContextFingerprint']"));
      expect(source, contains('_validatePreviewApplyConsistency('));
    });
  });
}

String _readRepoFile(String relativePath) {
  final direct = File(relativePath);
  if (direct.existsSync()) {
    return direct.readAsStringSync();
  }

  final fromTestDir = File('test/$relativePath');
  if (fromTestDir.existsSync()) {
    return fromTestDir.readAsStringSync();
  }

  final fromParent = File('../$relativePath');
  if (fromParent.existsSync()) {
    return fromParent.readAsStringSync();
  }

  throw StateError('Unable to locate file for contract test: $relativePath');
}
