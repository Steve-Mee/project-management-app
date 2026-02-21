/// Abstract interface for authentication repository
/// Makes auth swappable (Hive → Supabase → Mock for tests)
import 'package:my_project_management_app/core/auth/auth_user.dart';
import 'package:my_project_management_app/core/auth/role_models.dart';

abstract class IAuthRepository {
  Future<void> initialize();

  // Users
  List<AppUser> getUsers();
  AppUser? getUserByUsername(String username);
  Future<void> addUser(AppUser user);
  Future<void> deleteUser(String username);
  AppUser? validateUser(String username, String password);

  // Current user
  String? getCurrentUser();
  Future<void> setCurrentUser(String? username);

  // Roles & groups
  List<RoleDefinition> getRoles();
  RoleDefinition? getRoleById(String roleId);
  Future<void> upsertRole(RoleDefinition role);
  Future<void> deleteRole(String roleId);

  List<GroupDefinition> getGroups();
  GroupDefinition? getGroupById(String groupId);
  List<GroupDefinition> getGroupsForUser(String username);
  Future<void> upsertGroup(GroupDefinition group);
  Future<void> deleteGroup(String groupId);
  Future<void> addUserToGroup(String groupId, String username);
  Future<void> removeUserFromGroup(String groupId, String username);
  Future<void> updateUserRole(String username, String roleId);

  // Auth operations
  Future<bool> login(String email, String password);
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<void> register(String email, String password);

  // Rate limiting helpers
  Future<bool> canAttemptLogin(String identifier);
  Future<void> recordFailedLoginAttempt(String identifier);
}
