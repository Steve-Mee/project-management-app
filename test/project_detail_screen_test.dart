import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/core/auth/permissions.dart';
import 'package:project_management_app/core/providers.dart';
import 'package:project_management_app/core/repository/impl/project_meta_repository.dart';
import 'package:project_management_app/features/project/project_detail_screen.dart';
import 'package:project_management_app/generated/app_localizations.dart';
import 'package:project_management_app/models/project_meta.dart';
import 'package:project_management_app/models/project_model.dart';
import 'package:project_management_app/models/task_model.dart';

class FakeProjectsNotifier extends ProjectsNotifier {
  final List<ProjectModel> projects;

  FakeProjectsNotifier(this.projects);

  @override
  AsyncValue<List<ProjectModel>> build() {
    return AsyncValue.data(projects);
  }
}

class FakeTaskNotifier extends TaskNotifier {
  final List<Task> _tasks = <Task>[];

  @override
  Future<List<Task>> build() async => _tasks;

  @override
  Future<void> loadTasks(String projectId) async {
    state = AsyncValue.data(
      _tasks.where((task) => task.projectId == projectId).toList(),
    );
  }

  @override
  Future<void> addTask(Task task) async {
    _tasks.add(task);
    state = AsyncValue.data(List<Task>.from(_tasks));
  }
}

class FakeProjectMetaRepository extends ProjectMetaRepository {
  final Map<String, ProjectMeta> _meta = <String, ProjectMeta>{};

  @override
  Future<void> initialize() async {}

  @override
  ProjectMeta getMeta(String projectId) {
    return _meta[projectId] ?? ProjectMeta.defaultFor(projectId);
  }

  @override
  Map<String, ProjectMeta> getAllMeta() {
    return Map<String, ProjectMeta>.from(_meta);
  }

  @override
  Future<void> setTrackedSeconds(String projectId, int seconds) async {
    final current = getMeta(projectId);
    _meta[projectId] = current.copyWith(trackedSeconds: seconds);
  }

  @override
  Future<void> setUrgency(String projectId, UrgencyLevel urgency) async {
    final current = getMeta(projectId);
    _meta[projectId] = current.copyWith(urgency: urgency);
  }
}

void main() {
  const projectId = 'p_getwidget_removed';

  const project = ProjectModel(
    id: projectId,
    name: 'Migration Project',
    progress: 0.4,
    status: 'In Progress',
    description: 'UI migration validation',
    tasks: ['Design', 'Implementation'],
    sharedUsers: ['alice'],
    sharedGroups: ['devs'],
  );

  final fakeMetaRepository = FakeProjectMetaRepository();

  Widget createTestWidget(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ProjectDetailScreen(projectId: projectId),
          );
        },
      ),
    );
  }

  group('ProjectDetailScreen widget tests', () {
    testWidgets('renders correctly after UI migration', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          projectsProvider.overrideWith(() => FakeProjectsNotifier([project])),
          projectByIdProvider.overrideWith((ref, id) async => project),
          tasksProvider.overrideWith(FakeTaskNotifier.new),
          permissionsProvider.overrideWith(
            (ref) => {
              AppPermissions.viewProjects,
              AppPermissions.shareProjects,
              AppPermissions.useAi,
            },
          ),
          projectMetaRepositoryProvider.overrideWith(
            (ref) async => fakeMetaRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Tab).at(1));
      await tester.pumpAndSettle();

      expect(find.text('Migration Project'), findsOneWidget);
      expect(find.byType(Card), findsAtLeastNWidgets(5));
      expect(find.byType(ProjectDetailScreen), findsOneWidget);
    });

    testWidgets('shared users action remains visible', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          projectsProvider.overrideWith(() => FakeProjectsNotifier([project])),
          projectByIdProvider.overrideWith((ref, id) async => project),
          tasksProvider.overrideWith(FakeTaskNotifier.new),
          permissionsProvider.overrideWith(
            (ref) => {
              AppPermissions.viewProjects,
              AppPermissions.shareProjects,
              AppPermissions.useAi,
            },
          ),
          projectMetaRepositoryProvider.overrideWith(
            (ref) async => fakeMetaRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Tab).at(1));
      await tester.pumpAndSettle();

      final shareAction = find.byIcon(Icons.person_add_alt_1);
      expect(shareAction, findsOneWidget);

      await tester.tap(shareAction);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
