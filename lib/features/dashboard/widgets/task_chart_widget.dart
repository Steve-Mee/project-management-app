import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';
import 'package:my_project_management_app/models/project_model.dart';
import 'package:my_project_management_app/models/task_model.dart';
import 'package:my_project_management_app/features/dashboard/widgets/error_state_widget.dart';
import 'package:my_project_management_app/core/providers/task_providers.dart';

final _recentTasksProvider = FutureProvider.autoDispose<List<Task>>((ref) async {
  final repository = await ref.watch(taskRepositoryProvider.future);
  final List<Task> tasks = repository.getAllTasks();
  tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return tasks;
});

class TaskChartWidget extends ConsumerWidget {
  const TaskChartWidget({super.key, required this.projects});

  final List<ProjectModel> projects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final recentTasks = ref.watch(_recentTasksProvider);

    return recentTasks.when(
      loading: () => _buildWorkflowLoading(context),
      error: (error, _) => ErrorStateWidget(
        error: error,
        onRetry: () => ref.invalidate(_recentTasksProvider),
      ),
      data: (tasks) {
        if (tasks.isEmpty) {
          return Text(
            l10n.noRecentTasks,
            style: Theme.of(context).textTheme.bodySmall,
          );
        }

        final projectById = {
          for (final project in projects) project.id: project,
        };

        final recentItems = tasks.take(4).toList();
        return Column(
          children: List.generate(recentItems.length, (index) {
            final task = recentItems[index];
            final projectName =
              projectById[task.projectId]?.name ?? l10n.unknownProject;
            final statusLabel = _taskStatusLabel(task.status, l10n);
            final timeLabel = _formatRecentTime(task.createdAt, l10n);
            final statusStyle = _statusStyleForTask(task.status);

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Semantics(
                  label:
                      l10n.projectTaskStatusSemantics(
                        projectName,
                        task.title,
                        statusLabel,
                        timeLabel,
                      ),
                  child: ListTile(
                    dense: true,
                    isThreeLine: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 4.h,
                    ),
                    leading: Semantics(
                      label: l10n.taskStatusSemantics(task.title, statusLabel),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: statusStyle.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          statusStyle.icon,
                          color: statusStyle.color,
                          size: 24.sp,
                        ),
                      ),
                    ),
                    title: Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4.h),
                        Text(
                          '$projectName • $statusLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          timeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildWorkflowLoading(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          const CircularProgressIndicator(),
          SizedBox(width: 12.w),
          Text(
            l10n.recentWorkflowsLoading,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  _TaskStatusStyle _statusStyleForTask(TaskStatus status) {
    switch (status) {
      case TaskStatus.inProgress:
        return _TaskStatusStyle(color: Colors.blue, icon: Icons.autorenew);
      case TaskStatus.review:
        return _TaskStatusStyle(color: Colors.orange, icon: Icons.visibility);
      case TaskStatus.todo:
        return _TaskStatusStyle(color: Colors.grey, icon: Icons.schedule);
      case TaskStatus.done:
        return _TaskStatusStyle(color: Colors.green, icon: Icons.check_circle);
    }
  }

  String _formatRecentTime(DateTime date, AppLocalizations l10n) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) {
      return l10n.timeJustNow;
    }
    if (difference.inMinutes < 60) {
      return l10n.timeMinutesAgo(difference.inMinutes);
    }
    if (difference.inHours < 24) {
      return l10n.timeHoursAgo(difference.inHours);
    }
    if (difference.inDays < 7) {
      return l10n.timeDaysAgo(difference.inDays);
    }
    final weeks = (difference.inDays / 7).floor();
    if (weeks < 4) {
      return l10n.timeWeeksAgo(weeks);
    }
    final months = (difference.inDays / 30).floor();
    return l10n.timeMonthsAgo(months);
  }

  String _taskStatusLabel(TaskStatus status, AppLocalizations l10n) {
    switch (status) {
      case TaskStatus.todo:
        return l10n.taskStatusTodo;
      case TaskStatus.inProgress:
        return l10n.taskStatusInProgress;
      case TaskStatus.review:
        return l10n.taskStatusReview;
      case TaskStatus.done:
        return l10n.taskStatusDone;
    }
  }
}

class _TaskStatusStyle {
  final Color color;
  final IconData icon;

  const _TaskStatusStyle({
    required this.color,
    required this.icon,
  });
}