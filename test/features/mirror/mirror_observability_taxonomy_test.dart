@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mirror observability taxonomy', () {
    test('uses operation-specific latency event names', () {
      final serviceFile =
          File('lib/features/mirror/services/mirror_observability_service.dart');
      expect(serviceFile.existsSync(), isTrue,
          reason: 'Missing mirror observability service file');

      final content = serviceFile.readAsStringSync();

      expect(content, contains('mirror_compile_http_attempt_latency'));
      expect(content, contains('mirror_apply_http_attempt_latency'));
      expect(content, contains('mirror_http_attempt_latency'));
      expect(content, contains('mirror_templates_cache_fallback'));
      expect(content, isNot(contains("'mirror_compile_latency'")));
    });

    test('gateway backend emits latency via unified method', () {
      final backendFile = File('lib/features/mirror/mirror_gateway_backend.dart');
      expect(backendFile.existsSync(), isTrue,
          reason: 'Missing mirror gateway backend file');

      final content = backendFile.readAsStringSync();

      expect(content, contains('recordHttpAttemptLatency('));
      expect(content, isNot(contains('recordCompileLatency(')));
    });
  });
}
