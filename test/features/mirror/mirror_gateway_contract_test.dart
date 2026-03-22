// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/mirror/mirror_gateway_backend.dart';
import 'package:project_management_app/features/mirror/mirror_signed_inputs_backend.dart';

void main() {
  group('Mirror gateway contract', () {
    test('gateway keeps explicit compile/apply path dispatch', () {
      final indexSource =
          _readRepoFile('supabase/functions/mirror-gateway/index.ts');
      final routingSource = _readRepoFile(
        'supabase/functions/mirror-gateway/modules/routing_identity.ts',
      );
      final preconditionsSource = _readRepoFile(
        'supabase/functions/mirror-gateway/modules/pre_condition_handler.ts',
      );

      expect(indexSource, contains('resolveActionFromPath'));
      expect(indexSource, contains('validateRequestPreconditions'));
      expect(indexSource, contains('executeForwardAndFinalize'));

      expect(routingSource, contains("normalized.endsWith('/compile')"));
      expect(routingSource, contains("normalized.endsWith('/apply')"));
      expect(routingSource, contains('missing_endpoint_env:'));
      expect(routingSource, contains('resolveForwardEndpoint'));

      expect(preconditionsSource,
          contains('Invalid route. Use /compile or /apply.'));
      expect(preconditionsSource, contains("code: 'bad_request'"));
      expect(preconditionsSource, contains("code: 'method_not_allowed'"));
    });

    test(
        'runtime compile contract sends payload+auth and parses success response',
        () async {
      late Uri capturedUri;
      Map<String, dynamic>? capturedBody;
      String? capturedAuth;

      final mockClient = MockClient((http.Request request) async {
        capturedUri = request.url;
        capturedAuth = request.headers['Authorization'];
        capturedBody = _asMap(request.body);
        return http.Response(
          '{"success":true,"output":"compiled","warnings":["w1"]}',
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
        metadata: ProjectContextMetadata(teamModeEnabled: true),
      );

      final result = await backend.compile(
        prompt: 'compile this',
        context: context,
        mode: 'cloud',
      );

      expect(capturedUri.toString(),
          contains('/functions/v1/mirror-gateway/compile'));
      expect(
          capturedAuth == null || capturedAuth!.startsWith('Bearer '), isTrue);
      expect(capturedBody?['prompt'], 'compile this');
        expect(capturedBody?['projectId'], '11111111-1111-4111-8111-111111111111');
        expect(capturedBody?['taskId'], '22222222-2222-4222-8222-222222222222');
      expect(capturedBody?['mode'], 'cloud');
      expect(capturedBody?['files'], isA<Map>());

      expect(result.success, isTrue);
      expect(result.output, 'compiled');
      expect(result.warnings, contains('w1'));
    });

    test(
        'runtime compile contract maps non-2xx responses to typed code prefixes',
        () async {
      final mockClient = MockClient((http.Request request) async {
        return http.Response('denied', 403);
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
      );
      final result = await backend.compile(
        prompt: 'x',
        context: context,
        mode: 'private',
      );

      expect(result.success, isFalse);
      expect(result.errors.join(' | '), contains('unauthorized'));
      expect(result.errors.join(' | '), contains('HTTP 403'));
      expect(result.errors.join(' | '), contains('denied'));
    });

    test('runtime apply contract sends apply payload and maps success',
        () async {
      final capturedUris = <Uri>[];
      final capturedBodies = <Map<String, dynamic>>[];

      final mockClient = MockClient((http.Request request) async {
        capturedUris.add(request.url);
        capturedBodies.add(_asMap(request.body));
        if (request.url.path.endsWith('/compile')) {
          return http.Response(
            '{"success":true,"output":"void main() { print(\\"ok\\"); }"}',
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }
        return http.Response(
          '{"success":true,"files":{"lib/main.dart":"void main() { print(\\"ok\\"); }"}}',
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });

      final backend = MirrorGatewayBackend(
        httpClient: mockClient,
        httpEndpoint:
          'https://edge.example/functions/v1/mirror-gateway/compile',
        applyHttpEndpoint:
            'https://edge.example/functions/v1/mirror-gateway/apply',
        useSecureApply: false,
      );

      const context = ProjectContext(
        projectId: '11111111-1111-4111-8111-111111111111',
        taskId: '22222222-2222-4222-8222-222222222222',
        files: <String, String>{'lib/main.dart': 'void main() {}'},
      );

      final result = await backend.apply(
        prompt: 'apply this change',
        context: context,
        mode: 'cloud',
      );

      final applyIndex = capturedUris.indexWhere(
        (uri) => uri.toString().contains('/functions/v1/mirror-gateway/apply'),
      );
      expect(applyIndex, isNonNegative);
      final capturedBody = capturedBodies[applyIndex];

      expect(capturedUris[applyIndex].toString(),
          contains('/functions/v1/mirror-gateway/apply'));
      expect(capturedBody['prompt'], 'apply this change');
      expect(capturedBody['projectId'], '11111111-1111-4111-8111-111111111111');
      expect(capturedBody['taskId'], '22222222-2222-4222-8222-222222222222');
      expect(capturedBody['mode'], 'cloud');
      expect(result.success, isTrue);
      expect(result.appliedFiles, contains('lib/main.dart'));
    });

    test('runtime apply contract maps non-2xx responses to typed code prefixes',
        () async {
      final mockClient = MockClient((http.Request request) async {
        return http.Response('upstream down', 502);
      });

      final backend = MirrorGatewayBackend(
        httpClient: mockClient,
        httpEndpoint:
          'https://edge.example/functions/v1/mirror-gateway/compile',
        applyHttpEndpoint:
            'https://edge.example/functions/v1/mirror-gateway/apply',
        useSecureApply: false,
      );

      const context = ProjectContext(
        projectId: '11111111-1111-4111-8111-111111111111',
        taskId: '22222222-2222-4222-8222-222222222222',
        files: <String, String>{'lib/main.dart': 'void main() {}'},
      );

      final result = await backend.apply(
        prompt: 'apply this change',
        context: context,
        mode: 'cloud',
      );

      expect(result.success, isFalse);
      expect(result.message ?? '', contains('server_error'));
      expect(result.message ?? '', contains('HTTP 502'));
      expect(result.message ?? '', contains('upstream down'));
    });

    test('apply route contract is explicit in gateway + flutter backend wiring',
        () {
      final gatewaySource = _readRepoFile(
      'supabase/functions/mirror-gateway/modules/routing_identity.ts',
      );
      final flutterSource =
          _readRepoFile('lib/features/mirror/mirror_gateway_backend.dart');

      expect(gatewaySource, contains('resolveActionFromPath'));
      expect(gatewaySource, contains("normalized.endsWith('/apply')"));
      expect(gatewaySource,
        contains('resolveForwardEndpoint('));

      expect(flutterSource, contains('/functions/v1/mirror-gateway/apply'));
      expect(flutterSource, contains('applyHttpEndpoint'));
      expect(flutterSource, contains('supabase_url_missing'));
    });
  });
}

Map<String, dynamic> _asMap(String raw) {
  final decoded = jsonDecode(raw);
  return Map<String, dynamic>.from(decoded as Map);
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
