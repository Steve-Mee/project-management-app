import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pma_core/services/app_logger.dart';
import 'package:pma_core/providers/auth/auth_providers.dart';
import 'package:pma_core/providers/settings/settings_providers.dart';

/// Payment status model
class PaymentStatus {
  final String status; // 'idle', 'processing', 'success', 'error'
  final String? message;
  final String? sessionId;
  final String? paymentIntentId;

  const PaymentStatus({
    required this.status,
    this.message,
    this.sessionId,
    this.paymentIntentId,
  });

  factory PaymentStatus.idle() => const PaymentStatus(status: 'idle');
  factory PaymentStatus.processing({String? message}) => PaymentStatus(status: 'processing', message: message);
  factory PaymentStatus.success({String? sessionId, String? paymentIntentId}) =>
      PaymentStatus(status: 'success', sessionId: sessionId, paymentIntentId: paymentIntentId);
  factory PaymentStatus.error(String message) => PaymentStatus(status: 'error', message: message);
}

/// Payment notifier for managing Stripe payment operations
class PaymentNotifier extends StateNotifier<AsyncValue<PaymentStatus>> {
  PaymentNotifier(this._ref) : super(AsyncValue.data(PaymentStatus.idle()));

  final Ref _ref;

  /// Create a checkout session
  /// In production, this should call your backend API to create the session
  Future<String> createCheckoutSession({
    required int amount,
    required String currency,
    required String product,
  }) async {
    state = AsyncValue.data(PaymentStatus.processing(message: 'Creating checkout session...'));

    try {
      // For demo purposes, simulate creating a session
      final sessionId = 'demo_session_${DateTime.now().millisecondsSinceEpoch}';

      // Example backend call (uncomment when backend is ready):
      // final response = await http.post(
      //   Uri.parse('https://your-backend.com/create-checkout-session'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'amount': amount,
      //     'currency': currency,
      //     'product': product,
      //   }),
      // );
      // final sessionData = jsonDecode(response.body);
      // final sessionId = sessionData['id'];

      state = AsyncValue.data(PaymentStatus.success(sessionId: sessionId));

      AppLogger.event('Created checkout session', params: {
        'sessionId': sessionId,
        'amount': amount,
        'currency': currency,
        'product': product,
      });

      // Start polling for session status updates
      pollSessionStatus(sessionId);

      return sessionId;
    } catch (e) {
      final errorMessage = 'Failed to create checkout session: $e';
      state = AsyncValue.data(PaymentStatus.error(errorMessage));
      AppLogger.instance.e(errorMessage, error: e);
      rethrow;
    }
  }

  /// Handle webhook payload (typically called from backend webhook handler)
  /// This is a simplified implementation - in production, webhooks should be
  /// handled server-side with proper signature verification
  Future<void> handleWebhook(Map<String, dynamic> payload) async {
    try {
      final eventType = payload['type'] as String?;
      final eventData = payload['data'] as Map<String, dynamic>?;

      AppLogger.event('Processing webhook', params: {
        'eventType': eventType,
        'hasData': eventData != null,
      });

      switch (eventType) {
        case 'checkout.session.completed':
          final session = eventData?['object'] as Map<String, dynamic>?;
          final sessionId = session?['id'] as String?;
          if (sessionId != null) {
            state = AsyncValue.data(PaymentStatus.success(sessionId: sessionId));
            AppLogger.event('Checkout session completed', params: {'sessionId': sessionId});
          }
          break;

        case 'payment_intent.succeeded':
          final paymentIntent = eventData?['object'] as Map<String, dynamic>?;
          final paymentIntentId = paymentIntent?['id'] as String?;
          if (paymentIntentId != null) {
            state = AsyncValue.data(PaymentStatus.success(paymentIntentId: paymentIntentId));
            AppLogger.event('Payment intent succeeded', params: {'paymentIntentId': paymentIntentId});
          }
          break;

        case 'payment_intent.payment_failed':
          final paymentIntent = eventData?['object'] as Map<String, dynamic>?;
          final lastPaymentError = paymentIntent?['last_payment_error'] as Map<String, dynamic>?;
          final errorMessage = lastPaymentError?['message'] as String? ?? 'Payment failed';
          state = AsyncValue.data(PaymentStatus.error(errorMessage));
          AppLogger.warning('Payment failed', params: {'error': errorMessage});
          break;

        default:
          AppLogger.debug('Unhandled webhook event type', params: {'eventType': eventType});
      }
    } catch (e) {
      AppLogger.instance.e('Error processing webhook', error: e);
    }
  }

  /// Poll for session status updates (for demo purposes when webhooks aren't available)
  Future<void> pollSessionStatus(String sessionId) async {
    // In production, this would poll your backend API for session status
    // For demo, we'll simulate success after a delay
    await Future.delayed(const Duration(seconds: 2));

    // Simulate success for demo
    await _handlePaymentSuccess('Premium');
  }

  /// Handle successful payment and update subscription
  Future<void> _handlePaymentSuccess(String subscriptionLevel) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Real backend call – controlled by enableRealPaymentBackend flag (default: false)
      final service = _ref.read(paymentBackendServiceProvider);
      await service.updateSubscriptionAfterPayment(
        userId,
        subscriptionLevel,
        'demo_transaction_${DateTime.now().millisecondsSinceEpoch}', // TODO: Pass real transaction ID from webhook
      );

      // Update token limits
      final tokenLimit = subscriptionLevel == 'PremiumPlus' ? 100000 : 10000;
      await supabase.from('user_tokens').upsert({
        'user_id': userId,
        'total_tokens': tokenLimit,
        'monthly_tokens': tokenLimit,
        'last_reset': DateTime.now().toIso8601String(),
      });

      // Persist subscription level in settings for offline access
      final settings = await _ref.read(settingsRepositoryProvider.future);
      await settings.setSubscriptionLevel(subscriptionLevel);

      state = AsyncValue.data(PaymentStatus.success());

      AppLogger.event('subscription_updated', params: {
        'userId': userId,
        'level': subscriptionLevel,
      });

      // Refresh auth state to reflect subscription changes
      _ref.invalidate(authProvider);

    } catch (e) {
      final errorMessage = 'Failed to update subscription: $e';
      state = AsyncValue.data(PaymentStatus.error(errorMessage));
      AppLogger.instance.e(errorMessage, error: e);
    }
  }

  /// Retry payment operation
  Future<void> retryPayment({
    required int amount,
    required String currency,
    required String product,
  }) async {
    await createCheckoutSession(
      amount: amount,
      currency: currency,
      product: product,
    );
  }
}

/// Provider for payment operations
final paymentProvider = StateNotifierProvider<PaymentNotifier, AsyncValue<PaymentStatus>>((ref) {
  return PaymentNotifier(ref);
});

/// Provider for render credits tied to Stripe/Premium subscription state.
///
/// Primary source: `user_tokens.render_credits`.
/// Fallback source: cached subscription level from settings.
final renderCreditsProvider = FutureProvider<int>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) {
    return 0;
  }

  try {
    final row = await supabase
        .from('user_tokens')
        .select('render_credits')
        .eq('user_id', userId)
        .maybeSingle();

    final credits = _coerceInt(row?['render_credits']);
    if (credits != null) {
      return credits;
    }
  } catch (error, stackTrace) {
    AppLogger.instance.w(
      'render_credits_primary_lookup_failed',
      error: error,
      stackTrace: stackTrace,
    );
  }

  try {
    final settings = await ref.watch(settingsRepositoryProvider.future);
    final subscriptionLevel = settings.getSubscriptionLevel();
    return _defaultRenderCreditsForSubscription(subscriptionLevel);
  } catch (error, stackTrace) {
    AppLogger.instance.w(
      'render_credits_fallback_lookup_failed',
      error: error,
      stackTrace: stackTrace,
    );
    return _defaultRenderCreditsForSubscription(null);
  }
});

int _defaultRenderCreditsForSubscription(String? subscriptionLevel) {
  final normalized = (subscriptionLevel ?? 'free').trim().toLowerCase();
  switch (normalized) {
    case 'premiumplus':
    case 'premium_plus':
      return 300;
    case 'premium':
      return 75;
    case 'free':
    default:
      return 10;
  }
}

int? _coerceInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value.trim());
  }
  return null;
}
