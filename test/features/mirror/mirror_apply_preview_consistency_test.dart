// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mirror preview/apply consistency contract', () {
    test('editor computes and threads compile fingerprint through dialog and apply', () {
      final source =
          _readRepoFile('lib/features/mirror/services/mirror_apply_flow_coordinator.dart');

      expect(source, contains('computeCompileResultFingerprint('));
      expect(source, contains('compileFingerprint: compileFingerprint,'));
      expect(source, contains('context: compileContext,'));
      expect(source, contains('files: Map<String, String>.from(compileContext.files),'));
    });

    test('backend apply contract supports compile fingerprint validation', () {
      final contract =
          _readRepoFile('lib/features/mirror/mirror_signed_inputs_backend.dart');
      final workflows = _readRepoFile(
        'lib/features/mirror/services/mirror_backend_workflows.dart',
      );
      final validator = _readRepoFile(
        'lib/features/mirror/services/mirror_apply_validator_service.dart',
      );

      expect(contract, contains('String? compileFingerprint'));
      expect(contract, contains('computeCompileResultFingerprint'));
      expect(workflows, contains('Apply blocked: preview fingerprint missing'));
      expect(validator, contains('Apply blocked: preview fingerprint mismatch'));
      expect(validator, contains('Apply blocked: preview context mismatch'));
    });

    test('apply dialog carries compile fingerprint without changing consent flow', () {
      final source = _readRepoFile('lib/features/mirror/apply_dialog.dart');

      expect(source, contains('final String compileFingerprint;'));
      expect(source, contains('required this.compileFingerprint'));
      expect(source, contains('acceptRisk'));
      expect(
        source,
        contains('mirrorApplyConfirm'),
      );
      expect(
        source,
        contains('mirrorApplyRiskAcknowledgeSubtitle'),
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


