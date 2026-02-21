import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_project_management_app/core/services/app_logger.dart';
import 'package:my_project_management_app/core/auth/permissions.dart';
import 'package:my_project_management_app/core/auth/role_models.dart';
import 'package:my_project_management_app/core/auth/auth_user.dart';
import 'package:my_project_management_app/core/repository/i_auth_repository.dart';

enum Role {
  admin,
  user,
}

/// Placeholder for future backend integration.
class RemoteAuthService {
  Future<void> signIn(String username, String password) async {
    AppLogger.instance.w('Remote auth sign-in not configured.');
  }

  Future<void> signOut() async {
    AppLogger.instance.w('Remote auth sign-out not configured.');
  }

  Future<void> registerUser(String username, String password) async {
    AppLogger.instance.w('Remote auth register not configured.');
  }
}

class AuthRepository implements IAuthRepository {
  static const String _boxName = 'auth';
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user';
  static const String _rolesKey = 'roles';
  static const String _groupsKey = 'groups';

  static const String adminRoleId = 'role_admin';
  static const String defaultUserRoleId = 'role_member';
  static const String viewerRoleId = 'role_viewer';

  final RemoteAuthService _remote;

  AuthRepository({RemoteAuthService? remote})
      : _remote = remote ?? RemoteAuthService();

  Future<void> initialize() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    await _seedRolesIfEmpty();
    await _seedDefaultsIfEmpty();
  }

  Box get _box => Hive.box(_boxName);

  List<AppUser> getUsers() {
    final raw = _box.get(_usersKey);
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((entry) => AppUser.fromMap(Map<String, dynamic>.from(entry)))
          .where((user) => user.username.isNotEmpty)
          .toList();
    }
    return [];
  }

  AppUser? getUserByUsername(String username) {
    final trimmed = username.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return null;
    }

    for (final user in getUsers()) {
      if (user.username.toLowerCase() == trimmed) {
        return user;
      }
    }
    return null;
  }

  List<RoleDefinition> getRoles() {
    final raw = _box.get(_rolesKey);
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((entry) => RoleDefinition.fromMap(Map<String, dynamic>.from(entry)))
          .where((role) => role.id.isNotEmpty)
          .toList();
    }
    return [];
  }

  RoleDefinition? getRoleById(String roleId) {
    for (final role in getRoles()) {
      if (role.id == roleId) {
        return role;
      }
    }
    return null;
  }

  Future<void> upsertRole(RoleDefinition role) async {
    final roles = getRoles();
    roles.removeWhere((item) => item.id == role.id);
    roles.add(role);
    await _box.put(
      _rolesKey,
      roles.map((entry) => entry.toMap()).toList(),
    );
  }

  Future<void> deleteRole(String roleId) async {
    if (roleId == adminRoleId || roleId == defaultUserRoleId) {
      return;
    }
    final roles = getRoles()..removeWhere((item) => item.id == roleId);
    await _box.put(
      _rolesKey,
      roles.map((entry) => entry.toMap()).toList(),
    );
  }

  List<GroupDefinition> getGroups() {
    final raw = _box.get(_groupsKey);
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((entry) => GroupDefinition.fromMap(Map<String, dynamic>.from(entry)))
          .where((group) => group.id.isNotEmpty)
          .toList();
    }
    return [];
  }

  GroupDefinition? getGroupById(String groupId) {
    for (final group in getGroups()) {
      if (group.id == groupId) {
        return group;
      }
    }
    return null;
  }

  List<GroupDefinition> getGroupsForUser(String username) {
    final trimmed = username.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return [];
    }
    return getGroups()
        .where(
          (group) => group.members
              .any((member) => member.toLowerCase() == trimmed),
        )
        .toList();
  }

  Future<void> upsertGroup(GroupDefinition group) async {
    final groups = getGroups();
    groups.removeWhere((item) => item.id == group.id);
    groups.add(group);
    await _box.put(
      _groupsKey,
      groups.map((entry) => entry.toMap()).toList(),
    );
  }

  Future<void> deleteGroup(String groupId) async {
    final groups = getGroups()..removeWhere((item) => item.id == groupId);
    await _box.put(
      _groupsKey,
      groups.map((entry) => entry.toMap()).toList(),
    );
  }

  Future<void> addUserToGroup(String groupId, String username) async {
    final group = getGroupById(groupId);
    if (group == null) {
      return;
    }
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      return;
    }
    if (group.members.any((member) => member.toLowerCase() == trimmed.toLowerCase())) {
      return;
    }

    await upsertGroup(
      group.copyWith(members: [...group.members, trimmed]),
    );
  }

  Future<void> removeUserFromGroup(String groupId, String username) async {
    final group = getGroupById(groupId);
    if (group == null) {
      return;
    }
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await upsertGroup(
      group.copyWith(
        members: group.members
            .where((member) => member.toLowerCase() != trimmed.toLowerCase())
            .toList(),
      ),
    );
  }

  Future<void> updateUserRole(String username, String roleId) async {
    final users = getUsers();
    final updated = users.map((user) {
      if (user.username.toLowerCase() == username.toLowerCase()) {
        return AppUser(
          username: user.username,
          password: user.password,
          roleId: roleId,
        );
      }
      return user;
    }).toList();

    await _box.put(
      _usersKey,
      updated.map((entry) => entry.toMap()).toList(),
    );
  }

  Future<void> addUser(AppUser user) async {
    // NOTE: Integreer Firebase Auth later; if (useRemote) { ... } else { local add }.
    final users = getUsers();
    final hashedPassword = _hashPassword(user.password);
    users.removeWhere(
      (existing) => existing.username.toLowerCase() == user.username.toLowerCase(),
    );
    users.add(
      AppUser(
        username: user.username,
        password: hashedPassword,
        roleId: user.roleId,
      ),
    );
    await _box.put(
      _usersKey,
      users.map((entry) => entry.toMap()).toList(),
    );
    // NOTE: Integreer Firebase Auth later; register remote user when online.
  }

  Future<void> deleteUser(String username) async {
    final users = getUsers();
    users.removeWhere(
      (existing) => existing.username.toLowerCase() == username.toLowerCase(),
    );
    await _box.put(
      _usersKey,
      users.map((entry) => entry.toMap()).toList(),
    );

    final current = getCurrentUser();
    if (current != null && current.toLowerCase() == username.toLowerCase()) {
      await setCurrentUser(null);
    }
  }

  AppUser? validateUser(String username, String password) {
    // NOTE: Integreer Firebase Auth later; if (useRemote) { ... } else { local validate }.
    final users = getUsers();
    final hashedPassword = _hashPassword(password);
    for (final user in users) {
      if (user.username == username && user.password == hashedPassword) {
        return user;
      }
      if (user.username == username && user.password == password) {
        _upgradeLegacyPassword(username, hashedPassword, users);
        return AppUser(
          username: user.username,
          password: hashedPassword,
          roleId: user.roleId,
        );
      }
    }
    return null;
  }

  String? getCurrentUser() {
    final value = _box.get(_currentUserKey);
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  Future<void> setCurrentUser(String? username) async {
    if (username == null || username.isEmpty) {
      await _box.delete(_currentUserKey);
      return;
    }
    await _box.put(_currentUserKey, username);
  }

  Future<void> logout() async {
    await _remote.signOut();
    await setCurrentUser(null);
  }

  // Implement IAuthRepository's small wrappers
  @override
  Future<bool> login(String email, String password) async {
    final validated = validateUser(email.trim(), password);
    if (validated != null) {
      await setCurrentUser(validated.username);
      return true;
    }
    await recordFailedLoginAttempt(email.trim().toLowerCase());
    return false;
  }

  @override
  Future<void> register(String email, String password) async {
    await addUser(AppUser(username: email.trim(), password: password));
  }

  @override
  Future<bool> isLoggedIn() async {
    return getCurrentUser() != null;
  }

  // Simple in-memory rate limiter stored per-repository instance
  final Map<String, List<DateTime>> _failedAttempts = {};

  @override
  Future<bool> canAttemptLogin(String identifier) async {
    final now = DateTime.now();
    final list = _failedAttempts.putIfAbsent(identifier, () => []);
    list.retainWhere((t) => now.difference(t) <= const Duration(minutes: 1));
    return list.length < 5;
  }

  @override
  Future<void> recordFailedLoginAttempt(String identifier) async {
    final now = DateTime.now();
    final list = _failedAttempts.putIfAbsent(identifier, () => []);
    list.add(now);
  }

  Future<void> _seedDefaultsIfEmpty() async {
    if (getUsers().isNotEmpty) {
      return;
    }

    await _box.put(
      _usersKey,
      [
        {
          'username': 'admin',
          'password': _hashPassword('admin123'),
          'roleId': adminRoleId,
        },
        {
          'username': 'user',
          'password': _hashPassword('user123'),
          'roleId': defaultUserRoleId,
        },
      ],
    );
  }

  Future<void> _seedRolesIfEmpty() async {
    final roles = getRoles();
    if (roles.isNotEmpty) {
      return;
    }

    await _box.put(
      _rolesKey,
      [
        RoleDefinition(
          id: adminRoleId,
          name: 'Admin',
          permissions: AppPermissions.all,
        ).toMap(),
        RoleDefinition(
          id: defaultUserRoleId,
          name: 'Member',
          permissions: const [
            AppPermissions.viewProjects,
            AppPermissions.editProjects,
            AppPermissions.shareProjects,
            AppPermissions.useAi,
            AppPermissions.viewSettings,
          ],
        ).toMap(),
        RoleDefinition(
          id: viewerRoleId,
          name: 'Viewer',
          permissions: const [
            AppPermissions.viewProjects,
            AppPermissions.viewSettings,
          ],
        ).toMap(),
      ],
    );
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  void _upgradeLegacyPassword(
    String username,
    String hashedPassword,
    List<AppUser> users,
  ) {
    final updated = <AppUser>[];
    for (final user in users) {
      if (user.username == username) {
        updated.add(
          AppUser(
            username: user.username,
            password: hashedPassword,
            roleId: user.roleId,
          ),
        );
      } else {
        updated.add(user);
      }
    }
    _box.put(
      _usersKey,
      updated.map((entry) => entry.toMap()).toList(),
    );
  }
}
