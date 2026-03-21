import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mirror orchestrator execution path contract', () {
    test('orchestrator delegates execution to explicit path services', () {
      final source = _readRepoFile(
        'lib/features/mirror/services/mirror_orchestrator_service.dart',
      );

      expect(source, contains('MirrorInteractiveExecutionPath'));
      expect(source, contains('MirrorReplayExecutionPath'));
      expect(source, contains('_interactivePath.generate('));
      expect(source, contains('_interactivePath.compile('));
      expect(source, contains('_interactivePath.apply('));
      expect(source, contains('_replayPath.execute(entry)'));
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
