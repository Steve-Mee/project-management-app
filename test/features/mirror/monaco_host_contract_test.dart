import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Monaco host contract', () {
    test('conditional export maps web to web host and non-web to io host', () {
      final source =
          _readRepoFile('lib/features/mirror/widgets/monaco_editor_host.dart');

      expect(source, contains("'monaco_editor_host_io.dart'"));
      expect(source,
          contains("if (dart.library.html) 'monaco_editor_host_web.dart'"));
    });

    test('io host uses desktop webview and mobile text fallback', () {
      final source = _readRepoFile(
          'lib/features/mirror/widgets/monaco_editor_host_io.dart');

      expect(source, contains('InAppWebView('));
      expect(
          source,
          contains(
              'Platform.isWindows || Platform.isLinux || Platform.isMacOS'));
      expect(source, contains('return _buildMobileFallback();'));
      expect(source, contains('TextField('));
      expect(source, contains('window.__setMirrorCode'));
    });

    test('web host remains a real monaco html embedding', () {
      final source = _readRepoFile(
          'lib/features/mirror/widgets/monaco_editor_host_web.dart');

      expect(source, contains('HtmlElementView'));
      expect(source, contains('loader.min.js'));
      expect(source, contains('mirror-monaco'));
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
