/// Abstract interface for project repository
/// Allows easy swapping of implementations (Hive, Supabase, mock for tests, etc.)
library;
import 'package:project_management_app/models/project_model.dart';
import 'package:project_management_app/models/project_filter.dart';
import 'models/project_models.dart';

/// Define abstract class `IProjectRepository`.
/// Keep method signatures narrow and backend-agnostic to allow swapping.
abstract class IProjectRepository {
  /// Retrieves all projects from storage.
  /// Retrieves all projects from storage.
  Future<List<ProjectModel>> getAllProjects();

  /// Adds a new project to storage.
  /// Adds a new project to storage.
  Future<void> addProject(
    ProjectModel project, {
    String? userId,
    Map<String, Object?>? metadata,
  });

  /// Updates an existing project in storage.
  /// Updates an existing project in storage.
  Future<void> updateProject(
    String projectId,
    ProjectModel updatedProject, {
    String? userId,
    String? changeDescription,
    Map<String, Object?>? metadata,
  });

  /// Updates the progress of a project.
  /// Updates the progress of a project.
  Future<void> updateProgress(
    String projectId,
    double newProgress, {
    String? userId,
    Map<String, Object?>? metadata,
  });

  /// Updates the tasks of a project.
  /// Updates the tasks of a project.
  Future<void> updateTasks(
    String projectId,
    List<String> tasks, {
    String? userId,
    Map<String, Object?>? metadata,
  });

  /// Deletes a project from storage.
  Future<void> deleteProject(
    String projectId, {
    String? userId,
    Map<String, Object?>? metadata,
  });

  /// Efficient direct fetch of a single project by ID (Hive box.get)
  /// Preferred over loading all projects
  Future<ProjectModel> getProjectById(String id);

  // These helpers are present because some repository implementations
  // used by the app rely on them; keeping them in the interface prevents
  // breaking changes when swapping implementations.

  /// Updates the directory path of a project.
  /// Updates the directory path of a project.
  Future<void> updateDirectoryPath(
    String projectId,
    String? directoryPath, {
    String? userId,
    Map<String, Object?>? metadata,
  });

  /// Updates the plan JSON of a project.
  Future<void> updatePlanJson(
    String projectId,
    String? planJson, {
    String? userId,
    Map<String, Object?>? metadata,
  });

  /// Close repository resources (e.g., Hive boxes)
  Future<void> close();

  /// Sharing helpers

  /// Adds a shared user to a project.
  Future<void> addSharedUser(String projectId, String username, {String? userId, Map<String, Object?>? metadata});

  /// Removes a shared user from a project.
  Future<void> removeSharedUser(String projectId, String username, {String? userId, Map<String, Object?>? metadata});

  /// Adds a shared group to a project.
  Future<void> addSharedGroup(String projectId, String groupId, {String? userId, Map<String, Object?>? metadata});

  /// Removes a shared group from a project.
  /// Removes a shared group from a project.
  Future<void> removeSharedGroup(String projectId, String groupId, {String? userId, Map<String, Object?>? metadata});

  // Future methods to consider:
  // Future<List<ProjectModel>> getProjectsPaginated(int page, int limit);
  // Future<List<ProjectModel>> getProjectsByStatus(String status);

  /// Fetch projects with pagination for large lists
  /// `page` starts at 1
  Future<List<ProjectModel>> getProjectsPaginated({
    int page = 1,
    int limit = 20,
    ProjectFilter? filter,
  });

  /// Fetch projects filtered by a single status
  Future<List<ProjectModel>> getProjectsByStatus(String status);

  /// Advanced filtering with multiple criteria
  Future<List<ProjectModel>> getFilteredProjects(ProjectFilter filter, {List<ProjectFilterConditions> extraConditions = const []});

  /// Sync methods for Supabase integration (039-supabase-sync-implementation.md)
  /// Syncs a specific project to/from Supabase
  Future<void> syncProject(String projectId);

  /// Syncs all projects to/from Supabase
  Future<void> syncAllProjects();

  // Fully implemented in 040-supabase-sync-cleanup.md

  /// Performs bidirectional sync for a specific project (upload local + download remote)
  Future<void> bidirectionalSyncProject(String projectId);

  /// Watches for real-time changes to a specific project
  Stream<List<ProjectModel>> watchProjectChanges(String projectId);

  /// Resolves sync conflicts between local and remote project versions
  Future<void> resolveConflict(ProjectModel local, ProjectModel remote);
}
