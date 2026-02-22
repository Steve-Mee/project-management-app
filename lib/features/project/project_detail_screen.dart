import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getwidget/getwidget.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';
import 'package:my_project_management_app/core/auth/permissions.dart';
import 'package:my_project_management_app/core/providers/project_providers.dart';
import 'package:my_project_management_app/core/providers/task_providers.dart';
import 'package:my_project_management_app/core/providers/dashboard_providers.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/services/project_file_service.dart';
import '../../models/project_meta.dart';
import '../../models/project_model.dart';
import '../../models/task_model.dart';
import 'package:my_project_management_app/features/project/ai_chat_bottom_sheet.dart';
import 'package:my_project_management_app/features/project/expandable_task_card.dart';
import 'package:my_project_management_app/features/project/project_chat.dart';
import 'package:my_project_management_app/features/project/task_help_dialog.dart';
import 'package:my_project_management_app/features/project/requirements_icon_list_view.dart';

// Caching integrated – projectByIdProvider now uses 5-minute TTL cache (issue 006 part 5/5)

/// Project detail screen with responsive layout
class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen>
  with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final ProjectFileService _fileService = ProjectFileService();
  final TextEditingController _taskSearchController = TextEditingController();
  TaskStatus? _taskStatusFilter;
  Timer? _trackingTimer;
  int _trackedSeconds = 0;
  UrgencyLevel _urgency = UrgencyLevel.medium;
  bool _trackingPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);
    // Load tasks for the project
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tasksProvider.notifier).loadTasks(widget.projectId);
      _startTimeTracking();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _trackingTimer?.cancel();
    _persistTrackedTime();
    _tabController.dispose();
    _taskSearchController.dispose();
    super.dispose();
  }

  Future<void> _startTimeTracking() async {
    await _loadProjectMeta();
    _trackingTimer?.cancel();
    _trackingPaused = false;
    _trackingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _trackingPaused) {
        return;
      }
      setState(() {
        _trackedSeconds += 1;
      });
      if (_trackedSeconds % 30 == 0) {
        _persistTrackedTime();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _trackingPaused = true;
      _persistTrackedTime();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _trackingPaused = false;
    }
  }

  Future<void> _loadProjectMeta() async {
    final repo = await ref.read(projectMetaRepositoryProvider.future);
    final meta = repo.getMeta(widget.projectId);
    if (!mounted) {
      return;
    }
    setState(() {
      _trackedSeconds = meta.trackedSeconds;
      _urgency = meta.urgency;
    });
  }

  Future<void> _persistTrackedTime() async {
    try {
      final repo = await ref.read(projectMetaRepositoryProvider.future);
      await repo.setTrackedSeconds(widget.projectId, _trackedSeconds);
      ref.invalidate(projectMetaProvider);
    } catch (_) {
      // Ignore persistence errors; tracked time will retry on next tick.
    }
  }


  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectByIdProvider(widget.projectId));
    final isFromCache = ref.watch(projectCacheProvider(widget.projectId)) != null;

    return projectAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Failed to load project: $error')),
      ),
      data: (project) => project == null
          ? Scaffold(
              appBar: AppBar(title: const Text('Project Not Found')),
              body: const Center(child: Text('Project not found')),
            )
          : Scaffold(
              appBar: _buildAppBar(context, project, isFromCache),
              body: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width,
                  maxHeight: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 900;

                    return isDesktop
                        ? _buildDesktopLayout(context)
                        : _buildMobileLayout(context);
                  },
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => _showChatBottomSheet(context),
                tooltip: 'Project AI Assistant',
                child: const Icon(Icons.chat),
              ),
            ),
    );
  }

  /// Build app bar
  PreferredSizeWidget _buildAppBar(BuildContext context, ProjectModel project, bool isFromCache) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;

    return AppBar(
      toolbarHeight: isCompact ? 56.h : 64.h,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              project.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (isFromCache)
            Text(
              'Loaded from cache',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 10.sp,
              ),
            ),
        ],
      ),
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh project data',
          onPressed: () => ref.invalidate(projectByIdProvider(widget.projectId)),
        ),
        if (!isCompact)
          Tooltip(
            message: l10n.aiChatWithProjectFilesTooltip,
            child: IconButton(
              icon: const Icon(Icons.smart_toy),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => AiChatBottomSheet(projectId: widget.projectId),
                );
              },
            ),
          ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          tooltip: l10n.moreOptionsLabel,
          onPressed: () {
            final messenger = ScaffoldMessenger.maybeOf(context);
            if (messenger != null) {
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.moreOptionsLabel)),
              );
            }
          },
        ),
      ],
    );
  }

  /// Desktop layout with Kanban board on left and details pane on right
  Widget _buildDesktopLayout(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        // Left side - Kanban Board
        Expanded(
          flex: 2,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tasksTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 12.h),
                _buildTaskSearchControls(context),
                SizedBox(height: 12.h),
                Expanded(child: _buildKanbanBoard(context)),
              ],
            ),
          ),
        ),
        // Vertical divider
        VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
        // Right side - Details Pane
        Expanded(child: _buildDetailsPaneDesktop(context)),
      ],
    );
  }

  /// Mobile layout with TabBar
  Widget _buildMobileLayout(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;
    final tabPadding = EdgeInsets.all(isCompact ? 8.w : 12.w);

    return Column(
      children: [
        // Tab bar with responsive text
        TabBar(
          controller: _tabController,
          labelPadding: EdgeInsets.symmetric(horizontal: isCompact ? 8.w : 16.w),
          tabs: [
            Tab(
              child: Text(
                l10n.tasksTab,
                style: TextStyle(fontSize: isCompact ? 12.sp : 14.sp),
              ),
            ),
            Tab(
              child: Text(
                l10n.detailsTab,
                style: TextStyle(fontSize: isCompact ? 12.sp : 14.sp),
              ),
            ),
            Tab(
              child: Text(
                'Chat',
                style: TextStyle(fontSize: isCompact ? 12.sp : 14.sp),
              ),
            ),
          ],
        ),
        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Tasks tab
              Padding(
                padding: tabPadding,
                child: _buildTasksListMobile(context),
              ),
              // Details tab
              Padding(
                padding: tabPadding,
                child: _buildDetailsTabMobile(context),
              ),
              // Chat tab
              ProjectChat(projectId: widget.projectId),
            ],
          ),
        ),
      ],
    );
  }

  /// Build Kanban board with draggable cards
  Widget _buildKanbanBoard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tasksState = ref.watch(tasksProvider);
    if (tasksState.isLoading) {
      return _buildTasksLoading();
    }

    if (tasksState.hasError) {
      return _buildTasksError(l10n.tasksLoadFailed);
    }

    final tasksByStatus = _filterTasksByStatus(ref.watch(tasksByStatusProvider));
    final statuses = [
      TaskStatus.todo,
      TaskStatus.inProgress,
      TaskStatus.review,
      TaskStatus.done,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isNarrow = availableWidth < 600;
        final columnWidth = isNarrow
            ? null
            : (availableWidth / statuses.length).clamp(180.0, 280.0);

        if (isNarrow) {
          return ListView(
            children: statuses
                .map(
                  (status) => Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: _buildKanbanColumn(
                      context,
                      status,
                      tasksByStatus[status] ?? [],
                      columnWidth,
                    ),
                  ),
                )
                .toList(),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: availableWidth,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: statuses
                  .map(
                    (status) => Padding(
                      padding: EdgeInsets.only(right: 12.w),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: max(180.w, availableWidth / statuses.length - 24.w),
                          minWidth: 160.w,
                        ),
                        child: _buildKanbanColumn(
                          context,
                          status,
                          tasksByStatus[status] ?? [],
                          null, // Let ConstrainedBox handle width
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  /// Build individual Kanban column
  Widget _buildKanbanColumn(
    BuildContext context,
    TaskStatus status,
    List<Task> tasks,
    double? columnWidth,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final filteredTasks = _filterTasks(tasks);
    final statusColors = {
      TaskStatus.todo: Colors.grey,
      TaskStatus.inProgress: Colors.blue,
      TaskStatus.review: Colors.orange,
      TaskStatus.done: Colors.green,
    };

    return SizedBox(
      width: columnWidth ?? double.infinity,
      child: Container(
        constraints: BoxConstraints(
          minHeight: 200.h,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Column header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: (statusColors[status] ?? Colors.grey).withValues(
                  alpha: 0.2,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.r),
                  topRight: Radius.circular(8.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _taskStatusLabel(status, l10n).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: statusColors[status],
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: (statusColors[status] ?? Colors.grey).withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '${filteredTasks.length}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: statusColors[status],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tasks list
            Expanded(
              child: DragTarget<Task>(
                onAcceptWithDetails: (details) {
                  final task = details.data;
                  ref
                      .read(tasksProvider.notifier)
                      .updateTaskStatus(task.id, status);
                },
                builder: (context, candidateData, rejectedData) {
                  return ListView.builder(
                    padding: EdgeInsets.all(12.w),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: _buildDraggableTaskCard(context, task),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build draggable task card
  Widget _buildDraggableTaskCard(BuildContext context, Task task) {
    return Draggable<Task>(
      data: task,
      feedback: Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          width: 250.w,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildTaskCardContent(context, task),
      ),
      child: _buildTaskCardContent(context, task),
    );
  }

  /// Task card content
  Widget _buildTaskCardContent(BuildContext context, Task task) {
    return ExpandableTaskCard(
      task: task,
      onTap: () => _showTaskHelpDialog(context, task),
    );
  }

  /// Build details pane for desktop
  Widget _buildDetailsPaneDesktop(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stats = ref.watch(taskStatsProvider);
    final tasksState = ref.watch(tasksProvider);
    final projectsState = ref.watch(projectsProvider);
    final project = _getProjectFromState(projectsState);
    final canShare = ref.watch(hasPermissionProvider(AppPermissions.shareProjects));

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project header
            Text(
              l10n.projectOverviewTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8.h),
            if (project != null)
              Hero(
                tag: 'project-${project.id}',
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: project.progress,
                                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            SizedBox(height: 16.h),

            // Project requirements
            _buildRequirementsSection(context),
            SizedBox(height: 16.h),

            // Project directory linking
            _buildProjectDirectoryCard(context, project, projectsState),
            SizedBox(height: 16.h),
            _buildSharedUsersCard(context, project, canShare),
            SizedBox(height: 16.h),
            _buildTrackingCard(context),
            SizedBox(height: 16.h),

            if (tasksState.isLoading)
              Text(
                l10n.tasksLoading,
                style: Theme.of(context).textTheme.bodySmall,
              )
            else if (tasksState.hasError)
              Text(
                l10n.tasksLoadFailed,
                style: Theme.of(context).textTheme.bodySmall,
              ),

            // Task statistics
            _buildStatisticsCard(context, stats),
            SizedBox(height: 16.h),

            // Burndown chart placeholder
            _buildBurndownChartPlaceholder(context),
            SizedBox(height: 16.h),

            // Workflows expandable section
            _buildWorkflowsSection(
              context,
              tasksState.value ?? const <Task>[],
            ),
            SizedBox(height: 16.h),

            // Project chat section
            _buildChatSection(context),
          ],
        ),
      ),
    );
  }

  /// Build statistics card
  Widget _buildStatisticsCard(BuildContext context, TaskStats stats) {
    final l10n = AppLocalizations.of(context)!;
    return GFCard(
      border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      content: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.taskStatisticsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 12.h),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 320;
                final itemWidth = isNarrow
                    ? (constraints.maxWidth - 12.w) / 2
                    : null;

                Widget wrapItem(Widget child) {
                  if (itemWidth == null) {
                    return child;
                  }

                  return SizedBox(
                    width: itemWidth,
                    child: Align(alignment: Alignment.center, child: child),
                  );
                }

                return Wrap(
                  alignment: isNarrow
                      ? WrapAlignment.start
                      : WrapAlignment.spaceEvenly,
                  spacing: 12.w,
                  runSpacing: 12.h,
                  children: [
                    wrapItem(
                      _buildStatItem(
                        context,
                        '${stats.total}',
                        l10n.totalLabel,
                        Colors.blue,
                      ),
                    ),
                    wrapItem(
                      _buildStatItem(
                        context,
                        '${stats.completed}',
                        l10n.completedLabel,
                        Colors.green,
                      ),
                    ),
                    wrapItem(
                      _buildStatItem(
                        context,
                        '${stats.inProgress}',
                        l10n.inProgressLabel,
                        Colors.orange,
                      ),
                    ),
                    wrapItem(
                      _buildStatItem(
                        context,
                        '${stats.remaining}',
                        l10n.remainingLabel,
                        Colors.grey,
                      ),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 12.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: LinearProgressIndicator(
                value: stats.completionPercentage / 100,
                minHeight: 8.h,
                backgroundColor: Theme.of(context).colorScheme.surface,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.completionPercentLabel(
                stats.completionPercentage.toStringAsFixed(1),
              ),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  /// Build stat item
  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4.h),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  /// Build burndown chart placeholder
  Widget _buildBurndownChartPlaceholder(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GFCard(
      border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      content: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.burndownChartTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16.h),
            LayoutBuilder(
              builder: (context, constraints) {
                // Responsive placeholder height - aspect ratio ~2:1
                final placeholderHeight = (constraints.maxWidth * 0.5).clamp(
                  180.0,
                  350.0,
                );

                return Container(
                  height: placeholderHeight,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bar_chart,
                            size: 48.sp,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.5),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            l10n.chartPlaceholderTitle,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.7),
                                ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            l10n.chartPlaceholderSubtitle,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.5),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build workflows section with expandable tiles
  Widget _buildWorkflowsSection(BuildContext context, List<Task> tasks) {
    final l10n = AppLocalizations.of(context)!;
    if (tasks.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.workflowsTitle, style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 12.h),
          Text(
            l10n.noWorkflowsAvailable,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }

    final grouped = <TaskStatus, List<Task>>{
      TaskStatus.todo: [],
      TaskStatus.inProgress: [],
      TaskStatus.review: [],
      TaskStatus.done: [],
    };

    for (final task in tasks) {
      grouped[task.status]?.add(task);
    }

    String labelForStatus(TaskStatus status) {
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

    final sections = grouped.entries
        .where((entry) => entry.value.isNotEmpty)
        .map(
          (entry) => {
            'name': labelForStatus(entry.key),
            'status': entry.key == TaskStatus.inProgress
                ? l10n.workflowStatusActive
                : l10n.workflowStatusPending,
            'items': entry.value.map((task) => task.title).toList(),
          },
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.workflowsTitle, style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 12.h),
        ...sections.map((workflow) {
          final isActive = workflow['status'] == l10n.workflowStatusActive;
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: ExpansionTile(
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      workflow['name'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      workflow['status'] as String,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final item in (workflow['items'] as List<String>))
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 18.sp,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  item,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Build tasks list for mobile
  Widget _buildTasksListMobile(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tasksState = ref.watch(tasksProvider);
    if (tasksState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tasksState.hasError) {
      return Center(
        child: Text(
          l10n.tasksLoadFailed,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    final tasks = _filterTasks(tasksState.value ?? const <Task>[]);
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 48.sp,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.noTasksYet,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildTaskSearchControls(context),
        SizedBox(height: 12.h),
        Expanded(
          child: SingleChildScrollView(
            child: ExpansionPanelList(
              expansionCallback: (int index, bool isExpanded) {
                ref.read(taskExpansionProvider.notifier).toggleExpansion(tasks[index].id);
              },
              children: tasks.map<ExpansionPanel>((task) {
                final isExpanded = ref.watch(taskExpansionProvider.select((state) => state[task.id] ?? false));
                return ExpansionPanel(
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return ListTile(
                      title: Text(task.title),
                      subtitle: Text(task.statusLabel),
                      trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                    );
                  },
                  body: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(task.description),
                  ),
                  isExpanded: isExpanded,
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  /// Build details tab for mobile
  Widget _buildDetailsTabMobile(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stats = ref.watch(taskStatsProvider);
    final tasksState = ref.watch(tasksProvider);
    final projectsState = ref.watch(projectsProvider);
    final project = _getProjectFromState(projectsState);
    final canShare = ref.watch(hasPermissionProvider(AppPermissions.shareProjects));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProjectDirectoryCard(context, project, projectsState),
          SizedBox(height: 16.h),
          _buildSharedUsersCard(context, project, canShare),
          SizedBox(height: 16.h),
          _buildTrackingCard(context),
          SizedBox(height: 16.h),
          if (tasksState.isLoading)
            Text(
              l10n.tasksLoading,
              style: Theme.of(context).textTheme.bodySmall,
            )
          else if (tasksState.hasError)
            Text(
              l10n.tasksLoadFailed,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          _buildStatisticsCard(context, stats),
          SizedBox(height: 16.h),
          _buildBurndownChartPlaceholder(context),
          SizedBox(height: 16.h),
          _buildWorkflowsSection(
            context,
            tasksState.value ?? const <Task>[],
          ),
        ],
      ),
    );
  }

  Widget _buildTasksLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildTasksError(String message) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _buildTrackingCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GFCard(
      border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      content: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.projectTimeTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.urgencyValue(_urgencyLabel(_urgency, l10n)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            SizedBox(height: 4.h),
            Text(
              l10n.trackedTimeValue(_formatTrackedTime(_trackedSeconds, l10n)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTrackedTime(int seconds, AppLocalizations l10n) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    final parts = <String>[];
    if (hours > 0) {
      parts.add('$hours${l10n.hourShort}');
    }
    if (minutes > 0 || hours > 0) {
      parts.add('$minutes${l10n.minuteShort}');
    }
    parts.add('$secs${l10n.secondShort}');
    return parts.join(' ');
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

  String _urgencyLabel(UrgencyLevel level, AppLocalizations l10n) {
    switch (level) {
      case UrgencyLevel.low:
        return l10n.urgencyLow;
      case UrgencyLevel.medium:
        return l10n.urgencyMedium;
      case UrgencyLevel.high:
        return l10n.urgencyHigh;
    }
  }

  Widget _buildTaskSearchControls(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _taskSearchController,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchTasksHint,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12.w : 16.w,
              vertical: isCompact ? 8.h : 12.h,
            ),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _taskSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: l10n.clearSearchTooltip,
                    onPressed: () {
                      _taskSearchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: isCompact ? 4.w : 8.w,
          runSpacing: isCompact ? 4.h : 8.h,
          children: [
            _buildTaskStatusChip(l10n.allLabel, null),
            _buildTaskStatusChip(l10n.taskStatusTodo, TaskStatus.todo),
            _buildTaskStatusChip(l10n.taskStatusInProgress, TaskStatus.inProgress),
            _buildTaskStatusChip(l10n.taskStatusReview, TaskStatus.review),
            _buildTaskStatusChip(l10n.taskStatusDone, TaskStatus.done),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskStatusChip(String label, TaskStatus? status) {
    final isSelected = _taskStatusFilter == status;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: isCompact ? 12.sp : 14.sp,
        ),
      ),
      selected: isSelected,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8.w : 12.w,
        vertical: isCompact ? 4.h : 8.h,
      ),
      onSelected: (_) {
        setState(() {
          _taskStatusFilter = status;
        });
      },
    );
  }

  Map<TaskStatus, List<Task>> _filterTasksByStatus(
    Map<TaskStatus, List<Task>> tasksByStatus,
  ) {
    if (_taskStatusFilter == null) {
      return tasksByStatus;
    }

    return {
      TaskStatus.todo: _taskStatusFilter == TaskStatus.todo
          ? tasksByStatus[TaskStatus.todo] ?? const <Task>[]
          : const <Task>[],
      TaskStatus.inProgress: _taskStatusFilter == TaskStatus.inProgress
          ? tasksByStatus[TaskStatus.inProgress] ?? const <Task>[]
          : const <Task>[],
      TaskStatus.review: _taskStatusFilter == TaskStatus.review
          ? tasksByStatus[TaskStatus.review] ?? const <Task>[]
          : const <Task>[],
      TaskStatus.done: _taskStatusFilter == TaskStatus.done
          ? tasksByStatus[TaskStatus.done] ?? const <Task>[]
          : const <Task>[],
    };
  }

  List<Task> _filterTasks(List<Task> tasks) {
    final query = _taskSearchController.text.toLowerCase();
    final filtered = tasks
        .where((task) =>
            task.title.toLowerCase().contains(query) ||
            task.description.toLowerCase().contains(query))
        .toList();

    if (_taskStatusFilter == null) {
      return filtered;
    }

    return filtered
        .where((task) => task.status == _taskStatusFilter)
        .toList();
  }

  ProjectModel? _getProjectFromState(
    AsyncValue<List<ProjectModel>> projectsState,
  ) {
    return projectsState.maybeWhen(
      data: (projects) {
        for (final project in projects) {
          if (project.id == widget.projectId) {
            return project;
          }
        }
        return null;
      },
      orElse: () => null,
    );
  }

  Widget _buildProjectDirectoryCard(
    BuildContext context,
    ProjectModel? project,
    AsyncValue<List<ProjectModel>> projectsState,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final hasPath = (project?.directoryPath?.isNotEmpty ?? false);
    final isLoading = projectsState.isLoading;
    final hasError = projectsState.hasError;

    return GFCard(
      border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      content: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.projectMapTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () => _linkProjectDirectory(project),
                icon: const Icon(Icons.folder_open),
                label: Text(l10n.linkProjectMapButton),
              ),
            ),
            SizedBox(height: 12.h),
            if (isLoading)
              Text(
                l10n.projectDataLoading,
                style: Theme.of(context).textTheme.bodySmall,
              )
            else if (hasError)
              Text(
                l10n.projectDataLoadFailed,
                style: Theme.of(context).textTheme.bodySmall,
              )
            else if (hasPath)
              Text(
                l10n.currentMapLabel(project!.directoryPath!),
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              Text(
                l10n.noProjectMapLinked,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedUsersCard(
    BuildContext context,
    ProjectModel? project,
    bool canShare,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (project == null) {
      return const SizedBox.shrink();
    }

    final shared = project.sharedUsers;
    final sharedGroups = project.sharedGroups;
    return GFCard(
      border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      content: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.settingsUsersSection,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (canShare)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.person_add_alt_1),
                    tooltip: l10n.settingsAddUserTitle,
                    onSelected: (value) {
                      if (value == 'user') {
                        _promptShareUser(context, project.id);
                      } else if (value == 'group') {
                        _promptShareGroup(context, project.id);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'user',
                        child: Text(l10n.settingsAddUserTitle),
                      ),
                      PopupMenuItem(
                        value: 'group',
                        child: Text(l10n.groupAddTitle),
                      ),
                    ],
                  ),
              ],
            ),
            if (shared.isEmpty && sharedGroups.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  l10n.settingsNoUsersFound,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (shared.isNotEmpty)
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        for (final user in shared)
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width < 400 ? 120.w : 200.w),
                            child: Chip(
                              label: Text(
                                user,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onDeleted: canShare
                                  ? () => _removeSharedUser(project.id, user)
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  if (sharedGroups.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        for (final group in sharedGroups)
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width < 400 ? 120.w : 200.w),
                            child: Chip(
                              label: Text(
                                '${l10n.groupLabel}: $group',
                                overflow: TextOverflow.ellipsis,
                              ),
                              onDeleted: canShare
                                  ? () => _removeSharedGroup(project.id, group)
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _promptShareUser(
    BuildContext context,
    String projectId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final username = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.settingsAddUserTitle),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.usernameLabel,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancelButton),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(l10n.saveButton),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (username == null || username.trim().isEmpty) {
      return;
    }

    try {
      final repo = ref.read(projectRepositoryProvider);
      await repo.addSharedUser(projectId, username);
      ref.read(projectsProvider.notifier).refresh();
    } catch (_) {
      _showSnackBar(l10n.projectDataLoadFailed);
    }
  }

  Future<void> _promptShareGroup(
    BuildContext context,
    String projectId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final groupId = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.groupAddTitle),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: l10n.groupNameLabel,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancelButton),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(l10n.saveButton),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (groupId == null || groupId.trim().isEmpty) {
      return;
    }

    try {
      final repo = ref.read(projectRepositoryProvider);
      await repo.addSharedGroup(projectId, groupId);
      ref.read(projectsProvider.notifier).refresh();
    } catch (_) {
      _showSnackBar(l10n.projectDataLoadFailed);
    }
  }

  Future<void> _removeSharedUser(String projectId, String username) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final repo = ref.read(projectRepositoryProvider);
      await repo.removeSharedUser(projectId, username);
      ref.read(projectsProvider.notifier).refresh();
    } catch (_) {
      _showSnackBar(l10n.projectDataLoadFailed);
    }
  }

  Future<void> _removeSharedGroup(String projectId, String groupId) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final repo = ref.read(projectRepositoryProvider);
      await repo.removeSharedGroup(projectId, groupId);
      ref.read(projectsProvider.notifier).refresh();
    } catch (_) {
      _showSnackBar(l10n.projectDataLoadFailed);
    }
  }

  Future<void> _linkProjectDirectory(ProjectModel? project) async {
    final l10n = AppLocalizations.of(context)!;
    if (project == null) {
      _showSnackBar(l10n.projectNotAvailable);
      return;
    }

    final allowPick = await _showPrivacyWarningDialog();
    if (!allowPick) {
      return;
    }

    final consentEnabled = ref.read(privacyConsentProvider).maybeWhen(
      data: (enabled) => enabled,
      orElse: () => false,
    );
    if (!consentEnabled) {
      _showSnackBar(l10n.enableConsentInSettings);
      return;
    }

    // Prompt user to choose a directory and persist it to Hive.
    final directoryPath = await _fileService.pickProjectDirectory();
    if (directoryPath == null || directoryPath.isEmpty) {
      return;
    }

    await ref
        .read(projectsProvider.notifier)
        .updateDirectoryPath(project.id, directoryPath);

    _showSnackBar(l10n.projectMapLinked);
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showTaskHelpDialog(BuildContext context, Task task) async {
    final projectsAsync = ref.read(projectsProvider);
    final projectData = projectsAsync.maybeWhen(
      data: (projects) => projects.where((p) => p.id == widget.projectId).firstOrNull,
      orElse: () => null,
    );

    await showDialog(
      context: context,
      builder: (context) => TaskHelpDialog(
        task: task, 
        projectCategory: projectData?.category,
        aiAssistant: projectData?.aiAssistant,
      ),
    );
  }

  Future<bool> _showPrivacyWarningDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.privacyWarningTitle),
          content: Text(l10n.privacyWarningContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancelButton),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.continueButton),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// Build requirements section
  Widget _buildRequirementsSection(BuildContext context) {
    final innerProvider = ref.watch(projectRequirementsProvider(widget.projectId));
    final requirementsAsync = ref.watch(innerProvider);

    return requirementsAsync.when(
      data: (requirements) {
        if (requirements.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project Requirements',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            RequirementsIconListView(requirements: requirements),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Requirements',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Failed to load requirements: $error'),
            ),
          ),
        ],
      ),
    );
  }

  /// Build chat section for desktop
  Widget _buildChatSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Project Discussion',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 300,
          child: ProjectChat(projectId: widget.projectId),
        ),
      ],
    );
  }

  /// Show AI chat bottom sheet with compliance check
  void _showChatBottomSheet(BuildContext context) {
    final aiConsentEnabled = ref.read(aiConsentProvider).maybeWhen(
      data: (enabled) => enabled,
      orElse: () => false,
    );
    final canUseAi = ref.read(hasPermissionProvider(AppPermissions.useAi));
    
    if (!canUseAi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access denied: You do not have permission to use AI features.'),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    
    if (!aiConsentEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI features are disabled. Please enable AI consent in Settings.'),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AiChatBottomSheet(projectId: widget.projectId),
    );
  }
}
