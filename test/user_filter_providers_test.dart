import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_project_management_app/core/providers/auth_providers.dart';
import 'package:my_project_management_app/core/repository/settings_repository.dart';
import 'package:my_project_management_app/core/repository/i_auth_repository.dart';
import 'package:my_project_management_app/core/auth/auth_user.dart';
import 'package:my_project_management_app/core/auth/role_models.dart';

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
    _users.where((u) => u.username == username).firstOrNull;

  @override
  List<RoleDefinition> getRoles() => [
    const RoleDefinition(id: 'role_admin', name: 'Admin', permissions: []),
    const RoleDefinition(id: 'role_member', name: 'Member', permissions: []),
    const RoleDefinition(id: 'role_viewer', name: 'Viewer', permissions: []),
  ];

  @override
  RoleDefinition? getRoleById(String roleId) => 
    getRoles().where((r) => r.id == roleId).firstOrNull;

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

// Fake settings repository
class FakeSettingsRepository extends Fake implements SettingsRepository {
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
  late FakeSettingsRepository fakeSettings;
  late ProviderContainer container;

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

    test('authUsersProvider returns all users', () async {
      final usersAsync = testContainer.read(authUsersProvider);
      expect(usersAsync, isA<AsyncValue<List<AppUser>>>());
      
      final users = usersAsync.value;
      expect(users?.length, 6);
      expect(users?.map((u) => u.username), containsAll(['admin_user', 'member_one', 'member_two', 'viewer_user', 'john_doe', 'jane_smith']));
    });

    test('searchUsersProvider returns all users for empty query', () {
      final users = testContainer.read(searchUsersProvider(''));
      expect(users.length, 6);
    });

    test('searchUsersProvider filters users by username (case insensitive)', () {
      // Search for 'member' should find member_one and member_two
      final users = testContainer.read(searchUsersProvider('member'));
      expect(users.length, 2);
      expect(users.map((u) => u.username), containsAll(['member_one', 'member_two']));
      
      // Search for 'JOHN' should find john_doe (case insensitive)
      final johnUsers = testContainer.read(searchUsersProvider('JOHN'));
      expect(johnUsers.length, 1);
      expect(johnUsers.first.username, 'john_doe');
      
      // Search for 'smith' should find jane_smith
      final smithUsers = testContainer.read(searchUsersProvider('smith'));
      expect(smithUsers.length, 1);
      expect(smithUsers.first.username, 'jane_smith');
    });

    test('searchUsersProvider returns empty list when no matches', () {
      final users = testContainer.read(searchUsersProvider('nonexistent'));
      expect(users, isEmpty);
    });

    test('filteredUsersProvider returns all users for empty filter', () {
      final filter = const UsersFilter();
      final users = testContainer.read(filteredUsersProvider(filter));
      expect(users.length, 6);
    });

    test('filteredUsersProvider filters by role', () {
      // Filter for admin role
      final adminFilter = const UsersFilter(role: 'role_admin');
      final adminUsers = testContainer.read(filteredUsersProvider(adminFilter));
      expect(adminUsers.length, 2);
      expect(adminUsers.map((u) => u.username), containsAll(['admin_user', 'jane_smith']));
      
      // Filter for member role
      final memberFilter = const UsersFilter(role: 'role_member');
      final memberUsers = testContainer.read(filteredUsersProvider(memberFilter));
      expect(memberUsers.length, 3);
      expect(memberUsers.map((u) => u.username), containsAll(['member_one', 'member_two', 'john_doe']));
      
      // Filter for viewer role
      final viewerFilter = const UsersFilter(role: 'role_viewer');
      final viewerUsers = testContainer.read(filteredUsersProvider(viewerFilter));
      expect(viewerUsers.length, 1);
      expect(viewerUsers.first.username, 'viewer_user');
    });

    test('filteredUsersProvider filters by search query (case insensitive)', () {
      // Search for 'jane'
      final janeFilter = const UsersFilter(searchQuery: 'jane');
      final janeUsers = testContainer.read(filteredUsersProvider(janeFilter));
      expect(janeUsers.length, 1);
      expect(janeUsers.first.username, 'jane_smith');
      
      // Search for 'MEMBER' (case insensitive)
      final memberSearchFilter = const UsersFilter(searchQuery: 'MEMBER');
      final memberSearchUsers = testContainer.read(filteredUsersProvider(memberSearchFilter));
      expect(memberSearchUsers.length, 2);
      expect(memberSearchUsers.map((u) => u.username), containsAll(['member_one', 'member_two']));
    });

    test('filteredUsersProvider combines search and role filters', () {
      // Search for 'member' and filter by role_member
      final combinedFilter = const UsersFilter(searchQuery: 'member', role: 'role_member');
      final combinedUsers = testContainer.read(filteredUsersProvider(combinedFilter));
      expect(combinedUsers.length, 2);
      expect(combinedUsers.map((u) => u.username), containsAll(['member_one', 'member_two']));
      
      // Search for 'john' and filter by role_admin (should return empty)
      final conflictingFilter = const UsersFilter(searchQuery: 'john', role: 'role_admin');
      final conflictingUsers = testContainer.read(filteredUsersProvider(conflictingFilter));
      expect(conflictingUsers, isEmpty);
    });

    test('filteredUsersProvider handles status filter placeholder', () {
      // Status filtering is not implemented, so it should be ignored
      final statusFilter = const UsersFilter(status: 'active');
      final users = testContainer.read(filteredUsersProvider(statusFilter));
      expect(users.length, 6); // All users returned since status filter is ignored
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