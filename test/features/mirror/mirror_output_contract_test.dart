import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mirror output contract', () {
    test('shared runner serializes output files separately from signedUrl', () {
      final source = _readRepoFile('server/mirror-shared/lib/runner_service.dart');

      expect(
        RegExp(
          r"output:\s*jsonEncode\(<String, dynamic>\{\s*'files':\s*Map<String, String>\.from\(compileResult\.outputFiles\),\s*\}\)",
          multiLine: true,
          dotAll: true,
        ).hasMatch(source),
        isTrue,
      );
      expect(
        RegExp(r"signedUrl:\s*signedUrl\s*\?\?\s*''").hasMatch(source),
        isTrue,
      );
    });

    test('shared gateway decodes output payload and keeps signedUrl at top level', () {
      final source = _readRepoFile('server/mirror-shared/lib/http_gateway.dart');

      expect(
        RegExp(
          r"'output':\s*_decodeJsonField\(response\.output\)",
          multiLine: true,
        ).allMatches(source).length,
        2,
      );
      expect(
        RegExp(
          r"'signedUrl':\s*response\.signedUrl\.isEmpty\s*\?\s*null\s*:\s*response\.signedUrl",
          multiLine: true,
        ).allMatches(source).length,
        2,
      );
    });

    test('gateway idempotency contract uses expires_at cache columns and runtime statuses', () {
      final source = _readRepoFile('supabase/functions/mirror-gateway/index.ts');

      expect(RegExp(r'\bexpires_at\b').allMatches(source).isNotEmpty, isTrue);
      expect(RegExp(r'\bresponse_status\b').allMatches(source).isNotEmpty, isTrue);
      expect(RegExp(r'\bresponse_body\b').allMatches(source).isNotEmpty, isTrue);
      expect(RegExp(r'\bresponse_content_type\b').allMatches(source).isNotEmpty, isTrue);
      expect(
        RegExp(
          r"IDEMPOTENCY_ALLOWED_STATUSES\s*=\s*\['processing',\s*'completed',\s*'failed'\]\s+as const",
          multiLine: true,
        ).hasMatch(source),
        isTrue,
      );
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
