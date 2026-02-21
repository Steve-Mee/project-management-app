import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_project_management_app/core/providers.dart';
import 'package:my_project_management_app/core/repository/project_repository.dart';
import 'package:my_project_management_app/models/project_model.dart';

class FakeProjectRepository extends ProjectRepository {
  final Map<String, ProjectModel> _store = {};

  FakeProjectRepository({List<ProjectModel>? seed}) : super() {
    if (seed != null) {
      for (final project in seed) {
        _store[project.id] = project;
      }
    }
  }

  @override
  Future<void> initialize({String? testPath}) async {}

  @override
  bool get isInitialized => true;

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
  Future<ProjectModel?> getProjectById(String id) async {
    return _store[id];
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
}

void main() {
  test('ProjectsNotifier initializes with repository data', () async {
    final project = ProjectModel(
      id: 'p1',
      name: 'Alpha',
      progress: 0.2,
      status: 'In Progress',
    );
    final repository = FakeProjectRepository(seed: [project]);
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // TODO: migrate to projectsPaginatedProvider (issue #004)
    final notifier = container.read(projectsProvider.notifier);
    await notifier.initialize(repository);

    // TODO: migrate to projectsPaginatedProvider (issue #004)
    final state = container.read(projectsProvider);
    expect(state.hasValue, true);
    expect(state.value?.length, 1);
    expect(state.value?.first.name, 'Alpha');
  });

  test('ProjectsNotifier addProject updates state', () async {
    final repository = FakeProjectRepository();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // TODO: migrate to projectsPaginatedProvider (issue #004)
    final notifier = container.read(projectsProvider.notifier);
    await notifier.initialize(repository);

    await notifier.addProject(
      const ProjectModel(
        id: 'p2',
        name: 'Beta',
        progress: 0.5,
        status: 'Planning',
      ),
    );

    final state = container.read(projectsProvider);
    expect(state.hasValue, true);
    expect(state.value?.length, 1);
    expect(state.value?.first.id, 'p2');
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
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // TODO: migrate to projectsPaginatedProvider (issue #004)
    final notifier = container.read(projectsProvider.notifier);
    await notifier.initialize(repository);

    await notifier.updateProgress('p3', 0.9);

    // TODO: migrate to projectsPaginatedProvider (issue #004)
    final state = container.read(projectsProvider);
    expect(state.hasValue, true);
    expect(state.value?.first.progress, 0.9);
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
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // TODO: migrate to projectsPaginatedProvider (issue #004)
    final notifier = container.read(projectsProvider.notifier);
    await notifier.initialize(repository);

    await notifier.deleteProject('p4');

    // TODO: migrate to projectsPaginatedProvider (issue #004)
    final state = container.read(projectsProvider);
    expect(state.hasValue, true);
    expect(state.value?.isEmpty, true);
  });
}
