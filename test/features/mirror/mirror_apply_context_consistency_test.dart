import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mirror apply context consistency contract', () {
    test('apply context is derived from original compile context', () {
      final source =
          _readRepoFile('lib/features/mirror/mirror_editor_screen.dart');

      expect(
        source,
        contains('final originalCompileContext = executionContext;'),
      );
      expect(
        source,
        contains('files: Map<String, String>.from(originalCompileContext.files),'),
      );
      expect(
        source,
        isNot(contains('files: backend.applyPatchesToFiles(')),
      );
    });

    test('compile context still allows preview patches for compile stage', () {
      final source =
          _readRepoFile('lib/features/mirror/mirror_editor_screen.dart');

      expect(source, contains('final compileContext = generatedPatches.isEmpty'));
      expect(source, contains('files: backend.applyPatchesToFiles('));
      expect(source, contains('context: compileContext,'));
      expect(source, contains('context: applyContext,'));
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
