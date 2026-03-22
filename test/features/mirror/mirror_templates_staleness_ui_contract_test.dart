import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mirror templates staleness UI contract', () {
    test('stale fallback warning includes reason label and refresh action', () {
      final source = _readRepoFile(
        'lib/features/mirror/mirror_editor_screen.dart',
      );

      expect(source, contains('if (result.isStaleFallback)'));
      expect(source, contains(r'($staleReasonMessage)'));
      expect(source, contains("TextButton.icon("));
      expect(source, contains('mirrorTemplatesInvalidationControllerProvider'));
      expect(source, contains('invalidateTemplatesCache(refresh: true)'));
      expect(source, contains('_l10n.mirrorRetryButton'));
    });

    test('fresh templates path does not render stale fallback branch', () {
      final source = _readRepoFile(
        'lib/features/mirror/mirror_editor_screen.dart',
      );

      expect(source, contains('final staleWarningMessage = result.isStaleFallback'));
      expect(source, contains('if (result.isStaleFallback)'));
      expect(source, contains('Expanded('));
      expect(source, contains('TemplatesGallery('));
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
