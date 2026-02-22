/// Abstract interface for auth repository
/// Allows easy swapping of implementations (Hive, Supabase, mock for tests, etc.)
library;
import 'package:my_project_management_app/core/auth/auth_user.dart';
import 'package:my_project_management_app/core/auth/role_models.dart';

/// Define abstract class `IAuthRepository`.
/// Keep method signatures narrow and backend-agnostic to allow swapping.
abstract class IAuthRepository {
  /// Initialize the repository
  Future<void> initialize();

  /// Get all users
  List<AppUser> getUsers();

  /// Get user by username
  AppUser? getUserByUsername(String username);

  /// Get all roles
  List<RoleDefinition> getRoles();

  /// Get role by ID
  RoleDefinition? getRoleById(String roleId);

  /// Upsert a role
  Future<void> upsertRole(RoleDefinition role);

  /// Delete a role
  Future<void> deleteRole(String roleId);

  /// Get all groups
  List<GroupDefinition> getGroups();

  /// Get group by ID
  GroupDefinition? getGroupById(String groupId);

  /// Get groups for a user
  List<GroupDefinition> getGroupsForUser(String username);

  /// Upsert a group
  Future<void> upsertGroup(GroupDefinition group);

  /// Delete a group
  Future<void> deleteGroup(String groupId);

  /// Add user to group
  Future<void> addUserToGroup(String groupId, String username);

  /// Remove user from group
  Future<void> removeUserFromGroup(String groupId, String username);

  /// Update user role
  Future<void> updateUserRole(String username, String roleId);

  /// Add a user
  Future<void> addUser(AppUser user);

  /// Delete a user
  Future<void> deleteUser(String username);

  /// Validate user credentials
  AppUser? validateUser(String username, String password);

  /// Get current user
  String? getCurrentUser();

  /// Set current user
  Future<void> setCurrentUser(String? username);

  /// Logout
  Future<void> logout();

  /// Login
  Future<bool> login(String email, String password);

  /// Register
  Future<void> register(String email, String password);

  /// Check if logged in
  Future<bool> isLoggedIn();

  /// Check if can attempt login
  Future<bool> canAttemptLogin(String identifier);

  /// Record failed login attempt
  Future<void> recordFailedLoginAttempt(String identifier);

  /// Check if login is blocked for email
  Future<bool> isLoginBlocked(String email);

  /// Record a login attempt for email
  Future<void> recordLoginAttempt(String email);

  /// Reset login attempts for email
  Future<void> resetLoginAttempts(String email);

  /// Admin role ID
  String get adminRoleId;

  /// Default user role ID
  String get defaultUserRoleId;

  /// Viewer role ID
  String get viewerRoleId;

  // Future methods to consider:
  // Future<void> inviteUser(String email);
  // Future<void> resetPassword(String email);
  // Future<void> syncAuthToSupabase();
  // Future<void> syncAuthFromSupabase();
}
