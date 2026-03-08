import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mirror edge function contract', () {
    test('edge function keeps explicit compile/apply path dispatch', () {
      final source = _readRepoFile('supabase/functions/mirror_compute/index.ts');

      expect(source, contains('function resolveActionFromPath'));
      expect(source, contains("normalized.endsWith('/compile')"));
      expect(source, contains("normalized.endsWith('/apply')"));
      expect(source, contains('Invalid route. Use /compile or /apply.'));
      expect(source, contains("const action = resolveActionFromPath"));
      expect(source, contains("if (!action)"));
    });

    test('edge function keeps idempotency contract and forwarding headers', () {
      final source = _readRepoFile('supabase/functions/mirror_compute/index.ts');

      expect(source, contains("req.headers.get('x-idempotency-key')"));
      expect(source, contains("req.headers.get('idempotency-key')"));
      expect(source, contains("'x-idempotency-key': idempotencyKey"));
      expect(source, contains("'x-request-id': requestId"));
      expect(source, contains('idempotencyKey'));
      expect(source, contains('action'));
      expect(source, contains('resolveForwardEndpoint(normalized.mode, action)'));
    });

    test('flutter edge backend targets compile and apply endpoints and keeps fail-fast config', () {
      final source = _readRepoFile('lib/features/mirror/edge_function_backend.dart');

      expect(source, contains("/functions/v1/mirror_compute/compile"));
      expect(source, contains("/functions/v1/mirror_compute/apply"));
      expect(source, contains('applyHttpEndpoint'));
      expect(source, contains('supabase_url_missing'));
      expect(source, contains('Edge HTTP /compile request timed out.'));
      expect(source, contains('Edge HTTP /apply request timed out.'));
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
