import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_project_management_app/core/providers/auth_providers.dart';
import 'package:my_project_management_app/core/repository/settings_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Fake box for testing
class FakeBox implements Box<List<DateTime>> {
  final Map<String, List<DateTime>> _map = {};
  final List<List<DateTime>> putCalls = [];

  @override
  List<DateTime>? get(dynamic key, {List<DateTime>? defaultValue}) => _map[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, List<DateTime> value) async {
    _map[key] = value;
    putCalls.add(value);
  }

  // Implement minimal required methods
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestAuthNotifier extends AuthNotifier {
  TestAuthNotifier(this.testBox);

  final Box<List<DateTime>> testBox;

  @override
  Future<AuthState> build() async {
    attemptsBox = testBox;
    return const AuthState(isAuthenticated: false);
  }

  // Override login to simulate success without Supabase
  @override
  Future<bool> login(String username, String password, {bool enableAutoLogin = false}) async {
    final attempts = await loadFailedAttempts(username);
    if (!canAttemptLogin(attempts)) {
      throw RateLimitExceededException(getBackoffTime(attempts)!);
    }
    // Simulate success
    await resetAttempts(username);
    return true;
  }
}

// Fake classes
class FakeSettingsRepository extends Fake implements SettingsRepository {
  bool _enableBiometricLogin = false;

  @override
  bool getEnableBiometricLogin() => _enableBiometricLogin;

  @override
  Future<void> setEnableBiometricLogin(bool enabled) async {
    _enableBiometricLogin = enabled;
  }

  // Implement other methods as needed, but for minimal, only the used ones
  @override
  Future<void> initialize() async {}

  @override
  ThemeMode? getThemeMode() => null;

  @override
  Future<void> setThemeMode(ThemeMode mode) async {}

  @override
  bool? getNotificationsEnabled() => null;

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {}

  @override
  String? getLocaleCode() => null;

  @override
  Future<void> setLocaleCode(String? localeCode) async {}

  @override
  DateTime? getLastBackupTime() => null;

  @override
  Future<void> setLastBackupTime(DateTime timestamp) async {}

  @override
  String? getLastBackupPath() => null;

  @override
  Future<void> setLastBackupPath(String path) async {}

  @override
  bool getAutoLoginEnabled() => false;

  @override
  Future<void> setAutoLoginEnabled(bool enabled) async {}

  @override
  DateTime? getLastLoginTime() => null;

  @override
  Future<void> setLastLoginTime(DateTime time) async {}

  @override
  String? getHelpLevel() => null;

  @override
  Future<void> setHelpLevel(String level) async {}

  @override
  bool getAiConsentEnabled() => false;

  @override
  Future<void> setAiConsentEnabled(bool enabled) async {}

  @override
  bool getUseBiometricsEnabled() => false;

  @override
  Future<void> setUseBiometricsEnabled(bool enabled) async {}
}

void main() {
  late ProviderContainer container;
  late FakeSettingsRepository fakeSettings;

  setUp(() {
    fakeSettings = FakeSettingsRepository();

    container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettings)),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('BiometricLoginNotifier', () {
    test('build returns false when settings return false', () {
      fakeSettings._enableBiometricLogin = false;

      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettings)),
        ],
      );

      final notifier = container.read(biometricLoginProvider.notifier);
      expect(notifier.state, false);
      container.dispose();
    });

    test('setEnabled updates state and calls settings', () async {
      final notifier = container.read(biometricLoginProvider.notifier);
      await notifier.setEnabled(true);

      expect(notifier.state, true);
      expect(fakeSettings._enableBiometricLogin, true);
    });
  });

  group('Biometric Authentication Methods', () {
    // Note: Full testing of AuthNotifier methods (isBiometricAvailable, authenticateWithBiometrics, enrollBiometrics)
    // requires mocking LocalAuthentication, FlutterSecureStorage, and platform checks.
    // For minimal changes, we cover the feature flag logic above.
    // The methods are tested implicitly through integration in the app.
  });

  group('Rate Limiting', () {
    late FakeBox fakeBox;

    setUp(() {
      fakeBox = FakeBox();
    });

    test('allows login with less than 5 attempts in 60s', () async {
      fakeBox._map['test@example.com'] = [DateTime.now().subtract(const Duration(seconds: 30))];

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => TestAuthNotifier(fakeBox)),
        ],
      );

      final notifier = container.read(authProvider.notifier);
      expect(await notifier.login('test@example.com', 'password'), true);
      expect(fakeBox.putCalls, [<DateTime>[]]);
      container.dispose();
    });

    test('blocks login with 5+ attempts and throws RateLimitExceededException', () async {
      final attempts = List.generate(5, (i) => DateTime.now().subtract(Duration(seconds: i * 10)));
      fakeBox._map['test@example.com'] = attempts;

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => TestAuthNotifier(fakeBox)),
        ],
      );

      final notifier = container.read(authProvider.notifier);
      expect(() async => await notifier.login('test@example.com', 'password'), throwsA(isA<RateLimitExceededException>()));
      expect(fakeBox.putCalls, isEmpty);
      container.dispose();
    });

    test('cleans attempts older than 60s', () async {
      final oldAttempt = DateTime.now().subtract(const Duration(seconds: 70));
      final newAttempt = DateTime.now().subtract(const Duration(seconds: 30));
      fakeBox._map['test@example.com'] = [oldAttempt, newAttempt];

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => TestAuthNotifier(fakeBox)),
        ],
      );

      final notifier = container.read(authProvider.notifier);
      await notifier.login('test@example.com', 'password');
      expect(fakeBox.putCalls.length, 2);
      expect(fakeBox.putCalls[0], [newAttempt]);
      expect(fakeBox.putCalls[1], <DateTime>[]);
      container.dispose();
    });

    test('successful login clears attempts', () async {
      fakeBox._map['test@example.com'] = [DateTime.now()];

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => TestAuthNotifier(fakeBox)),
        ],
      );

      final notifier = container.read(authProvider.notifier);
      await notifier.login('test@example.com', 'password');
      expect(fakeBox.putCalls, [<DateTime>[]]);
      container.dispose();
    });
  });
}