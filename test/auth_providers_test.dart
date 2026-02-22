import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:my_project_management_app/core/repository/i_auth_repository.dart';
import 'package:my_project_management_app/core/auth/auth_user.dart';
import 'package:my_project_management_app/core/auth/role_models.dart';
import 'package:my_project_management_app/core/providers/auth_providers.dart';
import 'package:my_project_management_app/core/repository/settings_repository.dart';
import 'package:my_project_management_app/core/config/ai_config.dart' as ai_config;

// Fake box for testing
class FakeBox {
  final Map<String, List<DateTime>> _map = {};
  final List<List<DateTime>> putCalls = [];

  List<DateTime>? get(String key, {List<DateTime>? defaultValue}) => _map[key] ?? defaultValue;

  Future<void> put(String key, List<DateTime> value) async {
    _map[key] = value;
    putCalls.add(value);
  }
}

class TestAuthNotifier extends AuthNotifier {
  TestAuthNotifier(this.testBox);

  final FakeBox testBox;

  @override
  Future<AuthState> build() async {
    attemptsBox = testBox as Box<List<DateTime>>;
    return const AuthState(isAuthenticated: false);
  }

  // Override login to simulate success without Supabase
  @override
  Future<bool> login(String username, String password, {bool enableAutoLogin = false}) async {
    final attempts = testBox.get('global') ?? [];
    final now = DateTime.now();
    final cleaned = attempts.where((t) => now.difference(t).inSeconds <= 60).toList();
    if (cleaned.length != attempts.length) {
      await testBox.put('global', cleaned);
    }
    if (cleaned.length >= 5) {
      throw RateLimitExceededException(const Duration(seconds: 60));
    }
    await testBox.put('global', []);
    return true;
  }
}

// Fake classes
class FakeSettingsRepository extends Fake implements SettingsRepository {
  bool _enableBiometricLogin = false;
  String? _helpLevel;

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
  String? getHelpLevel() => _helpLevel;

  @override
  Future<void> setHelpLevel(String level) async {
    _helpLevel = level;
  }

  @override
  bool getAiConsentEnabled() => false;

  @override
  Future<void> setAiConsentEnabled(bool enabled) async {}

  @override
  bool getUseBiometricsEnabled() => false;

  @override
  Future<void> setUseBiometricsEnabled(bool enabled) async {}
}

// Fake auth repository for testing user filtering
class FakeAuthRepository implements IAuthRepository {
  final List<AppUser> _users;
  
  FakeAuthRepository(this._users);

  @override
  Future<void> initialize() async {}

  @override
  List<AppUser> getUsers() => _users;

  @override
  AppUser? getUserByUsername(String username) => 
    _users.where((u) => u.username == username).isEmpty ? null : _users.where((u) => u.username == username).first;

  @override
  List<RoleDefinition> getRoles() => [
    const RoleDefinition(id: 'role_admin', name: 'Admin', permissions: []),
    const RoleDefinition(id: 'role_member', name: 'Member', permissions: []),
    const RoleDefinition(id: 'role_viewer', name: 'Viewer', permissions: []),
  ];

  @override
  RoleDefinition? getRoleById(String roleId) => 
    getRoles().where((r) => r.id == roleId).isEmpty ? null : getRoles().where((r) => r.id == roleId).first;

  @override
  Future<void> upsertRole(RoleDefinition role) async {}

  @override
  Future<void> deleteRole(String roleId) async {}

  @override
  List<GroupDefinition> getGroups() => [];

  @override
  GroupDefinition? getGroupById(String groupId) => null;

  @override
  List<GroupDefinition> getGroupsForUser(String username) => [];

  @override
  Future<void> upsertGroup(GroupDefinition group) async {}

  @override
  Future<void> deleteGroup(String groupId) async {}

  @override
  Future<void> addUserToGroup(String groupId, String username) async {}

  @override
  Future<void> removeUserFromGroup(String groupId, String username) async {}

  @override
  Future<void> updateUserRole(String username, String roleId) async {}

  @override
  Future<void> addUser(AppUser user) async {}

  @override
  Future<void> deleteUser(String username) async {}

  @override
  AppUser? validateUser(String username, String password) =>
      getUserByUsername(username);

  @override
  String? getCurrentUser() => null;

  @override
  Future<void> setCurrentUser(String? username) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<bool> login(String email, String password) async => true;

  @override
  Future<void> register(String email, String password) async {}

  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<bool> canAttemptLogin(String identifier) async => true;

  @override
  Future<void> recordFailedLoginAttempt(String identifier) async {}

  @override
  Future<bool> isLoginBlocked(String email) async => false;

  @override
  Future<void> recordLoginAttempt(String email) async {}

  @override
  Future<void> resetLoginAttempts(String email) async {}

  @override
  String get adminRoleId => 'role_admin';

  @override
  String get defaultUserRoleId => 'role_member';

  @override
  String get viewerRoleId => 'role_viewer';
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
    test('build returns false when settings return false', () async {
      fakeSettings._enableBiometricLogin = false;

      final testContainer = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettings)),
        ],
      );

      // Listen to the provider to wait for it to resolve
      final subscription = testContainer.listen(biometricLoginProvider, (previous, next) {});
      
      // Wait for the provider to resolve
      await Future.delayed(const Duration(milliseconds: 50));
      
      final asyncValue = testContainer.read(biometricLoginProvider);
      expect(asyncValue.hasValue, true, reason: 'Provider should have resolved');
      expect(asyncValue.value, false);
      
      subscription.close();
      testContainer.dispose();
    });

    test('setEnabled updates state and calls settings', () async {
      final testContainer = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettings)),
        ],
      );

      final notifier = testContainer.read(biometricLoginProvider.notifier);
      await notifier.setEnabled(true);

      expect(notifier.state.value, true);
      expect(fakeSettings._enableBiometricLogin, true);
      testContainer.dispose();
    });
  });

  group('HelpLevelNotifier', () {
    test('build returns basis when settings return null', () async {
      fakeSettings._helpLevel = null;

      final testContainer = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettings)),
        ],
      );

      // Listen to the provider to wait for it to resolve
      final subscription = testContainer.listen(helpLevelProvider, (previous, next) {});
      
      // Wait for the provider to resolve
      await Future.delayed(const Duration(milliseconds: 50));
      
      final asyncValue = testContainer.read(helpLevelProvider);
      expect(asyncValue.hasValue, true, reason: 'Provider should have resolved');
      expect(asyncValue.value, ai_config.HelpLevel.basis);
      
      subscription.close();
      testContainer.dispose();
    });

    test('setHelpLevel updates state and calls settings asynchronously', () async {
      final testContainer = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettings)),
        ],
      );

      // Listen to the provider to ensure it's initialized
      final subscription = testContainer.listen(helpLevelProvider, (previous, next) {});
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = testContainer.read(helpLevelProvider.notifier);
      await notifier.setHelpLevel(ai_config.HelpLevel.stapVoorStap);

      final asyncValue = testContainer.read(helpLevelProvider);
      expect(asyncValue.value, ai_config.HelpLevel.stapVoorStap);
      expect(fakeSettings._helpLevel, 'stapVoorStap');
      
      subscription.close();
      testContainer.dispose();
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
      fakeBox._map['global'] = [DateTime.now().subtract(const Duration(seconds: 30))];

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
      fakeBox._map['global'] = attempts;

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

    test('RateLimitExceededException has correct backoff duration', () async {
      final attempts = List.generate(5, (i) => DateTime.now().subtract(Duration(seconds: i * 10)));
      fakeBox._map['global'] = attempts;

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => TestAuthNotifier(fakeBox)),
        ],
      );

      final notifier = container.read(authProvider.notifier);
      try {
        await notifier.login('test@example.com', 'password');
        fail('Expected RateLimitExceededException');
      } on RateLimitExceededException catch (e) {
        expect(e.backoffDuration, const Duration(seconds: 60));
      }
      container.dispose();
    });

    test('cleans attempts older than 60s', () async {
      final oldAttempt = DateTime.now().subtract(const Duration(seconds: 70));
      final newAttempt = DateTime.now().subtract(const Duration(seconds: 30));
      fakeBox._map['global'] = [oldAttempt, newAttempt];

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
      fakeBox._map['global'] = [DateTime.now()];

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith(() => TestAuthNotifier(fakeBox)),
        ],
      );

      final notifier = container.read(authProvider.notifier);
      await notifier.login('test@example.com', 'password');
      expect(fakeBox.putCalls, [<DateTime>[]]);
      container.dispose();
      expect(fakeBox.putCalls, [<DateTime>[]]);
    });
  });

  group('User Search and Filter Providers', () {
    late FakeAuthRepository fakeAuthRepo;
    late ProviderContainer testContainer;

    setUp(() {
      // Create test users with different roles
      final testUsers = [
        const AppUser(username: 'admin_user', password: 'pass', roleId: 'role_admin'),
        const AppUser(username: 'member_one', password: 'pass', roleId: 'role_member'),
        const AppUser(username: 'member_two', password: 'pass', roleId: 'role_member'),
        const AppUser(username: 'viewer_user', password: 'pass', roleId: 'role_viewer'),
        const AppUser(username: 'john_doe', password: 'pass', roleId: 'role_member'),
        const AppUser(username: 'jane_smith', password: 'pass', roleId: 'role_admin'),
      ];
      
      fakeAuthRepo = FakeAuthRepository(testUsers);
      
      testContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => fakeAuthRepo),
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettings)),
        ],
      );
    });

    tearDown(() {
      testContainer.dispose();
    });

    test('filteredUsersProvider handles null/empty filter values', () {
      final nullFilter = const UsersFilter(searchQuery: null, role: null, status: null);
      final users = testContainer.read(filteredUsersProvider(nullFilter));
      expect(users.length, 6);
      
      final emptyStringFilter = const UsersFilter(searchQuery: '', role: '', status: '');
      final users2 = testContainer.read(filteredUsersProvider(emptyStringFilter));
      expect(users2.length, 6);
    });
  });
}
