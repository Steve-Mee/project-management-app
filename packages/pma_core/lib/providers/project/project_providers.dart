// ignore_for_file: prefer_const_constructors
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive/hive.dart';
import 'package:pma_core/models/project_model.dart';
import 'package:pma_core/repository/impl/hive_project_repository.dart';
import 'package:pma_core/repository/i_project_repository.dart' as repo;
import 'package:pma_core/repository/models/project_models.dart';
import 'package:pma_core/services/app_logger.dart';
import 'package:pma_core/providers/auth/auth_providers.dart';
import 'package:pma_core/repository/impl/project_meta_repository.dart';

import 'package:pma_core/models/project_meta.dart';
import 'package:pma_core/auth/permissions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pma_core/models/project_filter.dart' as models;

part 'project_providers.freezed.dart';

/// Parameters for the filtered projects family provider
@freezed
abstract class ProjectFilterParams with _$ProjectFilterParams {
  const factory ProjectFilterParams({
    String? status,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    String? priority,
    String? ownerId,
    List<String>? tags,
    List<ProjectFilterConditions>? extraConditions,
  }) = _ProjectFilterParams;
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

/// In-memory cache for individual projects (key = project ID)
final projectCacheProvider = StateProvider.family<ProjectModel?, String>((ref, id) {
  // Auto-expire cache after 5 minutes
  ref.onDispose(() {
    Future.delayed(const Duration(minutes: 5), () {
      ref.invalidateSelf();
    });
  });
  return null;
});

/// Provider for project repository with abstract interface
/// Easy to swap implementations for testing or different backends
final projectRepositoryProvider = Provider<repo.IProjectRepository>((ref) {
  return HiveProjectRepository();
});

/// @deprecated Use projectsPaginatedProvider instead for better performance
/// (kept for backward compatibility)
/// Provider for projects with caching and TTL
/// Uses AsyncValue.guard() for robust error handling
final projectsProvider = AsyncNotifierProvider<ProjectsNotifier, List<ProjectModel>>(
  ProjectsNotifier.new,
);


/// Cached individual project provider (keeps alive for 5 minutes)
final projectByIdProvider = FutureProvider.autoDispose.family<ProjectModel, String>((ref, id) async {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.getProjectById(id);
});

/// Family provider for filtered projects (synchronous filtering)
/// Uses the projectsProvider for data and filters synchronously
final filteredProjectsProvider = Provider.autoDispose.family<List<ProjectModel>, models.ProjectFilter>((ref, filter) {
  final projectsAsync = ref.watch(projectsProvider);
  return projectsAsync.maybeWhen(
    data: (projects) => _filterProjects(projects, filter),
    orElse: () => <ProjectModel>[],
  );
});

/// Fuzzy search implementation for project name, description, and tags
bool _matchesFuzzySearch(ProjectModel project, String query) {
  final searchFields = [
    project.name.toLowerCase(),
    project.description?.toLowerCase() ?? '',
    ...project.tags.map((tag) => tag.toLowerCase()),
  ];

  // Simple fuzzy search: check if query words are contained in any field
  final queryWords = query.split(' ').where((word) => word.isNotEmpty);
  
  for (final field in searchFields) {
    // Exact match gets highest priority
    if (field.contains(query)) return true;
    
    // Check if all query words are present in the field (fuzzy match)
    if (queryWords.every(field.contains)) return true;
    
    // Check for partial matches (e.g., "proj" matches "project")
    for (final word in queryWords) {
      if (field.contains(word)) return true;
    }
  }
  
  return false;
}

/// Fuzzy search helper: filters projects by search query
/// Searches on name, description and tags (case-insensitive, contains or Levenshtein if simple)
List<ProjectModel> _fuzzySearch(List<ProjectModel> projects, String query) {
  if (query.isEmpty) return projects;
  
  AppLogger.debug('Fuzzy search: filtering ${projects.length} projects with query "$query"');
  final filtered = projects.where((p) => _matchesFuzzySearch(p, query.toLowerCase())).toList();
  AppLogger.debug('Fuzzy search: found ${filtered.length} matching projects');
  
  return filtered;
}

/// Synchronous filtering function for projects using ProjectFilter
List<ProjectModel> _filterProjects(List<ProjectModel> projects, models.ProjectFilter filter) {
  var filtered = projects;

  // Apply status filter
  if (filter.status != null && filter.status!.isNotEmpty) {
    filtered = filtered.where((p) => p.status == filter.status).toList();
  }

  // Apply search query with fuzzy matching
  if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
    filtered = _fuzzySearch(filtered, filter.searchQuery!);
  }

  // Apply priority filter
  if (filter.priority != null && filter.priority!.isNotEmpty) {
    filtered = filtered.where((p) => p.priority == filter.priority).toList();
  }

  // Apply tags filter (OR logic - project must have at least one of the tags)
  if (filter.tags != null && filter.tags!.isNotEmpty) {
    filtered = filtered.where((p) => filter.tags!.any((tag) => p.tags.contains(tag))).toList();
  }

  // Apply start date filter: include projects with startDate on or after the filter startDate
  if (filter.startDate != null) {
    filtered = filtered.where((p) => p.startDate != null && p.startDate!.isAfter(filter.startDate!.subtract(const Duration(days: 1)))).toList();
  }

  // Apply end date filter: include projects with dueDate on or before the filter endDate
  if (filter.endDate != null) {
    filtered = filtered.where((p) => p.dueDate != null && p.dueDate!.isBefore(filter.endDate!.add(const Duration(days: 1)))).toList();
  }

  return filtered;
}
// Ready for UI integration

/// Combined parameters for filtered pagination
@freezed
abstract class FilteredPaginationParams with _$FilteredPaginationParams {
  const factory FilteredPaginationParams({
    required ProjectFilter filter,
    required int page,
    required int limit,
  }) = _FilteredPaginationParams;
}

/// Provider for filtered and paginated projects
/// Combines filtering with pagination for infinite scroll
final filteredProjectsPaginatedProvider = FutureProvider.autoDispose.family<List<ProjectModel>, FilteredPaginationParams>((ref, params) async {
  final repository = ref.watch(projectRepositoryProvider);

  // First get all filtered projects
  final allFiltered = await repository.getFilteredProjects(
    models.ProjectFilter(
      status: params.filter.status,
      searchQuery: params.filter.searchQuery,
      startDate: params.filter.startDate,
      endDate: params.filter.endDate,
      priority: params.filter.priority,
      tags: params.filter.tags,
    ),
    extraConditions: params.filter.extraConditions ?? [],
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
    if (params.page < 1) {
      throw ArgumentError.value(params.page, 'page', 'must be >= 1');
    }
    if (params.limit <= 0) {
      throw ArgumentError.value(params.limit, 'limit', 'must be > 0');
    }

    ref.keepAlive();
    final repository = ref.watch(projectRepositoryProvider);
    return repository.getProjectsPaginated(
      page: params.page,
      limit: params.limit,
      filter: params.filter,
    );
  },
);

/// Backward-compatible alias retained for older docs/imports.
@Deprecated('Use projectsPaginatedProvider instead.')
final paginatedProjectsProvider = projectsPaginatedProvider;

/// Filter class for project queries
/// Extensible for future filter parameters
@Freezed(fromJson: false, toJson: false)
abstract class ProjectFilter with _$ProjectFilter {
  const ProjectFilter._();

  static const List<String> sortOptions = [
    'name',
    'priority',
    'startDate',
    'dueDate',
    'status',
  ];

  const factory ProjectFilter({
    String? status,
    String? ownerId,
    String? searchQuery,
    String? priority,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? dueDateStart,
    DateTime? dueDateEnd,
    List<String>? tags,
    List<String>? requiredTags,
    List<ProjectFilterConditions>? extraConditions,
    String? sortBy,
    @Default(true) bool sortAscending,
    String? viewName,
    @Default(false) bool isSaved,
    @Default('list') String viewMode,
    @Default(false) bool addToDashboard,
  }) = _ProjectFilter;

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'ownerId': ownerId,
      'searchQuery': searchQuery,
      'priority': priority,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'dueDateStart': dueDateStart?.toIso8601String(),
      'dueDateEnd': dueDateEnd?.toIso8601String(),
      'tags': tags,
      'sortBy': sortBy,
      'sortAscending': sortAscending,
      'viewName': viewName,
      'isSaved': isSaved,
      'viewMode': viewMode,
      'addToDashboard': addToDashboard,
      // extraConditions not persisted as they are complex
    };
  }

  factory ProjectFilter.fromJson(Map<String, dynamic> json) {
    return ProjectFilter(
      status: json['status'] as String?,
      ownerId: json['ownerId'] as String?,
      searchQuery: json['searchQuery'] as String?,
      priority: json['priority'] as String?,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      dueDateStart: json['dueDateStart'] != null ? DateTime.parse(json['dueDateStart'] as String) : null,
      dueDateEnd: json['dueDateEnd'] != null ? DateTime.parse(json['dueDateEnd'] as String) : null,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      sortBy: json['sortBy'] as String?,
      sortAscending: json['sortAscending'] as bool? ?? true,
      viewName: json['viewName'] as String?,
      isSaved: json['isSaved'] as bool? ?? false,
      viewMode: json['viewMode'] as String? ?? 'list',
      addToDashboard: json['addToDashboard'] as bool? ?? false,
    );
  }
}

class ProjectPaginationParams {
  final int page;
  final int limit;
  final models.ProjectFilter? filter;

  const ProjectPaginationParams({
    required this.page,
    required this.limit,
    this.filter,
  });
}

/// Notifier for managing projects with caching, pagination, and error handling.
///
/// Notes:
/// - Uses [IProjectRepository.getAllProjects] as the source of truth.
/// - Paginates in-memory for backward compatibility with existing repository APIs.
/// - State remains `AsyncValue<List<ProjectModel>>` via `AsyncNotifier<List<ProjectModel>>`.
class ProjectsNotifier extends AsyncNotifier<List<ProjectModel>> {
  late repo.IProjectRepository _repository;
  _CacheEntry<List<ProjectModel>>? _cache;
  static const _cacheTtl = Duration(minutes: 5); // Configurable TTL
  static const int pageSize = 20;

  /// Current page in the in-memory dataset (starts at 1).
  int currentPage = 1;

  /// True when more pages are available.
  bool hasMore = true;

  /// True while [loadMoreProjects] is appending data.
  bool isLoadingMore = false;

  /// Stores non-fatal pagination errors from [loadMoreProjects].
  ///
  /// We keep already-loaded items in state and surface this separately so
  /// the UI can show a retry affordance at the list footer.
  Object? loadMoreError;

  @override
  Future<List<ProjectModel>> build() async {
    _repository = ref.watch(projectRepositoryProvider);
    return _loadInitialPage();
  }

  /// Loads all projects and updates cache.
  Future<List<ProjectModel>> _loadProjects() async {
    final projects = await _repository.getAllProjects();
    _cache = _CacheEntry(projects, DateTime.now(), _cacheTtl);
    return projects;
  }

  /// Resets pagination and loads page 1.
  Future<List<ProjectModel>> _loadInitialPage() async {
    final allProjects = (_cache != null && !_cache!.isExpired)
        ? _cache!.data
        : await _loadProjects();

    currentPage = 1;
    isLoadingMore = false;
    loadMoreError = null;

    final firstPage = allProjects.take(pageSize).toList();
    hasMore = allProjects.length > firstPage.length;
    return firstPage;
  }

  /// Loads and appends the next page for infinite scroll.
  ///
  /// Pagination logic (issue #064):
  /// 1. Fetch source list from [IProjectRepository.getAllProjects].
  /// 2. Compute next page start index as `(nextPage - 1) * pageSize`.
  /// 3. Append `skip(startIndex).take(pageSize)` to existing state.
  /// 4. Set [hasMore] to false when there are no more items.
  ///
  /// No-op when already loading or when [hasMore] is false.
  Future<void> loadMoreProjects() async {
    if (isLoadingMore || !hasMore) {
      return;
    }

    final currentItems = state.valueOrNull ?? const <ProjectModel>[];
    isLoadingMore = true;
    loadMoreError = null;

    try {
      final allProjects = (_cache != null && !_cache!.isExpired)
          ? _cache!.data
          : await _loadProjects();

      final nextPage = currentPage + 1;
      final startIndex = (nextPage - 1) * pageSize;

      if (startIndex >= allProjects.length) {
        hasMore = false;
        return;
      }

      final nextItems = allProjects.skip(startIndex).take(pageSize).toList();
      final combined = [...currentItems, ...nextItems];

      currentPage = nextPage;
      hasMore = combined.length < allProjects.length;
      state = AsyncValue.data(combined);
    } catch (e, st) {
      // Keep rendered items and surface load-more errors separately.
      loadMoreError = e;
      if (currentItems.isEmpty) {
        state = AsyncValue.error(e, st);
      } else {
        state = AsyncValue.data(currentItems);
      }
    } finally {
      isLoadingMore = false;
    }
  }

  void clearLoadMoreError() {
    loadMoreError = null;
  }

  Future<void> addProject(ProjectModel project) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = ref.read(authProvider).maybeWhen(
        data: (auth) => auth.username,
        orElse: () => 'system',
      ) ?? 'system'; // Use auth provider
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
        params: {
          'id': project.id,
          'name': project.name,
          'status': project.status,
        },
      );
      _cache = null;
      return _loadInitialPage();
    });
  }

  /// Update project progress with error handling
  Future<void> updateProgress(String projectId, double newProgress) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = ref.read(authProvider).maybeWhen(
        data: (auth) => auth.username,
        orElse: () => 'system',
      ) ?? 'system'; // Use auth provider
      await _repository.updateProgress(
        projectId,
        newProgress,
        userId: userId,
        metadata: {'progress': newProgress},
      );
      AppLogger.event(
        'project_progress_updated',
        params: {'id': projectId, 'progress': newProgress},
      );
      _cache = null;
      return _loadInitialPage();
    });
  }

  /// Update project's directory path
  Future<void> updateDirectoryPath(String projectId, String? directoryPath) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = ref.read(authProvider).maybeWhen(
        data: (auth) => auth.username,
        orElse: () => 'system',
      ) ?? 'system';
      await _repository.updateDirectoryPath(
        projectId,
        directoryPath,
        userId: userId,
        metadata: {'action': 'update_directory_path'},
      );
      AppLogger.event('project_directory_updated', params: {'id': projectId});
      _cache = null;
      return _loadInitialPage();
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
      final userId = ref.read(authProvider).maybeWhen(
        data: (auth) => auth.username,
        orElse: () => 'system',
      ) ?? 'system'; // Use auth provider
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
        params: {
          'id': projectId,
          'change_description': changeDescription,
        },
      );
      _cache = null;
      return _loadInitialPage();
    });
  }

  /// Refresh projects (bypasses cache)
  Future<void> refresh() async {
    _cache = null;
    loadMoreError = null;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_loadInitialPage);
  }

  @Deprecated('Use projectByIdProvider(id) family provider instead. It provides better performance by only loading the specific project when needed and auto-disposing when no longer watched. Migration: replace ref.read(projectsProvider.notifier).getProjectById(id) with ref.watch(projectByIdProvider(id)) or ref.read(projectByIdProvider(id).future)')
  /// Use projectByIdProvider family provider instead for better performance and Riverpod patterns.
  Future<ProjectModel> getProjectById(String id) async {
    final projects = state.maybeWhen(
      data: (data) => data,
      orElse: () => <ProjectModel>[],
    );
    return projects.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Project with id $id not found'),
    );
  }

  /// Delete project with error handling
  Future<void> deleteProject(String projectId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = ref.read(authProvider).maybeWhen(
        data: (auth) => auth.username,
        orElse: () => 'system',
      ) ?? 'system';
      await _repository.deleteProject(projectId, userId: userId);
      AppLogger.event('project_deleted', params: {'id': projectId});
      _cache = null;
      return _loadInitialPage();
    });
  }

  /// Update a project's tasks list via repository
  Future<void> updateTasks(String projectId, List<String> tasks) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = ref.read(authProvider).maybeWhen(
        data: (auth) => auth.username,
        orElse: () => 'system',
      ) ?? 'system';
      await _repository.updateTasks(
        projectId,
        tasks,
        userId: userId,
        metadata: {'action': 'update_tasks'},
      );
      AppLogger.event('project_tasks_updated', params: {'id': projectId});
      _cache = null;
      return _loadInitialPage();
    });
  }

  /// Update project's plan JSON
  Future<void> updatePlanJson(String projectId, String? planJson) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final userId = ref.read(authProvider).maybeWhen(
        data: (auth) => auth.username,
        orElse: () => 'system',
      ) ?? 'system';
      await _repository.updatePlanJson(
        projectId,
        planJson,
        userId: userId,
        metadata: {'action': 'update_plan_json'},
      );
      AppLogger.event('project_plan_updated', params: {'id': projectId});
      _cache = null;
      return _loadInitialPage();
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
  final authAsync = ref.watch(authProvider);
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
      final username = authAsync.maybeWhen(data: (auth) => auth.username, orElse: () => null);
      return AsyncValue.data(
        projects.where((p) => p.sharedUsers.contains(username ?? '')).toList(),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
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
    final repoFilter = models.ProjectFilter(
      status: params.filter.status,
      searchQuery: params.filter.searchQuery,
    );

    var filtered = await repository.getFilteredProjects(repoFilter);
    // provider-level ownerId filter; repo doesn't handle shared-users
    if (params.filter.ownerId != null) {
      filtered = filtered.where((p) => p.sharedUsers.contains(params.filter.ownerId!)).toList();
    }

    // sort in-memory (dataset is expected to be moderate in size)
    filtered = _sortProjects(filtered, params.sortBy, params.sortAscending);

    // paginate
    final startIndex = (params.page - 1) * params.limit;
    if (startIndex >= filtered.length) return [];
    return filtered.skip(startIndex).take(params.limit).toList();
  },
);

/// Notifier for persistent project filter
class ProjectFilterNotifier extends StateNotifier<ProjectFilter> {
  static const String _boxName = 'project_filters';
  static const String _key = 'current_filter';
  static const String _defaultKey = 'default_project_filter';
  static const String _recentFiltersKey = 'recent_filters';
  static const int _maxRecentFilters = 5;
  static const String _channelName = 'project_filters';

  RealtimeChannel? _channel;
  StreamSubscription? _channelSubscription;
  List<ProjectFilter> _recentFilters = [];

  ProjectFilterNotifier() : super(const ProjectFilter()) {
    _loadFilter();
    _loadRecentFilters();
    _initializeRealtime();
  }

  Future<void> _initializeRealtime() async {
    try {
      final supabase = Supabase.instance.client;
      _channel = supabase.channel(_channelName);

      _channel!.onBroadcast(
        event: 'filter_change',
        callback: (payload, [_]) {
          _handleRealtimeFilterChange(payload);
        },
      ).subscribe();

      // Track our presence for collaborative features
      final user = supabase.auth.currentUser;
      if (user != null) {
        await _channel!.track({
          'user_id': user.id,
          'user_email': user.email,
        });
      }
    } catch (e) {
      AppLogger.instance.e('Failed to initialize filter realtime: $e');
    }
  }

  void _handleRealtimeFilterChange(Map<String, dynamic> payload) {
    // This will be handled by a separate notification provider
    // that listens to this notifier and shows UI notifications
  }

  Future<void> _broadcastFilterChange(String changeType, {String? viewName}) async {
    if (_channel == null) return;

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await _channel!.sendBroadcastMessage(
        event: 'filter_change',
        payload: {
          'userId': user.id,
          'viewName': viewName,
          'changeType': changeType,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      AppLogger.instance.e('Failed to broadcast filter change: $e');
    }
  }

  @override
  void dispose() {
    _channelSubscription?.cancel();
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadFilter() async {
    try {
      final box = await Hive.openBox(_boxName);
      final json = box.get(_key);
      if (json != null && json is Map) {
        state = ProjectFilter.fromJson(Map<String, dynamic>.from(json));
      } else {
        // If no current filter, load default
        await _loadDefaultFilter();
      }
    } catch (e) {
      // Fallback to default if loading fails
      await _loadDefaultFilter();
    }
  }

  Future<void> _loadRecentFilters() async {
    try {
      final box = await Hive.openBox(_boxName);
      final jsonList = box.get(_recentFiltersKey);
      if (jsonList != null && jsonList is List) {
        _recentFilters = jsonList
            .map((json) => ProjectFilter.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
    } catch (e) {
      _recentFilters = [];
    }
  }

  Future<void> _saveRecentFilters() async {
    try {
      final box = await Hive.openBox(_boxName);
      final jsonList = _recentFilters.map((filter) => filter.toJson()).toList();
      await box.put(_recentFiltersKey, jsonList);
    } catch (e) {
      // Log error but don't fail
    }
  }

  Future<void> _saveFilter(ProjectFilter filter) async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_key, filter.toJson());
    } catch (e) {
      // Log error but don't fail
    }
  }

  Future<void> _loadDefaultFilter() async {
    try {
      final box = await Hive.openBox(_boxName);
      final json = box.get(_defaultKey);
      if (json != null && json is Map) {
        state = ProjectFilter.fromJson(Map<String, dynamic>.from(json));
      } else {
        state = const ProjectFilter();
      }
    } catch (e) {
      state = const ProjectFilter();
    }
  }

  Future<void> saveAsDefault() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_defaultKey, state.toJson());
    } catch (e) {
      // Log error
    }
  }

  void clearAll() {
    state = const ProjectFilter();
    _saveFilter(state);
  }

  void updateFilter(ProjectFilter newFilter) {
    state = newFilter;
    _saveFilter(newFilter);
    _addToRecentFilters(newFilter);
    _broadcastFilterChange('apply');
  }

  void _addToRecentFilters(ProjectFilter filter) {
    // Remove if already exists (to move to front)
    _recentFilters.removeWhere((f) => f == filter);
    // Add to front
    _recentFilters.insert(0, filter);
    // Keep only the most recent 5
    if (_recentFilters.length > _maxRecentFilters) {
      _recentFilters = _recentFilters.sublist(0, _maxRecentFilters);
    }
    _saveRecentFilters();
  }

  Future<void> saveView(String name) async {
    final savedFilter = state.copyWith(viewName: name, isSaved: true);
    // Update the current filter to reflect it's saved
    state = savedFilter;
    _saveFilter(savedFilter);
    // Also save to saved views
    // This will be handled by the SavedViewsNotifier
    await _broadcastFilterChange('save', viewName: name);
  }

  Future<void> loadView(ProjectFilter view) async {
    state = view;
    _saveFilter(view);
  }

  Future<void> deleteView(String viewName) async {
    // If current filter is the deleted view, reset to default
    if (state.viewName == viewName) {
      await _loadDefaultFilter();
    }
    // The actual deletion is handled by SavedViewsNotifier
    await _broadcastFilterChange('delete', viewName: viewName);
  }

  List<ProjectFilter> get recentFilters => _recentFilters;

  /// Bulk operations for selected projects
  Future<void> bulkDeleteProjects(Set<String> projectIds, WidgetRef ref) async {
    final repository = ref.read(projectRepositoryProvider);
    for (final id in projectIds) {
      await repository.deleteProject(id);
    }
  }

  Future<void> bulkUpdatePriority(Set<String> projectIds, String priority, WidgetRef ref) async {
    // Migrated to use projectByIdProvider for consistency with Riverpod patterns.
    final repository = ref.read(projectRepositoryProvider);
    for (final id in projectIds) {
      final project = await ref.read(projectByIdProvider(id).future);
      final updated = ProjectModel(
          id: project.id,
          name: project.name,
          progress: project.progress,
          directoryPath: project.directoryPath,
          tasks: project.tasks,
          status: project.status,
          description: project.description,
          category: project.category,
          aiAssistant: project.aiAssistant,
          planJson: project.planJson,
          helpLevel: project.helpLevel,
          complexity: project.complexity,
          history: project.history,
          sharedUsers: project.sharedUsers,
          sharedGroups: project.sharedGroups,
          priority: priority,
          startDate: project.startDate,
          dueDate: project.dueDate,
        );
        await repository.updateProject(id, updated);
    }
  }

  Future<void> bulkUpdateStatus(Set<String> projectIds, String status, WidgetRef ref) async {
    // Migrated to use projectByIdProvider for consistency with Riverpod patterns.
    final repository = ref.read(projectRepositoryProvider);
    for (final id in projectIds) {
      final project = await ref.read(projectByIdProvider(id).future);
      final updated = ProjectModel(
          id: project.id,
          name: project.name,
          progress: project.progress,
          directoryPath: project.directoryPath,
          tasks: project.tasks,
          status: status,
          description: project.description,
          category: project.category,
          aiAssistant: project.aiAssistant,
          planJson: project.planJson,
          helpLevel: project.helpLevel,
          complexity: project.complexity,
          history: project.history,
          sharedUsers: project.sharedUsers,
          sharedGroups: project.sharedGroups,
          priority: project.priority,
          startDate: project.startDate,
          dueDate: project.dueDate,
        );
        await repository.updateProject(id, updated);
    }
  }

  Future<void> bulkAssignUser(Set<String> projectIds, String username, WidgetRef ref) async {
    final repository = ref.read(projectRepositoryProvider);
    for (final id in projectIds) {
      await repository.addSharedUser(id, username);
    }
  }
}

/// Persistent project filter provider
final persistentProjectFilterProvider = StateNotifierProvider<ProjectFilterNotifier, ProjectFilter>((ref) {
  return ProjectFilterNotifier();
});

/// Provider for saved project filter views loaded from Hive box 'saved_views'
/// Provider for realtime filter change notifications
final filterChangeNotificationsProvider = StateNotifierProvider<FilterNotificationNotifier, List<FilterChangeNotification>>((ref) {
  return FilterNotificationNotifier();
});

/// Notification model for filter changes
class FilterChangeNotification {
  final String userId;
  final String? userEmail;
  final String? viewName;
  final String changeType; // 'apply', 'save', 'delete', 'reset'
  final DateTime timestamp;
  final bool isRead;

  const FilterChangeNotification({
    required this.userId,
    required this.changeType,
    required this.timestamp,
    this.userEmail,
    this.viewName,
    this.isRead = false,
  });

  FilterChangeNotification copyWith({
    String? userId,
    String? userEmail,
    String? viewName,
    String? changeType,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return FilterChangeNotification(
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      viewName: viewName ?? this.viewName,
      changeType: changeType ?? this.changeType,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  String get id => '${userId}_${timestamp.millisecondsSinceEpoch}';
}

/// Notifier for managing filter change notifications
class FilterNotificationNotifier extends StateNotifier<List<FilterChangeNotification>> {
  static const String _channelName = 'project_filters';
  static const Duration _notificationTimeout = Duration(seconds: 30);

  RealtimeChannel? _channel;
  Timer? _cleanupTimer;

  FilterNotificationNotifier() : super([]) {
    _initializeRealtime();
    _startCleanupTimer();
  }

  Future<void> _initializeRealtime() async {
    try {
      final supabase = Supabase.instance.client;
      _channel = supabase.channel(_channelName);

      _channel!.onBroadcast(
        event: 'filter_change',
        callback: (payload, [_]) {
          _handleFilterChangeNotification(payload);
        },
      ).subscribe();
    } catch (e) {
      AppLogger.instance.e('Failed to initialize notification realtime: $e');
    }
  }

  void _handleFilterChangeNotification(Map<String, dynamic> payload) {
    final userId = payload['userId'] as String?;
    final viewName = payload['viewName'] as String?;
    final changeType = payload['changeType'] as String?;
    final timestamp = payload['timestamp'] as String?;

    if (userId == null || changeType == null) return;

    // Don't show notifications for our own changes
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;
    if (currentUser?.id == userId) return;

    final notification = FilterChangeNotification(
      userId: userId,
      viewName: viewName,
      changeType: changeType,
      timestamp: timestamp != null ? DateTime.parse(timestamp) : DateTime.now(),
    );

    // Add to state (limit to last 10 notifications)
    state = [...state, notification].take(10).toList();
  }

  void markAsRead(String notificationId) {
    state = state.map((notification) {
      if ('${notification.userId}_${notification.timestamp.millisecondsSinceEpoch}' == notificationId) {
        return notification.copyWith(isRead: true);
      }
      return notification;
    }).toList();
  }

  void dismissNotification(String notificationId) {
    state = state.where((notification) => notification.id != notificationId).toList();
  }

  void clearAll() {
    state = [];
  }

  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(_notificationTimeout, (_) {
      final cutoff = DateTime.now().subtract(_notificationTimeout);
      state = state.where((notification) => notification.timestamp.isAfter(cutoff)).toList();
    });
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    _channel?.unsubscribe();
    super.dispose();
  }
}
/// Provider for selected project IDs in bulk selection mode
final selectedProjectIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Provider for bulk selection mode state
final isSelectionModeProvider = StateProvider<bool>((ref) => false);
class SavedViewsNotifier extends StateNotifier<List<ProjectFilter>> {
  static const String _boxName = 'saved_views';
  static const String _channelName = 'project_filters';

  RealtimeChannel? _channel;

  SavedViewsNotifier() : super([]) {
    _loadViews();
    syncFromSupabase();
    _initializeRealtime();
  }

  Future<void> _loadViews() async {
    try {
      final box = await Hive.openBox(_boxName);
      final views = <ProjectFilter>[];
      for (final key in box.keys) {
        final json = box.get(key);
        if (json != null && json is Map) {
          final filter = ProjectFilter.fromJson(Map<String, dynamic>.from(json));
          if (filter.isSaved && filter.viewName != null) {
            views.add(filter);
          }
        }
      }
      state = views;
    } catch (e) {
      state = [];
    }
  }

  Future<void> _saveViews() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.clear();
      for (final view in state) {
        if (view.viewName != null) {
          await box.put(view.viewName!, view.toJson());
        }
      }
    } catch (e) {
      // Log error but don't fail
    }
  }

  Future<void> syncFromSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('user_views')
          .select('view_name, filter_data')
          .eq('user_id', user.id);

      final remoteViews = <ProjectFilter>[];
      for (final row in response) {
        final filterData = row['filter_data'] as Map<String, dynamic>;
        final filter = ProjectFilter.fromJson(filterData);
        final viewWithName = filter.copyWith(viewName: row['view_name'], isSaved: true);
        remoteViews.add(viewWithName);
      }

      // Merge with local views (remote takes precedence)
      final localViews = Map<String, ProjectFilter>.fromEntries(
        state.where((v) => v.viewName != null).map((v) => MapEntry(v.viewName!, v))
      );

      for (final remoteView in remoteViews) {
        localViews[remoteView.viewName!] = remoteView;
      }

      state = localViews.values.toList();
      await _saveViews();
    } catch (e) {
      // Log error but don't fail
    }
  }

  Future<void> _initializeRealtime() async {
    try {
      final supabase = Supabase.instance.client;
      _channel = supabase.channel(_channelName);

      // Listen for filter changes from other users
      _channel!.onBroadcast(
        event: 'filter_change',
        callback: (payload, [_]) {
          // This will trigger a refresh of saved views if needed
          _handleRealtimeFilterChange(payload);
        },
      ).subscribe();
    } catch (e) {
      AppLogger.instance.e('Failed to initialize saved views realtime: $e');
    }
  }

  void _handleRealtimeFilterChange(Map<String, dynamic> payload) {
    // Refresh saved views when other users make changes
    // This ensures the dashboard stays in sync
    syncFromSupabase();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _syncToSupabase(ProjectFilter filter) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null || filter.viewName == null) return;

      await supabase.from('user_views').upsert({
        'user_id': user.id,
        'view_name': filter.viewName,
        'filter_data': filter.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // If Supabase sync fails, continue locally
    }
  }

  Future<void> saveView(ProjectFilter filter, String name) async {
    final savedFilter = filter.copyWith(viewName: name, isSaved: true);
    final existingIndex = state.indexWhere((v) => v.viewName == name);
    if (existingIndex >= 0) {
      state = [...state]..[existingIndex] = savedFilter;
    } else {
      state = [...state, savedFilter];
    }
    await _saveViews();
    await _syncToSupabase(savedFilter);
    await _broadcastViewChange('save', viewName: name);
  }

  Future<void> deleteView(String viewName) async {
    state = state.where((v) => v.viewName != viewName).toList();
    await _saveViews();

    // Sync deletion to Supabase
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase
            .from('user_views')
            .delete()
            .eq('user_id', user.id)
            .eq('view_name', viewName);
      }
    } catch (e) {
      // If Supabase sync fails, continue locally
    }
  }

  Future<void> _broadcastViewChange(String changeType, {String? viewName}) async {
    if (_channel == null) return;

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await _channel!.sendBroadcastMessage(
        event: 'filter_change',
        payload: {
          'userId': user.id,
          'viewName': viewName,
          'changeType': changeType,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      AppLogger.instance.e('Failed to broadcast view change: $e');
    }
  }
}

/// Provider for saved project views
final savedProjectViewsProvider = StateNotifierProvider<SavedViewsNotifier, List<ProjectFilter>>(
  (ref) => SavedViewsNotifier(),
);

/// Provider for dashboard views (only views marked for dashboard)
final dashboardViewsProvider = Provider<List<ProjectFilter>>((ref) {
  final allViews = ref.watch(savedProjectViewsProvider);
  return allViews.where((view) => view.addToDashboard).toList();
});
