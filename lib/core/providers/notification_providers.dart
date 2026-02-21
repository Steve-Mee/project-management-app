/// Notification providers – part 3/4
/// All notification-related state is declared here, including services and
/// toggles.  Moving code from theme_providers and task_providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart'; // for settingsRepositoryProvider
import '../../core/services/notification_service.dart';

/// Provider for the notification service instance used throughout the app.
/// Originally defined alongside task providers because tasks schedule
/// notifications; it's now centralized here.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  service.initialize();
  return service;
});

/// Notifier for notifications toggle
class NotificationsNotifier extends Notifier<bool> {
  @override
  bool build() {
    final settingsAsync = ref.watch(settingsRepositoryProvider);
    return settingsAsync.maybeWhen(
      data: (settings) => settings.getNotificationsEnabled() ?? true,
      orElse: () => true,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final settings = await ref.read(settingsRepositoryProvider.future);
    await settings.setNotificationsEnabled(enabled);
  }
}

/// Whether notifications are enabled globally (settings toggle)
final notificationsProvider = NotifierProvider<NotificationsNotifier, bool>(
  NotificationsNotifier.new,
);

