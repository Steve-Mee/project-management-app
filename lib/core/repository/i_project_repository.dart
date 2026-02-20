/// Abstract interface for project repository
/// Allows easy swapping of implementations (Hive, Supabase, mock for tests, etc.)
import 'package:my_project_management_app/models/project_model.dart';

abstract class IProjectRepository {
  Future<List<ProjectModel>> getAllProjects();
  Future<void> addProject(ProjectModel project, {String? userId, Map<String, Object?>? metadata});
  Future<void> updateProject(String projectId, ProjectModel updatedProject, {String? userId, String? changeDescription, Map<String, Object?>? metadata});
  Future<void> updateProgress(String projectId, double newProgress, {String? userId, Map<String, Object?>? metadata});
  Future<void> updateTasks(String projectId, List<String> tasks, {String? userId, Map<String, Object?>? metadata});
  Future<void> deleteProject(String projectId, {String? userId});
  Future<ProjectModel?> getProjectById(String id);

  /// Close repository resources (e.g., Hive boxes)
  Future<void> close();

  // Sharing helpers
  Future<void> addSharedUser(String projectId, String username, {String? userId, Map<String, Object?>? metadata});
  Future<void> removeSharedUser(String projectId, String username, {String? userId, Map<String, Object?>? metadata});
  Future<void> addSharedGroup(String projectId, String groupId, {String? userId, Map<String, Object?>? metadata});
  Future<void> removeSharedGroup(String projectId, String groupId, {String? userId, Map<String, Object?>? metadata});

  // Directory and plan updates
  Future<void> updateDirectoryPath(String projectId, String? directoryPath, {String? userId, Map<String, Object?>? metadata});
  Future<void> updatePlanJson(String projectId, String? planJson, {String? userId, Map<String, Object?>? metadata});

  // Future<List<ProjectModel>> getProjectsPaginated(int page, int limit);
  // Future<List<ProjectModel>> getProjectsByStatus(String status);
}
