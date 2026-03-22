import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Unified secure apply contract', () {
    test('both backends delegate apply orchestration to shared workflow', () {
      final gatewaySource =
          _readRepoFile('lib/features/mirror/mirror_gateway_backend.dart');
      final grpcSource =
          _readRepoFile('lib/features/mirror/private_grpc_backend.dart');

      expect(gatewaySource, contains('executeApplyFlow('));
      expect(grpcSource, contains('executeApplyFlow('));
      expect(gatewaySource, contains("backend: 'mirror_gateway'"));
      expect(grpcSource, contains("backend: 'private_grpc'"));
    });

    test('shared workflow decides security mode centrally', () {
      final workflowSource = _readRepoFile(
        'lib/features/mirror/services/mirror_backend_workflows.dart',
      );

      expect(workflowSource, contains('determineApplySecurityMode')); 
      expect(workflowSource, contains('buildApplySecurityModeFactors')); 
      expect(workflowSource, contains('logSecurityModeDecision')); 
    });

    test('secure apply artifacts use shared retry wrapper', () {
      final secureApplySource = _readRepoFile(
        'lib/features/mirror/services/mirror_secure_apply_service.dart',
      );

      expect(secureApplySource, contains('_runArtifactOperationWithRetry')); 
      expect(secureApplySource, contains('_artifactOperationMaxAttempts')); 
      expect(secureApplySource, contains('createSignedUrl')); 
      expect(secureApplySource, contains('uploadBinary')); 
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
