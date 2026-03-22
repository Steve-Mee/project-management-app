import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mirror gateway schema validation contract', () {
    test('request schema keeps payload size, prompt, uuid, and mode guards', () {
      final schemaSource = _readRepoFile(
        'supabase/functions/mirror-gateway/modules/request_schema.ts',
      );
      final normalizationSource = _readRepoFile(
        'supabase/functions/mirror-gateway/modules/request_normalization.ts',
      );

      expect(schemaSource, contains('MAX_REQUEST_BODY_BYTES = 512 * 1024'));
      expect(schemaSource, contains("'payload_too_large'"));
      expect(schemaSource, contains('prompt.length > 50000'));
      expect(schemaSource, contains('projectId: must be valid UUID'));
      expect(schemaSource, contains('taskId: must be valid UUID'));
      expect(schemaSource, contains('mode: must be "private" or "cloud"'));

      expect(normalizationSource, contains('UUID_V4_LIKE_REGEX'));
      expect(normalizationSource, contains("if (!normalizedPrompt || !normalizedProjectId || !normalizedTaskId || !mode)"));
      expect(normalizationSource, contains("if (mode !== 'private' && mode !== 'cloud')"));
    });

    test('request schema keeps signed input, fingerprint, and file limits', () {
      final schemaSource = _readRepoFile(
        'supabase/functions/mirror-gateway/modules/request_schema.ts',
      );

      expect(schemaSource, contains('actorUserId: must be valid UUID when provided'));
      expect(schemaSource, contains('fileSetFingerprint: must be valid hash format'));
      expect(schemaSource, contains(r'signedInputUrls[${key}]: must be valid HTTPS URL'));
      expect(schemaSource, contains('files: must contain ≤1000 entries'));
      expect(schemaSource, contains('value must be ≤1MB'));
      expect(schemaSource, contains('backupId: must be ≤512 characters'));
    });

    test('gateway schema deno tests cover boundary and normalization cases', () {
      final schemaTestSource = _readRepoFile(
        'supabase/functions/mirror-gateway/modules/request_schema_test.ts',
      );

      expect(schemaTestSource, contains('rejects payload too large from content-length header'));
      expect(schemaTestSource, contains('rejects oversized prompt'));
      expect(schemaTestSource, contains('rejects invalid actor user id and fingerprint'));
      expect(schemaTestSource, contains('rejects non-https signed input urls'));
      expect(schemaTestSource, contains('rejects too many files'));
      expect(schemaTestSource, contains('rejects oversized file content'));
      expect(schemaTestSource, contains('normalizes blank files and sorts signed input urls'));
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