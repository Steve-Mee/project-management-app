import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_management_app/core/services/app_logger.dart';
import 'package:project_management_app/core/auth/permissions.dart';
import 'package:project_management_app/core/auth/role_models.dart';
import 'package:project_management_app/core/services/login_rate_limiter.dart';
import 'package:project_management_app/core/auth/auth_user.dart';
import 'package:project_management_app/core/repository/i_auth_repository.dart';
import 'package:project_management_app/core/repository/encrypted_hive_box.dart';

enum Role {
  admin,
  user,
}

/// Remote auth service using Supabase
class RemoteAuthService {
  Future<void> signIn(String username, String password, {String? captchaToken}) async {
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: username.trim(),
        password: password,
        captchaToken: captchaToken,
      );
      AppLogger.event('auth_sign_in_attempt', params: {'email': username.trim()});
    } catch (e) {
      AppLogger.error('Supabase sign in failed', error: e);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      AppLogger.event('auth_sign_out_attempt');
    } catch (e) {
      AppLogger.error('Supabase sign out failed', error: e);
      rethrow;
    }
  }

  Future<void> registerUser(String username, String password, {String? captchaToken}) async {
    try {
      await Supabase.instance.client.auth.signUp(
        email: username.trim(),
        password: password,
        captchaToken: captchaToken,
      );
      AppLogger.event('auth_sign_up_attempt', params: {'email': username.trim()});
    } catch (e) {
      AppLogger.error('Supabase sign up failed', error: e);
      rethrow;
    }
  }
}

class AuthRepository implements IAuthRepository {
  static const String _boxName = 'auth';
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user';
  static const String _rolesKey = 'roles';
  static const String _groupsKey = 'groups';

  final RemoteAuthService _remote;

  AuthRepository({RemoteAuthService? remote})
      : _remote = remote ?? RemoteAuthService();

  @override
  String get adminRoleId => 'role_admin';

  @override
  String get defaultUserRoleId => 'role_member';

  @override
  String get viewerRoleId => 'role_viewer';

  @override
  Future<void> initialize() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(_boxName)) {
      await EncryptedHiveBox(
        boxName: _boxName,
        encryptionKey: 'hive_encryption_key_auth',
      ).open();
    }
    await _seedRolesIfEmpty();
    await _seedDefaultsIfEmpty();
  }

  Box get _box => Hive.box(_boxName);

  @override
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

  @override
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

  @override
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

  @override
  RoleDefinition? getRoleById(String roleId) {
    for (final role in getRoles()) {
      if (role.id == roleId) {
        return role;
      }
    }
    return null;
  }

  @override
  Future<void> upsertRole(RoleDefinition role) async {
    final roles = getRoles();
    roles.removeWhere((item) => item.id == role.id);
    roles.add(role);
    await _box.put(
      _rolesKey,
      roles.map((entry) => entry.toMap()).toList(),
    );
  }

  @override
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

  @override
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

  @override
  GroupDefinition? getGroupById(String groupId) {
    for (final group in getGroups()) {
      if (group.id == groupId) {
        return group;
      }
    }
    return null;
  }

  @override
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

  @override
  Future<void> upsertGroup(GroupDefinition group) async {
    final groups = getGroups();
    groups.removeWhere((item) => item.id == group.id);
    groups.add(group);
    await _box.put(
      _groupsKey,
      groups.map((entry) => entry.toMap()).toList(),
    );
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    final groups = getGroups()..removeWhere((item) => item.id == groupId);
    await _box.put(
      _groupsKey,
      groups.map((entry) => entry.toMap()).toList(),
    );
  }

  @override
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

  @override
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

  @override
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

  @override
  Future<void> addUser(AppUser user) async {
    // NOTE: Integrate Supabase Auth later; if (useRemote) { ... } else { local add }.
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
    // NOTE: Integrate Supabase Auth later; register remote user when online.
  }

  @override
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

  @override
  AppUser? validateUser(String username, String password) {
    // NOTE: Integrate Supabase Auth later; if (useRemote) { ... } else { local validate }.
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

  @override
  String? getCurrentUser() {
    final value = _box.get(_currentUserKey);
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  @override
  Future<void> setCurrentUser(String? username) async {
    if (username == null || username.isEmpty) {
      await _box.delete(_currentUserKey);
      return;
    }
    await _box.put(_currentUserKey, username);
  }

  @override
  Future<bool> isLoginBlocked(String email) async {
    return await LoginRateLimiter.instance.isBlocked(email);
  }

  @override
  Future<void> recordLoginAttempt(String email) async {
    await LoginRateLimiter.instance.recordAttempt(email);
  }

  @override
  Future<void> resetLoginAttempts(String email) async {
    await LoginRateLimiter.instance.resetOnSuccess(email);
  }

  @override
  dynamic getCurrentSession() => Supabase.instance.client.auth.currentSession;

  @override
  Stream<dynamic> get onAuthStateChange => Supabase.instance.client.auth.onAuthStateChange;

  @override
  Future<void> recoverSession() async {
    try {
      await Supabase.instance.client.auth.refreshSession();
      AppLogger.event('auth_session_recovered');
    } catch (e) {
      AppLogger.error('Supabase session recovery failed', error: e);
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    await _remote.signOut();
    await setCurrentUser(null);
  }

  // Implement IAuthRepository's small wrappers
  @override
  Future<bool> login(String email, String password) async {
    try {
      await _remote.signIn(email, password);
      await setCurrentUser(email.trim());
      return true;
    } catch (e) {
      AppLogger.instance.w('Supabase login failed', error: e);
      await recordFailedLoginAttempt(email.trim().toLowerCase());
      return false;
    }
  }

  @override
  Future<void> register(String email, String password) async {
    await _remote.registerUser(email, password);
  }

  @override
  Future<bool> isLoggedIn() async {
    return Supabase.instance.client.auth.currentSession != null;
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
