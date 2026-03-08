library;

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const Set<String> _premiumLevels = <String>{
    'premium',
    'pro',
    'enterprise',
    'premiumplus',
  };

  Future<bool> hasActiveStripePremiumSubscription({User? user}) async {
    final resolvedUser = user ?? _client.auth.currentUser;
    if (resolvedUser == null) {
      return false;
    }

    final appMetadata = resolvedUser.appMetadata;
    final userMetadata = resolvedUser.userMetadata ?? const <String, dynamic>{};

    final stripeActiveFlag =
        appMetadata['stripe_subscription_active'] ??
        userMetadata['stripe_subscription_active'];
    if (stripeActiveFlag is bool && stripeActiveFlag) {
      final tier =
          appMetadata['stripe_subscription_tier'] ??
          userMetadata['stripe_subscription_tier'] ??
          appMetadata['subscription'] ??
          appMetadata['plan'] ??
          userMetadata['subscription'] ??
          userMetadata['plan'];
      final normalizedTier = tier?.toString().toLowerCase().trim() ?? '';
      if (_premiumLevels.contains(normalizedTier)) {
        return true;
      }
    }

    try {
      final List<dynamic> rows = await _client
          .from('subscriptions')
          .select('level,status,payment_provider')
          .eq('user_id', resolvedUser.id)
          .eq('status', 'active')
          .limit(5);

      for (final entry in rows) {
        if (entry is! Map) {
          continue;
        }

        final row = Map<String, dynamic>.from(entry);
        final provider = (row['payment_provider']?.toString() ?? '')
            .toLowerCase()
            .trim();
        final level = (row['level']?.toString() ?? '').toLowerCase().trim();
        final isStripe = provider.isEmpty || provider == 'stripe';
        if (isStripe && _premiumLevels.contains(level)) {
          return true;
        }
      }
    } catch (_) {
      // Fall back to token metadata when subscriptions query is unavailable.
    }

    final fallbackTier =
        appMetadata['subscription'] ??
        appMetadata['plan'] ??
        userMetadata['subscription'] ??
        userMetadata['plan'];
    final normalizedFallback =
        fallbackTier?.toString().toLowerCase().trim() ?? '';
    return _premiumLevels.contains(normalizedFallback);
  }
}
