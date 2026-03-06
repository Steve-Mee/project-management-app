import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';
import 'package:pma_core/widgets/modern_gantt_chart.dart';
import 'package:pma_core/models/project_model.dart';
import 'package:pma_core/models/task_model.dart';

ProjectModel _projectFixture() {
  return ProjectModel(
    id: 'p-modern-gantt',
    name: 'Modern Gantt Test Project',
    progress: 0.45,
    startDate: DateTime(2026, 3, 1),
    dueDate: DateTime(2026, 3, 31),
  );
}

Task _taskFixture() {
  return Task(
    id: 't-modern-gantt-1',
    projectId: 'p-modern-gantt',
    title: 'Implement timeline',
    description: 'Build timeline and gestures',
    status: TaskStatus.done,
    assignee: 'QA',
    createdAt: DateTime(2026, 3, 5),
    dueDate: DateTime(2026, 3, 10),
    priority: 0.8,
  );
}

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('ModernGanttChart commits drag once on drag-end', (tester) async {
    final project = _projectFixture();
    final task = _taskFixture();

    int commitCount = 0;
    DateTime? committedStart;
    DateTime? committedEnd;

    await tester.pumpWidget(
      _wrap(
        ModernGanttChart(
          project: project,
          tasks: [task],
          dayWidth: 24,
          eventHeight: 44,
          onTaskRescheduleCommit: (updatedTask, newStartDate, newEndDate) {
            commitCount += 1;
            committedStart = newStartDate;
            committedEnd = newEndDate;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    // The start-day cell renders progress text; dragging it should trigger one commit on drag-end.
    final startCell = find.text('100%').first;
    expect(startCell, findsOneWidget);

    await tester.drag(startCell, const Offset(90, 0));
    await tester.pumpAndSettle();

    expect(commitCount, 1);
    expect(committedStart, isNotNull);
    expect(committedEnd, isNotNull);
    expect(
      committedStart!.difference(task.ganttStartDate).inDays,
      greaterThan(0),
    );
  });

  testWidgets('ModernGanttChart exports CSV through callback', (tester) async {
    final project = _projectFixture();
    final task = _taskFixture();

    String? exportedCsv;

    await tester.pumpWidget(
      _wrap(
        ModernGanttChart(
          project: project,
          tasks: [task],
          eventHeight: 44,
          onExportCsv: (csv) async {
            exportedCsv = csv;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.download_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export CSV').last);
    await tester.pumpAndSettle();

    expect(exportedCsv, isNotNull);
    expect(exportedCsv, contains('Project,Task ID,Title,Status,Start,End,Progress'));
    expect(exportedCsv, contains(project.name));
    expect(exportedCsv, contains(task.title));
  });

  testWidgets('ModernGanttChart exports PDF through callback', (tester) async {
    final project = _projectFixture();
    final task = _taskFixture();

    Uint8List? exportedPdf;

    await tester.pumpWidget(
      _wrap(
        ModernGanttChart(
          project: project,
          tasks: [task],
          eventHeight: 44,
          onExportPdf: (bytes) async {
            exportedPdf = bytes;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.download_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export PDF').last);
    await tester.pumpAndSettle();

    expect(exportedPdf, isNotNull);
    expect(exportedPdf!.isNotEmpty, isTrue);
  });
}
