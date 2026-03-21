import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Monaco degraded desktop contract', () {
    test('io host exposes explicit degraded-state and limited-mode recovery', () {
      final source =
          _readRepoFile('lib/features/mirror/widgets/monaco_editor_host_io.dart');

      expect(source, contains('_buildDesktopDegradedState')); 
      expect(source, contains('Retry editor initialization'));
      expect(source, contains('Continue in limited editor'));
      expect(source, contains('_buildDesktopLimitedFallback'));
      expect(source, contains('Restore studio editor'));
      expect(source, contains('_allowDesktopLimitedEditor = false'));
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
