import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/services/mirror_realtime_service.dart';

void main() {
  group('Mirror new-file patch apply contract', () {
    test('editor apply flow upserts new files from patch previews', () {
      final editorSource =
          _readRepoFile('lib/features/mirror/services/mirror_editor_orchestration_service.dart');

        expect(editorSource, contains('sessionNotifier.upsertFileContent('));
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
      expect(providerSource, contains('state = state.copyWith('));
      expect(providerSource, contains('files: updatedFiles,'));
    });

    test('realtime output merge keeps only latest max lines', () {
      final merged = mergeLiveOutputWithCap(
        currentLines: List<String>.generate(480, (int i) => 'current-$i'),
        incomingLines: List<String>.generate(80, (int i) => 'incoming-$i'),
        maxLines: 500,
      );

      expect(merged.length, 500);
      expect(merged.first, 'current-60');
      expect(merged.last, 'incoming-79');
    });

    test('realtime output merge preserves all lines below cap', () {
      final merged = mergeLiveOutputWithCap(
        currentLines: const <String>['a', 'b'],
        incomingLines: const <String>['c', 'd'],
        maxLines: 500,
      );

      expect(merged, const <String>['a', 'b', 'c', 'd']);
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
