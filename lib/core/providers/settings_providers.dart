import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';
import '../services/payment_backend_service.dart';

/// Notifier for managing real payment backend toggle
class EnableRealPaymentBackendNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final settings = await ref.watch(settingsRepositoryProvider.future);
    return settings.getEnableRealPaymentBackend();
  }

  Future<void> setEnableRealPaymentBackend(bool enabled) async {
    state = AsyncValue.data(enabled);
    final settings = await ref.read(settingsRepositoryProvider.future);
    await settings.setEnableRealPaymentBackend(enabled);
  }
}

/// Provider for managing real payment backend toggle
/// Controls whether to use real Stripe backend API calls or demo mode
final enableRealPaymentBackendProvider = AsyncNotifierProvider<EnableRealPaymentBackendNotifier, bool>(
  EnableRealPaymentBackendNotifier.new,
);

/// Provider for PaymentBackendService
/// Injects the service with the current backend toggle setting
final paymentBackendServiceProvider = Provider<PaymentBackendService>((ref) {
  final useRealBackend = ref.watch(enableRealPaymentBackendProvider).maybeWhen(
    data: (enabled) => enabled,
    orElse: () => false, // Default to false if not loaded yet
  );
  return PaymentBackendService(useRealBackend: useRealBackend);
});