import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mirror gateway hardening contract', () {
    test('gateway keeps weighted throttling, circuit breaker, and redaction hooks', () {
      final source = _readRepoFile('supabase/functions/mirror-gateway/index.ts');

      expect(source, contains("reason?: 'minute_rate' | 'burst_quota' | 'weighted_minute' | 'weighted_burst'"));
      expect(source, contains('weightedUnitsLastMinute'));
      expect(source, contains('evaluateCircuitBreakerAllowance'));
      expect(source, contains("reason: 'circuit_breaker_open'"));
      expect(source, contains('sanitizeUpstreamBodyForErrorDetails'));
      expect(source, contains('normalizeArtifactId'));
      expect(source, isNot(contains('body: upstreamBody')));
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
