import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/app_logger.dart';

/// Service for handling payment backend operations
/// Supports both mock mode and real backend calls
class PaymentBackendService {
  final bool useRealBackend;

  PaymentBackendService({required this.useRealBackend});

  /// Update subscription after successful payment
  Future<void> updateSubscriptionAfterPayment(
    String userId,
    String subscriptionLevel,
    String transactionId,
  ) async {
    if (!useRealBackend) {
      // mock / local storage fallback
      AppLogger.debug('PaymentBackendService: Mock mode - subscription update skipped', params: {
        'userId': userId,
        'subscriptionLevel': subscriptionLevel,
        'transactionId': transactionId,
      });
      return;
    }

    // REAL backend call here (Supabase Edge Function or direct table update)
    AppLogger.event('PaymentBackendService: Updating subscription via real backend', params: {
      'userId': userId,
      'subscriptionLevel': subscriptionLevel,
      'transactionId': transactionId,
    });

    // Example: await supabase.functions.invoke('stripe-webhook-complete', body: {...});
    final supabase = Supabase.instance.client;

    await supabase.from('subscriptions').upsert({
      'user_id': userId,
      'level': subscriptionLevel,
      'status': 'active',
      'transaction_id': transactionId,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}