import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// settings repository is used by the theme notifier to persist the theme mode
import 'auth_providers.dart';


/// Notifier for managing theme mode state
class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final settings = await ref.watch(settingsRepositoryProvider.future);
    return settings.getThemeMode() ?? ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncValue.data(mode);
    final settings = await ref.read(settingsRepositoryProvider.future);
    await settings.setThemeMode(mode);
  }
}

/// Provider for managing theme mode across the application
/// Supports: ThemeMode.system (default), ThemeMode.dark, ThemeMode.light
final themeModeProvider = AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Provider for checking if dark mode is currently active
/// Returns true if the app is in dark mode (either system dark or explicitly set to dark)
final isDarkModeProvider = Provider<bool>((ref) {
  final themeModeAsync = ref.watch(themeModeProvider);
  return themeModeAsync.maybeWhen(
    data: (themeMode) {
      if (themeMode == ThemeMode.dark) {
        return true;
      } else if (themeMode == ThemeMode.light) {
        return false;
      } else {
        return true; // Default to dark for system mode
      }
    },
    orElse: () => true,
  );
});

/// Locale selection notifier (null = system locale)
class LocaleNotifier extends AsyncNotifier<Locale?> {
  @override
  Future<Locale?> build() async {
    final settings = await ref.watch(settingsRepositoryProvider.future);
    final code = settings.getLocaleCode();
    return code == null ? null : Locale(code);
  }

  Future<void> setLocaleCode(String? localeCode) async {
    state = AsyncValue.data(localeCode == null ? null : Locale(localeCode));
    final settings = await ref.read(settingsRepositoryProvider.future);
    await settings.setLocaleCode(localeCode);
  }
}

final localeProvider = AsyncNotifierProvider<LocaleNotifier, Locale?>(
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


