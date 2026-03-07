import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/models/project_filter.dart' as model_filters;
import 'package:pma_core/models/project_model.dart';
import 'package:pma_core/providers/project_providers.dart';
import 'package:pma_core/providers/auth_providers.dart';
import 'package:pma_core/repository/i_project_repository.dart';
import 'package:pma_core/repository/models/project_models.dart';

// ignore_for_file: prefer_const_constructors

class FakeAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async {
    return const AuthState(isAuthenticated: true, username: 'test');
  }
}

class FakeProjectRepository implements IProjectRepository {
  final Map<String, ProjectModel> _store = {};
  int getProjectByIdCallCount = 0;

  FakeProjectRepository({List<ProjectModel>? seed}) {
    if (seed != null) {
      for (final project in seed) {
        _store[project.id] = project;
      }
    }
  }

  @override
  Future<void> addProject(
    ProjectModel project, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    _store[project.id] = project;
  }

  @override
  Future<List<ProjectModel>> getAllProjects() async {
    return _store.values.toList();
  }

  @override
  Future<ProjectModel> getProjectById(String id) async {
    getProjectByIdCallCount += 1;
    final project = _store[id];
    if (project == null) {
      throw Exception('Project with id $id not found');
    }
    return project;
  }

  @override
  Future<void> updateProgress(
    String projectId,
    double newProgress, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    final project = _store[projectId];
    if (project == null) {
      return;
    }

    _store[projectId] = ProjectModel(
      id: project.id,
      name: project.name,
      progress: newProgress,
      directoryPath: project.directoryPath,
      tasks: project.tasks,
      status: project.status,
      description: project.description,
    );
  }

  @override
  Future<void> updateTasks(
    String projectId,
    List<String> tasks, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    final project = _store[projectId];
    if (project == null) {
      return;
    }

    _store[projectId] = ProjectModel(
      id: project.id,
      name: project.name,
      progress: project.progress,
      directoryPath: project.directoryPath,
      tasks: tasks,
      status: project.status,
      description: project.description,
    );
  }

  @override
  Future<void> updateDirectoryPath(
    String projectId,
    String? directoryPath, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    final project = _store[projectId];
    if (project == null) {
      return;
    }

    _store[projectId] = ProjectModel(
      id: project.id,
      name: project.name,
      progress: project.progress,
      directoryPath: directoryPath,
      tasks: project.tasks,
      status: project.status,
      description: project.description,
    );
  }

  @override
  Future<void> deleteProject(
    String projectId, {
    String? userId,
    Map<String, Object?>? metadata,
  }) async {
    _store.remove(projectId);
  }

  // Stub implementations for remaining interface methods
  @override
  Future<void> updateProject(String projectId, ProjectModel updatedProject, {String? userId, String? changeDescription, Map<String, Object?>? metadata}) async {
    _store[projectId] = updatedProject;
  }

  @override
  Future<void> updatePlanJson(String projectId, String? planJson, {String? userId, Map<String, Object?>? metadata}) async {
    // Stub implementation
  }

  @override
  Future<void> close() async {
    // Stub implementation
  }

  @override
  Future<void> addSharedUser(String projectId, String username, {String? userId, Map<String, Object?>? metadata}) async {
    // Stub implementation
  }

  @override
  Future<void> removeSharedUser(String projectId, String username, {String? userId, Map<String, Object?>? metadata}) async {
    // Stub implementation
  }

  @override
  Future<void> addSharedGroup(String projectId, String groupId, {String? userId, Map<String, Object?>? metadata}) async {
    // Stub implementation
  }

  @override
  Future<void> removeSharedGroup(String projectId, String groupId, {String? userId, Map<String, Object?>? metadata}) async {
    // Stub implementation
  }

  @override
  Future<List<ProjectModel>> getProjectsPaginated({int page = 1, int limit = 20, model_filters.ProjectFilter? filter}) async {
    if (page < 1) {
      throw ArgumentError.value(page, 'page', 'must be >= 1');
    }
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'must be > 0');
    }

    var projects = _store.values.toList();
    projects.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (filter != null) {
      if (filter.status != null && filter.status!.isNotEmpty) {
        projects = projects.where((p) => p.status == filter.status).toList();
      }
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final q = filter.searchQuery!.toLowerCase();
        projects = projects
            .where((p) =>
                p.name.toLowerCase().contains(q) ||
                (p.description?.toLowerCase().contains(q) ?? false) ||
                p.tags.any((tag) => tag.toLowerCase().contains(q)))
            .toList();
      }
    }

    final startIndex = (page - 1) * limit;
    if (startIndex >= projects.length) {
      return <ProjectModel>[];
    }
    return projects.skip(startIndex).take(limit).toList();
  }

  @override
  Future<List<ProjectModel>> getProjectsByStatus(String status) async {
    return _store.values.where((p) => p.status == status).toList();
  }

  @override
  Future<List<ProjectModel>> getFilteredProjects(model_filters.ProjectFilter filter, {List<ProjectFilterConditions> extraConditions = const []}) async {
    return _store.values.toList();
  }

  @override
  Future<void> syncProject(String projectId) async {
    // Stub implementation
  }

  @override
  Future<void> syncAllProjects() async {
    // Stub implementation
  }

  @override
  Future<void> bidirectionalSyncProject(String projectId) async {
    // Stub implementation
  }

  @override
  Stream<List<ProjectModel>> watchProjectChanges(String projectId) {
    // Stub implementation
    return Stream.value([]);
  }

  @override
  Future<void> resolveConflict(ProjectModel local, ProjectModel remote) async {
    // Stub implementation
  }
}

void main() {
  test('ProjectsNotifier initializes with repository data', () async {
    const project = ProjectModel(
      id: 'p1',
      name: 'Alpha',
      progress: 0.2,
      status: 'In Progress',
    );
    final repository = FakeProjectRepository(seed: [project]);
    final container = ProviderContainer(overrides: [
      projectRepositoryProvider.overrideWithValue(repository),
      authProvider.overrideWith(() => FakeAuthNotifier()),
    ]);
    addTearDown(container.dispose);

    final projects = await container.read(projectsProvider.future);
    expect(projects.length, 1);
    expect(projects.first.name, 'Alpha');
  });

  test('ProjectsNotifier addProject updates state', () async {
    final repository = FakeProjectRepository();
    final container = ProviderContainer(overrides: [
      projectRepositoryProvider.overrideWithValue(repository),
      authProvider.overrideWith(() => FakeAuthNotifier()),
    ]);
    addTearDown(container.dispose);

    await container.read(projectsProvider.future);

    final notifier = container.read(projectsProvider.notifier);
    await notifier.addProject(
      const ProjectModel(
        id: 'p2',
        name: 'Beta',
        progress: 0.5,
        status: 'Planning',
      ),
    );

    final state = container.read(projectsProvider);
    expect(state, isA<AsyncData<List<ProjectModel>>>());
    expect(state.asData!.value.length, 1);
    expect(state.asData!.value.first.id, 'p2');
  });

  test('ProjectsNotifier updateProgress changes project', () async {
    final repository = FakeProjectRepository(
      seed: const [
        ProjectModel(
          id: 'p3',
          name: 'Gamma',
          progress: 0.1,
          status: 'In Progress',
        ),
      ],
    );
    final container = ProviderContainer(overrides: [
      projectRepositoryProvider.overrideWithValue(repository),
      authProvider.overrideWith(() => FakeAuthNotifier()),
    ]);
    addTearDown(container.dispose);

    // Wait for initial load
    await Future.delayed(Duration.zero);

    final notifier = container.read(projectsProvider.notifier);
    await notifier.updateProgress('p3', 0.9);

    final state = container.read(projectsProvider);
    expect(state, isA<AsyncData<List<ProjectModel>>>());
    expect(state.asData!.value.first.progress, 0.9);
  });

  test('ProjectsNotifier deleteProject removes project', () async {
    final repository = FakeProjectRepository(
      seed: const [
        ProjectModel(
          id: 'p4',
          name: 'Delta',
          progress: 0.3,
          status: 'Completed',
        ),
      ],
    );
    final container = ProviderContainer(overrides: [
      projectRepositoryProvider.overrideWithValue(repository),
      authProvider.overrideWith(() => FakeAuthNotifier()),
    ]);
    addTearDown(container.dispose);

    // Wait for initial load
    await Future.delayed(Duration.zero);

    final notifier = container.read(projectsProvider.notifier);
    await notifier.deleteProject('p4');

    final state = container.read(projectsProvider);
    expect(state, isA<AsyncData<List<ProjectModel>>>());
    expect(state.asData!.value.isEmpty, true);
  });

  test('fuzzy search matches projects by name', () async {
    final repository = FakeProjectRepository();
    final container = ProviderContainer(overrides: [
      projectRepositoryProvider.overrideWithValue(repository),
      authProvider.overrideWith(() => FakeAuthNotifier()),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(projectsProvider.notifier);

    // Add test projects
    await notifier.addProject(const ProjectModel(
      id: 'p1',
      name: 'Flutter Project',
      progress: 0.5,
      status: 'In Progress',
      tasks: [],
      description: 'A mobile app',
    ));

    await notifier.addProject(const ProjectModel(
      id: 'p2',
      name: 'React Website',
      progress: 0.3,
      status: 'Planning',
      tasks: [],
      description: 'A web application',
    ));

    // Test fuzzy search
    const filter = ProjectFilter(searchQuery: 'flutter');
    final results = container.read(filteredProjectsProvider(filter));
    expect(results.length, 1);
    expect(results[0].id, 'p1');
  });

  test('fuzzy search matches projects by description', () async {
    final repository = FakeProjectRepository();
    final container = ProviderContainer(overrides: [
      projectRepositoryProvider.overrideWithValue(repository),
      authProvider.overrideWith(() => FakeAuthNotifier()),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(projectsProvider.notifier);

    await notifier.addProject(const ProjectModel(
      id: 'p1',
      name: 'Mobile App',
      progress: 0.5,
      status: 'In Progress',
      tasks: [],
      description: 'Built with Flutter framework',
    ));

    // Test fuzzy search on description
    const filter = ProjectFilter(searchQuery: 'flutter');
    final results = container.read(filteredProjectsProvider(filter));
    expect(results.length, 1);
    expect(results[0].id, 'p1');
  });

  test('fuzzy search matches projects by tags', () async {
    final repository = FakeProjectRepository();
    final container = ProviderContainer(overrides: [
      projectRepositoryProvider.overrideWithValue(repository),
      authProvider.overrideWith(() => FakeAuthNotifier()),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(projectsProvider.notifier);

    await notifier.addProject(const ProjectModel(
      id: 'p1',
      name: 'Web App',
      progress: 0.5,
      status: 'In Progress',
      tasks: [],
      description: 'A web application',
      tags: ['flutter', 'mobile', 'dart'],
    ));

    // Test fuzzy search on tags
    const filter = ProjectFilter(searchQuery: 'mobile');
    final results = container.read(filteredProjectsProvider(filter));
    expect(results.length, 1);
    expect(results[0].id, 'p1');
  });

  test('fuzzy search tolerates small typos in query tokens', () async {
    final repository = FakeProjectRepository();
    final container = ProviderContainer(overrides: [
      projectRepositoryProvider.overrideWithValue(repository),
      authProvider.overrideWith(() => FakeAuthNotifier()),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(projectsProvider.notifier);

    await notifier.addProject(const ProjectModel(
      id: 'p-typo-1',
      name: 'Flutter Dashboard',
      progress: 0.5,
      status: 'In Progress',
      tasks: [],
      description: 'Analytics and planning workspace',
    ));

    // "fluter" (missing "t") should still match "flutter".
    const filter = ProjectFilter(searchQuery: 'fluter');
    final results = container.read(filteredProjectsProvider(filter));

    expect(results.length, 1);
    expect(results.first.id, 'p-typo-1');
  });

  test('projectsPaginatedProvider validates invalid params', () async {
    final repository = FakeProjectRepository();
    final container = ProviderContainer(overrides: [
      projectRepositoryProvider.overrideWithValue(repository),
      authProvider.overrideWith(() => FakeAuthNotifier()),
    ]);
    addTearDown(container.dispose);

    await expectLater(
      container.read(
        projectsPaginatedProvider(
          const ProjectPaginationParams(page: 0, limit: 10),
        ).future,
      ),
      throwsA(isA<ArgumentError>()),
    );

    await expectLater(
      container.read(
        projectsPaginatedProvider(
          const ProjectPaginationParams(page: 1, limit: 0),
        ).future,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('projectsPaginatedProvider returns paginated slice', () async {
    final repository = FakeProjectRepository(seed: const [
      ProjectModel(id: 'p1', name: 'Alpha', progress: 0.1, status: 'In Progress'),
      ProjectModel(id: 'p2', name: 'Beta', progress: 0.2, status: 'In Progress'),
      ProjectModel(id: 'p3', name: 'Gamma', progress: 0.3, status: 'In Progress'),
    ]);

    final container = ProviderContainer(overrides: [
      projectRepositoryProvider.overrideWithValue(repository),
      authProvider.overrideWith(() => FakeAuthNotifier()),
    ]);
    addTearDown(container.dispose);

    await container.read(projectsProvider.future);

    final page1 = await container.read(
      projectsPaginatedProvider(
        const ProjectPaginationParams(page: 1, limit: 2),
      ).future,
    );

    final page2 = await container.read(
      // ignore: deprecated_member_use
      paginatedProjectsProvider(
        const ProjectPaginationParams(page: 2, limit: 2),
      ).future,
    );

    expect(page1.length, 2);
    expect(page2.length, 1);
    expect(page1.first.name, 'Alpha');
    expect(page2.first.name, 'Gamma');
  });

  test('ProjectFilter bridge maps repository-supported fields only', () {
    final uiFilter = ProjectFilter(
      status: 'In Progress',
      ownerId: 'owner-1',
      searchQuery: 'alpha',
      priority: 'High',
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 31),
      dueDateStart: DateTime(2026, 2, 1),
      dueDateEnd: DateTime(2026, 2, 28),
      tags: const <String>['mobile'],
      requiredTags: const <String>['urgent'],
      sortBy: 'status',
      sortAscending: false,
      viewMode: 'board',
    );

    final repoFilter = uiFilter.toRepositoryFilter();

    expect(repoFilter.status, 'In Progress');
    expect(repoFilter.searchQuery, 'alpha');
    expect(repoFilter.priority, 'High');
    expect(repoFilter.startDate, DateTime(2026, 1, 1));
    expect(repoFilter.endDate, DateTime(2026, 1, 31));
    expect(repoFilter.tags, const <String>['mobile']);
  });

  test('projectByIdProvider uses per-project cache after provider invalidation', () async {
    final repository = FakeProjectRepository(seed: const [
      ProjectModel(id: 'p-cache-1', name: 'Cache One', progress: 0.1, status: 'In Progress'),
    ]);

    final container = ProviderContainer(overrides: [
      projectRepositoryProvider.overrideWithValue(repository),
      authProvider.overrideWith(() => FakeAuthNotifier()),
      projectByIdCacheTtlProvider.overrideWithValue(const Duration(minutes: 5)),
    ]);
    addTearDown(container.dispose);

    final first = await container.read(projectByIdProvider('p-cache-1').future);
    expect(first.name, 'Cache One');
    expect(repository.getProjectByIdCallCount, 1);
    expect(container.read(projectIsCachedProvider('p-cache-1')), isTrue);

    container.invalidate(projectByIdProvider('p-cache-1'));

    final second = await container.read(projectByIdProvider('p-cache-1').future);
    expect(second.name, 'Cache One');
    expect(repository.getProjectByIdCallCount, 1);
  });

  test('projectByIdProvider refreshes when TTL expired', () async {
    final repository = FakeProjectRepository(seed: const [
      ProjectModel(id: 'p-cache-2', name: 'Cache Two', progress: 0.2, status: 'Planning'),
    ]);

    final container = ProviderContainer(overrides: [
      projectRepositoryProvider.overrideWithValue(repository),
      authProvider.overrideWith(() => FakeAuthNotifier()),
      projectByIdCacheTtlProvider.overrideWithValue(Duration.zero),
    ]);
    addTearDown(container.dispose);

    await container.read(projectByIdProvider('p-cache-2').future);
    expect(repository.getProjectByIdCallCount, 1);

    await Future<void>.delayed(const Duration(milliseconds: 2));
    container.invalidate(projectByIdProvider('p-cache-2'));
    await container.read(projectByIdProvider('p-cache-2').future);

    expect(repository.getProjectByIdCallCount, 2);
  });

  test('mutations invalidate cached projectById entry', () async {
    final repository = FakeProjectRepository(seed: const [
      ProjectModel(id: 'p-cache-3', name: 'Cache Three', progress: 0.3, status: 'In Progress'),
    ]);

    final container = ProviderContainer(overrides: [
      projectRepositoryProvider.overrideWithValue(repository),
      authProvider.overrideWith(() => FakeAuthNotifier()),
      projectByIdCacheTtlProvider.overrideWithValue(const Duration(minutes: 5)),
    ]);
    addTearDown(container.dispose);

    await container.read(projectByIdProvider('p-cache-3').future);
    expect(repository.getProjectByIdCallCount, 1);
    expect(container.read(projectIsCachedProvider('p-cache-3')), isTrue);

    await container.read(projectsProvider.notifier).updateProgress('p-cache-3', 0.95);

    expect(container.read(projectCacheProvider('p-cache-3')), isNull);
    expect(container.read(projectCacheTimestampProvider('p-cache-3')), isNull);

    container.invalidate(projectByIdProvider('p-cache-3'));
    final refreshed = await container.read(projectByIdProvider('p-cache-3').future);

    expect(refreshed.progress, 0.95);
    expect(repository.getProjectByIdCallCount, 2);
  });

  test('filteredProjectsPaginatedProvider applies owner/requiredTags/dueDate range', () async {
    final repository = FakeProjectRepository(seed: [
      ProjectModel(
        id: 'p-f1',
        name: 'Alpha',
        progress: 0.2,
        status: 'In Progress',
        sharedUsers: <String>['owner-1'],
        tags: <String>['mobile', 'urgent'],
        dueDate: DateTime(2026, 2, 10),
      ),
      ProjectModel(
        id: 'p-f2',
        name: 'Beta',
        progress: 0.3,
        status: 'In Progress',
        sharedUsers: <String>['owner-1'],
        tags: <String>['mobile'],
        dueDate: DateTime(2026, 2, 10),
      ),
      ProjectModel(
        id: 'p-f3',
        name: 'Gamma',
        progress: 0.4,
        status: 'In Progress',
        sharedUsers: <String>['owner-2'],
        tags: <String>['mobile', 'urgent'],
        dueDate: DateTime(2026, 2, 10),
      ),
    ]);

    final container = ProviderContainer(overrides: [
      projectRepositoryProvider.overrideWithValue(repository),
      authProvider.overrideWith(() => FakeAuthNotifier()),
    ]);
    addTearDown(container.dispose);

    final params = FilteredPaginationParams(
      filter: ProjectFilter(
        ownerId: 'owner-1',
        requiredTags: const <String>['mobile', 'urgent'],
        dueDateStart: DateTime(2026, 2, 10),
        dueDateEnd: DateTime(2026, 2, 10),
        sortBy: 'name',
        sortAscending: true,
      ),
      page: 1,
      limit: 10,
    );

    final result = await container.read(filteredProjectsPaginatedProvider(params).future);

    expect(result.length, 1);
    expect(result.first.id, 'p-f1');
  });

  test('projectsCombinedProvider applies dueDate boundaries and requiredTags', () async {
    final repository = FakeProjectRepository(seed: [
      ProjectModel(
        id: 'p-c1',
        name: 'One',
        progress: 0.1,
        status: 'In Progress',
        sharedUsers: <String>['owner-1'],
        tags: <String>['alpha', 'beta'],
        dueDate: DateTime(2026, 3, 15),
      ),
      ProjectModel(
        id: 'p-c2',
        name: 'Two',
        progress: 0.1,
        status: 'In Progress',
        sharedUsers: <String>['owner-1'],
        tags: <String>['alpha'],
        dueDate: DateTime(2026, 3, 15),
      ),
      ProjectModel(
        id: 'p-c3',
        name: 'Three',
        progress: 0.1,
        status: 'In Progress',
        sharedUsers: <String>['owner-1'],
        tags: <String>['alpha', 'beta'],
        dueDate: DateTime(2026, 3, 16),
      ),
    ]);

    final container = ProviderContainer(overrides: [
      projectRepositoryProvider.overrideWithValue(repository),
      authProvider.overrideWith(() => FakeAuthNotifier()),
    ]);
    addTearDown(container.dispose);

    final params = ProjectParams(
      page: 1,
      limit: 10,
      filter: ProjectFilter(
        ownerId: 'owner-1',
        requiredTags: const <String>['alpha', 'beta'],
        dueDateStart: DateTime(2026, 3, 15),
        dueDateEnd: DateTime(2026, 3, 15),
      ),
    );

    final result = await container.read(projectsCombinedProvider(params).future);

    expect(result.length, 1);
    expect(result.first.id, 'p-c1');
  });

  test('projectsCombinedProvider honors filter sortBy over params sortBy', () async {
    final repository = FakeProjectRepository(seed: const [
      ProjectModel(id: 'p-s1', name: 'Zeta', progress: 0.1, status: 'B'),
      ProjectModel(id: 'p-s2', name: 'Alpha', progress: 0.1, status: 'A'),
    ]);

    final container = ProviderContainer(overrides: [
      projectRepositoryProvider.overrideWithValue(repository),
      authProvider.overrideWith(() => FakeAuthNotifier()),
    ]);
    addTearDown(container.dispose);

    final params = ProjectParams(
      page: 1,
      limit: 10,
      filter: const ProjectFilter(sortBy: 'status', sortAscending: true),
      sortBy: 'name',
      sortAscending: false,
    );

    final result = await container.read(projectsCombinedProvider(params).future);

    expect(result.map((p) => p.id).toList(), <String>['p-s2', 'p-s1']);
  });

  test('filteredProjectsProvider combines OR tags with AND requiredTags', () async {
    final repository = FakeProjectRepository(seed: [
      ProjectModel(
        id: 'p-009-1',
        name: 'Alpha',
        progress: 0.2,
        status: 'In Progress',
        tags: const <String>['mobile', 'urgent', 'backend'],
      ),
      ProjectModel(
        id: 'p-009-2',
        name: 'Beta',
        progress: 0.2,
        status: 'In Progress',
        tags: const <String>['mobile', 'backend'],
      ),
      ProjectModel(
        id: 'p-009-3',
        name: 'Gamma',
        progress: 0.2,
        status: 'In Progress',
        tags: const <String>['web', 'urgent', 'backend'],
      ),
    ]);

    final container = ProviderContainer(overrides: [
      projectRepositoryProvider.overrideWithValue(repository),
      authProvider.overrideWith(() => FakeAuthNotifier()),
    ]);
    addTearDown(container.dispose);

    final initial = await container.read(projectsProvider.future);
    expect(initial.length, 3);

    const filter = ProjectFilter(
      tags: <String>['mobile', 'web'],
      requiredTags: <String>['urgent', 'backend'],
    );

    final results = container.read(filteredProjectsProvider(filter));
    expect(results.map((p) => p.id).toList(), <String>['p-009-1', 'p-009-3']);
  });

  test('filteredProjectsProvider handles empty and null-like fields safely', () async {
    final repository = FakeProjectRepository(seed: const [
      ProjectModel(id: 'p-009-a', name: 'A', progress: 0.1, status: 'In Progress'),
      ProjectModel(id: 'p-009-b', name: 'B', progress: 0.2, status: 'Planning'),
    ]);

    final container = ProviderContainer(overrides: [
      projectRepositoryProvider.overrideWithValue(repository),
      authProvider.overrideWith(() => FakeAuthNotifier()),
    ]);
    addTearDown(container.dispose);

    final initial = await container.read(projectsProvider.future);
    expect(initial.length, 2);

    const filter = ProjectFilter(
      status: '',
      searchQuery: '',
      tags: <String>[],
      requiredTags: <String>[],
    );

    final results = container.read(filteredProjectsProvider(filter));
    expect(results.length, 2);
  });

  test('filteredProjectsProvider dueDate range is inclusive on boundary instants', () async {
    final repository = FakeProjectRepository(seed: [
      ProjectModel(
        id: 'p-010-1',
        name: 'Boundary Start',
        progress: 0.1,
        status: 'In Progress',
        dueDate: DateTime.utc(2026, 4, 10, 0, 0, 0),
      ),
      ProjectModel(
        id: 'p-010-2',
        name: 'Boundary End',
        progress: 0.1,
        status: 'In Progress',
        dueDate: DateTime.utc(2026, 4, 10, 23, 59, 59),
      ),
      ProjectModel(
        id: 'p-010-3',
        name: 'Out Of Range',
        progress: 0.1,
        status: 'In Progress',
        dueDate: DateTime.utc(2026, 4, 11, 0, 0, 0),
      ),
    ]);

    final container = ProviderContainer(overrides: [
      projectRepositoryProvider.overrideWithValue(repository),
      authProvider.overrideWith(() => FakeAuthNotifier()),
    ]);
    addTearDown(container.dispose);

    await container.read(projectsProvider.future);

    final filter = ProjectFilter(
      dueDateStart: DateTime.utc(2026, 4, 10, 0, 0, 0),
      dueDateEnd: DateTime.utc(2026, 4, 10, 23, 59, 59),
    );

    final results = container.read(filteredProjectsProvider(filter));
    expect(results.map((p) => p.id).toSet(), <String>{'p-010-1', 'p-010-2'});
  });

  test('projectsCombinedProvider handles dueDate timezone-offset boundaries', () async {
    final repository = FakeProjectRepository(seed: [
      ProjectModel(
        id: 'p-010-tz-1',
        name: 'UTC Match',
        progress: 0.1,
        status: 'In Progress',
        dueDate: DateTime.parse('2026-05-01T00:00:00Z'),
      ),
      ProjectModel(
        id: 'p-010-tz-2',
        name: 'UTC Out',
        progress: 0.1,
        status: 'In Progress',
        dueDate: DateTime.parse('2026-04-30T20:59:59Z'),
      ),
    ]);

    final container = ProviderContainer(overrides: [
      projectRepositoryProvider.overrideWithValue(repository),
      authProvider.overrideWith(() => FakeAuthNotifier()),
    ]);
    addTearDown(container.dispose);

    final params = ProjectParams(
      page: 1,
      limit: 10,
      filter: ProjectFilter(
        // +03:00 offset resolves to UTC window starting at 2026-04-30T21:00:00Z.
        dueDateStart: DateTime.parse('2026-05-01T00:00:00+03:00'),
        dueDateEnd: DateTime.parse('2026-05-01T03:00:00+03:00'),
      ),
    );

    final result = await container.read(projectsCombinedProvider(params).future);
    expect(result.map((p) => p.id).toList(), <String>['p-010-tz-1']);
  });
}
