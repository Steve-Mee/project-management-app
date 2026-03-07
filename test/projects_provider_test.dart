import 'dart:async';
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

    // Wait for the notifier to load data
    await Future.delayed(Duration.zero);
    // Since build() starts with loading and then loads data asynchronously,
    // we need to wait for the state to become data
    final completer = Completer<void>();
    final subscription = container.listen(projectsProvider, (previous, next) {
      if (next is AsyncData) {
        completer.complete();
      }
    });
    await completer.future;
    subscription.close();

    final state = container.read(projectsProvider);
    expect(state, isA<AsyncData<List<ProjectModel>>>());
    expect(state.asData!.value.length, 1);
    expect(state.asData!.value.first.name, 'Alpha');
  });

  test('ProjectsNotifier addProject updates state', () async {
    final repository = FakeProjectRepository();
    final container = ProviderContainer(overrides: [
      projectRepositoryProvider.overrideWithValue(repository),
      authProvider.overrideWith(() => FakeAuthNotifier()),
    ]);
    addTearDown(container.dispose);

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
    const filter = model_filters.ProjectFilter(searchQuery: 'flutter');
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
    const filter = model_filters.ProjectFilter(searchQuery: 'flutter');
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
    const filter = model_filters.ProjectFilter(searchQuery: 'mobile');
    final results = container.read(filteredProjectsProvider(filter));
    expect(results.length, 1);
    expect(results[0].id, 'p1');
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
}
