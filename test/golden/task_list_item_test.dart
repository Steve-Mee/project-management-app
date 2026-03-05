import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/core/providers/task_providers.dart';
import 'package:project_management_app/core/repository/impl/hive_task_repository.dart';
import 'package:project_management_app/features/dashboard/widgets/task_chart_widget.dart';
import 'package:project_management_app/generated/app_localizations.dart';
import 'package:project_management_app/models/project_model.dart';
import 'package:project_management_app/models/task_model.dart';

const _surfaceSize = Size(1000, 800);
const _listKey = Key('task_list_item_golden');

class _FakeTaskRepository extends HiveTaskRepository {
  _FakeTaskRepository(this.tasks);

  final List<Task> tasks;

  @override
  List<Task> getAllTasks() => List<Task>.from(tasks);
}

Future<void> _pumpTaskListItems(
  WidgetTester tester, {
  required ThemeData theme,
  required List<Task> tasks,
}) async {
  await tester.binding.setSurfaceSize(_surfaceSize);

  const projects = [
    ProjectModel(id: 'p-task-1', name: 'Alpha', progress: 0.45, status: 'In Progress'),
    ProjectModel(id: 'p-task-2', name: 'Beta', progress: 0.80, status: 'Review'),
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
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
              body: Center(
                child: RepaintBoundary(
                  key: _listKey,
                  child: SizedBox(
                    width: 760,
                    child: TaskChartWidget(projects: projects),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  await tester.pumpAndSettle();
}

List<Task> _taskItemsFixture() {
  return [
    Task(
      id: 't-item-1',
      projectId: 'p-task-1',
      title: 'Implement onboarding cards',
      description: 'Create responsive onboarding cards for mobile and desktop.',
      status: TaskStatus.inProgress,
      assignee: 'Sam',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      dueDate: DateTime.now().add(const Duration(days: 2)),
      priority: 0.7,
    ),
    Task(
      id: 't-item-2',
      projectId: 'p-task-2',
      title: 'Review release checklist',
      description: 'Validate QA, docs, and deployment rollback plan.',
      status: TaskStatus.review,
      assignee: 'Jordan',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      dueDate: DateTime.now().add(const Duration(days: 1)),
      priority: 0.9,
    ),
  ];
}

void main() {
  testWidgets('Task list item golden - empty - light', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpTaskListItems(
      tester,
      theme: ThemeData.light(useMaterial3: true),
      tasks: const <Task>[],
    );

    await expectLater(
      find.byKey(_listKey),
      matchesGoldenFile('goldens/task_list_item_empty_light.png'),
    );
  });

  testWidgets('Task list item golden - empty - dark', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpTaskListItems(
      tester,
      theme: ThemeData.dark(useMaterial3: true),
      tasks: const <Task>[],
    );

    await expectLater(
      find.byKey(_listKey),
      matchesGoldenFile('goldens/task_list_item_empty_dark.png'),
    );
  });

  testWidgets('Task list item golden - data - light', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpTaskListItems(
      tester,
      theme: ThemeData.light(useMaterial3: true),
      tasks: _taskItemsFixture(),
    );

    await expectLater(
      find.byKey(_listKey),
      matchesGoldenFile('goldens/task_list_item_data_light.png'),
    );
  });

  testWidgets('Task list item golden - data - dark', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpTaskListItems(
      tester,
      theme: ThemeData.dark(useMaterial3: true),
      tasks: _taskItemsFixture(),
    );

    await expectLater(
      find.byKey(_listKey),
      matchesGoldenFile('goldens/task_list_item_data_dark.png'),
    );
  });
}
