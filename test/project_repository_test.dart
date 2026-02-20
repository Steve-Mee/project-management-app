import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:my_project_management_app/core/repository/project_repository.dart';
import 'package:my_project_management_app/models/project_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProjectRepository repository;
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
      Hive.registerAdapter(ProjectModelAdapter());
    }
  });

  setUp(() async {
    repository = ProjectRepository();
    await repository.initialize(testPath: tempDir.path);
  });

  tearDown(() async {
    await repository.close();
    await Hive.deleteBoxFromDisk('projects');
  });

  test('addProject stores and returns project', () async {
    final project = await createProject();
    await repository.addProject(project);

    final projects = repository.getAllProjects();
    expect(projects.length, 1);
    expect(projects.first.id, project.id);
  });

  test('updateProgress updates progress value', () async {
    final project = await createProject(progress: 0.1);
    await repository.addProject(project);

    await repository.updateProgress(project.id, 0.6);
    final updated = repository.getProjectById(project.id);

    expect(updated, isNotNull);
    expect(updated!.progress, 0.6);
  });

  test('updateTasks replaces task list', () async {
    final project = await createProject();
    await repository.addProject(project);

    await repository.updateTasks(project.id, const ['Task A', 'Task B']);
    final updated = repository.getProjectById(project.id);

    expect(updated, isNotNull);
    expect(updated!.tasks, const ['Task A', 'Task B']);
  });

  test('deleteProject removes project', () async {
    final project = await createProject();
    await repository.addProject(project);

    await repository.deleteProject(project.id);
    final projects = repository.getAllProjects();

    expect(projects, isEmpty);
  });
}
