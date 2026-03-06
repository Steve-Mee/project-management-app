import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/features/project/widgets/project_views.dart';
import 'package:project_management_app/generated/app_localizations.dart';
import 'package:pma_core/models/project_model.dart';

ProjectModel _project({
  required String id,
  required String name,
  required String status,
  required double progress,
  String? priority,
  DateTime? dueDate,
  List<String> tags = const <String>[],
}) {
  return ProjectModel(
    id: id,
    name: name,
    progress: progress,
    status: status,
    description: 'Description for $name',
    priority: priority,
    dueDate: dueDate,
    tags: tags,
  );
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required Widget child,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox.expand(child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final projects = <ProjectModel>[
    _project(
      id: 'p1',
      name: 'Alpha',
      status: 'In Progress',
      progress: 0.4,
      priority: 'High',
      dueDate: DateTime(2026, 3, 20),
      tags: const <String>['app', 'core'],
    ),
    _project(
      id: 'p2',
      name: 'Beta',
      status: 'In Review',
      progress: 0.8,
      priority: 'Medium',
      dueDate: DateTime(2026, 3, 28),
      tags: const <String>['ux'],
    ),
  ];

  group('Project views accessibility semantics', () {
    testWidgets('ProjectListView exposes expected semantics labels', (
      WidgetTester tester,
    ) async {
      await _pumpHarness(
        tester,
        child: ProjectListView(
          projects: projects,
          metaByProjectId: const <String, dynamic>{},
          canEditProjects: true,
          isSelectionMode: false,
          selectedIds: const <String>{},
          onLongPress: () {},
          onSelectionChanged: (_) {},
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'Projects list',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Projects list' &&
              widget.properties.value == '${projects.length} items',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'Project folder icon',
        ),
        findsWidgets,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'Open project details',
        ),
        findsWidgets,
      );
    });

    testWidgets('ProjectKanbanView exposes column/list/card semantics', (
      WidgetTester tester,
    ) async {
      await _pumpHarness(
        tester,
        child: SizedBox(
          height: 600,
          child: ProjectKanbanView(
            projects: projects,
            metaByProjectId: const <String, dynamic>{},
            canEditProjects: true,
            isSelectionMode: false,
            selectedIds: const <String>{},
            onLongPress: () {},
            onSelectionChanged: (_) {},
            onStatusChanged: (_, __) {},
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'In Progress column',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'In Progress column' &&
              widget.properties.value == '1 projects',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'In Progress project list',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'Kanban project card Alpha',
        ),
        findsOneWidget,
      );
    });

    testWidgets('ProjectTableView exposes table and progress semantics', (
      WidgetTester tester,
    ) async {
      await _pumpHarness(
        tester,
        child: ProjectTableView(
          projects: projects,
          metaByProjectId: const <String, dynamic>{},
          canEditProjects: true,
          isSelectionMode: false,
          selectedIds: const <String>{},
          onLongPress: () {},
          onSelectionChanged: (_) {},
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'Projects table view',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Projects table view' &&
              widget.properties.value == '${projects.length} projects',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'Project progress',
        ),
        findsWidgets,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Project progress' &&
              widget.properties.value == '40 percent',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == 'Open project Alpha',
        ),
        findsOneWidget,
      );
    });
  });
}
