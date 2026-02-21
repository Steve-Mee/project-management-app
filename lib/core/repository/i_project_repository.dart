/// Abstract interface for project repository
/// Allows easy swapping of implementations (Hive, Supabase, mock for tests, etc.)
library;
import 'package:my_project_management_app/models/project_model.dart';

/// Filter criteria for projects
class ProjectFilter {
  final String? status;
  final String? searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? priority;
  final String? ownerId;
  final List<String>? tags;

  const ProjectFilter({
    this.status,
    this.searchQuery,
    this.startDate,
    this.endDate,
    this.priority,
    this.ownerId,
    this.tags,
  });
}

/// Define abstract class `IProjectRepository`.
/// Keep method signatures narrow and backend-agnostic to allow swapping.
abstract class IProjectRepository {
  Future<List<ProjectModel>> getAllProjects();

  Future<void> addProject(
    ProjectModel project, {
    String? userId,
    Map<String, Object?>? metadata,
  });

  Future<void> updateProject(
    String projectId,
    ProjectModel updatedProject, {
    String? userId,
    String? changeDescription,
    Map<String, Object?>? metadata,
  });

  Future<void> updateProgress(
    String projectId,
    double newProgress, {
    String? userId,
    Map<String, Object?>? metadata,
  });

  Future<void> updateTasks(
    String projectId,
    List<String> tasks, {
    String? userId,
    Map<String, Object?>? metadata,
  });

  Future<void> deleteProject(
    String projectId, {
    String? userId,
    Map<String, Object?>? metadata,
  });

  Future<ProjectModel?> getProjectById(String id);

  // These helpers are present because some repository implementations
  // used by the app rely on them; keeping them in the interface prevents
  // breaking changes when swapping implementations.
  Future<void> updateDirectoryPath(
    String projectId,
    String? directoryPath, {
    String? userId,
    Map<String, Object?>? metadata,
  });

  Future<void> updatePlanJson(
    String projectId,
    String? planJson, {
    String? userId,
    Map<String, Object?>? metadata,
  });

  /// Close repository resources (e.g., Hive boxes)
  Future<void> close();

  /// Sharing helpers
  Future<void> addSharedUser(String projectId, String username, {String? userId, Map<String, Object?>? metadata});
  Future<void> removeSharedUser(String projectId, String username, {String? userId, Map<String, Object?>? metadata});
  Future<void> addSharedGroup(String projectId, String groupId, {String? userId, Map<String, Object?>? metadata});
  Future<void> removeSharedGroup(String projectId, String groupId, {String? userId, Map<String, Object?>? metadata});

  // Future methods to consider:
  // Future<List<ProjectModel>> getProjectsPaginated(int page, int limit);
  // Future<List<ProjectModel>> getProjectsByStatus(String status);

  /// Fetch projects with pagination for large lists
  /// `page` starts at 1
  Future<List<ProjectModel>> getProjectsPaginated({
    required int page,
    required int limit,
    String? statusFilter,
    String? searchQuery,
  });

  /// Fetch projects filtered by a single status
  Future<List<ProjectModel>> getProjectsByStatus(String status);

  /// Advanced filtering with multiple criteria
  Future<List<ProjectModel>> getFilteredProjects(ProjectFilter filter);

  /// Sync methods for future Supabase integration
  /// TODO: Implement sync methods when Supabase sync is added
  // Future<void> syncProjectsToSupabase();
  // Future<void> syncProjectsFromSupabase();
  // Future<void> resolveSyncConflicts(List<SyncConflict> conflicts);
}
