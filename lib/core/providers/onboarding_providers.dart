import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/auth_providers.dart' show settingsRepositoryProvider;

/// Riverpod provider for issue #067 onboarding flow state.
///
/// Persists a simple first-launch flag in shared_preferences:
/// - key: onboardingCompleted
/// - default: false
final onboardingProvider = NotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);

class OnboardingNotifier extends Notifier<bool> {
  static const String _onboardingCompletedKey = 'onboardingCompleted';

  SharedPreferences? _prefs;
  bool _didStartInitialization = false;

  @override
  bool build() {
    // Issue #067: default to false until persisted value is loaded.
    unawaited(_initializeFromStorage());
    return false;
  }

  Future<void> _initializeFromStorage() async {
    if (_didStartInitialization) {
      return;
    }
    _didStartInitialization = true;

    // Keep initialization order consistent with other app preferences.
    try {
      await ref.read(settingsRepositoryProvider.future);
    } catch (_) {
      // Onboarding persistence should still work even if settings init fails.
    }

    _prefs ??= await SharedPreferences.getInstance();
    final completed = _prefs!.getBool(_onboardingCompletedKey) ?? false;
    if (state != completed) {
      state = completed;
    }
  }

  /// Marks onboarding as completed and persists it immediately.
  Future<void> markOnboardingCompleted() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_onboardingCompletedKey, true);
    state = true;
  }

  /// Returns true only for first launch (when onboarding is not completed).
  Future<bool> isFirstLaunch() async {
    _prefs ??= await SharedPreferences.getInstance();
    final completed = _prefs!.getBool(_onboardingCompletedKey) ?? false;

    if (state != completed) {
      state = completed;
    }

    return !completed;
  }
}
