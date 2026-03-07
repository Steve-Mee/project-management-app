import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:pma_core/core/feature_flags/feature_flag_resolver.dart';
import 'package:pma_core/models/project_model.dart';
import 'package:pma_core/models/task_model.dart';
import 'package:pma_core/core/providers.dart';
import 'package:pma_core/providers/project_providers.dart';
import 'package:pma_core/providers/task_providers.dart';
import 'package:pma_core/widgets/modern_gantt_chart.dart';
import 'package:project_management_app/generated/app_localizations.dart';

/// Gantt chart view for projects and tasks
class ProjectGanttView extends ConsumerStatefulWidget {
  const ProjectGanttView({super.key});

  @override
  ConsumerState<ProjectGanttView> createState() => _ProjectGanttViewState();
}

class _ProjectGanttViewState extends ConsumerState<ProjectGanttView> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now().add(const Duration(days: 90));
  double _zoomLevel = 1.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final featureFlags = ref.watch(featureFlagProvider);

    // Issue #071: fail-open while flags are still loading or unavailable.
    final isGanttEnabled = featureFlags.maybeWhen(
      data: (flags) =>
          FeatureFlagResolver.isEnabled(flags, 'gantt_chart_enabled', defaultValue: true),
      orElse: () => true,
    );

    if (!isGanttEnabled) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.ganttViewTitle)),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timeline,
                  size: 56,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                SizedBox(height: 12.h),
                Text(
                  l10n.featureFlagGanttDisabledMessage,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ganttViewTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () => _zoomIn(),
            tooltip: l10n.zoomInTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () => _zoomOut(),
            tooltip: l10n.zoomOutTooltip,
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _showDateRangePicker(),
            tooltip: l10n.selectDateRangeTooltip,
          ),
        ],
      ),
      body: projectsAsync.when(
        data: (projects) => _buildGanttView(context, projects, l10n),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading projects: $error'),
        ),
      ),
    );
  }

  Widget _buildGanttView(BuildContext context, List<ProjectModel> projects, AppLocalizations l10n) {
    final validProjects = projects.where((p) => p.startDate != null && p.dueDate != null).toList();

    if (validProjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
            SizedBox(height: 16.h),
            Text(
              l10n.noProjectsForGantt,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.addProjectsWithDates,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: validProjects.length,
      itemBuilder: (context, index) {
        final project = validProjects[index];
        return _buildProjectTimeline(context, project, l10n);
      },
    );
  }

  Widget _buildProjectTimeline(BuildContext context, ProjectModel project, AppLocalizations l10n) {
    final projectStart = project.startDate!;
    final projectEnd = project.dueDate!;
    final taskRepository = ref.watch(taskRepositoryProvider).value;
    final tasks = taskRepository == null
        ? const <Task>[]
        : taskRepository
            .getTasksForProject(project.id)
            .where((task) => task.dueDate != null)
            .toList();

    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project header
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => context.go('/projects/${project.id}'),
                  tooltip: l10n.openProjectTooltip,
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Project dates
            Text(
              '${DateFormat.yMMMd().format(projectStart)} - ${DateFormat.yMMMd().format(projectEnd)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.tasksTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            if (tasks.isEmpty)
              Text(
                l10n.noTasksYet,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              ModernGanttChart(
                project: project,
                    tasks: tasks.whereType<Task>().toList(),
                startDate: _startDate,
                endDate: _endDate,
                enableDragReschedule: true,
                onTaskRescheduleCommit: (task, newStartDate, newEndDate) {
                  _rescheduleTask(
                    project.id,
                    task,
                    newStartDate,
                    newEndDate,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _rescheduleTask(
    String projectId,
    Task task,
    DateTime newStartDate,
    DateTime newEndDate,
  ) async {
    final notifier = ref.read(tasksProvider.notifier);

    // Ensure TaskNotifier is scoped to the project before persisting updates.
    await notifier.loadTasks(projectId);

    final updatedTask = task.copyWith(
      createdAt: newStartDate,
      dueDate: newEndDate,
    );
    await notifier.updateTask(updatedTask);

    if (!mounted) {
      return;
    }

    // Refresh card content so task dates are reflected immediately.
    setState(() {});
  }

  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel * 1.2).clamp(0.5, 3.0);
      // Adjust date range based on zoom
      final currentRange = _endDate.difference(_startDate);
      final newRange = Duration(days: (currentRange.inDays / 1.2).round());
      final center = _startDate.add(currentRange ~/ 2);
      _startDate = center.subtract(newRange ~/ 2);
      _endDate = center.add(newRange ~/ 2);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel / 1.2).clamp(0.5, 3.0);
      // Adjust date range based on zoom
      final currentRange = _endDate.difference(_startDate);
      final newRange = Duration(days: (currentRange.inDays * 1.2).round());
      final center = _startDate.add(currentRange ~/ 2);
      _startDate = center.subtract(newRange ~/ 2);
      _endDate = center.add(newRange ~/ 2);
    });
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }
}
