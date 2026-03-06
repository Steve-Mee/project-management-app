# Gantt Chart Upgrade (Issue #069)

## Summary

This document tracks the final modernization of the Gantt feature:

- Legacy package usage removed from runtime code
- New `ModernGanttChart` wrapper added in `lib/core/widgets/modern_gantt_chart.dart`
- Riverpod + Hive task data integration completed
- Material 3 + dark mode + touch interactions verified
- Export and control polish completed (CSV/PDF, zoom, pan)

## Acceptance Criteria Checklist

- [x] Replace legacy chart implementation with modern `gantt_chart` integration
- [x] Use Material 3 theme tokens (`Theme.of(context).colorScheme`)
- [x] Support dark mode automatically
- [x] Render tasks with start/end dates, status colors, and progress labels
- [x] Touch gestures enabled
- [x] Drag-to-reschedule callback wired to `tasksProvider.notifier.updateTask(...)`
- [x] Full Riverpod integration for reactive updates
- [x] Offline support through Hive-backed task repository and notifier persistence
- [x] Add export actions (CSV/PDF share)
- [x] Add zoom/pan controls
- [x] Document upgrade in README and docs

## Key Implementation Files

- `lib/core/widgets/modern_gantt_chart.dart`
- `lib/features/projects/views/project_gantt_view.dart`
- `lib/core/repository/example_widgets.dart`
- `lib/core/providers/task/task_providers.dart`
- `lib/models/task_model.dart`

## Verification Notes

### Material 3 + Dark Mode

- `ModernGanttChart` uses `Theme.of(context).colorScheme` for task bars, borders, holidays, and containers.
- Theme brightness is read to adjust holiday/background alpha behavior.

### Touch Gestures + Drag-and-Drop

- Native horizontal timeline pan is supported by `GanttChartView` scroll behavior.
- Additional pan buttons are provided in control bar.
- Drag-to-reschedule is implemented through per-day event cell gesture handling and an `onTaskRescheduled` callback.

### Riverpod + Offline

- `ProjectDetailsWidget` loads project tasks via `tasksProvider.notifier.loadTasks(projectId)`.
- Reschedule operations call `tasksProvider.notifier.updateTask(updatedTask)`.
- `TaskNotifier` persists task changes through Hive repository (`HiveTaskRepository`), preserving offline behavior.
- `ganttTasksProvider` and `ganttTasksByProjectProvider` expose normalized, Gantt-compatible task streams.

### Legacy Code Check

- Runtime Dart source no longer imports or uses `legacy_gantt_chart`.
- Historical references may remain in docs/changelog sections for migration traceability.

## Notes

- Export behavior uses platform sharing:
  - CSV: generated from task rows
  - PDF: generated in-memory and shared as file data
- If product requirements need filesystem save dialogs, wire `onExportCsv`/`onExportPdf` callbacks from feature screens.
