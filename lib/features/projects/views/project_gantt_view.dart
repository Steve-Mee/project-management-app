import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:my_project_management_app/models/project_model.dart';
import 'package:my_project_management_app/models/task_model.dart';
import 'package:my_project_management_app/core/providers/project_providers.dart';
import 'package:my_project_management_app/core/providers/task_providers.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';

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
    final filter = ref.watch(persistentProjectFilterProvider);
    final projectsAsync = ref.watch(filteredProjectsProvider(filter));

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
    final totalDays = _endDate.difference(_startDate).inDays;
    final projectStart = project.startDate!;
    final projectEnd = project.dueDate!;
    final projectDuration = projectEnd.difference(projectStart).inDays;

    // Calculate position and width as percentage of total timeline
    final startOffset = projectStart.difference(_startDate).inDays;
    final leftPercent = (startOffset / totalDays).clamp(0.0, 1.0);
    final widthPercent = (projectDuration / totalDays).clamp(0.0, 1.0 - leftPercent);

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

            // Timeline visualization
            Container(
              height: 40.h,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Stack(
                children: [
                  // Project bar
                  Positioned(
                    left: leftPercent * (MediaQuery.of(context).size.width - 64.w),
                    width: widthPercent * (MediaQuery.of(context).size.width - 64.w),
                    top: 8.h,
                    bottom: 8.h,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getStatusColor(project.status),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Center(
                        child: Text(
                          '${project.progress}%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tasks
            SizedBox(height: 16.h),
            _buildProjectTasks(context, project, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectTasks(BuildContext context, ProjectModel project, AppLocalizations l10n) {
    final taskRepository = ref.read(taskRepositoryProvider).value;
    if (taskRepository == null) return const SizedBox.shrink();

    final tasks = taskRepository.getTasksForProject(project.id)
        .where((task) => task.dueDate != null)
        .toList();

    if (tasks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.tasksTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        ...tasks.map((task) => _buildTaskItem(context, task, project)),
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, Task task, ProjectModel project) {
    final totalDays = _endDate.difference(_startDate).inDays;
    final taskStart = task.createdAt;
    final taskEnd = task.dueDate!;
    final taskDuration = taskEnd.difference(taskStart).inDays;

    final startOffset = taskStart.difference(_startDate).inDays;
    final leftPercent = (startOffset / totalDays).clamp(0.0, 1.0);
    final widthPercent = (taskDuration / totalDays).clamp(0.0, 1.0 - leftPercent);

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              task.title,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Container(
              height: 20.h,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2.r),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: leftPercent * (MediaQuery.of(context).size.width - 200.w),
                    width: widthPercent * (MediaQuery.of(context).size.width - 200.w),
                    top: 2.h,
                    bottom: 2.h,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getTaskStatusColor(task.status),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
        return Colors.blue;
      case 'on hold':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getTaskStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.done:
        return Colors.green;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.review:
        return Colors.orange;
      case TaskStatus.todo:
        return Colors.grey;
    }
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