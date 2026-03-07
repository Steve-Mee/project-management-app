import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/auth/auth_user.dart';
import 'package:pma_core/auth/role_models.dart';
import 'package:pma_core/repository/i_auth_repository.dart';

class InMemoryAuthRepository implements IAuthRepository {
  final Map<String, AppUser> _users = {};
  final Map<String, RoleDefinition> _roles = {
    'role_admin': const RoleDefinition(id: 'role_admin', name: 'Admin', permissions: []),
    'role_member': const RoleDefinition(id: 'role_member', name: 'Member', permissions: []),
    'role_viewer': const RoleDefinition(id: 'role_viewer', name: 'Viewer', permissions: []),
  };
  final Map<String, GroupDefinition> _groups = {};
  final Map<String, int> _failedAttempts = {};
  final StreamController<dynamic> _authStateController = StreamController<dynamic>.broadcast();

  String? _currentUser;

  @override
  String get adminRoleId => 'role_admin';

  @override
  String get defaultUserRoleId => 'role_member';

  @override
  String get viewerRoleId => 'role_viewer';

  @override
  Future<void> initialize() async {}

  @override
  List<AppUser> getUsers() => _users.values.toList();

  @override
  AppUser? getUserByUsername(String username) => _users[username.trim()];

  @override
  List<RoleDefinition> getRoles() => _roles.values.toList();

  @override
  RoleDefinition? getRoleById(String roleId) => _roles[roleId];

  @override
  Future<void> upsertRole(RoleDefinition role) async {
    _roles[role.id] = role;
  }

  @override
  Future<void> deleteRole(String roleId) async {
    _roles.remove(roleId);
  }

  @override
  List<GroupDefinition> getGroups() => _groups.values.toList();

  @override
  GroupDefinition? getGroupById(String groupId) => _groups[groupId];

  @override
  List<GroupDefinition> getGroupsForUser(String username) {
    return _groups.values.where((g) => g.members.contains(username)).toList();
  }

  @override
  Future<void> upsertGroup(GroupDefinition group) async {
    _groups[group.id] = group;
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    _groups.remove(groupId);
  }

  @override
  Future<void> addUserToGroup(String groupId, String username) async {
    final group = _groups[groupId];
    if (group == null) {
      return;
    }
    if (group.members.contains(username)) {
      return;
    }
    _groups[groupId] = group.copyWith(members: [...group.members, username]);
  }

  @override
  Future<void> removeUserFromGroup(String groupId, String username) async {
    final group = _groups[groupId];
    if (group == null) {
      return;
    }
    _groups[groupId] = group.copyWith(
      members: group.members.where((m) => m != username).toList(),
    );
  }

  @override
  Future<void> updateUserRole(String username, String roleId) async {
    final user = _users[username];
    if (user == null) {
      return;
    }
    _users[username] = AppUser(
      username: user.username,
      password: user.password,
      roleId: roleId,
    );
  }

  @override
  Future<void> addUser(AppUser user) async {
    _users[user.username] = user;
  }

  @override
  Future<void> deleteUser(String username) async {
    _users.remove(username);
    if (_currentUser == username) {
      _currentUser = null;
      _authStateController.add(null);
    }
  }

  @override
  AppUser? validateUser(String username, String password) {
    final user = _users[username.trim()];
    if (user == null) {
      return null;
    }
    return user.password == password ? user : null;
  }

  @override
  String? getCurrentUser() => _currentUser;

  @override
  Future<void> setCurrentUser(String? username) async {
    _currentUser = username?.trim().isEmpty ?? true ? null : username?.trim();
    _authStateController.add(_currentUser);
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<bool> login(String email, String password) async {
    final user = validateUser(email.trim(), password);
    if (user == null) {
      await recordFailedLoginAttempt(email.trim().toLowerCase());
      return false;
    }
    _currentUser = user.username;
    await resetLoginAttempts(email.trim().toLowerCase());
    _authStateController.add(_currentUser);
    return true;
  }

  @override
  Future<void> register(String email, String password) async {
    _users[email.trim()] = AppUser(
      username: email.trim(),
      password: password,
      roleId: defaultUserRoleId,
    );
  }

  @override
  Future<void> inviteUser(String email) async {}

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<bool> isLoggedIn() async => _currentUser != null;

  @override
  Future<bool> canAttemptLogin(String identifier) async {
    return (_failedAttempts[identifier] ?? 0) < 5;
  }

  @override
  Future<void> recordFailedLoginAttempt(String identifier) async {
    _failedAttempts[identifier] = (_failedAttempts[identifier] ?? 0) + 1;
  }

  @override
  Future<bool> isLoginBlocked(String email) async {
    return (_failedAttempts[email] ?? 0) >= 5;
  }

  @override
  Future<void> recordLoginAttempt(String email) async {
    await recordFailedLoginAttempt(email);
  }

  @override
  Future<void> resetLoginAttempts(String email) async {
    _failedAttempts.remove(email);
  }

  @override
  dynamic getCurrentSession() {
    return _currentUser == null ? null : {'user': _currentUser};
  }

  @override
  Stream<dynamic> get onAuthStateChange => _authStateController.stream;

  @override
  Future<void> recoverSession() async {}

  Future<void> close() async {
    await _authStateController.close();
  }
}

void runAuthRepositorySessionContract(
  String label,
  Future<IAuthRepository> Function() createRepository,
) {
  group('IAuthRepository session contract: $label', () {
    late IAuthRepository repository;

    setUp(() async {
      repository = await createRepository();
      await repository.initialize();
      await repository.register('alice@example.com', 'secret');
    });

    tearDown(() async {
      if (repository is InMemoryAuthRepository) {
        await (repository as InMemoryAuthRepository).close();
      }
    });

    test('login sets current user and logged-in state', () async {
      final ok = await repository.login('alice@example.com', 'secret');

      expect(ok, isTrue);
      expect(await repository.isLoggedIn(), isTrue);
      expect(repository.getCurrentUser(), 'alice@example.com');
      expect(repository.getCurrentSession(), isNotNull);
    });

    test('logout clears session and current user', () async {
      await repository.login('alice@example.com', 'secret');
      await repository.logout();

      expect(await repository.isLoggedIn(), isFalse);
      expect(repository.getCurrentUser(), isNull);
      expect(repository.getCurrentSession(), isNull);
    });

    test('setCurrentUser roundtrip persists user identity', () async {
      await repository.setCurrentUser('manual@example.com');
      expect(repository.getCurrentUser(), 'manual@example.com');

      await repository.setCurrentUser(null);
      expect(repository.getCurrentUser(), isNull);
    });

    test('auth state stream emits changes for login/logout', () async {
      final events = <dynamic>[];
      final sub = repository.onAuthStateChange.listen(events.add);
      addTearDown(sub.cancel);

      await repository.login('alice@example.com', 'secret');
      await repository.logout();

      await Future<void>.delayed(const Duration(milliseconds: 1));
      expect(events, isNotEmpty);
      expect(events.last, isNull);
    });

    test('inviteUser and resetPassword contract methods are callable', () async {
      await repository.inviteUser('alice@example.com');
      await repository.resetPassword('alice@example.com');
    });
  });
}

void main() {
  runAuthRepositorySessionContract(
    'in-memory implementation',
    () async => InMemoryAuthRepository(),
  );
}
