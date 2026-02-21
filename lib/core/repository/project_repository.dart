import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_project_management_app/models/project_model.dart';
import 'package:my_project_management_app/core/services/cloud_sync_service.dart';
import 'package:my_project_management_app/core/services/project_members_service.dart';
import 'package:my_project_management_app/core/services/app_logger.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_project_management_app/core/repository/i_project_repository.dart';

/// Repository for managing project persistence using Hive
class ProjectRepository implements IProjectRepository {
  static const String _boxName = 'projects';
  static final Uuid _uuid = Uuid();
  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-'
    r'[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  late Box<Map<dynamic, dynamic>> _projectsBox;
  final CloudSyncService _cloudSync;
  final ProjectMembersService _membersService;

  ProjectRepository({
    CloudSyncService? cloudSync,
    ProjectMembersService? membersService,
  })  : _cloudSync = cloudSync ?? CloudSyncService(),
        _membersService = membersService ?? ProjectMembersService();

  /// Initialize Hive and open the projects box
  Future<void> initialize({String? testPath}) async {
    if (testPath != null && testPath.isNotEmpty) {
      Hive.init(testPath);
    } else {
      await Hive.initFlutter();
    }
    _projectsBox = await Hive.openBox<Map<dynamic, dynamic>>(_boxName);
  }

  /// Check if repository is initialized
  bool get isInitialized => _projectsBox.isOpen;

  bool _isValidUuid(String value) {
    return _uuidRegex.hasMatch(value);
  }

  ProjectModel _withNewId(ProjectModel project, String newId) {
    return ProjectModel(
      id: newId,
      name: project.name,
      progress: project.progress,
      directoryPath: project.directoryPath,
      tasks: project.tasks,
      status: project.status,
      description: project.description,
      sharedUsers: project.sharedUsers,
      sharedGroups: project.sharedGroups,
    );
  }

  Future<ProjectModel> _ensureValidId(
    ProjectModel project,
    String storageKey,
  ) async {
    if (_isValidUuid(project.id) && !project.id.startsWith('project_')) {
      return project;
    }

    final newId = _uuid.v4();
    final migrated = _withNewId(project, newId);
    await _projectsBox.delete(storageKey);
    await _projectsBox.put(newId, migrated.toJson());
    AppLogger.instance.i(
      'Migrated project id from ${project.id} to $newId',
    );
    return migrated;
  }

  /// Add a new project to Hive
  @override
  Future<void> addProject(
    ProjectModel project, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    var resolved = project;
    if (!_isValidUuid(project.id) || project.id.startsWith('project_')) {
      final newId = _uuid.v4();
      resolved = _withNewId(project, newId);
      AppLogger.instance.i(
        'Generated UUID for new project: ${project.id} -> $newId',
      );
    }
    await _projectsBox.put(resolved.id, resolved.toJson());

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    // Membership insert is now handled in syncProjectCreate
    await _cloudSync.syncProjectCreate(
      resolved.id,
      userId: userId,
      metadata: metadata,
    );
  }

  /// Get all projects from Hive
  @override
  Future<List<ProjectModel>> getAllProjects() async {
    final projects = <ProjectModel>[];
    try {
      final entries = _projectsBox.toMap().entries.toList();
      for (final entry in entries) {
        final projectData = Map<String, dynamic>.from(entry.value);
        var project = ProjectModel.fromJson(projectData);
        if (!_isValidUuid(project.id) || project.id.startsWith('project_')) {
          project = _withNewId(project, _uuid.v4());
          _projectsBox.delete(entry.key);
          _projectsBox.put(project.id, project.toJson());
          AppLogger.instance.i(
            'Migrated project id from ${entry.key} to ${project.id}',
          );
        }
        projects.add(project);
      }
    } catch (e) {
      AppLogger.instance.e('Error reading projects from Hive', error: e);
    }
    return projects;
  }

  @override
  Future<List<ProjectModel>> getProjectsPaginated({
    required int page,
    required int limit,
    String? statusFilter,
    String? searchQuery,
  }) async {
    try {
      final allProjects = await getAllProjects();

      // Apply optional filters
      var filtered = allProjects;
      if (statusFilter != null && statusFilter.isNotEmpty) {
        filtered = filtered.where((p) => p.status == statusFilter).toList();
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        filtered = filtered.where((p) {
          final nameMatch = p.name.toLowerCase().contains(q);
          final descMatch = (p.description != null) && p.description!.toLowerCase().contains(q);
          return nameMatch || descMatch;
        }).toList();
      }

      // Pagination (page starts at 1)
      final startIndex = (page - 1) * limit;
      if (startIndex >= filtered.length) return <ProjectModel>[];

      return filtered.skip(startIndex).take(limit).toList();
    } catch (e, s) {
      AppLogger.instance.e('Error in getProjectsPaginated', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Return projects matching a given status (simple filter)
  @override
  Future<List<ProjectModel>> getProjectsByStatus(String status) async {
    final allProjects = await getAllProjects();
    return allProjects.where((p) => p.status == status).toList();
  }

  /// Apply complex filtering criteria defined by [ProjectFilter].
  /// Currently supports status, search query, and date ranges; other fields
  /// (priority, ownerId, tags) are reserved for future use.
  @override
  Future<List<ProjectModel>> getFilteredProjects(ProjectFilter filter, {List<ProjectFilterConditions> extraConditions = const []}) async {
    var projects = await getAllProjects();

    if (filter.status != null) {
      projects = projects.where((p) => p.status == filter.status).toList();
    }
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      final q = filter.searchQuery!.toLowerCase();
      projects = projects.where((p) =>
        p.name.toLowerCase().contains(q) ||
        (p.description?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
    // date-based filtering would go here, but ProjectModel currently
    // lacks a timestamp field (createdAt), so those filters are skipped.
    // priority, ownerId, tags filtering can be added here later

    for (final cond in extraConditions) {
      projects = projects.where((p) => cond.condition(p)).toList();
    }

    return projects;
  }

  /// Get a single project by ID
  @override
  Future<ProjectModel?> getProjectById(String id) async {
    final box = await Hive.openBox<ProjectModel>('projects');
    return box.get(id);
  }

  /// Update project progress
  @override
  Future<void> updateProgress(
    String projectId,
    double newProgress, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    try {
      final data = _projectsBox.get(projectId);
      if (data != null) {
        final projectData = Map<String, dynamic>.from(data);
        var project = ProjectModel.fromJson(projectData);
        project = await _ensureValidId(project, projectId);
        final resolvedId = project.id;
        
        // Create updated project with new progress
        final updatedProject = ProjectModel(
          id: project.id,
          name: project.name,
          progress: newProgress,
          directoryPath: project.directoryPath,
          tasks: project.tasks,
          status: project.status,
          description: project.description,
          sharedUsers: project.sharedUsers,
          sharedGroups: project.sharedGroups,
        );
        
        await _projectsBox.put(resolvedId, updatedProject.toJson());
        await _cloudSync.syncProjectUpdate(
          resolvedId,
          userId: userId,
          metadata: metadata,
        );
      }
    } catch (e) {
      AppLogger.instance.e('Error updating project progress', error: e);
      rethrow;
    }
  }

  /// Update a project's tasks list
  @override
  Future<void> updateTasks(
    String projectId,
    List<String> tasks, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    try {
      final data = _projectsBox.get(projectId);
      if (data != null) {
        final projectData = Map<String, dynamic>.from(data);
        var project = ProjectModel.fromJson(projectData);
        project = await _ensureValidId(project, projectId);
        final resolvedId = project.id;
        
        // Create updated project with new tasks
        final updatedProject = ProjectModel(
          id: project.id,
          name: project.name,
          progress: project.progress,
          directoryPath: project.directoryPath,
          tasks: tasks,
          status: project.status,
          description: project.description,
          sharedUsers: project.sharedUsers,
          sharedGroups: project.sharedGroups,
        );
        
        await _projectsBox.put(resolvedId, updatedProject.toJson());
        await _cloudSync.syncProjectUpdate(
          resolvedId,
          userId: userId,
          metadata: metadata,
        );
      }
    } catch (e) {
      AppLogger.instance.e('Error updating project tasks', error: e);
      rethrow;
    }
  }

  /// Update a project's directory path
  @override
  Future<void> updateDirectoryPath(
    String projectId,
    String? directoryPath, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    try {
      final data = _projectsBox.get(projectId);
      if (data != null) {
        final projectData = Map<String, dynamic>.from(data);
        var project = ProjectModel.fromJson(projectData);
        project = await _ensureValidId(project, projectId);
        final resolvedId = project.id;

        // Create updated project with new directory path
        final updatedProject = ProjectModel(
          id: project.id,
          name: project.name,
          progress: project.progress,
          directoryPath: directoryPath,
          tasks: project.tasks,
          status: project.status,
          description: project.description,
          sharedUsers: project.sharedUsers,
          sharedGroups: project.sharedGroups,
        );

        await _projectsBox.put(resolvedId, updatedProject.toJson());
        await _cloudSync.syncProjectUpdate(
          resolvedId,
          userId: userId,
          metadata: metadata,
        );
      }
    } catch (e) {
      AppLogger.instance.e('Error updating project directory path', error: e);
      rethrow;
    }
  }

  /// Update a project's plan JSON
  @override
  Future<void> updatePlanJson(
    String projectId,
    String? planJson, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    try {
      final data = _projectsBox.get(projectId);
      if (data != null) {
        final projectData = Map<String, dynamic>.from(data);
        var project = ProjectModel.fromJson(projectData);
        project = await _ensureValidId(project, projectId);
        final resolvedId = project.id;

        // Create updated project with new plan JSON
        final updatedProject = ProjectModel(
          id: project.id,
          name: project.name,
          progress: project.progress,
          directoryPath: project.directoryPath,
          tasks: project.tasks,
          status: project.status,
          description: project.description,
          category: project.category,
          aiAssistant: project.aiAssistant,
          planJson: planJson,
          sharedUsers: project.sharedUsers,
          sharedGroups: project.sharedGroups,
        );

        await _projectsBox.put(resolvedId, updatedProject.toJson());
        await _cloudSync.syncProjectUpdate(
          resolvedId,
          userId: userId,
          metadata: metadata,
        );
      }
    } catch (e) {
      AppLogger.instance.e('Error updating project plan JSON', error: e);
      rethrow;
    }
  }

  /// General update method for project with change history logging
  /// Updates any fields and adds change entry to history for compliance
  @override
  Future<void> updateProject(
    String projectId,
    ProjectModel updatedProject, {
    String? userId,
    String? changeDescription,
    Map<String, Object?>? metadata,
  }) async {
    try {
      final data = _projectsBox.get(projectId);
      if (data != null) {
        final projectData = Map<String, dynamic>.from(data);
        var existingProject = ProjectModel.fromJson(projectData);
        existingProject = await _ensureValidId(existingProject, projectId);
        final resolvedId = existingProject.id;

        // Create change history entry for compliance
        final changeEntry = {
          'change': changeDescription ?? 'Project updated via AI suggestion',
          'user': userId ?? 'anonymous_user', // Anonymous per privacy laws
          'time': DateTime.now().toIso8601String(),
          'metadata': metadata ?? {},
        };

        // Add to history (limit to last 100 entries for storage efficiency)
        final updatedHistory = [...existingProject.history, changeEntry];
        final limitedHistory = updatedHistory.length > 100
            ? updatedHistory.sublist(updatedHistory.length - 100)
            : updatedHistory;

        // Create final updated project with history
        final finalProject = ProjectModel(
          id: updatedProject.id,
          name: updatedProject.name,
          progress: updatedProject.progress,
          directoryPath: updatedProject.directoryPath,
          tasks: updatedProject.tasks,
          status: updatedProject.status,
          description: updatedProject.description,
          category: updatedProject.category,
          aiAssistant: updatedProject.aiAssistant,
          planJson: updatedProject.planJson,
          helpLevel: updatedProject.helpLevel,
          complexity: updatedProject.complexity,
          history: limitedHistory,
          sharedUsers: updatedProject.sharedUsers,
          sharedGroups: updatedProject.sharedGroups,
        );

        await _projectsBox.put(resolvedId, finalProject.toJson());
        await _cloudSync.syncProjectUpdate(
          resolvedId,
          userId: userId,
          metadata: metadata,
        );
      }
    } catch (e) {
      AppLogger.instance.e('Error updating project with history', error: e);
      rethrow;
    }
  }

  /// Delete a project by ID
  @override
  Future<void> deleteProject(
    String projectId, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    try {
      final data = _projectsBox.get(projectId);
      if (data != null) {
        final projectData = Map<String, dynamic>.from(data);
        var project = ProjectModel.fromJson(projectData);
        project = await _ensureValidId(project, projectId);
        final resolvedId = project.id;
        await _projectsBox.delete(resolvedId);
        await _cloudSync.syncProjectDelete(
          resolvedId,
          userId: userId,
          metadata: metadata,
        );
        return;
      }
      await _projectsBox.delete(projectId);
      await _cloudSync.syncProjectDelete(
        projectId,
        userId: userId,
        metadata: metadata,
      );
    } catch (e) {
      AppLogger.instance.e('Error deleting project', error: e);
      rethrow;
    }
  }

  @override
  Future<void> addSharedUser(
    String projectId,
    String username, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      return;
    }

    try {
      final data = _projectsBox.get(projectId);
      if (data == null) {
        return;
      }
      final projectData = Map<String, dynamic>.from(data);
      final project = ProjectModel.fromJson(projectData);
      if (project.sharedUsers
          .any((user) => user.toLowerCase() == trimmed.toLowerCase())) {
        return;
      }

      final updatedProject = ProjectModel(
        id: project.id,
        name: project.name,
        progress: project.progress,
        directoryPath: project.directoryPath,
        tasks: project.tasks,
        status: project.status,
        description: project.description,
        sharedUsers: [...project.sharedUsers, trimmed],
        sharedGroups: project.sharedGroups,
      );

      await _projectsBox.put(projectId, updatedProject.toJson());
      await _cloudSync.syncProjectUpdate(
        projectId,
        userId: userId,
        metadata: metadata,
      );
    } catch (e) {
      AppLogger.instance.e('Error sharing project $projectId', error: e);
      rethrow;
    }
  }

  @override
  Future<void> removeSharedUser(
    String projectId,
    String username, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      return;
    }

    try {
      final data = _projectsBox.get(projectId);
      if (data == null) {
        return;
      }
      final projectData = Map<String, dynamic>.from(data);
      final project = ProjectModel.fromJson(projectData);

      final updatedProject = ProjectModel(
        id: project.id,
        name: project.name,
        progress: project.progress,
        directoryPath: project.directoryPath,
        tasks: project.tasks,
        status: project.status,
        description: project.description,
        sharedUsers: project.sharedUsers
            .where((user) => user.toLowerCase() != trimmed.toLowerCase())
            .toList(),
        sharedGroups: project.sharedGroups,
      );

      await _projectsBox.put(projectId, updatedProject.toJson());
      await _cloudSync.syncProjectUpdate(
        projectId,
        userId: userId,
        metadata: metadata,
      );
    } catch (e) {
      AppLogger.instance.e('Error removing shared user on $projectId', error: e);
      rethrow;
    }
  }

  @override
  Future<void> addSharedGroup(
    String projectId,
    String groupId, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    final trimmed = groupId.trim();
    if (trimmed.isEmpty) {
      return;
    }

    try {
      final data = _projectsBox.get(projectId);
      if (data == null) {
        return;
      }
      final projectData = Map<String, dynamic>.from(data);
      final project = ProjectModel.fromJson(projectData);
      if (project.sharedGroups
          .any((group) => group.toLowerCase() == trimmed.toLowerCase())) {
        return;
      }

      final updatedProject = ProjectModel(
        id: project.id,
        name: project.name,
        progress: project.progress,
        directoryPath: project.directoryPath,
        tasks: project.tasks,
        status: project.status,
        description: project.description,
        sharedUsers: project.sharedUsers,
        sharedGroups: [...project.sharedGroups, trimmed],
      );

      await _projectsBox.put(projectId, updatedProject.toJson());
      await _cloudSync.syncProjectUpdate(
        projectId,
        userId: userId,
        metadata: metadata,
      );
    } catch (e) {
      AppLogger.instance.e('Error sharing project group $projectId', error: e);
      rethrow;
    }
  }

  @override
  Future<void> removeSharedGroup(
    String projectId,
    String groupId, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    final trimmed = groupId.trim();
    if (trimmed.isEmpty) {
      return;
    }

    try {
      final data = _projectsBox.get(projectId);
      if (data == null) {
        return;
      }
      final projectData = Map<String, dynamic>.from(data);
      final project = ProjectModel.fromJson(projectData);

      final updatedProject = ProjectModel(
        id: project.id,
        name: project.name,
        progress: project.progress,
        directoryPath: project.directoryPath,
        tasks: project.tasks,
        status: project.status,
        description: project.description,
        sharedUsers: project.sharedUsers,
        sharedGroups: project.sharedGroups
            .where((group) => group.toLowerCase() != trimmed.toLowerCase())
            .toList(),
      );

      await _projectsBox.put(projectId, updatedProject.toJson());
      await _cloudSync.syncProjectUpdate(
        projectId,
        userId: userId,
        metadata: metadata,
      );
    } catch (e) {
      AppLogger.instance.e(
        'Error removing shared group on $projectId',
        error: e,
      );
      rethrow;
    }
  }

  /// Invite a user to a project
  Future<void> inviteUserToProject(
    String projectId,
    String email,
    String role, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    await _membersService.inviteUser(
      email: email,
      projectId: projectId,
      role: role,
    );
  }

  /// Change a member's role in a project
  Future<void> changeMemberRole(
    String projectId,
    String targetUserId,
    String newRole, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    if (!['owner', 'admin', 'member', 'viewer'].contains(newRole)) {
      throw Exception('Invalid role: $newRole');
    }

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    // Check if current user has permission (owner/admin)
    final membership = await Supabase.instance.client
        .from('project_members')
        .select('role')
        .eq('project_id', projectId)
        .eq('user_id', currentUser.id)
        .single();

    if (membership['role'] != 'owner' && membership['role'] != 'admin') {
      throw Exception('Insufficient permissions to change member roles');
    }

    // Prevent demoting the last owner
    if (newRole != 'owner') {
      final owners = await Supabase.instance.client
          .from('project_members')
          .select('user_id')
          .eq('project_id', projectId)
          .eq('role', 'owner');

      if (owners.length == 1 && owners[0]['user_id'] == targetUserId) {
        throw Exception('Cannot remove the last owner from the project');
      }
    }

    await Supabase.instance.client
        .from('project_members')
        .update({'role': newRole})
        .eq('project_id', projectId)
        .eq('user_id', targetUserId);

    await _cloudSync.syncProjectUpdate(
      projectId,
      userId: userId,
      metadata: {...?metadata, 'action': 'change_member_role', 'target_user': targetUserId, 'new_role': newRole},
    );
  }

  /// Remove a member from a project
  Future<void> removeMemberFromProject(
    String projectId,
    String targetUserId, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    // Check if current user has permission (owner/admin)
    final membership = await Supabase.instance.client
        .from('project_members')
        .select('role')
        .eq('project_id', projectId)
        .eq('user_id', currentUser.id)
        .single();

    if (membership['role'] != 'owner' && membership['role'] != 'admin') {
      throw Exception('Insufficient permissions to remove members');
    }

    // Prevent removing the last owner
    final targetMembership = await Supabase.instance.client
        .from('project_members')
        .select('role')
        .eq('project_id', projectId)
        .eq('user_id', targetUserId)
        .single();

    if (targetMembership['role'] == 'owner') {
      final owners = await Supabase.instance.client
          .from('project_members')
          .select('user_id')
          .eq('project_id', projectId)
          .eq('role', 'owner');

      if (owners.length == 1) {
        throw Exception('Cannot remove the last owner from the project');
      }
    }

    await Supabase.instance.client
        .from('project_members')
        .delete()
        .eq('project_id', projectId)
        .eq('user_id', targetUserId);

    await _cloudSync.syncProjectUpdate(
      projectId,
      userId: userId,
      metadata: {...?metadata, 'action': 'remove_member', 'target_user': targetUserId},
    );
  }

  /// Close the Hive box (call on app shutdown)
  @override
  Future<void> close() async {
    await _projectsBox.compact();
    await _projectsBox.close();
  }

  /// Get project count
  int getProjectCount() {
    return _projectsBox.length;
  }
}
