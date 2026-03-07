import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pma_core/models/project_filter.dart';
import 'package:pma_core/models/project_model.dart';
import 'package:pma_core/repository/impl/hive_project_repository.dart';
import 'package:pma_core/repository/models/project_models.dart';

// ignore_for_file: prefer_const_constructors

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HiveProjectRepository repository;
  late Directory tempDir;

  Future<ProjectModel> createProject({
    String id = 'project-1',
    String name = 'Test Project',
    double progress = 0.2,
    String status = 'In Progress',
    String? priority,
    DateTime? startDate,
    DateTime? dueDate,
    List<String> tags = const <String>[],
    String description = 'Sample',
  }) async {
    return ProjectModel(
      id: id,
      name: name,
      progress: progress,
      status: status,
      priority: priority,
      startDate: startDate,
      dueDate: dueDate,
      tags: tags,
      tasks: const [],
      directoryPath: null,
      description: description,
    );
  }

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('project_repo_test_');
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter<ProjectModel>(ProjectModelAdapter());
    }
  });

  setUp(() async {
    repository = HiveProjectRepository(isTestMode: true);
    await repository.initialize(testPath: tempDir.path);
  });

  tearDown(() async {
    await repository.close();
    // Ensure box is closed before deleting
    if (Hive.isBoxOpen('projects')) {
      final box = Hive.box('projects');
      await box.clear();
      await box.close();
    }
    await Hive.deleteBoxFromDisk('projects');
  });

  test('addProject stores and returns project', () async {
    final project = await createProject();
    await repository.addProject(project);

    final projects = await repository.getAllProjects();
    expect(projects.length, 1);
    expect(projects.first.id, project.id);
  });

  test('updateProgress updates progress value', () async {
    final project = await createProject(progress: 0.1);
    await repository.addProject(project);

    await repository.updateProgress(project.id, 0.6);
    final updated = await repository.getProjectById(project.id);

    expect(updated.progress, 0.6);
  });

  test('updateTasks replaces task list', () async {
    final project = await createProject();
    await repository.addProject(project);

    await repository.updateTasks(project.id, const ['Task A', 'Task B']);
    final updated = await repository.getProjectById(project.id);

    expect(updated.tasks, const ['Task A', 'Task B']);
  });

  test('deleteProject removes project', () async {
    final project = await createProject();
    await repository.addProject(project);

    await repository.deleteProject(project.id);
    final projects = await repository.getAllProjects();

    expect(projects, isEmpty);
  });

  test('getProjectsPaginated returns correct slice', () async {
    // Create 5 test projects
    for (int i = 1; i <= 5; i++) {
      final project = await createProject(
        id: 'project-$i',
        name: 'Test Project $i',
      );
      await repository.addProject(project);
    }

    // Test first page with limit 2
    final page1 = await repository.getProjectsPaginated(page: 1, limit: 2);
    expect(page1.length, 2);
    expect(page1[0].id, 'project-1');
    expect(page1[1].id, 'project-2');

    // Test second page
    final page2 = await repository.getProjectsPaginated(page: 2, limit: 2);
    expect(page2.length, 2);
    expect(page2[0].id, 'project-3');
    expect(page2[1].id, 'project-4');

    // Test third page (should have 1 item)
    final page3 = await repository.getProjectsPaginated(page: 3, limit: 2);
    expect(page3.length, 1);
    expect(page3[0].id, 'project-5');
  });

  test('getProjectsPaginated throws on invalid page and limit', () async {
    expect(
      () => repository.getProjectsPaginated(page: 0, limit: 2),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => repository.getProjectsPaginated(page: 1, limit: 0),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => repository.getProjectsPaginated(page: -1, limit: -10),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('getProjectsPaginated returns empty list for empty dataset', () async {
    final result = await repository.getProjectsPaginated(page: 1, limit: 20);
    expect(result, isEmpty);
  });

  test('getProjectsPaginated combines filter and pagination', () async {
    await repository.addProject(
      await createProject(id: 'project-1', name: 'A Project 1', status: 'In Progress'),
    );
    await repository.addProject(
      await createProject(id: 'project-2', name: 'B Project 2', status: 'Completed'),
    );
    await repository.addProject(
      await createProject(id: 'project-3', name: 'C Project 3', status: 'In Progress'),
    );
    await repository.addProject(
      await createProject(id: 'project-4', name: 'D Project 4', status: 'In Progress'),
    );

    const filter = ProjectFilter(status: 'In Progress');

    final page1 = await repository.getProjectsPaginated(
      page: 1,
      limit: 2,
      filter: filter,
    );
    final page2 = await repository.getProjectsPaginated(
      page: 2,
      limit: 2,
      filter: filter,
    );

    expect(page1.length, 2);
    expect(page2.length, 1);
    expect(page1.every((p) => p.status == 'In Progress'), isTrue);
    expect(page2.every((p) => p.status == 'In Progress'), isTrue);
  });

  test('getProjectById returns correct project', () async {
    final project = await createProject(id: 'test-project', name: 'Test Project');
    await repository.addProject(project);

    final fetched = await repository.getProjectById('test-project');
    expect(fetched.id, 'test-project');
    expect(fetched.name, 'Test Project');
  });

  test('getProjectById throws for non-existent project', () async {
    expect(
      () => repository.getProjectById('non-existent'),
      throwsA(isA<Exception>()),
    );
  });

  test('getFilteredProjects filters by status', () async {
    // Create projects with different statuses
    await repository.addProject(await createProject(id: 'project-1', name: 'Project 1', status: 'In Progress'));
    await repository.addProject(await createProject(id: 'project-2', name: 'Project 2', status: 'Completed'));
    await repository.addProject(await createProject(id: 'project-3', name: 'Project 3', status: 'In Progress'));

    const filter = ProjectFilter(status: 'In Progress');
    final filtered = await repository.getFilteredProjects(filter);
    final typedFiltered = filtered.whereType<ProjectModel>().toList();

    expect(typedFiltered.length, 2);
    expect(typedFiltered.every((p) => p.status == 'In Progress'), true);
  });

  test('getFilteredProjects filters by search query', () async {
    // Create projects with different names
    await repository.addProject(await createProject(id: 'project-1', name: 'Flutter App', status: 'In Progress'));
    await repository.addProject(await createProject(id: 'project-2', name: 'React Website', status: 'Completed'));
    await repository.addProject(await createProject(id: 'project-3', name: 'Flutter Widget', status: 'In Progress'));

    const filter = ProjectFilter(searchQuery: 'flutter');
    final filtered = await repository.getFilteredProjects(filter);
    final typedFiltered = filtered.whereType<ProjectModel>().toList();

    expect(typedFiltered.length, 2);
    expect(typedFiltered.every((p) => p.name.toLowerCase().contains('flutter')), true);
  });

  test('getFilteredProjects applies extra conditions', () async {
    // Create projects
    await repository.addProject(await createProject(id: 'project-1', name: 'Project 1', status: 'In Progress'));
    await repository.addProject(await createProject(id: 'project-2', name: 'Project 2', status: 'Completed'));
    await repository.addProject(await createProject(id: 'project-3', name: 'Project 3', status: 'In Progress'));

    final extraCondition = ProjectFilterConditions(
      (project) => project.name.contains('1'),
    );
    final filtered = await repository.getFilteredProjects(const ProjectFilter(), extraConditions: [extraCondition]);
    final typedFiltered = filtered.whereType<ProjectModel>().toList();

    expect(typedFiltered.length, 1);
    expect(typedFiltered[0].id, 'project-1');
  });

  test('getFilteredProjects supports priority, tags, and date range', () async {
    await repository.addProject(
      await createProject(
        id: 'project-1',
        name: 'Alpha',
        status: 'In Progress',
        priority: 'High',
        tags: const ['mobile', 'urgent'],
        startDate: DateTime(2026, 1, 1),
        dueDate: DateTime(2026, 1, 20),
      ),
    );
    await repository.addProject(
      await createProject(
        id: 'project-2',
        name: 'Beta',
        status: 'In Progress',
        priority: 'Low',
        tags: const ['backend'],
        startDate: DateTime(2026, 2, 1),
        dueDate: DateTime(2026, 2, 20),
      ),
    );

    final result = await repository.getFilteredProjects(
      ProjectFilter(
        status: 'In Progress',
        priority: 'High',
        tags: const ['urgent'],
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
      ),
    );

    expect(result.length, 1);
    expect(result.first.id, 'project-1');
  });

  test('getFilteredProjects searchQuery also matches tags', () async {
    await repository.addProject(
      await createProject(
        id: 'project-1',
        name: 'Alpha',
        tags: const ['finops'],
      ),
    );

    final result = await repository.getFilteredProjects(
      const ProjectFilter(searchQuery: 'finops'),
    );

    expect(result.length, 1);
    expect(result.first.id, 'project-1');
  });

  test('getFilteredProjects date range includes boundary startDate and dueDate values', () async {
    await repository.addProject(
      await createProject(
        id: 'project-1',
        name: 'Boundary Match',
        startDate: DateTime.utc(2026, 6, 1, 0, 0, 0),
        dueDate: DateTime.utc(2026, 6, 30, 23, 59, 59),
      ),
    );
    await repository.addProject(
      await createProject(
        id: 'project-2',
        name: 'Outside End',
        startDate: DateTime.utc(2026, 6, 1, 0, 0, 0),
        dueDate: DateTime.utc(2026, 7, 1, 0, 0, 0),
      ),
    );

    final result = await repository.getFilteredProjects(
      ProjectFilter(
        startDate: DateTime.utc(2026, 6, 1, 0, 0, 0),
        endDate: DateTime.utc(2026, 6, 30, 23, 59, 59),
      ),
    );

    expect(result.map((p) => p.id).toSet(), <String>{'project-1'});
  });

  test('IProjectRepository contract: status filter matches getProjectsByStatus', () async {
    await repository.addProject(
      await createProject(id: 'project-1', name: 'Project 1', status: 'In Progress'),
    );
    await repository.addProject(
      await createProject(id: 'project-2', name: 'Project 2', status: 'Completed'),
    );
    await repository.addProject(
      await createProject(id: 'project-3', name: 'Project 3', status: 'In Progress'),
    );

    final fromStatusMethod = await repository.getProjectsByStatus('In Progress');
    final fromFilterMethod = await repository.getFilteredProjects(
      const ProjectFilter(status: 'In Progress'),
    );

    final statusIds = fromStatusMethod.map((p) => p.id).toSet();
    final filterIds = fromFilterMethod.map((p) => p.id).toSet();

    expect(filterIds, equals(statusIds));
  });

  test('IProjectRepository contract: paginated pages keep stable coverage without duplicates', () async {
    for (int i = 1; i <= 7; i++) {
      await repository.addProject(
        await createProject(id: 'project-$i', name: 'Project $i', status: 'In Progress'),
      );
    }

    final all = await repository.getAllProjects();
    final page1 = await repository.getProjectsPaginated(page: 1, limit: 3);
    final page2 = await repository.getProjectsPaginated(page: 2, limit: 3);
    final page3 = await repository.getProjectsPaginated(page: 3, limit: 3);

    final pagedIds = <String>{
      ...page1.map((p) => p.id),
      ...page2.map((p) => p.id),
      ...page3.map((p) => p.id),
    };

    expect(pagedIds.length, page1.length + page2.length + page3.length);
    expect(pagedIds, equals(all.map((p) => p.id).toSet()));
  });
}
