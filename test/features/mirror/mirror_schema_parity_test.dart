import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/services/mirror_request_schema.dart';

// ignore: avoid_relative_lib_imports
import '../../../server/mirror-shared/lib/request_validator.dart';

MirrorCompileRequestSchema _compileSchemaFromMap(Map<String, dynamic> body) {
  Map<String, String>? toStringMap(Object? value) {
    if (value is! Map) {
      return null;
    }
    return value.map((key, val) => MapEntry(key.toString(), val.toString()));
  }

  return MirrorCompileRequestSchema(
    prompt: (body['prompt'] ?? '').toString(),
    projectId: (body['projectId'] ?? body['project_id'] ?? '').toString(),
    taskId: (body['taskId'] ?? body['task_id'] ?? '').toString(),
    mode: (body['mode'] ?? '').toString(),
    files: toStringMap(body['files']),
    metadata: body['metadata'] is Map ? Map<String, dynamic>.from(body['metadata'] as Map) : null,
    actorUserId: body['actorUserId']?.toString(),
    backupId: body['backupId']?.toString(),
    fileSetFingerprint: body['fileSetFingerprint']?.toString(),
    signedInputUrls: toStringMap(body['signedInputUrls']),
  );
}

void main() {
  group('Mirror schema parity', () {
    test('valid compile payload passes in both validators', () {
      final body = <String, dynamic>{
        'prompt': 'Generate a test helper',
        'projectId': '550e8400-e29b-41d4-a716-446655440000',
        'taskId': '7d444840-9dc0-11d1-b245-5ffdce74fad2',
        'mode': 'cloud',
        'files': <String, String>{'lib/main.dart': 'void main() {}'},
        'metadata': <String, dynamic>{'requestId': 'r-1'},
        'actorUserId': '550e8400-e29b-41d4-a716-446655440000',
        'backupId': 'backup-1',
        'fileSetFingerprint': 'sha256:abc123',
        'signedInputUrls': <String, String>{
          'archive': 'https://example.com/archive.zip',
        },
      };

      final appErrors = _compileSchemaFromMap(body).validate();
      final runnerErrors = MirrorRequestValidator.validateCompileBody(body);

      expect(appErrors, isEmpty);
      expect(runnerErrors, isEmpty);
    });

    test('invalid UUID fails in both validators', () {
      final body = <String, dynamic>{
        'prompt': 'X',
        'projectId': 'not-a-uuid',
        'taskId': '7d444840-9dc0-11d1-b245-5ffdce74fad2',
        'mode': 'private',
        'files': <String, String>{'a.txt': '1'},
      };

      final appErrors = _compileSchemaFromMap(body).validate().join(' | ');
      final runnerErrors = MirrorRequestValidator.validateCompileBody(body).join(' | ');

      expect(appErrors, contains('projectId'));
      expect(runnerErrors, contains('projectId'));
    });

    test('invalid mode fails in both validators', () {
      final body = <String, dynamic>{
        'prompt': 'X',
        'projectId': '550e8400-e29b-41d4-a716-446655440000',
        'taskId': '7d444840-9dc0-11d1-b245-5ffdce74fad2',
        'mode': 'team',
        'files': <String, String>{'a.txt': '1'},
      };

      final appErrors = _compileSchemaFromMap(body).validate().join(' | ');
      final runnerErrors = MirrorRequestValidator.validateCompileBody(body).join(' | ');

      expect(appErrors, contains('mode'));
      expect(runnerErrors, contains('mode'));
    });

    test('oversized prompt fails in both validators', () {
      final body = <String, dynamic>{
        'prompt': 'x' * 50001,
        'projectId': '550e8400-e29b-41d4-a716-446655440000',
        'taskId': '7d444840-9dc0-11d1-b245-5ffdce74fad2',
        'mode': 'cloud',
        'files': <String, String>{'a.txt': '1'},
      };

      final appErrors = _compileSchemaFromMap(body).validate().join(' | ');
      final runnerErrors = MirrorRequestValidator.validateCompileBody(body).join(' | ');

      expect(appErrors, contains('50000'));
      expect(runnerErrors, contains('50000'));
    });
  });
}
