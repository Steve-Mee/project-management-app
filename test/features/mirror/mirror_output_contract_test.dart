import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mirror output contract', () {
    test('cloud runner returns output.files and keeps signedUrl separate', () {
      final source =
          _readRepoFile('server/mirror-cloud-runner/lib/main.dart');

      expect(source, contains("output: <String, dynamic>{"));
      expect(source, contains("'files': Map<String, String>.from(compileResult.outputFiles)"));
      expect(source, contains('signedUrl: signedUrl'));
      expect(source, isNot(contains("output: signedUrl")));
    });

    test('local runner returns output.files and keeps signedUrl separate', () {
      final source =
          _readRepoFile('server/mirror-local-runner/lib/main.dart');

      expect(source, contains("output: <String, dynamic>{"));
      expect(source, contains("'files': Map<String, String>.from(compileResult.outputFiles)"));
      expect(source, contains('signedUrl: signedUrl'));
      expect(source, isNot(contains("output: signedUrl")));
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
