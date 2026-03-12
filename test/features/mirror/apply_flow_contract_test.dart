// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_management_app/features/mirror/mirror_gateway_backend.dart';
import 'package:project_management_app/features/mirror/mirror_compute_backend.dart';

void main() {
  group('Mirror apply end-to-end contract', () {
    test('signed uploads contract keeps backup and signed URL artifacts', () {
      final source =
          _readRepoFile('lib/features/mirror/mirror_compute_backend.dart');

      expect(source, contains('prepareSignedInputAndBackup'));
      expect(source, contains('signedInputBucket = \'mirror-signed-inputs\''));
      expect(source, contains('backupBucket = \'mirror-backups\''));
      expect(source, contains('await _uploadReplaceBinary('));
      expect(source, contains('.createSignedUrl(signedInputPath'));
      expect(source, contains('.createSignedUrl(backupPath'));
      expect(source, contains('signedInputUrls'));
      expect(source, contains('backupSignedUrls'));
      expect(source, contains('backupId'));
    });

    test('apply forwards metadata and security payload fields', () async {
      late Uri capturedUri;
      Map<String, dynamic>? capturedBody;

      // Mock client handles both compile (preflight) and apply calls
      final mockClient = MockClient((http.Request request) async {
        capturedUri = request.url;
        capturedBody = _asMap(request.body);
        
        if (request.url.toString().contains('/compile')) {
          // Return compile response for preflight
          return http.Response(
            '{"success":true,"output":"// compiled output"}',
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }
        // Return apply response
        return http.Response(
          '{"success":true,"files":{"lib/main.dart":"void main() { print(\\"ok\\"); }"}}',
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });

      final backend = MirrorGatewayBackend(
        httpClient: mockClient,
        applyHttpEndpoint:
            'https://edge.example/functions/v1/mirror-gateway/apply',
        useSecureApply: false,
      );

      const context = ProjectContext(
        projectId: 'project-7',
        taskId: 'task-42',
        files: <String, String>{'lib/main.dart': 'void main() {}'},
        metadata: <String, dynamic>{
          'buildTarget': 'flutter',
          'teamMode': true,
          'priority': 'high',
        },
      );

      // Compute fingerprint using the same logic as the backend
      final fingerprint = computeCompileResultFingerprint(
        prompt: 'apply patch',
        context: context,
        mode: 'private',
        output: '// compiled output',
      );

      final result = await backend.apply(
        prompt: 'apply patch',
        context: context,
        mode: 'private',
        compileFingerprint: fingerprint,
      );

      expect(capturedUri.toString(),
          contains('/functions/v1/mirror-gateway/apply'));
      expect(capturedBody?['prompt'], 'apply patch');
      expect(capturedBody?['projectId'], 'project-7');
      expect(capturedBody?['taskId'], 'task-42');
      expect(capturedBody?['mode'], 'private');

      final metadata = Map<String, dynamic>.from(
        (capturedBody?['metadata'] as Map?) ?? const <String, dynamic>{},
      );
      expect(metadata['buildTarget'], 'flutter');
      expect(metadata['teamMode'], isTrue);
      expect(metadata['priority'], 'high');

      expect(result.success, isTrue);
      expect(result.appliedFiles, contains('lib/main.dart'));
    });

    test('audit consistency contract keeps canonical apply event flow', () {
      final source =
          _readRepoFile('lib/features/mirror/mirror_compute_backend.dart');

      expect(source, contains("const eventApplyStarted = 'apply_started';"));
      expect(source,
          contains("const eventApplyPreparationFailed = 'apply_preparation_failed';"));
      expect(source, contains("const eventApplyException = 'apply_exception';"));
      expect(source, contains("const eventApplyCompleted = 'apply_completed';"));
      expect(source, contains('event: eventApplyStarted'));
      expect(source, contains('event: eventApplyPreparationFailed'));
      expect(source, contains('event: eventApplyException'));
      expect(source, contains('event: eventApplyCompleted'));
      expect(source, contains('fileSetFingerprint'));
      expect(source, contains('appliedFilesFingerprint'));
      expect(source, contains('mirror_apply_audit'));
    });
  });
}

Map<String, dynamic> _asMap(String raw) {
  final decoded = jsonDecode(raw);
  return Map<String, dynamic>.from(decoded as Map);
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


