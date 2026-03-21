import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mirror editor run coordinator contract', () {
    test('editor run flow delegates to interactive run coordinator provider', () {
      final source =
          _readRepoFile('lib/features/mirror/mirror_editor_screen.dart');

      expect(source, contains('mirrorInteractiveRunCoordinatorProvider'));
      expect(source, contains('runCurrentFileInTerminal('));
      expect(source, contains('mirrorContextBudgetServiceProvider'));
      expect(source, isNot(contains('MirrorEditorRunService')));
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
