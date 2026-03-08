import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/core/services/mirror_premium_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

User _buildUser({
  required String id,
  Map<String, dynamic>? appMetadata,
  Map<String, dynamic>? userMetadata,
}) {
  return User.fromJson(<String, dynamic>{
    'id': id,
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': '$id@example.com',
    'created_at': DateTime.now().toUtc().toIso8601String(),
    'app_metadata': appMetadata ?? <String, dynamic>{},
    'user_metadata': userMetadata ?? <String, dynamic>{},
  })!;
}

void main() {
  group('MirrorPremiumService integration precedence', () {
    late _FakeSupabaseRestServer fakeServer;
    late MirrorPremiumService service;

    setUp(() async {
      fakeServer = await _FakeSupabaseRestServer.start();
      final client = SupabaseClient(fakeServer.baseUrl, 'test-anon-key');
      service = MirrorPremiumService(client: client);
    });

    tearDown(() async {
      await fakeServer.close();
    });

    test('metadata premium short-circuits subscriptions lookup', () async {
      fakeServer.subscriptionRows = <Map<String, dynamic>>[
        <String, dynamic>{
          'level': 'basic',
          'status': 'active',
          'payment_provider': 'stripe',
        },
      ];

      final user = _buildUser(
        id: 'meta-first',
        appMetadata: <String, dynamic>{
          'stripe_subscription_active': true,
          'stripe_subscription_tier': 'premium',
        },
      );

      final result = await service.isPremium(user: user, forceRefresh: true);

      expect(result, isTrue);
      expect(fakeServer.subscriptionRequests, 0);
    });

    test('active stripe subscription is used when metadata is not premium',
        () async {
      fakeServer.subscriptionRows = <Map<String, dynamic>>[
        <String, dynamic>{
          'level': 'premium',
          'status': 'active',
          'payment_provider': 'stripe',
        },
      ];

      final user = _buildUser(
        id: 'subs-win',
        appMetadata: <String, dynamic>{
          'stripe_subscription_active': false,
          'stripe_subscription_tier': 'basic',
        },
      );

      final result = await service.isPremium(user: user, forceRefresh: true);

      expect(result, isTrue);
      expect(fakeServer.subscriptionRequests, 1);
    });

    test('non-premium metadata with non-premium subscriptions stays false',
        () async {
      fakeServer.subscriptionRows = <Map<String, dynamic>>[
        <String, dynamic>{
          'level': 'basic',
          'status': 'active',
          'payment_provider': 'stripe',
        },
      ];

      final user = _buildUser(
        id: 'no-premium',
        appMetadata: <String, dynamic>{
          'stripe_subscription_active': false,
          'stripe_subscription_tier': 'basic',
        },
      );

      final result = await service.isPremium(user: user, forceRefresh: true);

      expect(result, isFalse);
      expect(fakeServer.subscriptionRequests, 1);
    });
  });
}

class _FakeSupabaseRestServer {
  _FakeSupabaseRestServer._(this._server);

  final HttpServer _server;

  List<Map<String, dynamic>> subscriptionRows = <Map<String, dynamic>>[];
  int subscriptionRequests = 0;

  String get baseUrl => 'http://${_server.address.host}:${_server.port}';

  static Future<_FakeSupabaseRestServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fake = _FakeSupabaseRestServer._(server);

    server.listen((HttpRequest request) async {
      if (request.method == 'GET' &&
          request.uri.path == '/rest/v1/subscriptions') {
        fake.subscriptionRequests += 1;
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(fake.subscriptionRows));
        await request.response.close();
        return;
      }

      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write('[]');
      await request.response.close();
    });

    return fake;
  }

  Future<void> close() async {
    await _server.close(force: true);
  }
}
