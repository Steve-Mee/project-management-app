import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/providers/project_providers.dart';
import 'package:pma_core/providers/task_providers.dart';
import 'package:pma_core/repository/impl/hive_task_repository.dart';
import 'package:project_management_app/features/projects/views/project_gantt_view.dart';
import 'package:project_management_app/generated/app_localizations.dart';
import 'package:pma_core/models/project_model.dart';
import 'package:pma_core/models/task_model.dart';

const _surfaceSize = Size(1280, 940);
const _viewKey = Key('gantt_chart_golden');

class _FakeProjectsNotifier extends ProjectsNotifier {
  _FakeProjectsNotifier(this.projects);

  final List<ProjectModel> projects;

  @override
  Future<List<ProjectModel>> build() async => projects;
}

class _FakeTaskRepository extends HiveTaskRepository {
  _FakeTaskRepository(this.tasks);

  final List<Task> tasks;

  @override
  List<Task> getAllTasks() => List<Task>.from(tasks);

  @override
  List<Task> getTasksForProject(String projectId) =>
      tasks.where((task) => task.projectId == projectId).toList();
}

Future<void> _pumpGantt(
  WidgetTester tester, {
  required ThemeData theme,
  required List<ProjectModel> projects,
  required List<Task> tasks,
}) async {
  await tester.binding.setSurfaceSize(_surfaceSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        projectsProvider.overrideWith(() => _FakeProjectsNotifier(projects)),
        taskRepositoryProvider.overrideWith((ref) async => _FakeTaskRepository(tasks)),
      ],
      child: ScreenUtilInit(
        designSize: _surfaceSize,
        builder: (context, child) {
          return MaterialApp(
            theme: theme,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: RepaintBoundary(
                key: _viewKey,
                child: ProjectGanttView(),
              ),
            ),
          );
        },
      ),
    ),
  );

  await tester.pumpAndSettle();
}

List<ProjectModel> _ganttProjectsFixture() {
  return [
    ProjectModel(
      id: 'p-gantt-1',
      name: 'Website Relaunch',
      progress: 0.55,
      status: 'In Progress',
      startDate: DateTime(2026, 2, 20),
      dueDate: DateTime(2026, 4, 10),
      tasks: const ['Design', 'Implementation'],
    ),
    ProjectModel(
      id: 'p-gantt-2',
      name: 'Mobile QA Cycle',
      progress: 0.35,
      status: 'On Hold',
      startDate: DateTime(2026, 3, 1),
      dueDate: DateTime(2026, 3, 28),
      tasks: const ['Regression', 'Fixes'],
    ),
  ];
}

List<Task> _ganttTasksFixture() {
  return [
    Task(
      id: 't-gantt-1',
      projectId: 'p-gantt-1',
      title: 'Design handoff',
      description: 'Share final specs with dev team',
      status: TaskStatus.inProgress,
      assignee: 'Alex',
      createdAt: DateTime(2026, 2, 24),
      dueDate: DateTime(2026, 3, 8),
      priority: 0.8,
    ),
    Task(
      id: 't-gantt-2',
      projectId: 'p-gantt-2',
      title: 'Device matrix run',
      description: 'Execute smoke tests on target devices',
      status: TaskStatus.todo,
      assignee: 'Casey',
      createdAt: DateTime(2026, 3, 4),
      dueDate: DateTime(2026, 3, 20),
      priority: 0.6,
    ),
  ];
}

void main() {
  testWidgets('Gantt chart golden - empty - light', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpGantt(
      tester,
      theme: ThemeData.light(useMaterial3: true),
      projects: const <ProjectModel>[],
      tasks: const <Task>[],
    );

    await expectLater(
      find.byKey(_viewKey),
      matchesGoldenFile('goldens/gantt_chart_empty_light.png'),
    );
  });

  testWidgets('Gantt chart golden - empty - dark', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpGantt(
      tester,
      theme: ThemeData.dark(useMaterial3: true),
      projects: const <ProjectModel>[],
      tasks: const <Task>[],
    );

    await expectLater(
      find.byKey(_viewKey),
      matchesGoldenFile('goldens/gantt_chart_empty_dark.png'),
    );
  });

  testWidgets('Gantt chart golden - data - light', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpGantt(
      tester,
      theme: ThemeData.light(useMaterial3: true),
      projects: _ganttProjectsFixture(),
      tasks: _ganttTasksFixture(),
    );

    await expectLater(
      find.byKey(_viewKey),
      matchesGoldenFile('goldens/gantt_chart_data_light.png'),
    );
  });

  testWidgets('Gantt chart golden - data - dark', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpGantt(
      tester,
      theme: ThemeData.dark(useMaterial3: true),
      projects: _ganttProjectsFixture(),
      tasks: _ganttTasksFixture(),
    );

    await expectLater(
      find.byKey(_viewKey),
      matchesGoldenFile('goldens/gantt_chart_data_dark.png'),
    );
  });
}
