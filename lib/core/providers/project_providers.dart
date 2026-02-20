import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_project_management_app/models/project_model.dart';
import 'package:my_project_management_app/core/repository/project_repository.dart';
import 'package:my_project_management_app/core/services/app_logger.dart';
import 'auth_providers.dart'; // Import for auth provider access
import 'package:my_project_management_app/core/repository/project_meta_repository.dart';
import 'package:my_project_management_app/models/project_meta.dart';
import 'package:my_project_management_app/core/auth/permissions.dart';

/// Cache entry with TTL for project data
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;

  const _CacheEntry(this.data, this.timestamp, this.ttl);

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

/// Abstract interface for project repository
/// Allows easy swapping of implementations (Hive, Supabase, etc.)
/// TODO: Move to separate file when repository implementations grow
abstract class IProjectRepository {
  Future<List<ProjectModel>> getAllProjects();
  Future<void> addProject(ProjectModel project, {String? userId, Map<String, dynamic>? metadata});
  Future<void> updateProject(String projectId, ProjectModel updatedProject, {String? userId, String? changeDescription, Map<String, dynamic>? metadata});
  Future<void> updateProgress(String projectId, double newProgress, {String? userId, Map<String, dynamic>? metadata});
  /// Update the project's task list; used by task provider when syncing
  Future<void> updateTasks(String projectId, List<String> tasks, {String? userId, Map<String, dynamic>? metadata});
  Future<void> deleteProject(String projectId, {String? userId});
  Future<ProjectModel?> getProjectById(String id);
  // TODO: Add pagination methods: getProjectsPaginated(int page, int limit)
  // TODO: Add filtering methods: getProjectsByStatus(String status)
}

/// Provider for project repository with abstract interface
/// Easy to swap implementations for testing or different backends
final projectRepositoryProvider = Provider<IProjectRepository>((ref) {
  return ProjectRepository() as IProjectRepository;
});

/// Provider for projects with caching and TTL
/// Uses AsyncValue.guard() for robust error handling
/// TODO: Add pagination for large project lists
/// TODO: Add filtering/sorting parameters via family provider
final projectsProvider = NotifierProvider<ProjectsNotifier, AsyncValue<List<ProjectModel>>>(
  ProjectsNotifier.new,
);

/// Family provider for getting a specific project by ID
/// Uses AsyncValue.guard() for robust error handling
/// TODO: Add caching for individual projects
final projectByIdProvider = FutureProvider.autoDispose.family<ProjectModel?, String>((ref, projectId) async {
  final repository = ref.watch(projectRepositoryProvider);
  
  // TODO: Implement efficient single project fetch if repository supports it
  // For now, get all projects and filter
  final allProjects = await repository.getAllProjects();
  return allProjects.cast<ProjectModel?>().firstWhere(
    (p) => p?.id == projectId,
    orElse: () => null,
  );
});

/// Family provider for filtered projects (e.g., by status, user, etc.)
/// Extensible for future filtering needs
/// TODO: Add more filter parameters as needed
final filteredProjectsProvider = FutureProvider.autoDispose.family<List<ProjectModel>, ProjectFilter>((ref, filter) async {
  final repository = ref.watch(projectRepositoryProvider);
  
  final allProjects = await repository.getAllProjects();
  
  // Apply filters
  return allProjects.where((project) {
    if (filter.status != null && project.status != filter.status) return false;
    // Fix: ProjectModel does not have 'createdBy', use sharedUsers for userId filtering
    if (filter.userId != null && !project.sharedUsers.contains(filter.userId)) return false;
    // TODO: Add more filter conditions as needed
    return true;
  }).toList();
});

/// Filter class for project queries
/// Extensible for future filter parameters
class ProjectFilter {
  final String? status;
  final String? userId;
  final String? searchQuery;
  // TODO: Add more filter fields (date range, priority, etc.)
  
  const ProjectFilter({
    this.status,
    this.userId,
    this.searchQuery,
  });
}

/// Notifier for managing projects with caching and error handling
class ProjectsNotifier extends Notifier<AsyncValue<List<ProjectModel>>> {
  late IProjectRepository _repository;
  _CacheEntry<List<ProjectModel>>? _cache;
  static const _cacheTtl = Duration(minutes: 5); // Configurable TTL

  @override
  AsyncValue<List<ProjectModel>> build() {
    _repository = ref.watch(projectRepositoryProvider);
    // Load from cache if available and not expired
    if (_cache != null && !_cache!.isExpired) {
      return AsyncValue.data(_cache!.data);
    }
    // Otherwise load fresh data asynchronously
    Future.microtask(() async {
      state = await AsyncValue.guard(_loadProjects);
    });
    return AsyncValue.loading();
  }

  /// Initialize method for testing compatibility
  /// TODO: Remove when tests are updated to not require this
  Future<void> initialize(IProjectRepository repository) async {
    _repository = repository;
    state = await AsyncValue.guard(() => _repository.getAllProjects());
  }

  /// Load projects with error handling
  Future<List<ProjectModel>> _loadProjects() async {
    final projects = await _repository.getAllProjects();
    // Update cache
    _cache = _CacheEntry(projects, DateTime.now(), _cacheTtl);
    return projects;
  }

  /// Add a new project with guarded error handling
  Future<void> addProject(ProjectModel project) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = ref.read(authProvider).username ?? 'system'; // Use auth provider
      await _repository.addProject(
        project,
        userId: userId,
        metadata: {
          'name': project.name,
          'status': project.status,
        },
      );
      AppLogger.event(
        'project_created',
        details: {
          'id': project.id,
          'name': project.name,
          'status': project.status,
        },
      );
      return _loadProjects();
    });
  }

  /// Update project progress with error handling
  Future<void> updateProgress(String projectId, double newProgress) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = ref.read(authProvider).username ?? 'system'; // Use auth provider
      await _repository.updateProgress(
        projectId,
        newProgress,
        userId: userId,
        metadata: {'progress': newProgress},
      );
      AppLogger.event(
        'project_progress_updated',
        details: {'id': projectId, 'progress': newProgress},
      );
      return _loadProjects();
    });
  }

  /// Update project with change tracking
  Future<void> updateProject(
    String projectId,
    ProjectModel updatedProject, {
    String? changeDescription,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = ref.read(authProvider).username ?? 'system'; // Use auth provider
      await _repository.updateProject(
        projectId,
        updatedProject,
        userId: userId,
        changeDescription: changeDescription,
        metadata: {
          'updated_fields': ['general_update'],
          'change_type': 'ai_suggestion_applied',
        },
      );
      AppLogger.event(
        'project_updated_with_history',
        details: {
          'id': projectId,
          'change_description': changeDescription,
        },
      );
      return _loadProjects();
    });
  }

  /// Refresh projects (bypasses cache)
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_loadProjects);
  }

  /// Get project by ID (consider using projectByIdProvider family provider instead)
  /// TODO: Deprecate in favor of projectByIdProvider for better performance
  Future<ProjectModel?> getProjectById(String id) async {
    final projects = state.maybeWhen(
      data: (data) => data,
      orElse: () => <ProjectModel>[],
    );
    return projects.cast<ProjectModel?>().firstWhere(
      (p) => p?.id == id,
      orElse: () => null,
    );
  }

  /// Delete project with error handling
  Future<void> deleteProject(String projectId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = ref.read(authProvider).username ?? 'system';
      await _repository.deleteProject(projectId, userId: userId);
      AppLogger.event('project_deleted', details: {'id': projectId});
      return _loadProjects();
    });
  }
}

// --- additional providers moved from monolithic file ---

/// Provider for ProjectMetaRepository
/// Stores urgency and tracked time per project
final projectMetaRepositoryProvider =
    FutureProvider<ProjectMetaRepository>((ref) async {
  final repository = ProjectMetaRepository();
  await repository.initialize();
  return repository;
});

/// Provider for project metadata (urgency + tracked time).
final projectMetaProvider = Provider<Map<String, ProjectMeta>>((ref) {
  final repoAsync = ref.watch(projectMetaRepositoryProvider);
  return repoAsync.maybeWhen(
    data: (repo) => repo.getAllMeta(),
    orElse: () => const {},
  );
});

/// Projects filtered by current user's permissions and sharing status
final visibleProjectsProvider = Provider<AsyncValue<List<ProjectModel>>>((ref) {
  final projectsState = ref.watch(projectsProvider);
  final authState = ref.watch(authProvider);
  final permissions = ref.watch(permissionsProvider);

  return projectsState.when(
    data: (projects) {
      if (!permissions.contains(AppPermissions.viewProjects)) {
        return const AsyncValue.data(<ProjectModel>[]);
      }
      if (permissions.contains(AppPermissions.viewAllProjects)) {
        return AsyncValue.data(projects);
      }
      // fallback: only shared with user
      return AsyncValue.data(
        projects.where((p) => p.sharedUsers.contains(authState.username ?? '')).toList(),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});