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
  group('MirrorPremiumService', () {
    late MirrorPremiumService service;

    setUp(() {
      final client = SupabaseClient(
        'http://127.0.0.1:9',
        'test-anon-key',
      );
      service = MirrorPremiumService(client: client);
    });

    test('returns true from premium metadata', () async {
      final user = _buildUser(
        id: 'u-premium-meta',
        appMetadata: <String, dynamic>{
          'stripe_subscription_active': true,
          'stripe_subscription_tier': 'premium',
        },
      );

      final result = await service.isPremium(user: user);

      expect(result, isTrue);
    });

    test('uses cached value for same user id without forceRefresh', () async {
      const userId = 'u-cache';
      final premiumUser = _buildUser(
        id: userId,
        appMetadata: <String, dynamic>{
          'stripe_subscription_active': true,
          'stripe_subscription_tier': 'premium',
        },
      );
      final downgradedUser = _buildUser(id: userId);

      final first = await service.isPremium(user: premiumUser);
      final second = await service.isPremium(user: downgradedUser);

      expect(first, isTrue);
      expect(second, isTrue);
    });

    test('forceRefresh bypasses cache and re-evaluates metadata/query', () async {
      const userId = 'u-force-refresh';
      final premiumUser = _buildUser(
        id: userId,
        appMetadata: <String, dynamic>{
          'stripe_subscription_active': true,
          'stripe_subscription_tier': 'premium',
        },
      );
      final downgradedUser = _buildUser(id: userId);

      final first = await service.isPremium(user: premiumUser);
      final second = await service.isPremium(
        user: downgradedUser,
        forceRefresh: true,
      );

      expect(first, isTrue);
      expect(second, isFalse);
    });

    test('clearCache(userId) invalidates cached value', () async {
      const userId = 'u-clear-cache';
      final premiumUser = _buildUser(
        id: userId,
        appMetadata: <String, dynamic>{
          'stripe_subscription_active': true,
          'stripe_subscription_tier': 'premium',
        },
      );
      final downgradedUser = _buildUser(id: userId);

      final first = await service.isPremium(user: premiumUser);
      service.clearCache(userId: userId);
      final second = await service.isPremium(user: downgradedUser);

      expect(first, isTrue);
      expect(second, isFalse);
    });
  });
}
