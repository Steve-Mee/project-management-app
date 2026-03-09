import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mirror new-file patch apply contract', () {
    test('editor apply flow upserts new files from patch previews', () {
      final editorSource =
          _readRepoFile('lib/features/mirror/mirror_editor_screen.dart');

      expect(editorSource, contains('_sessionNotifier.upsertFileContent('));
      expect(editorSource, contains('path: patch.path,'));
      expect(editorSource, contains('content: patch.updatedContent,'));
      expect(editorSource, contains('if (!existsInSession) {'));
    });

    test('session notifier supports upsert by file path', () {
      final providerSource =
          _readRepoFile('lib/core/providers/mirror_session_provider.dart');

      expect(providerSource,
          contains('void upsertFileContent({required String path, required String content})'));
      expect(providerSource, contains('updatedFiles[path] = content;'));
      expect(providerSource, contains('state = state.copyWith(files: updatedFiles);'));
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
