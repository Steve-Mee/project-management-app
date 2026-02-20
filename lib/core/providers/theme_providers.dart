import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// settings repository is used by the theme notifier to persist the theme mode
import 'package:my_project_management_app/core/repository/settings_repository.dart';
import 'auth_providers.dart';


/// Notifier for managing theme mode state
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final settingsAsync = ref.watch(settingsRepositoryProvider);
    return settingsAsync.maybeWhen(
      data: (settings) => settings.getThemeMode() ?? ThemeMode.system,
      orElse: () => ThemeMode.system,
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    ref
        .read(settingsRepositoryProvider.future)
        .then((settings) => settings.setThemeMode(mode));
  }
}

/// Provider for managing theme mode across the application
/// Supports: ThemeMode.system (default), ThemeMode.dark, ThemeMode.light
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Provider for checking if dark mode is currently active
/// Returns true if the app is in dark mode (either system dark or explicitly set to dark)
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  if (themeMode == ThemeMode.dark) {
    return true;
  } else if (themeMode == ThemeMode.light) {
    return false;
  } else {
    return true; // Default to dark for system mode
  }
});

/// Locale selection notifier (null = system locale)
class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final settingsAsync = ref.watch(settingsRepositoryProvider);
    return settingsAsync.maybeWhen(
      data: (settings) {
        final code = settings.getLocaleCode();
        return code == null ? null : Locale(code);
      },
      orElse: () => null,
    );
  }

  void setLocaleCode(String? localeCode) {
    state = localeCode == null ? null : Locale(localeCode);
    ref
        .read(settingsRepositoryProvider.future)
        .then((settings) => settings.setLocaleCode(localeCode));
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

/// Global search query notifier used by search boxes
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) {
    state = value;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

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

final notificationsProvider = NotifierProvider<NotificationsNotifier, bool>(
  NotificationsNotifier.new,
);
