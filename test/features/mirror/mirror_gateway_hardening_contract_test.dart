import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mirror gateway hardening contract', () {
    test('gateway keeps weighted throttling, circuit breaker, and redaction hooks', () {
      final source = _readRepoFile('supabase/functions/mirror-gateway/index.ts');
      final telemetry =
          _readRepoFile('supabase/functions/mirror-gateway/modules/telemetry.ts');
      final resilience = _readRepoFile(
        'supabase/functions/mirror-gateway/modules/resilience_handler.ts',
      );
      final rateLimiter = _readRepoFile(
        'supabase/functions/mirror-gateway/modules/rate_limiter_handler.ts',
      );
      final forwarding = _readRepoFile(
        'supabase/functions/mirror-gateway/modules/request_forwarding.ts',
      );
      final auditLogger = _readRepoFile(
        'supabase/functions/mirror-gateway/modules/audit_logger.ts',
      );

      expect(telemetry, contains('reason?: string'));
      expect(rateLimiter, contains('weightedMinuteUnits'));
      expect(rateLimiter, contains('weightedBurstUnits'));
      expect(resilience, contains('evaluateCircuitBreakerAllowance'));
      expect(source, contains('handleCircuitBreakerRejection'));
      expect(forwarding, contains('sanitizeUpstreamBodyForErrorDetails'));
      expect(auditLogger, contains('normalizeArtifactId'));
      expect(forwarding, isNot(contains('body: upstreamBody')));
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
