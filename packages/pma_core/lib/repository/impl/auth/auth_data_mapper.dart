import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pma_core/auth/auth_user.dart';
import 'package:pma_core/auth/role_models.dart';

/// Handles persistence mapping between Hive records and auth domain models.
class AuthDataMapper {
  AuthDataMapper({Box? box}) : _box = box;

  static const String boxName = 'auth';
  static const String usersKey = 'users';
  static const String currentUserKey = 'current_user';
  static const String rolesKey = 'roles';
  static const String groupsKey = 'groups';

  final Box? _box;

  Box get box => _box ?? Hive.box(boxName);

  List<AppUser> getUsers() {
    final raw = box.get(usersKey);
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((entry) => AppUser.fromMap(Map<String, dynamic>.from(entry)))
          .where((user) => user.username.isNotEmpty)
          .toList();
    }
    return [];
  }

  Future<void> persistUsers(List<AppUser> users) async {
    await box.put(
      usersKey,
      users.map((entry) => entry.toMap()).toList(),
    );
  }

  void persistUsersSync(List<AppUser> users) {
    box.put(
      usersKey,
      users.map((entry) => entry.toMap()).toList(),
    );
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
    final raw = box.get(rolesKey);
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
    await box.put(
      rolesKey,
      roles.map((entry) => entry.toMap()).toList(),
    );
  }

  Future<void> deleteRole(String roleId) async {
    if (roleId == 'role_admin' || roleId == 'role_member') {
      return;
    }
    final roles = getRoles()..removeWhere((item) => item.id == roleId);
    await box.put(
      rolesKey,
      roles.map((entry) => entry.toMap()).toList(),
    );
  }

  List<GroupDefinition> getGroups() {
    final raw = box.get(groupsKey);
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
    await box.put(
      groupsKey,
      groups.map((entry) => entry.toMap()).toList(),
    );
  }

  Future<void> deleteGroup(String groupId) async {
    final groups = getGroups()..removeWhere((item) => item.id == groupId);
    await box.put(
      groupsKey,
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

    await persistUsers(updated);
  }

  Future<void> addUser(AppUser user) async {
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
    await persistUsers(users);
  }

  Future<void> deleteUser(String username) async {
    final users = getUsers();
    users.removeWhere(
      (existing) => existing.username.toLowerCase() == username.toLowerCase(),
    );
    await persistUsers(users);

    final current = getCurrentUser();
    if (current != null && current.toLowerCase() == username.toLowerCase()) {
      await setCurrentUser(null);
    }
  }

  String? getCurrentUser() {
    final value = box.get(currentUserKey);
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  Future<void> setCurrentUser(String? username) async {
    if (username == null || username.isEmpty) {
      await box.delete(currentUserKey);
      return;
    }
    await box.put(currentUserKey, username);
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  String _hashPassword(String password) {
    return hashPassword(password);
  }
}
