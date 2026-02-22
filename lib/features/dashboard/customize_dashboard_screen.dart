import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dashboard_grid/dashboard_grid.dart';
import 'package:my_project_management_app/features/dashboard/widgets/task_chart_widget.dart';
import 'package:my_project_management_app/features/dashboard/widgets/welcome_header_widget.dart';
import 'package:my_project_management_app/features/dashboard/widgets/project_card_widget.dart';
import 'package:my_project_management_app/features/dashboard/widgets/filters_sort_widget.dart';
import 'package:my_project_management_app/features/dashboard/widgets/recent_workflows_header_widget.dart';
import 'package:my_project_management_app/models/project_model.dart';
import 'package:my_project_management_app/core/models/dashboard_types.dart';
import 'package:my_project_management_app/models/project_sort.dart';
import 'package:my_project_management_app/core/providers/dashboard_providers.dart';
import 'package:my_project_management_app/core/providers/project_providers.dart';
import 'package:my_project_management_app/core/repository/i_dashboard_repository.dart';

class CustomizeDashboardScreen extends ConsumerStatefulWidget {
  const CustomizeDashboardScreen({super.key});

  @override
  ConsumerState<CustomizeDashboardScreen> createState() => _CustomizeDashboardScreenState();
}

class _CustomizeDashboardScreenState extends ConsumerState<CustomizeDashboardScreen> with WidgetsBindingObserver {
  List<DashboardItem> _dashboardItems = [];
  List<ProjectModel> _projects = [];
  late DashboardGrid _dashboardConfig;

  @override
  void initState() {
    super.initState();
    _dashboardConfig = DashboardGrid(maxColumns: 4);
    _dashboardConfig.addListener(_configListener);
    _dashboardConfig.listener = _onDashboardChanged;
    // Load config from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardConfigProvider.notifier).loadConfig().then((_) {
        _loadConfig();
      });
    });
  }

  @override
  void dispose() {
    _dashboardConfig.removeListener(_configListener);
    super.dispose();
  }

  void _configListener() {
    setState(() {});
  }

  void _onDashboardChanged(Iterable<DashboardGridChangeSnapshot> changes) {
    setState(() {
      _dashboardItems = _dashboardConfig.widgets.map((widget) => DashboardItem(
        widgetType: DashboardWidgetType.fromString(widget.id.split('_')[0]), // Extract type from id
        position: {
          'x': widget.x,
          'y': widget.y,
          'width': widget.width,
          'height': widget.height,
        },
      )).toList();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Config is loaded in initState
  }

  void _loadConfig() {
    // Load from provider
    final items = ref.read(dashboardConfigProvider);
    final projects = ref.read(projectsProvider).maybeWhen(
      data: (data) => data,
      orElse: () => <ProjectModel>[],
    );

    setState(() {
      if (items.isNotEmpty) {
        _dashboardItems = List.from(items);
      } else {
        // Add some default widgets for testing
        _dashboardItems = [
          DashboardItem(
            widgetType: DashboardWidgetType.metricCard,
            position: {'x': 0, 'y': 0, 'width': 4, 'height': 1},
          ),
          DashboardItem(
            widgetType: DashboardWidgetType.taskList,
            position: {'x': 0, 'y': 1, 'width': 2, 'height': 2},
          ),
          DashboardItem(
            widgetType: DashboardWidgetType.progressChart,
            position: {'x': 2, 'y': 1, 'width': 2, 'height': 2},
          ),
          DashboardItem(
            widgetType: DashboardWidgetType.kanbanBoard,
            position: {'x': 0, 'y': 3, 'width': 4, 'height': 2},
          ),
        ];
      }
      _projects = projects;

      // Clear existing widgets and add from _dashboardItems
      final existingWidgets = _dashboardConfig.widgets.toList();
      for (final widget in existingWidgets) {
        _dashboardConfig.removeWidget(widget);
      }
      for (final item in _dashboardItems) {
        _dashboardConfig.addWidget(DashboardWidget(
          id: '${item.widgetType}_${item.position['x']}_${item.position['y']}',
          x: item.position['x'] ?? 0,
          y: item.position['y'] ?? 0,
          width: item.position['width'] ?? 2,
          height: item.position['height'] ?? 1,
          builder: (context) => Card(
            elevation: 2,
            color: Theme.of(context).colorScheme.surface,
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: _buildWidgetForType(item.widgetType.name),
                ),
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: IconButton(
                    icon: Icon(
                      Icons.delete,
                      size: 20.sp,
                    ),
                    onPressed: () => _removeWidget(item),
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ));
      }
    });
  }

  void _saveConfig() {
    ref.read(dashboardConfigProvider.notifier).saveConfig(_dashboardItems);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dashboard saved!')),
    );
  }

  void _addWidget(String type, int x, int y) {
    final item = DashboardItem(
      widgetType: DashboardWidgetType.fromString(type),
      position: {'x': x, 'y': y, 'width': 2, 'height': 1},
    );
    setState(() {
      _dashboardItems.add(item);
    });
  }

  void _removeWidget(DashboardItem item) {
    setState(() {
      _dashboardItems.remove(item);
      // Remove from dashboard config
      final widgetId = '${item.widgetType}_${item.position['x']}_${item.position['y']}';
      final widgetToRemove = _dashboardConfig.widgets.firstWhere(
        (w) => w.id == widgetId,
        orElse: () => throw StateError('Widget not found'),
      );
      _dashboardConfig.removeWidget(widgetToRemove);
    });
  }

  Widget _buildWidgetForType(String type) {
    switch (type) {
      case 'welcome':
        return const WelcomeHeaderWidget();
      case 'taskChart':
        return TaskChartWidget(projects: _projects);
      case 'projectList':
        return Column(
          children: _projects.take(3).map((project) => ProjectCardWidget(
            project: project,
            onTap: () {},
          )).toList(),
        );
      case 'filters':
        return FiltersSortWidget(
          selectedStatus: 'All',
          sortBy: ProjectSort.name,
          onStatusChanged: (_) {},
          onSortChanged: (_) {},
          projects: _projects,
        );
      case 'recentWorkflows':
        return const RecentWorkflowsHeaderWidget();
      default:
        return const Text('Unknown widget');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Dashboard'),
        actions: [
          TextButton(
            onPressed: _saveConfig,
            child: const Text('Save'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          if (isDesktop) {
            return Row(
              children: [
                Flexible(
                  flex: 1,
                  child: _buildSidebar(),
                ),
                Flexible(
                  flex: 3,
                  child: _buildDashboardGrid(),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildSidebar(),
                ),
                Expanded(
                  flex: 2,
                  child: _buildDashboardGrid(),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                'Available Widgets',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                children: [
                  _buildDraggablePreview('welcome', 'Welcome Header'),
                  SizedBox(height: 8.h),
                  _buildDraggablePreview('taskChart', 'Task Chart'),
                  SizedBox(height: 8.h),
                  _buildDraggablePreview('projectList', 'Project List'),
                  SizedBox(height: 8.h),
                  _buildDraggablePreview('filters', 'Filters & Sort'),
                  SizedBox(height: 8.h),
                  _buildDraggablePreview('recentWorkflows', 'Recent Workflows'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardGrid() {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: DragTarget<String>(
        onAcceptWithDetails: (details) {
          final type = details.data;
          // Find next available position
          final existingPositions = _dashboardItems.map((item) => '${item.position['x']},${item.position['y']}').toSet();
          int x = 0, y = 0;
          while (existingPositions.contains('$x,$y')) {
            x++;
            if (x >= 4) {
              x = 0;
              y++;
            }
          }
          _addWidget(type, x, y);
        },
        builder: (context, candidateData, rejectedData) {
          return Dashboard(
            config: _dashboardConfig,
          );
        },
      ),
    );
  }

  Widget _buildDraggablePreview(String type, String label) {
    return Draggable<String>(
      data: type,
      feedback: Material(
        elevation: 4,
        child: Container(
          width: 200.w,
          height: 120.h,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Theme.of(context).colorScheme.primary),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(8.w),
                child: Text(
                  label,
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 80.h,
                  child: _buildWidgetForType(type),
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Container(
        margin: EdgeInsets.all(8.w),
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8.r),
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4.h),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Center(
                  child: Icon(
                    _getIconForType(type),
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 24.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      child: Card(
        elevation: 2,
        color: Theme.of(context).colorScheme.surface,
        child: Container(
          padding: EdgeInsets.all(8.w),
          child: Column(
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              SizedBox(
                height: 60.h,
                child: _buildWidgetForType(type),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'welcome':
        return Icons.waving_hand;
      case 'taskChart':
        return Icons.bar_chart;
      case 'projectList':
        return Icons.list;
      case 'filters':
        return Icons.filter_list;
      case 'recentWorkflows':
        return Icons.history;
      default:
        return Icons.widgets;
    }
  }
}