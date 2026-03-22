// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mirror preview/apply consistency contract', () {
    test('editor freezes mutable run inputs while run is active', () {
      final source =
          _readRepoFile('lib/features/mirror/mirror_editor_screen.dart');

      expect(source, contains('isEnabled: !_isRunInProgress'));
      expect(source, contains('if (_isRunInProgress) {'));
      expect(source, contains('onChanged: (String content) {'));
    });

    test('run flow carries previewContextFingerprint from compile snapshot',
        () {
      final source = _readRepoFile(
        'lib/features/mirror/services/mirror_apply_flow_coordinator.dart',
      );

      expect(source, contains('compileContextForPreviewAndApply'));
      expect(source, contains('_workflows.prepareCompilePlan('));
      expect(source, contains('_previewMetadataService.buildApplyMetadata('));
      expect(source, contains('previewCompileFingerprint: compileFingerprint,'));
      expect(source, contains('previewCompileOutput: compileOutput,'));
    });

    test('patch planning contract is centralized in backend workflows service', () {
      final source = _readRepoFile(
        'lib/features/mirror/services/mirror_backend_workflows.dart',
      );

      expect(source, contains('class MirrorBackendWorkflows'));
      expect(source, contains('MirrorCompilePatchPlan prepareCompilePlan('));
      expect(source, contains('MirrorApplyPatchPlan prepareApplyPlan('));
      expect(source, contains('buildSessionPersistPlan('));
    });

    test(
        'gateway apply requires compile fingerprint and validates context fingerprint',
        () {
      final gateway =
          _readRepoFile('lib/features/mirror/mirror_gateway_backend.dart');
      final workflows = _readRepoFile(
        'lib/features/mirror/services/mirror_backend_workflows.dart',
      );
      final validator = _readRepoFile(
        'lib/features/mirror/services/mirror_apply_validator_service.dart',
      );

      expect(workflows, contains('preview fingerprint missing'));
      expect(validator, contains('preview fingerprint mismatch'));
      expect(validator, contains('preview context mismatch'));
      expect(validator, contains('previewContextFingerprint'));
      expect(gateway, contains('compileFingerprint: compileFingerprint,'));
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
