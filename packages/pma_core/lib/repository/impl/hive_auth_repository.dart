import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pma_core/auth/auth_user.dart';
import 'package:pma_core/auth/permissions.dart';
import 'package:pma_core/auth/role_models.dart';
import 'package:pma_core/repository/encrypted_hive_box.dart';
import 'package:pma_core/repository/i_auth_repository.dart';
import 'package:pma_core/repository/impl/auth/auth_data_mapper.dart';
import 'package:pma_core/repository/impl/auth/auth_operations.dart';
import 'package:pma_core/repository/impl/auth/auth_remote_service.dart';
import 'package:pma_core/services/login_rate_limiter.dart';

Future<bool> _isLoginBlockedSafely(String identifier) async {
  try {
    await LoginRateLimiter.instance.initialize();
    return await LoginRateLimiter.instance.isBlocked(identifier);
  } catch (_) {
    // Fail-open to avoid locking out users if rate limiter storage is unavailable.
    return false;
  }
}

Future<void> _recordLoginAttemptSafely(String identifier) async {
  try {
    await LoginRateLimiter.instance.initialize();
    await LoginRateLimiter.instance.recordAttempt(identifier);
  } catch (_) {
    // Best-effort telemetry/rate-limit tracking.
  }
}

Future<void> _resetLoginAttemptsSafely(String identifier) async {
  try {
    await LoginRateLimiter.instance.initialize();
    await LoginRateLimiter.instance.resetOnSuccess(identifier);
  } catch (_) {
    // Best-effort reset.
  }
}

/// Concrete implementation of IAuthRepository using Hive for local persistence
/// and Supabase for remote authentication.
///
/// Refactored per .github/issues/049-repository-refactoring.md:
/// mapping and auth workflows are split into dedicated helper modules.
class HiveAuthRepository implements IAuthRepository {
  static const String _boxName = 'auth';

  HiveAuthRepository({RemoteAuthService? remote})
      : _remote = remote ?? RemoteAuthService();

  final RemoteAuthService _remote;
  final AuthDataMapper _dataMapper = AuthDataMapper();
  late final AuthOperations _authOperations = AuthOperations(
    dataMapper: _dataMapper,
    recordLoginAttempt: _recordLoginAttemptSafely,
    resetLoginAttempts: _resetLoginAttemptsSafely,
  );

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
    return _dataMapper.getUsers();
  }

  @override
  AppUser? getUserByUsername(String username) {
    return _dataMapper.getUserByUsername(username);
  }

  @override
  List<RoleDefinition> getRoles() {
    return _dataMapper.getRoles();
  }

  @override
  RoleDefinition? getRoleById(String roleId) {
    return _dataMapper.getRoleById(roleId);
  }

  @override
  Future<void> upsertRole(RoleDefinition role) async {
    return _dataMapper.upsertRole(role);
  }

  @override
  Future<void> deleteRole(String roleId) async {
    return _dataMapper.deleteRole(roleId);
  }

  @override
  List<GroupDefinition> getGroups() {
    return _dataMapper.getGroups();
  }

  @override
  GroupDefinition? getGroupById(String groupId) {
    return _dataMapper.getGroupById(groupId);
  }

  @override
  List<GroupDefinition> getGroupsForUser(String username) {
    return _dataMapper.getGroupsForUser(username);
  }

  @override
  Future<void> upsertGroup(GroupDefinition group) async {
    return _dataMapper.upsertGroup(group);
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    return _dataMapper.deleteGroup(groupId);
  }

  @override
  Future<void> addUserToGroup(String groupId, String username) async {
    return _dataMapper.addUserToGroup(groupId, username);
  }

  @override
  Future<void> removeUserFromGroup(String groupId, String username) async {
    return _dataMapper.removeUserFromGroup(groupId, username);
  }

  @override
  Future<void> updateUserRole(String username, String roleId) async {
    return _dataMapper.updateUserRole(username, roleId);
  }

  @override
  Future<void> addUser(AppUser user) async {
    return _dataMapper.addUser(user);
  }

  @override
  Future<void> deleteUser(String username) async {
    return _dataMapper.deleteUser(username);
  }

  @override
  AppUser? validateUser(String username, String password) {
    return _authOperations.validateUser(username, password);
  }

  @override
  String? getCurrentUser() {
    return _dataMapper.getCurrentUser();
  }

  @override
  Future<void> setCurrentUser(String? username) async {
    return _dataMapper.setCurrentUser(username);
  }

  @override
  Future<bool> isLoginBlocked(String email) async {
    return _isLoginBlockedSafely(email);
  }

  @override
  Future<void> recordLoginAttempt(String email) async {
    await _recordLoginAttemptSafely(email);
  }

  @override
  Future<void> resetLoginAttempts(String email) async {
    await _resetLoginAttemptsSafely(email);
  }

  @override
  dynamic getCurrentSession() => Supabase.instance.client.auth.currentSession;

  @override
  Future<void> recoverSession() async {
    await Supabase.instance.client.auth.refreshSession();
  }

  @override
  Stream<dynamic> get onAuthStateChange =>
      Supabase.instance.client.auth.onAuthStateChange;

  @override
  Future<bool> login(String email, String password) async {
    return _authOperations.login(email, password, _remote);
  }

  @override
  Future<void> register(String email, String password) async {
    return _authOperations.register(email, password, _remote);
  }

  @override
  Future<void> inviteUser(String email) async {
    return _authOperations.inviteUser(email, _remote);
  }

  @override
  Future<void> resetPassword(String email) async {
    return _authOperations.resetPassword(email, _remote);
  }

  @override
  Future<bool> isLoggedIn() async {
    return _authOperations.isLoggedIn();
  }

  @override
  Future<void> logout() async {
    return _authOperations.logout(_remote);
  }

  @override
  Future<bool> canAttemptLogin(String identifier) async {
    return !(await _isLoginBlockedSafely(identifier));
  }

  @override
  Future<void> recordFailedLoginAttempt(String identifier) async {
    await _recordLoginAttemptSafely(identifier);
  }

  Future<void> _seedDefaultsIfEmpty() async {
    if (getUsers().isNotEmpty) {
      return;
    }

    await _box.put(
      AuthDataMapper.usersKey,
      [
        {
          'username': 'admin',
          'password': _dataMapper.hashPassword('admin123'),
          'roleId': adminRoleId,
        },
        {
          'username': 'user',
          'password': _dataMapper.hashPassword('user123'),
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
      AuthDataMapper.rolesKey,
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
            AppPermissions.useMirror,
            AppPermissions.viewSettings,
          ],
        ).toMap(),
        RoleDefinition(
          id: viewerRoleId,
          name: 'Viewer',
          permissions: const [
            AppPermissions.viewProjects,
            AppPermissions.useMirror,
            AppPermissions.viewSettings,
          ],
        ).toMap(),
      ],
    );
  }
}
