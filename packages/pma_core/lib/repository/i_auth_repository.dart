/// Abstract interface for auth repository.
/// Allows easy swapping of implementations (Hive, Supabase, mock for tests, etc.)
library;

import 'package:pma_core/auth/auth_user.dart';
import 'package:pma_core/auth/role_models.dart';

/// Session/authentication operations used by login/logout flows.
abstract class IAuthSessionRepository {
  /// Validate user credentials.
  AppUser? validateUser(String username, String password);

  /// Get current user.
  String? getCurrentUser();

  /// Set current user.
  Future<void> setCurrentUser(String? username);

  /// Logout.
  Future<void> logout();

  /// Login.
  Future<bool> login(String email, String password);

  /// Register.
  Future<void> register(String email, String password);

  /// Check if logged in.
  Future<bool> isLoggedIn();

  /// Get current session.
  dynamic getCurrentSession();

  /// Stream of auth state changes.
  Stream<dynamic> get onAuthStateChange;

  /// Recover session.
  Future<void> recoverSession();
}

/// User/role/group administration operations.
abstract class IAuthDirectoryRepository {
  /// Get all users.
  List<AppUser> getUsers();

  /// Get user by username.
  AppUser? getUserByUsername(String username);

  /// Get all roles.
  List<RoleDefinition> getRoles();

  /// Get role by ID.
  RoleDefinition? getRoleById(String roleId);

  /// Upsert a role.
  Future<void> upsertRole(RoleDefinition role);

  /// Delete a role.
  Future<void> deleteRole(String roleId);

  /// Get all groups.
  List<GroupDefinition> getGroups();

  /// Get group by ID.
  GroupDefinition? getGroupById(String groupId);

  /// Get groups for a user.
  List<GroupDefinition> getGroupsForUser(String username);

  /// Upsert a group.
  Future<void> upsertGroup(GroupDefinition group);

  /// Delete a group.
  Future<void> deleteGroup(String groupId);

  /// Add user to group.
  Future<void> addUserToGroup(String groupId, String username);

  /// Remove user from group.
  Future<void> removeUserFromGroup(String groupId, String username);

  /// Update user role.
  Future<void> updateUserRole(String username, String roleId);

  /// Add a user.
  Future<void> addUser(AppUser user);

  /// Delete a user.
  Future<void> deleteUser(String username);

  /// Admin role ID.
  String get adminRoleId;

  /// Default user role ID.
  String get defaultUserRoleId;

  /// Viewer role ID.
  String get viewerRoleId;
}

/// Rate-limiting operations for login attempts.
abstract class IAuthRateLimitRepository {
  /// Check if can attempt login.
  Future<bool> canAttemptLogin(String identifier);

  /// Record failed login attempt.
  Future<void> recordFailedLoginAttempt(String identifier);

  /// Check if login is blocked for email.
  Future<bool> isLoginBlocked(String email);

  /// Record a login attempt for email.
  Future<void> recordLoginAttempt(String email);

  /// Reset login attempts for email.
  Future<void> resetLoginAttempts(String email);
}

/// Backward-compatible aggregate auth repository contract.
/// Existing implementations can keep implementing this type directly.
abstract class IAuthRepository
    implements
        IAuthSessionRepository,
        IAuthDirectoryRepository,
        IAuthRateLimitRepository {
  /// Initialize the repository.
  Future<void> initialize();
}
