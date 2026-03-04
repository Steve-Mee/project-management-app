import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:project_management_app/core/repository/impl/hive_project_repository.dart';

import 'package:project_management_app/core/repository/models/project_models.dart';
import 'package:project_management_app/models/project_model.dart';
import 'package:project_management_app/models/project_filter.dart';

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
  }) async {
    return ProjectModel(
      id: id,
      name: name,
      progress: progress,
      status: status,
      tasks: const [],
      directoryPath: null,
      description: 'Sample',
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

    expect(filtered.length, 2);
    expect(filtered.every((p) => p.status == 'In Progress'), true);
  });

  test('getFilteredProjects filters by search query', () async {
    // Create projects with different names
    await repository.addProject(await createProject(id: 'project-1', name: 'Flutter App', status: 'In Progress'));
    await repository.addProject(await createProject(id: 'project-2', name: 'React Website', status: 'Completed'));
    await repository.addProject(await createProject(id: 'project-3', name: 'Flutter Widget', status: 'In Progress'));

    const filter = ProjectFilter(searchQuery: 'flutter');
    final filtered = await repository.getFilteredProjects(filter);

    expect(filtered.length, 2);
    expect(filtered.every((p) => p.name.toLowerCase().contains('flutter')), true);
  });

  test('getFilteredProjects applies extra conditions', () async {
    // Create projects
    await repository.addProject(await createProject(id: 'project-1', name: 'Project 1', status: 'In Progress'));
    await repository.addProject(await createProject(id: 'project-2', name: 'Project 2', status: 'Completed'));
    await repository.addProject(await createProject(id: 'project-3', name: 'Project 3', status: 'In Progress'));

    final extraCondition = ProjectFilterConditions((project) => project.name.contains('1'));
    final filtered = await repository.getFilteredProjects(const ProjectFilter(), extraConditions: [extraCondition]);

    expect(filtered.length, 1);
    expect(filtered[0].id, 'project-1');
  });
}
