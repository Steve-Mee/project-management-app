library;

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class MirrorPremiumService {
  MirrorPremiumService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const Set<String> _premiumLevels = <String>{
    'premium',
    'pro',
    'enterprise',
    'premiumplus',
  };

  final Map<String, _PremiumCacheEntry> _cache = <String, _PremiumCacheEntry>{};
  final Map<String, Future<bool>> _inFlight = <String, Future<bool>>{};

  Future<bool> isPremium({
    User? user,
    bool forceRefresh = false,
    Duration cacheTtl = const Duration(minutes: 5),
  }) async {
    final resolvedUser = user ?? _client.auth.currentUser;
    if (resolvedUser == null) {
      return false;
    }

    final userId = resolvedUser.id;
    if (!forceRefresh) {
      final cached = _cache[userId];
      if (cached != null && !cached.isExpired(cacheTtl)) {
        return cached.value;
      }
      final pending = _inFlight[userId];
      if (pending != null) {
        return pending;
      }
    }

    final future = _resolvePremium(resolvedUser);
    _inFlight[userId] = future;

    try {
      final value = await future;
      _cache[userId] = _PremiumCacheEntry(
        value: value,
        createdAt: DateTime.now().toUtc(),
      );
      return value;
    } finally {
      _inFlight.remove(userId);
    }
  }

  void clearCache({String? userId}) {
    if (userId == null || userId.isEmpty) {
      _cache.clear();
      _inFlight.clear();
      return;
    }

    _cache.remove(userId);
    _inFlight.remove(userId);
  }

  Future<bool> _resolvePremium(User user) async {
    if (_metadataSaysPremium(user)) {
      return true;
    }

    try {
      final List<dynamic> rows = await _client
          .from('subscriptions')
          .select('level,status,payment_provider')
          .eq('user_id', user.id)
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
      // Keep metadata fallback behavior when subscriptions query fails.
    }

    return _metadataSaysPremium(user);
  }

  bool _metadataSaysPremium(User user) {
    final appMetadata = user.appMetadata;
    final userMetadata = user.userMetadata ?? const <String, dynamic>{};

    final stripeActive =
        appMetadata['stripe_subscription_active'] ??
        userMetadata['stripe_subscription_active'];
    final stripeTier =
        appMetadata['stripe_subscription_tier'] ??
        userMetadata['stripe_subscription_tier'];

    if (stripeActive is bool && stripeActive) {
      final normalizedStripeTier =
          stripeTier?.toString().toLowerCase().trim() ?? '';
      if (_premiumLevels.contains(normalizedStripeTier)) {
        return true;
      }
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

class _PremiumCacheEntry {
  const _PremiumCacheEntry({
    required this.value,
    required this.createdAt,
  });

  final bool value;
  final DateTime createdAt;

  bool isExpired(Duration ttl) {
    return DateTime.now().toUtc().difference(createdAt) > ttl;
  }
}
