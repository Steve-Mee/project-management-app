import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:my_project_management_app/models/project_model.dart';
import 'package:my_project_management_app/core/repository/project_repository.dart';
import 'package:my_project_management_app/core/repository/i_project_repository.dart' as repo;
import 'package:my_project_management_app/core/services/app_logger.dart';
import 'auth_providers.dart'; // Import for auth provider access
import 'package:my_project_management_app/core/repository/project_meta_repository.dart';
import 'package:my_project_management_app/models/project_meta.dart';
import 'package:my_project_management_app/core/auth/permissions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Parameters for the filtered projects family provider
class ProjectFilterParams {
  final String? status;
  final String? searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? priority;
  final String? ownerId;
  final List<String>? tags;
  final List<repo.ProjectFilterConditions>? extraConditions;

  const ProjectFilterParams({
    this.status,
    this.searchQuery,
    this.startDate,
    this.endDate,
    this.priority,
    this.ownerId,
    this.tags,
    this.extraConditions,
  });

  ProjectFilterParams copyWith({
    String? status,
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    String? priority,
    String? ownerId,
    List<String>? tags,
    List<repo.ProjectFilterConditions>? extraConditions,
  }) {
    return ProjectFilterParams(
      status: status ?? this.status,
      searchQuery: searchQuery ?? this.searchQuery,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      priority: priority ?? this.priority,
      ownerId: ownerId ?? this.ownerId,
      tags: tags ?? this.tags,
      extraConditions: extraConditions ?? this.extraConditions,
    );
  }
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
final projectByIdProvider = FutureProvider.autoDispose.family<ProjectModel?, String>((ref, id) async {
  final repository = ref.watch(projectRepositoryProvider);
  return repository.getProjectById(id);
});

/// Family provider for filtered projects (e.g., by status, user, etc.)
/// Extensible for future filtering needs
final filteredProjectsProvider = FutureProvider.autoDispose.family<List<ProjectModel>, ProjectFilter>((ref, params) async {
  final repository = ref.watch(projectRepositoryProvider);
  var projects = await repository.getFilteredProjects(
    repo.ProjectFilter( // map params to repository filter
      status: params.status,
      searchQuery: null, // handle search client-side for fuzzy matching
      startDate: null, // dates handled client-side below
      endDate: null,
      priority: null, // priority handled client-side below
      ownerId: params.ownerId,
      tags: null,
    ),
    extraConditions: [],
  );

  // Apply fuzzy search on name, description, and tags
  if (params.searchQuery != null && params.searchQuery!.isNotEmpty) {
    final query = params.searchQuery!.toLowerCase();
    projects = projects.where((p) => _matchesFuzzySearch(p, query)).toList();
  }

  // Apply tags filter (OR logic - project must have at least one of the tags)
  if (params.tags != null && params.tags!.isNotEmpty) {
    projects = projects.where((p) => params.tags!.any((tag) => p.tags.contains(tag))).toList();
  }

  // Apply required tags filter (AND logic - project must have ALL required tags)
  if (params.requiredTags != null && params.requiredTags!.isNotEmpty) {
    projects = projects.where((p) => params.requiredTags!.every((tag) => p.tags.contains(tag))).toList();
  }

  // Apply priority filter: exact match if specified
  if (params.priority != null) {
    projects = projects.where((p) => p.priority == params.priority).toList();
  }

  // Apply start date filter: include projects with startDate on or after the filter startDate
  if (params.startDate != null) {
    projects = projects.where((p) => p.startDate != null && p.startDate!.isAfter(params.startDate!.subtract(const Duration(days: 1)))).toList();
  }

  // Apply end date filter: include projects with dueDate on or before the filter endDate
  if (params.endDate != null) {
    projects = projects.where((p) => p.dueDate != null && p.dueDate!.isBefore(params.endDate!.add(const Duration(days: 1)))).toList();
  }

  // Apply sorting
  if (params.sortBy != null) {
    projects = _applySort(projects, params.sortBy!, params.sortAscending);
  }

  return projects;
});

List<ProjectModel> _applySort(List<ProjectModel> projects, String sortBy, bool ascending) {
  projects.sort((a, b) {
    int compare = 0;
    switch (sortBy) {
      case 'name':
        compare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        break;
      case 'priority':
        final priorityOrder = {'Low': 1, 'Medium': 2, 'High': 3};
        final aPriority = priorityOrder[a.priority] ?? 0;
        final bPriority = priorityOrder[b.priority] ?? 0;
        compare = aPriority.compareTo(bPriority);
        break;
      case 'startDate':
        if (a.startDate == null && b.startDate == null) {
          compare = 0;
        } else if (a.startDate == null) {
          compare = 1;
        } else if (b.startDate == null) {
          compare = -1;
        } else {
          compare = a.startDate!.compareTo(b.startDate!);
        }
        break;
      case 'dueDate':
        if (a.dueDate == null && b.dueDate == null) {
          compare = 0;
        } else if (a.dueDate == null) {
          compare = 1;
        } else if (b.dueDate == null) {
          compare = -1;
        } else {
          compare = a.dueDate!.compareTo(b.dueDate!);
        }
        break;
      case 'status':
        compare = a.status.compareTo(b.status);
        break;
      default:
        compare = 0;
    }
    return ascending ? compare : -compare;
  });
  return projects;
}

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
    if (queryWords.every((word) => field.contains(word))) return true;
    
    // Check for partial matches (e.g., "proj" matches "project")
    for (final word in queryWords) {
      if (field.contains(word)) return true;
    }
  }
  
  return false;
}
// Ready for UI integration

/// Combined parameters for filtered pagination
class FilteredPaginationParams {
  final ProjectFilter filter;
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
  final String? ownerId;
  final String? searchQuery;
  final String? priority;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? dueDateStart;
  final DateTime? dueDateEnd;
  final List<String>? tags;
  final List<String>? requiredTags;
  final List<repo.ProjectFilterConditions>? extraConditions;
  final String? sortBy; // values: "name", "priority", "startDate", "dueDate", "createdAt", "status"
  final bool sortAscending;
  final String? viewName;
  final bool isSaved;
  final String viewMode; // 'list', 'kanban', 'table', 'gantt'
  final bool addToDashboard;

  static const List<String> sortOptions = [
    'name',
    'priority',
    'startDate',
    'dueDate',
    'status',
  ];

  const ProjectFilter({
    this.status,
    this.ownerId,
    this.searchQuery,
    this.priority,
    this.startDate,
    this.endDate,
    this.dueDateStart,
    this.dueDateEnd,
    this.tags,
    this.requiredTags,
    this.extraConditions,
    this.sortBy,
    this.sortAscending = true,
    this.viewName,
    this.isSaved = false,
    this.viewMode = 'list',
    this.addToDashboard = false,
  });

  ProjectFilter copyWith({
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
    List<repo.ProjectFilterConditions>? extraConditions,
    String? sortBy,
    bool? sortAscending,
    String? viewName,
    bool? isSaved,
    String? viewMode,
    bool? addToDashboard,
  }) {
    return ProjectFilter(
      status: status ?? this.status,
      ownerId: ownerId ?? this.ownerId,
      searchQuery: searchQuery ?? this.searchQuery,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dueDateStart: dueDateStart ?? this.dueDateStart,
      dueDateEnd: dueDateEnd ?? this.dueDateEnd,
      tags: tags ?? this.tags,
      requiredTags: requiredTags ?? this.requiredTags,
      extraConditions: extraConditions ?? this.extraConditions,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
      viewName: viewName ?? this.viewName,
      isSaved: isSaved ?? this.isSaved,
      viewMode: viewMode ?? this.viewMode,
      addToDashboard: addToDashboard ?? this.addToDashboard,
    );
  }

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectFilter &&
        other.status == status &&
        other.ownerId == ownerId &&
        other.searchQuery == searchQuery &&
        other.priority == priority &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.dueDateStart == dueDateStart &&
        other.dueDateEnd == dueDateEnd &&
        other.sortBy == sortBy &&
        other.sortAscending == sortAscending &&
        other.tags == tags &&
        other.extraConditions == extraConditions &&
        other.viewName == viewName &&
        other.isSaved == isSaved &&
        other.viewMode == viewMode;
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      ownerId,
      searchQuery,
      priority,
      startDate,
      endDate,
      dueDateStart,
      dueDateEnd,
      sortBy,
      sortAscending,
      tags,
      extraConditions,
      viewName,
      isSaved,
      viewMode,
    );
  }
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

  @Deprecated('Use projectByIdProvider instead for better performance')
  /// Get project by ID (consider using projectByIdProvider family provider instead)
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
    final repository = ref.read(projectRepositoryProvider);
    for (final id in projectIds) {
      final project = await repository.getProjectById(id);
      if (project != null) {
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
  }

  Future<void> bulkUpdateStatus(Set<String> projectIds, String status, WidgetRef ref) async {
    final repository = ref.read(projectRepositoryProvider);
    for (final id in projectIds) {
      final project = await repository.getProjectById(id);
      if (project != null) {
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
