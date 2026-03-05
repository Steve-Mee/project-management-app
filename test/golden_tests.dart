import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/core/providers.dart';
import 'package:project_management_app/features/dashboard/dashboard_screen.dart';
import 'package:project_management_app/generated/app_localizations.dart';
import 'package:project_management_app/models/project_meta.dart';
import 'package:project_management_app/models/project_model.dart';
import 'package:project_management_app/models/task_model.dart';
import 'package:project_management_app/core/repository/impl/hive_task_repository.dart';

// ignore_for_file: prefer_const_constructors

class FakeProjectsNotifier extends ProjectsNotifier {
  final List<ProjectModel> projects;

  FakeProjectsNotifier(this.projects);

  @override
  Future<List<ProjectModel>> build() async => projects;
}

class FakeTaskRepository extends HiveTaskRepository {
  final List<Task> tasks;

  FakeTaskRepository(this.tasks);

  @override
  List<Task> getAllTasks() {
    return List<Task>.from(tasks);
  }

  @override
  List<Task> getTasksForProject(String projectId) {
    return tasks.where((task) => task.projectId == projectId).toList();
  }
}

void main() {
  testWidgets('Dashboard golden', (tester) async {
    const size = Size(1280, 720);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final projects = [
      const ProjectModel(
        id: 'p1',
        name: 'Atlas Redesign',
        progress: 0.45,
        status: 'In Progress',
        description: 'Revamp onboarding flow',
        tasks: ['Wireframes', 'Prototype'],
      ),
      const ProjectModel(
        id: 'p2',
        name: 'Mobile MVP',
        progress: 0.82,
        status: 'Review',
        description: 'Release candidate for mobile app',
        tasks: ['QA', 'Beta sign-off'],
      ),
    ];

    final tasks = [
      Task(
        id: 't1',
        projectId: 'p1',
        title: 'Wireframes',
        description: 'Finish dashboard wireframes',
        status: TaskStatus.todo,
        assignee: 'Jamie',
        createdAt: DateTime(2025, 1, 1),
        priority: 0.4,
      ),
      Task(
        id: 't2',
        projectId: 'p2',
        title: 'QA',
        description: 'Regression sweep on builds',
        status: TaskStatus.inProgress,
        assignee: 'Taylor',
        createdAt: DateTime(2025, 1, 3),
        priority: 0.7,
      ),
    ];

    final meta = {
      'p1': const ProjectMeta(
        projectId: 'p1',
        urgency: UrgencyLevel.high,
        trackedSeconds: 5400,
      ),
      'p2': const ProjectMeta(
        projectId: 'p2',
        urgency: UrgencyLevel.medium,
        trackedSeconds: 3600,
      ),
    };

    final container = ProviderContainer(
      overrides: [
        projectsProvider.overrideWith(() => FakeProjectsNotifier(projects)),
        taskRepositoryProvider.overrideWith(
          (ref) async => FakeTaskRepository(tasks),
        ),
        projectMetaProvider.overrideWithValue(meta),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: const Size(1280, 720),
          builder: (context, child) {
            return const MaterialApp(
              locale: Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: DashboardScreen(),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    await expectLater(
      find.byType(DashboardScreen),
      matchesGoldenFile('goldens/dashboard.png'),
    );
  });
}
