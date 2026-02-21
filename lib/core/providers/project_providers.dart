/*
Pagination Provider Setup Complete (issue #004)
All new UI should use projectsPaginatedProvider
*/
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_project_management_app/models/project_model.dart';
import 'package:my_project_management_app/core/repository/project_repository.dart';
import 'package:my_project_management_app/core/repository/i_project_repository.dart' as repo;
import 'package:my_project_management_app/core/services/app_logger.dart';
import 'auth_providers.dart'; // Import for auth provider access
import 'package:my_project_management_app/core/repository/project_meta_repository.dart';
import 'package:my_project_management_app/models/project_meta.dart';
import 'package:my_project_management_app/core/auth/permissions.dart';

/// Parameters for the filtered projects family provider
class ProjectFilterParams {
  final String? status;
  final String? searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? priority;
  final String? ownerId;
  final List<String>? tags;

  const ProjectFilterParams({
    this.status,
    this.searchQuery,
    this.startDate,
    this.endDate,
    this.priority,
    this.ownerId,
    this.tags,
  });
}

/// Cache entry with TTL for project data
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;

  const _CacheEntry(this.data, this.timestamp, this.ttl);

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}

// IProjectRepository has been moved to `lib/core/repository/i_project_repository.dart`

/// Simple in-memory cache for individual projects (auto-expire after 5 minutes)
final projectCacheProvider = StateProvider.family<ProjectModel?, String>((ref, id) {
  // schedule invalidation after TTL without referencing the provider itself
  // TODO: re-enable TTL invalidation when cycle issue is resolved
  // ref.onDispose(() {
  //   Future.delayed(const Duration(minutes: 5), () {
  //     if (ref.mounted) {
  //       ref.invalidateSelf();
  //     }
  //   });
  // });
  return null;
});

/// Provider for project repository with abstract interface
/// Easy to swap implementations for testing or different backends
final projectRepositoryProvider = Provider<repo.IProjectRepository>((ref) {
  return ProjectRepository();
});

/// @deprecated Use projectsPaginatedProvider instead for better performance
/// (kept for backward compatibility)
/// Provider for projects with caching and TTL
/// Uses AsyncValue.guard() for robust error handling
final projectsProvider = NotifierProvider<ProjectsNotifier, AsyncValue<List<ProjectModel>>>(
  ProjectsNotifier.new,
);


/// Cached individual project provider (keeps alive for 5 minutes)
final projectByIdProvider = FutureProvider.autoDispose.family<ProjectModel?, String>((ref, projectId) async {
  final repository = ref.watch(projectRepositoryProvider);
  // keep alive so cache entry remains while UI uses it
  ref.keepAlive();

  final cached = ref.watch(projectCacheProvider(projectId));
  if (cached != null) return cached;

  final project = await repository.getProjectById(projectId);
  if (project != null) {
    ref.read(projectCacheProvider(projectId).notifier).state = project;
  }
  return project;
});

/// Family provider for filtered projects (e.g., by status, user, etc.)
/// Extensible for future filtering needs
final filteredProjectsProvider = FutureProvider.autoDispose.family<List<ProjectModel>, ProjectFilterParams>((ref, params) async {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.getFilteredProjects(
    repo.ProjectFilter( // map params to repository filter
      status: params.status,
      searchQuery: params.searchQuery,
      startDate: params.startDate,
      endDate: params.endDate,
      priority: params.priority,
      ownerId: params.ownerId,
      tags: params.tags,
    ),
  );
});
// Ready for UI integration

/// Combined parameters for filtered pagination
class FilteredPaginationParams {
  final ProjectFilterParams filter;
  final int page;
  final int limit;

  const FilteredPaginationParams({
    required this.filter,
    required this.page,
    required this.limit,
  });
}

/// Provider for filtered and paginated projects
/// Combines filtering with pagination for infinite scroll
final filteredProjectsPaginatedProvider = FutureProvider.autoDispose.family<List<ProjectModel>, FilteredPaginationParams>((ref, params) async {
  final repository = ref.watch(projectRepositoryProvider);

  // First get all filtered projects
  final allFiltered = await repository.getFilteredProjects(
    repo.ProjectFilter(
      status: params.filter.status,
      searchQuery: params.filter.searchQuery,
      startDate: params.filter.startDate,
      endDate: params.filter.endDate,
      priority: params.filter.priority,
      ownerId: params.filter.ownerId,
      tags: params.filter.tags,
    ),
  );

  // Then paginate in-memory (since we need the full filtered set for accurate pagination)
  final startIndex = (params.page - 1) * params.limit;
  if (startIndex >= allFiltered.length) return [];
  return allFiltered.skip(startIndex).take(params.limit).toList();
});

/// Dedicated paginated projects provider
/// Use this for lists that need efficient loading (dashboard, projects page, etc.)
final projectsPaginatedProvider = FutureProvider.autoDispose.family<List<ProjectModel>, ProjectPaginationParams>(
  (ref, params) async {
    ref.keepAlive();
    final repository = ref.watch(projectRepositoryProvider);
    return repository.getProjectsPaginated(
      page: params.page,
      limit: params.limit,
      statusFilter: params.statusFilter,
      searchQuery: params.searchQuery,
    );
  },
);

/// Filter class for project queries
/// Extensible for future filter parameters
class ProjectFilter {
  final String? status;
  final String? userId;
  final String? searchQuery;

  const ProjectFilter({
    this.status,
    this.userId,
    this.searchQuery,
  });
}

class ProjectPaginationParams {
  final int page;
  final int limit;
  final String? statusFilter;
  final String? searchQuery;

  const ProjectPaginationParams({
    required this.page,
    required this.limit,
    this.statusFilter,
    this.searchQuery,
  });
}

/// Notifier for managing projects with caching and error handling
class ProjectsNotifier extends Notifier<AsyncValue<List<ProjectModel>>> {
  late repo.IProjectRepository _repository;
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
  Future<void> initialize(repo.IProjectRepository repository) async {
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

  /// Update project's directory path
  Future<void> updateDirectoryPath(String projectId, String? directoryPath) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = ref.read(authProvider).username ?? 'system';
      await _repository.updateDirectoryPath(
        projectId,
        directoryPath,
        userId: userId,
        metadata: {'action': 'update_directory_path'},
      );
      AppLogger.event('project_directory_updated', details: {'id': projectId});
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

  /// Update a project's tasks list via repository
  Future<void> updateTasks(String projectId, List<String> tasks) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = ref.read(authProvider).username ?? 'system';
      await _repository.updateTasks(
        projectId,
        tasks,
        userId: userId,
        metadata: {'action': 'update_tasks'},
      );
      AppLogger.event('project_tasks_updated', details: {'id': projectId});
      return _loadProjects();
    });
  }

  /// Update project's plan JSON
  Future<void> updatePlanJson(String projectId, String? planJson) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = ref.read(authProvider).username ?? 'system';
      await _repository.updatePlanJson(
        projectId,
        planJson,
        userId: userId,
        metadata: {'action': 'update_plan_json'},
      );
      AppLogger.event('project_plan_updated', details: {'id': projectId});
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
/// Combined parameters for pagination, filter, and sort
class ProjectParams {
  final int page;
  final int limit;
  final ProjectFilter filter;
  final String sortBy; // e.g., 'name', 'progress', 'createdAt', 'status'
  final bool sortAscending;

  const ProjectParams({
    required this.page,
    required this.limit,
    required this.filter,
    this.sortBy = 'name',
    this.sortAscending = true,
  });
}

// helper used by the combined provider
List<ProjectModel> _sortProjects(List<ProjectModel> projects, String sortBy, bool ascending) {
  projects.sort((a, b) {
    int cmp;
    switch (sortBy) {
      case 'name':
        cmp = a.name.compareTo(b.name);
        break;
      case 'progress':
        cmp = a.progress.compareTo(b.progress);
        break;
      case 'status':
        cmp = a.status.compareTo(b.status);
        break;
      // 'createdAt' is not on model yet; fallback to name
      default:
        cmp = 0;
    }
    return ascending ? cmp : -cmp;
  });
  return projects;
}

/// Combined projects provider with pagination, filtering and sorting
final projectsCombinedProvider = FutureProvider.autoDispose.family<List<ProjectModel>, ProjectParams>(
  (ref, params) async {
    final repository = ref.watch(projectRepositoryProvider);

    // build a repo filter from provider params
    final repoFilter = repo.ProjectFilter(
      status: params.filter.status,
      searchQuery: params.filter.searchQuery,
    );

    var filtered = await repository.getFilteredProjects(repoFilter);
    // provider-level userId filter; repo doesn't handle shared-users
    if (params.filter.userId != null) {
      filtered = filtered.where((p) => p.sharedUsers.contains(params.filter.userId!)).toList();
    }

    // sort in-memory (dataset is expected to be moderate in size)
    filtered = _sortProjects(filtered, params.sortBy, params.sortAscending);

    // paginate
    final startIndex = (params.page - 1) * params.limit;
    if (startIndex >= filtered.length) return [];
    return filtered.skip(startIndex).take(params.limit).toList();
  },
);
