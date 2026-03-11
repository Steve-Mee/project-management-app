import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_management_app/core/services/mirror_premium_service.dart';
import 'package:project_management_app/features/mirror/cloud_fly_backend.dart';
import 'package:project_management_app/features/mirror/mirror_compute_backend.dart';
import 'package:project_management_app/features/mirror/mirror_gateway_backend.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _AlwaysPremiumService extends MirrorPremiumService {
  _AlwaysPremiumService()
      : super(
          client: SupabaseClient(
            'http://127.0.0.1:9',
            'test-anon-key',
          ),
        );

  @override
  Future<bool> isPremium({
    User? user,
    bool forceRefresh = false,
    Duration cacheTtl = const Duration(minutes: 5),
  }) async {
    return true;
  }
}

void main() {
  group('Mirror HTTP idempotency header', () {
    test('MirrorGatewayBackend compile sends x-idempotency-key header',
        () async {
      String? capturedIdempotencyHeader;

      final mockClient = MockClient((http.Request request) async {
        capturedIdempotencyHeader = request.headers['x-idempotency-key'];
        return http.Response(
          '{"success":true,"output":"compiled"}',
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });

      final backend = MirrorGatewayBackend(
        httpClient: mockClient,
        httpEndpoint:
            'https://edge.example/functions/v1/mirror-gateway/compile',
      );

      const context = ProjectContext(
        projectId: 'project-1',
        taskId: 'task-1',
        files: <String, String>{'lib/main.dart': 'void main() {}'},
        metadata: <String, dynamic>{
          'idempotencyKey': 'idem-gateway-001',
        },
      );

      final result = await backend.compile(
        prompt: 'compile this',
        context: context,
        mode: 'cloud',
      );

      expect(result.success, isTrue);
      expect(capturedIdempotencyHeader, 'idem-gateway-001');
    });

    test('CloudFlyBackend compile sends x-idempotency-key header', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async {
        await server.close(force: true);
      });

      final requests = <HttpRequest>[];
      final serverReady = Completer<void>();

      unawaited(
        () async {
          await for (final request in server) {
            requests.add(request);
            final body = await utf8.decoder.bind(request).join();
            expect(body, isNotEmpty);
            request.response
              ..statusCode = 200
              ..headers.contentType = ContentType.json
              ..write('{"success":true,"output":"cloud-compiled"}');
            await request.response.close();
            if (!serverReady.isCompleted) {
              serverReady.complete();
            }
          }
        }(),
      );

      final backend = CloudFlyBackend(
        premiumService: _AlwaysPremiumService(),
        httpEndpoint:
            'http://${server.address.address}:${server.port}/functions/v1/mirror-gateway/compile',
      );

      const context = ProjectContext(
        projectId: 'project-1',
        taskId: 'task-1',
        files: <String, String>{'lib/main.dart': 'void main() {}'},
        metadata: <String, dynamic>{
          'idempotencyKey': 'idem-cloud-001',
        },
      );

      final result = await backend.compile(
        prompt: 'compile this',
        context: context,
        mode: 'cloud',
      );

      await serverReady.future.timeout(const Duration(seconds: 2));

      expect(result.success, isTrue);
      expect(result.output, 'cloud-compiled');
      expect(requests, hasLength(1));
      expect(requests.single.headers.value('x-idempotency-key'),
          'idem-cloud-001');
    });
  });
}
