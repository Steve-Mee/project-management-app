import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mirror request idempotency contract', () {
    test('idempotency handler keeps claim kinds and state transitions', () {
      final source = _readRepoFile(
        'supabase/functions/mirror-gateway/modules/idempotency_handler.ts',
      );

      expect(source, contains("type IdempotencyClaimKind = 'claimed' | 'replay' | 'in_progress' | 'conflict'"));
      expect(source, contains("if ((existing.status === 'completed' || existing.status === 'failed') && !expired)"));
      expect(source, contains("if (!expired && existing.status === 'processing' && !staleProcessing)"));
      expect(source, contains('return { kind: \'conflict\''));
      expect(source, contains('return { kind: \'replay\''));
      expect(source, contains('return { kind: \'in_progress\''));
      expect(source, contains('return { kind: \'claimed\''));
    });

    test('idempotency handler keeps ttl, stale recovery, and guarded finalization', () {
      final source = _readRepoFile(
        'supabase/functions/mirror-gateway/modules/idempotency_handler.ts',
      );

      expect(source, contains('DEFAULT_IDEMPOTENCY_TTL_SECONDS = 120'));
      expect(source, contains('IDEMPOTENCY_PROCESSING_STALE_SECONDS = 300'));
      expect(source, contains('parsed >= 30 && parsed <= 3600'));
      expect(source, contains('normalizeResponseBodyForStore'));
      expect(source, contains(".eq('request_id', requestId)"));
      expect(source, contains(".eq('request_hash', requestHash)"));
      expect(source, contains(".eq('status', 'processing')"));
      expect(source, contains('idempotency_update_conflict:no_matching_processing_claim'));
    });

    test('idempotency flow keeps replay headers and forward finalization wiring', () {
      final flowSource = _readRepoFile(
        'supabase/functions/mirror-gateway/modules/idempotency_flow_handler.ts',
      );
      final forwardSource = _readRepoFile(
        'supabase/functions/mirror-gateway/modules/forward_orchestrator.ts',
      );

      expect(flowSource, contains('buildIdempotencyRequestHash'));
      expect(flowSource, contains('claimIdempotencyKey'));
      expect(flowSource, contains('resolveIdempotencyEarlyExit'));
      expect(flowSource, contains("'x-idempotency-replay': 'true'"));

      expect(forwardSource, contains('finalizeIdempotencyKey'));
      expect(forwardSource, contains('classifyForwardIdempotencyStatus'));
      expect(forwardSource, contains('writeMirrorUsageLogIfReady'));
    });

    test('sql contracts keep expires_at cleanup and indexing', () {
      final runtimeContract = _readRepoFile(
        'test/supabase/mirror_idempotency_runtime_contract.sql',
      );
      final cronMigration = _readRepoFile(
        'supabase/migrations/20260322_mirror_request_idempotency_cron.sql',
      );

      expect(runtimeContract, contains('idx_mirror_request_idempotency_expires_at'));
      expect(runtimeContract, contains('cleanup_mirror_request_idempotency_expired'));
      expect(runtimeContract, contains('legacy expiry column still present'));
      expect(cronMigration, contains('cleanup_mirror_request_idempotency_expired(2000)'));
      expect(cronMigration, contains('pg_cron'));
    });

    test('gateway idempotency deno tests cover replay conflict finalize paths', () {
      final denoTestSource = _readRepoFile(
        'supabase/functions/mirror-gateway/modules/idempotency_handler_test.ts',
      );

      expect(denoTestSource, contains('claims a new key as processing'));
      expect(denoTestSource, contains('returns in_progress for active matching request'));
      expect(denoTestSource, contains('returns replay for completed matching request'));
      expect(denoTestSource, contains('returns conflict for active mismatched payload'));
      expect(denoTestSource, contains('reclaims expired mismatched payload'));
      expect(denoTestSource, contains('maps conflict, in-progress, and replay correctly'));
      expect(denoTestSource, contains('stores cached response and clips oversized bodies'));
      expect(denoTestSource, contains('rejects updates without matching processing claim'));
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