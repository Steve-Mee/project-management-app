library;

import 'dart:async';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Client-side entitlement hint cache for Mirror UX.
///
/// This service is intentionally non-authoritative: it only provides a fast,
/// local hint used to shape client UX while the final cloud entitlement
/// decision is always enforced server-side by `has_cloud_mirror_access()` in
/// the Mirror Gateway.
class MirrorPremiumService {
  MirrorPremiumService({
    SupabaseClient? client,
    bool? outboxFailClosedOnEncryptionError,
    bool? productionMode,
    bool autoRefreshOnEntitlementChange = true,
  })  : _client = client,
        _productionMode =
            productionMode ?? const bool.fromEnvironment('dart.vm.product'),
        _outboxFailClosedOnEncryptionError =
            outboxFailClosedOnEncryptionError ??
                bool.fromEnvironment(
                  'MIRROR_OUTBOX_FAIL_CLOSED_ON_ENCRYPTION_ERROR',
                  defaultValue:
                      productionMode ?? const bool.fromEnvironment('dart.vm.product'),
                ),
        _autoRefreshOnEntitlementChange = autoRefreshOnEntitlementChange {
    if (_autoRefreshOnEntitlementChange && _client != null) {
      _authSubscription = _client!.auth.onAuthStateChange.listen(
        _handleAuthStateChange,
      );
    }
  }

  final SupabaseClient? _client;
  final bool _productionMode;
  final bool _outboxFailClosedOnEncryptionError;
  final bool _autoRefreshOnEntitlementChange;
  StreamSubscription<AuthState>? _authSubscription;

  static const Set<String> _premiumLevels = <String>{
    'premium',
    'pro',
    'enterprise',
    'premiumplus',
  };

  final Map<String, _PremiumCacheEntry> _cache = <String, _PremiumCacheEntry>{};
  final Map<String, Future<bool>> _inFlight = <String, Future<bool>>{};

  static const int _ttlSecondsFromEnv =
      int.fromEnvironment('MIRROR_PREMIUM_CACHE_TTL_SECONDS', defaultValue: 0);
  static const int _ttlJitterPercentFromEnv = int.fromEnvironment(
    'MIRROR_PREMIUM_CACHE_TTL_JITTER_PERCENT',
    defaultValue: 20,
  );

  bool shouldFailClosedOnOutboxEncryptionError() {
    return _outboxFailClosedOnEncryptionError;
  }

  Duration get defaultCacheTtl =>
      Duration(seconds: _ttlSecondsFromEnv > 0
          ? _ttlSecondsFromEnv
          : (_productionMode ? 300 : 30));

  Future<void> triggerEntitlementRefresh({User? user}) async {
    final resolvedUser = user ?? _client?.auth.currentUser;
    if (resolvedUser == null) {
      clearCache();
      return;
    }

    clearCache(userId: resolvedUser.id);
    await isPremium(user: resolvedUser, forceRefresh: true);
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    _authSubscription = null;
  }

  Future<bool> isPremium({
    User? user,
    bool forceRefresh = false,
    Duration? cacheTtl,
  }) async {
    // This is a client UX hint only. Never treat it as the final source of
    // truth for cloud Mirror authorization.
    final resolvedUser = user ?? _client?.auth.currentUser;
    if (resolvedUser == null) {
      return false;
    }

    final userId = resolvedUser.id;
    final resolvedTtl = cacheTtl ?? defaultCacheTtl;
    if (!forceRefresh) {
      final cached = _cache[userId];
      if (cached != null && !cached.isExpired()) {
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
      final now = DateTime.now().toUtc();
      _cache[userId] = _PremiumCacheEntry(
        value: value,
        expiresAt: now.add(_jitteredTtlForUser(userId, resolvedTtl)),
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

  void _handleAuthStateChange(AuthState authState) {
    final event = authState.event;
    final sessionUser = authState.session?.user;

    switch (event) {
      case AuthChangeEvent.signedOut:
        clearCache();
        return;
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.userUpdated:
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.passwordRecovery:
      case AuthChangeEvent.mfaChallengeVerified:
      case AuthChangeEvent.initialSession:
        final user = sessionUser ?? _client?.auth.currentUser;
        if (user == null) {
          return;
        }
        unawaited(triggerEntitlementRefresh(user: user));
        return;
      case _:
        return;
    }
  }

  Duration _jitteredTtlForUser(String userId, Duration baseTtl) {
    if (baseTtl <= Duration.zero) {
      return const Duration(seconds: 1);
    }

    final jitterPercent = _ttlJitterPercentFromEnv.clamp(0, 90);
    if (jitterPercent == 0) {
      return baseTtl;
    }

    final maxJitterFraction = jitterPercent / 100;
    final seed = userId.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    final random = Random(seed);
    final jitterFactor = 1 + ((random.nextDouble() * 2 - 1) * maxJitterFraction);
    final jitteredMs = max(
      1000,
      (baseTtl.inMilliseconds * jitterFactor).round(),
    );
    return Duration(milliseconds: jitteredMs);
  }

  Future<bool> _resolvePremium(User user) async {
    // Use auth metadata only as a lightweight local hint. The gateway remains
    // server-authoritative for all cloud entitlement decisions.
    
    // First, check if metadata indicates premium (short-circuits subscriptions lookup).
    if (_metadataSaysPremium(user)) {
      return true;
    }

    // If metadata is not premium, fall back to checking subscriptions table.
    return _subscriptionsSaysPremium(user);
  }

  Future<bool> _subscriptionsSaysPremium(User user) async {
    if (_client == null) {
      return false;
    }

    try {
      final response = await _client!.rest
          .from('subscriptions')
          .select()
          .eq('user_id', user.id)
          .then(
            (response) =>
                (response as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
          );

      for (final row in response) {
        final level = row['level']?.toString().toLowerCase().trim() ?? '';
        final status = row['status']?.toString().toLowerCase().trim() ?? '';

        if (_premiumLevels.contains(level) && status == 'active') {
          return true;
        }
      }

      return false;
    } catch (_) {
      // Subscription lookup failed; default to non-premium for safety.
      return false;
    }
  }

  bool _metadataSaysPremium(User user) {
    final appMetadata = user.appMetadata;
    final userMetadata = user.userMetadata ?? const <String, dynamic>{};

    final stripeActive = appMetadata['stripe_subscription_active'] ??
        userMetadata['stripe_subscription_active'];
    final stripeTier = appMetadata['stripe_subscription_tier'] ??
        userMetadata['stripe_subscription_tier'];

    if (stripeActive is bool && stripeActive) {
      final normalizedStripeTier =
          stripeTier?.toString().toLowerCase().trim() ?? '';
      if (_premiumLevels.contains(normalizedStripeTier)) {
        return true;
      }
    }

    final fallbackTier = appMetadata['subscription'] ??
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
    required this.expiresAt,
  });

  final bool value;
  final DateTime expiresAt;

  bool isExpired() {
    return DateTime.now().toUtc().isAfter(expiresAt);
  }
}
