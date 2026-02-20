import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_project_management_app/core/providers.dart';
import 'package:my_project_management_app/features/dashboard/dashboard_screen.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';
import 'package:my_project_management_app/models/project_meta.dart';
import 'package:my_project_management_app/models/project_model.dart';
import 'package:my_project_management_app/models/task_model.dart';
import 'package:my_project_management_app/core/repository/task_repository.dart';

class FakeProjectsNotifier extends ProjectsNotifier {
  final List<ProjectModel> projects;

  FakeProjectsNotifier(this.projects);

  @override
  AsyncValue<List<ProjectModel>> build() {
    return AsyncValue.data(projects);
  }
}

class FakeTaskRepository extends TaskRepository {
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
      ProjectModel(
        id: 'p1',
        name: 'Atlas Redesign',
        progress: 0.45,
        status: 'In Progress',
        description: 'Revamp onboarding flow',
        tasks: const ['Wireframes', 'Prototype'],
      ),
      ProjectModel(
        id: 'p2',
        name: 'Mobile MVP',
        progress: 0.82,
        status: 'Review',
        description: 'Release candidate for mobile app',
        tasks: const ['QA', 'Beta sign-off'],
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
      'p1': ProjectMeta(
        projectId: 'p1',
        urgency: UrgencyLevel.high,
        trackedSeconds: 5400,
      ),
      'p2': ProjectMeta(
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
            return MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const DashboardScreen(),
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
