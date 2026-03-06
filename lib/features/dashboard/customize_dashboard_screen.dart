// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:dashboard_grid/dashboard_grid.dart';
import 'package:project_management_app/features/dashboard/widgets/task_chart_widget.dart';
import 'package:project_management_app/features/dashboard/widgets/welcome_header_widget.dart';
import 'package:project_management_app/features/dashboard/widgets/project_card_widget.dart';
import 'package:project_management_app/features/dashboard/widgets/filters_sort_widget.dart';
import 'package:project_management_app/features/dashboard/widgets/recent_workflows_header_widget.dart';
import 'package:pma_core/models/project_model.dart';
import 'package:pma_core/models/dashboard_types.dart';
import 'package:project_management_app/models/project_sort.dart';
import 'package:pma_core/providers/dashboard_providers.dart';
import 'package:pma_core/providers/project_providers.dart';
import 'package:pma_core/repository/models/dashboard_models.dart';
import 'package:pma_core/services/app_logger.dart';

class CustomizeDashboardScreen extends ConsumerStatefulWidget {
  const CustomizeDashboardScreen({super.key});

  @override
  ConsumerState<CustomizeDashboardScreen> createState() => _CustomizeDashboardScreenState();
}

class _CustomizeDashboardScreenState extends ConsumerState<CustomizeDashboardScreen> with WidgetsBindingObserver {
  List<DashboardItem> _dashboardItems = [];
  List<ProjectModel> _projects = [];
  late DashboardGrid _dashboardConfig;
  late TextEditingController _customWidgetJsonController;

  @override
  void initState() {
    super.initState();
    _dashboardConfig = DashboardGrid(maxColumns: 4);
    _customWidgetJsonController = TextEditingController();
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
    _customWidgetJsonController.dispose();
    super.dispose();
  }

  void _configListener() {
    setState(() {});
  }

  void _onDashboardChanged(Iterable<DashboardGridChangeSnapshot> changes) {
    final oldItems = List<DashboardItem>.from(_dashboardItems);
    
    setState(() {
      _dashboardItems = _dashboardConfig.widgets.map((widget) => DashboardItem(
        widgetType: DashboardWidgetType.fromString(widget.id.split('_')[0]), // Extract type from id
        position: {
          'x': widget.x,
          'y': widget.y,
          'width': _normalizeWidth(widget.width),
          'height': _normalizeHeight(widget.height),
        },
      )).toList();
    });

    // Update positions in provider for moved widgets
    for (int i = 0; i < _dashboardItems.length; i++) {
      final newItem = _dashboardItems[i];
      final oldItem = i < oldItems.length ? oldItems[i] : null;
      
      // Check if position changed
      if (oldItem == null || 
          oldItem.position['x'] != newItem.position['x'] ||
          oldItem.position['y'] != newItem.position['y'] ||
          oldItem.position['width'] != newItem.position['width'] ||
          oldItem.position['height'] != newItem.position['height']) {
        
        ref.read(dashboardConfigProvider.notifier).updateItemPosition(i, newItem.position);
        AppLogger.event('widget_arranged');
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Config is loaded in initState
  }

  void _loadConfig() {
    // Load from provider
    final itemsAsync = ref.read(dashboardConfigProvider);
    final projects = ref.read(projectsProvider).maybeWhen(
      data: (data) => data,
      orElse: () => <ProjectModel>[],
    );

    final items = itemsAsync.value ?? [];

    setState(() {
      if (items.isNotEmpty) {
        _dashboardItems = List.from(items);
      } else {
        // Add some default widgets for testing
        _dashboardItems = [
          const DashboardItem(
            widgetType: DashboardWidgetType.metricCard,
            position: {'x': 0, 'y': 0, 'width': 4, 'height': 1},
          ),
          const DashboardItem(
            widgetType: DashboardWidgetType.taskList,
            position: {'x': 0, 'y': 1, 'width': 2, 'height': 2},
          ),
          const DashboardItem(
            widgetType: DashboardWidgetType.progressChart,
            position: {'x': 2, 'y': 1, 'width': 2, 'height': 2},
          ),
          const DashboardItem(
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
        try {
          _dashboardConfig.addWidget(DashboardWidget(
            id: '${item.widgetType.name}_${item.position['x']}_${item.position['y']}',
            x: _normalizeAxis(item.position['x']),
            y: _normalizeAxis(item.position['y']),
            width: _normalizeWidth(item.position['width']),
            height: _normalizeHeight(item.position['height']),
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
        } catch (e) {
          AppLogger.instance.w('Skipping invalid dashboard widget during load', error: e);
        }
      }
    });
  }

  int _normalizeAxis(dynamic value) {
    final raw = (value as num?)?.toDouble() ?? 0;
    return raw >= kDashboardMinWidth
        ? (raw / kDashboardMinWidth).round()
        : raw.round();
  }

  int _normalizeWidth(dynamic value) {
    final raw = (value as num?)?.toDouble() ?? 2;
    final normalized = raw > 4 ? (raw / kDashboardMinWidth) : raw;
    return normalized.round().clamp(1, 4);
  }

  int _normalizeHeight(dynamic value) {
    final raw = (value as num?)?.toDouble() ?? 1;
    final normalized = raw > 12 ? (raw / kDashboardMinHeight) : raw;
    return normalized.round().clamp(1, 12);
  }

  void _saveConfig() {
    ref.read(dashboardConfigProvider.notifier).saveConfig(_dashboardItems);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dashboard saved!')),
    );
  }

  void _showTemplateSelector() {
    final templates = ref.read(layoutTemplatesProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Dashboard Template'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return ListTile(
                leading: Icon(
                  template.isPreset ? Icons.star : Icons.bookmark,
                  color: template.isPreset ? Colors.amber : Colors.blue,
                ),
                title: Text(template.name),
                subtitle: Text('${template.items.length} widgets'),
                onTap: () async {
                  final templateName = template.name;
                  await ref.read(dashboardConfigProvider.notifier).loadTemplate(template.id);
                  // Reload the config to update the UI
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  _loadConfig();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Applied template: $templateName')),
                    );
                  });
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
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
      final widgetId = '${item.widgetType.name}_${item.position['x']}_${item.position['y']}';
      final matchingWidgets = _dashboardConfig.widgets
          .where((w) => w.id == widgetId)
          .toList();
      if (matchingWidgets.isNotEmpty) {
        _dashboardConfig.removeWidget(matchingWidgets.first);
      }
    });
  }

  Future<void> _createCustomWidget() async {
    final jsonInput = _customWidgetJsonController.text.trim();
    if (jsonInput.isEmpty) return;

    try {
      await ref.read(dashboardConfigProvider.notifier).createCustomWidget(jsonInput);
      _customWidgetJsonController.clear();
      // Refresh the local state
      _loadConfig();
    } catch (e) {
      // Error is handled by the provider and shown via dashboardErrorProvider
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create custom widget: $e')),
      );
    }
  }

  Widget _buildWidgetForType(String type) {
    switch (type) {
      case 'welcome':
        return const WelcomeHeaderWidget();
      case 'taskChart':
        return TaskChartWidget(projects: _projects);
      case 'projectList':
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _projects.take(3).map((project) => ProjectCardWidget(
              project: project,
              onTap: () {},
            )).toList(),
          ),
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
          TextButton.icon(
            onPressed: _showTemplateSelector,
            icon: const Icon(Icons.view_module),
            label: const Text('Templates'),
          ),
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
                  SizedBox(height: 16.h),
                  _buildCustomWidgetCreator(),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Center(
                  child: Icon(
                    _getIconForType(type),
                    color: Theme.of(context).colorScheme.primary,
                    size: 28.sp,
                  ),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4.h),
            SizedBox(
              height: 40.h,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              SizedBox(
                height: 60.h,
                child: Center(
                  child: Icon(
                    _getIconForType(type),
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                    size: 26.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomWidgetCreator() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Custom Widget',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            TextField(
              controller: _customWidgetJsonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '{"widgetType": "metricCard", "position": {"x": 0, "y": 0, "width": 2, "height": 1}}',
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.all(8.w),
              ),
            ),
            SizedBox(height: 8.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createCustomWidget,
                icon: const Icon(Icons.add),
                label: const Text('Create Widget'),
              ),
            ),
          ],
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
