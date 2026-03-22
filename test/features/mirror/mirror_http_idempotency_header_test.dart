import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_management_app/features/mirror/mirror_signed_inputs_backend.dart';
import 'package:project_management_app/features/mirror/mirror_gateway_backend.dart';

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
        projectId: '11111111-1111-4111-8111-111111111111',
        taskId: '22222222-2222-4222-8222-222222222222',
        files: <String, String>{'lib/main.dart': 'void main() {}'},
        metadata: ProjectContextMetadata(
          idempotencyKey: 'idem-gateway-001',
        ),
      );

      final result = await backend.compile(
        prompt: 'compile this',
        context: context,
        mode: 'cloud',
      );

      expect(result.success, isTrue);
      expect(capturedIdempotencyHeader, 'idem-gateway-001');
    });
  });
}
