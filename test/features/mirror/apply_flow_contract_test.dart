// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_management_app/features/mirror/mirror_gateway_backend.dart';
import 'package:project_management_app/features/mirror/mirror_signed_inputs_backend.dart';

void main() {
  group('Mirror apply end-to-end contract', () {
    test('signed uploads contract keeps backup and signed URL artifacts', () {
      final workflowSource = _readRepoFile(
        'lib/features/mirror/services/mirror_backend_workflows.dart',
      );
      final secureApplySource = _readRepoFile(
        'lib/features/mirror/services/mirror_secure_apply_service.dart',
      );

      expect(workflowSource, contains('prepareSignedInputAndBackup'));
      expect(workflowSource, contains('executeApplyFlow'));
        expect(workflowSource, contains('defaultSignedInputBucket'));
        expect(workflowSource, contains('defaultBackupBucket'));
      expect(secureApplySource, contains('_runArtifactOperationWithRetry'));
        expect(secureApplySource, contains('_uploadReplaceBinary('));
      expect(secureApplySource, contains('.createSignedUrl(signedInputPath'));
      expect(secureApplySource, contains('.createSignedUrl(backupPath'));
      expect(secureApplySource, contains('signedInputUrls'));
      expect(secureApplySource, contains('backupSignedUrls'));
      expect(secureApplySource, contains('backupId'));
    });

    test('apply forwards metadata and security payload fields', () async {
      final capturedUris = <Uri>[];
      final capturedBodies = <Map<String, dynamic>>[];

      final mockClient = MockClient((http.Request request) async {
        capturedUris.add(request.url);
        capturedBodies.add(_asMap(request.body));
        if (request.url.path.endsWith('/compile')) {
          return http.Response(
            '{"success":true,"output":"void main() { print(\\"ok\\"); }"}',
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }
        return http.Response(
          '{"success":true,"files":{"lib/main.dart":"void main() { print(\\"ok\\"); }"}}',
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });

      final backend = MirrorGatewayBackend(
        httpClient: mockClient,
        httpEndpoint:
          'https://edge.example/functions/v1/mirror-gateway/compile',
        applyHttpEndpoint:
            'https://edge.example/functions/v1/mirror-gateway/apply',
        useSecureApply: false,
      );

      const context = ProjectContext(
        projectId: '11111111-1111-4111-8111-111111111111',
        taskId: '22222222-2222-4222-8222-222222222222',
        files: <String, String>{'lib/main.dart': 'void main() {}'},
        metadata: ProjectContextMetadata(
          buildTarget: 'flutter',
          teamModeEnabled: true,
          priority: 'high',
        ),
      );

      final result = await backend.apply(
        prompt: 'apply patch',
        context: context,
        mode: 'private',
      );

      final applyIndex = capturedUris.indexWhere(
        (uri) => uri.toString().contains('/functions/v1/mirror-gateway/apply'),
      );
      expect(applyIndex, isNonNegative);
      final capturedBody = capturedBodies[applyIndex];

      expect(capturedUris[applyIndex].toString(),
          contains('/functions/v1/mirror-gateway/apply'));
      expect(capturedBody['prompt'], 'apply patch');
      expect(capturedBody['projectId'], '11111111-1111-4111-8111-111111111111');
      expect(capturedBody['taskId'], '22222222-2222-4222-8222-222222222222');
      expect(capturedBody['mode'], 'private');

      final metadata = Map<String, dynamic>.from(
        (capturedBody['metadata'] as Map?) ?? const <String, dynamic>{},
      );
      expect(metadata['buildTarget'], 'flutter');
      expect(metadata['teamMode'], isTrue);
      expect(metadata['priority'], 'high');

      expect(result.success, isTrue);
      expect(result.appliedFiles, contains('lib/main.dart'));
    });

    test('audit consistency contract keeps canonical apply event flow', () {
      final source = _readRepoFile(
        'lib/features/mirror/services/mirror_secure_apply_service.dart',
      );

      expect(source, contains("const eventApplyStarted = 'apply_started';"));
      expect(
          source,
          contains(
              "const eventApplyPreparationFailed = 'apply_preparation_failed';"));
      expect(
          source, contains("const eventApplyException = 'apply_exception';"));
      expect(
          source, contains("const eventApplyCompleted = 'apply_completed';"));
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
