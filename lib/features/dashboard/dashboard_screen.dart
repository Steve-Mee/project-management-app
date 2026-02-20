import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dashboard_grid/dashboard_grid.dart';
import 'package:animate_do/animate_do.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:my_project_management_app/core/auth/permissions.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../models/project_meta.dart';
import '../../models/project_model.dart';
import '../../models/project_sort.dart';
import '../ai_chat/ai_chat_modal.dart';
import 'widgets/welcome_header_widget.dart';
import 'widgets/empty_state_widget.dart';
import 'widgets/filters_sort_widget.dart';
import 'widgets/error_state_widget.dart';
import 'widgets/loading_more_widget.dart';
import 'widgets/recent_workflows_header_widget.dart';
import 'widgets/task_chart_widget.dart';
import 'widgets/project_card_widget.dart';

/// Dashboard screen - responsive main page with projects overview
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _ChartColors {
  final Color primary;
  final Color secondary;
  final Color success;
  final Color neutral;
  final Color grid;
  final Color surface;

  const _ChartColors({
    required this.primary,
    required this.secondary,
    required this.success,
    required this.neutral,
    required this.grid,
    required this.surface,
  });
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  late final ProviderSubscription<String> _searchSubscription;
  static const int _pageSize = 9;
  int _visibleCount = _pageSize;
  String _selectedStatus = 'All';
  ProjectSort _sortBy = ProjectSort.name;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchSubscription = ref.listenManual<String>(
      searchQueryProvider,
      (_, _) {
      if (!mounted) {
        return;
      }
      setState(() {
        _visibleCount = _pageSize;
      });
      },
    );
    // _loadDashboardConfig(); // Removed, now using provider
  }

  // void _loadDashboardConfig() { // Removed
  //   // Placeholder: Load from Hive
  //   // _items = repo.getDashboardConfig() ?? [];
  //   // For now, default items
  //   _items = [
  //     DashboardItem(widgetType: 'welcome', position: {'x': 0, 'y': 0, 'width': 4, 'height': 1}),
  //     DashboardItem(widgetType: 'projectList', position: {'x': 0, 'y': 1, 'width': 2, 'height': 2}),
  //     DashboardItem(widgetType: 'taskChart', position: {'x': 2, 'y': 1, 'width': 2, 'height': 2}),
  //   ];
  // }

  Widget _buildWidgetForType(String type, List<ProjectModel> projects) {
    switch (type) {
      case 'welcome':
        return FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: const WelcomeHeaderWidget(),
        );
      case 'projectList':
        final visibleProjects = projects.take(6).toList(); // Limit for grid
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Projects',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: visibleProjects.length,
                    itemBuilder: (context, index) {
                      final project = visibleProjects[index];
                      return FadeInRight(
                        duration: Duration(milliseconds: 300 + (index * 100)),
                        child: Hero(
                          tag: 'project-${project.id}',
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () {
                                context.go('/projects/${project.id}');
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: 120,
                                  maxHeight: 160,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.folder,
                                      size: 32,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(height: 8),
                                    Flexible(
                                      child: Text(
                                        project.name,
                                        style: Theme.of(context).textTheme.titleSmall,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 4,
                                      child: LinearProgressIndicator(
                                        value: project.progress,
                                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      case 'taskChart':
        return TaskChartWidget(projects: projects);
      case 'aiUsage':
        return const _AiUsageWidget();
      case 'filters':
        return FiltersSortWidget(
          selectedStatus: _selectedStatus,
          sortBy: _sortBy,
          onStatusChanged: (status) {
            setState(() {
              _selectedStatus = status;
              _visibleCount = _pageSize;
            });
          },
          onSortChanged: (sort) {
            setState(() {
              _sortBy = sort;
              _visibleCount = _pageSize;
            });
          },
          projects: projects,
        );
      default:
        return const Text('Unknown widget');
    }
  }

  /// Build shimmer loading skeleton
  Widget _buildShimmerLoading() {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      child: Shimmer.fromColors(
        baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        highlightColor: Theme.of(context).colorScheme.surface,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            ...List.generate(
              3,
              (index) => Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: Container(
                  height: 150.h,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchSubscription.close();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      setState(() {
        _visibleCount += _pageSize;
      });
    }
  }

  _ChartColors _chartColors(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    Color tone(Color color, double amount) {
      if (!isDark) {
        return color;
      }
      final hsl = HSLColor.fromColor(color);
      final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
      return hsl.withLightness(lightness).toColor();
    }

    return _ChartColors(
      primary: tone(scheme.primary, 0.12),
      secondary: tone(scheme.secondary, 0.12),
      success: tone(scheme.tertiary, 0.12),
      neutral: isDark ? scheme.surfaceContainerHighest : scheme.outlineVariant,
      grid: scheme.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.6),
      surface: scheme.surface,
    );
  }

  String _formatChartPoints(List<FlSpot> points) {
    return points
        .map((spot) => '${spot.x.toInt()}=${spot.y.toInt()}')
        .join(', ');
  }

  Widget _buildProjectRow(BuildContext context, int rowIndex, List<ProjectModel> visibleProjects, bool isDesktop) {
    if (isDesktop) {
      const itemsPerRow = 3;
      final start = rowIndex * itemsPerRow;
      final end = min(start + itemsPerRow, visibleProjects.length);
      final rowProjects = visibleProjects.sublist(start, end);

      return Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: Row(
          children: List.generate(itemsPerRow, (colIndex) {
            if (colIndex >= rowProjects.length) {
              return const Spacer();
            }

            final project = rowProjects[colIndex];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: colIndex == itemsPerRow - 1 ? 0 : 12.w,
                ),
                child: AspectRatio(
                  aspectRatio: 1 / 0.75,
                  child: FadeInUp(
                    duration: Duration(milliseconds: 400 + (rowIndex * itemsPerRow + colIndex) * 50),
                    child: ProjectCardWidget(
                      key: Key(project.id),
                      project: project,
                      onTap: () => _showProjectDetailSheet(context, project),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    } else {
      final project = visibleProjects[rowIndex];
      return Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: AspectRatio(
          aspectRatio: 1 / 0.75,
          child: FadeInUp(
            duration: Duration(milliseconds: 400 + rowIndex * 100),
            child: ProjectCardWidget(
              key: Key(project.id),
              project: project,
              onTap: () => _showProjectDetailSheet(context, project),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final projectsState = ref.watch(visibleProjectsProvider);
    final canUseAi = ref.watch(hasPermissionProvider(AppPermissions.useAi));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.accentColor,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: FadeIn(
                duration: const Duration(milliseconds: 500),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width,
                    maxHeight: MediaQuery.of(context).size.height,
                  ),
                  child: projectsState.when(
                    loading: _buildShimmerLoading,
                    error: (error, _) => ErrorStateWidget(
                      error: error,
                      onRetry: () => ref.read(projectsProvider.notifier).refresh(),
                    ),
                    data: (projects) => _buildDashboardContent(context, projects),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: canUseAi
          ? Tooltip(
              message: l10n.aiChatWithProjectFilesTooltip,
              child: FloatingActionButton.extended(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const AiChatModal(),
                  );
                },
                icon: const Icon(Icons.smart_toy),
                label: Text(l10n.aiAssistantLabel),
              ),
            )
          : null,
    );
  }

  /// Build main dashboard content with responsive layout
  Widget _buildDashboardContent(
    BuildContext context,
    List<ProjectModel> projects,
  ) {
    final items = ref.watch(dashboardConfigProvider);
    if (items.isEmpty) {
      // Fallback to default layout
      return _buildDefaultDashboard(context, projects);
    }

    return _buildCustomDashboard(context, items, projects);
  }

  /// Build custom dashboard with grid layout
  Widget _buildCustomDashboard(
    BuildContext context,
    List<DashboardItem> items,
    List<ProjectModel> projects,
  ) {
    final dashboardConfig = DashboardGrid(maxColumns: 4);
    
    // Add widgets to config
    for (final item in items) {
      dashboardConfig.addWidget(DashboardWidget(
        id: '${item.widgetType}_${item.position['x']}_${item.position['y']}',
        x: item.position['x'] ?? 0,
        y: item.position['y'] ?? 0,
        width: item.position['width'] ?? 2,
        height: item.position['height'] ?? 1,
        builder: (context) => Card(
          elevation: 2,
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: _buildWidgetForType(item.widgetType, projects),
          ),
        ),
      ));
    }

    return Dashboard(
      config: dashboardConfig,
    );
  }

  Widget _buildDefaultDashboard(BuildContext context, List<ProjectModel> projects) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 600;

        // Filter projects based on search + status
        final statusFilter = _selectedStatus;
        final query = ref.watch(searchQueryProvider).toLowerCase();
        final filteredProjects = projects
            .where(
              (p) =>
                  p.name.toLowerCase().contains(query) ||
                  p.status.toLowerCase().contains(query),
            )
            .where(
              (p) => statusFilter == 'All' || p.status == statusFilter,
            )
            .toList();

        final metaByProjectId = ref.watch(projectMetaProvider);
        final sortedProjects =
            _sortProjects(filteredProjects, metaByProjectId);

        if (filteredProjects.isEmpty) {
          return EmptyStateWidget(query: query);
        }

        final visibleProjects =
          sortedProjects.take(_visibleCount).toList();
        final hasMore = visibleProjects.length < sortedProjects.length;
        final itemsPerRow = 3;
        final rowCount = isDesktop
            ? (visibleProjects.length / itemsPerRow).ceil()
            : visibleProjects.length;
        const headerCount = 2;
        const footerCount = 3;
        final totalCount = headerCount + rowCount + footerCount;

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(16.w),
          itemCount: totalCount,
          itemBuilder: (context, index) {
            if (index == 0) {
              return FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: const WelcomeHeaderWidget(),
              );
            }

            if (index == 1) {
              return FadeInLeft(
                duration: const Duration(milliseconds: 600),
                child: FiltersSortWidget(
                  selectedStatus: _selectedStatus,
                  sortBy: _sortBy,
                  onStatusChanged: (status) {
                    setState(() {
                      _selectedStatus = status;
                      _visibleCount = _pageSize;
                    });
                  },
                  onSortChanged: (sort) {
                    setState(() {
                      _sortBy = sort;
                      _visibleCount = _pageSize;
                    });
                  },
                  projects: projects,
                ),
              );
            }

            final projectStart = headerCount;
            final projectEnd = projectStart + rowCount;
            if (index >= projectStart && index < projectEnd) {
              final rowIndex = index - projectStart;
              return _buildProjectRow(context, rowIndex, visibleProjects, isDesktop);
            }

            final footerIndex = index - projectEnd;
            if (footerIndex == 0) {
              if (!hasMore) {
                return const SizedBox.shrink();
              }
              return const LoadingMoreWidget();
            }

            if (footerIndex == 1) {
              return const RecentWorkflowsHeaderWidget();
            }

            return TaskChartWidget(projects: projects);
          },
        );
      },
    );
  }

  List<ProjectModel> _sortProjects(
    List<ProjectModel> projects,
    Map<String, ProjectMeta> metaByProjectId,
  ) {
    final sorted = [...projects];
    switch (_sortBy) {
      case ProjectSort.name:
        sorted.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case ProjectSort.progress:
        sorted.sort((a, b) => b.progress.compareTo(a.progress));
        break;
      case ProjectSort.priority:
        sorted.sort((a, b) {
          final metaA = metaByProjectId[a.id] ?? ProjectMeta.defaultFor(a.id);
          final metaB = metaByProjectId[b.id] ?? ProjectMeta.defaultFor(b.id);
          final urgencyCompare =
              metaB.urgency.weight.compareTo(metaA.urgency.weight);
          if (urgencyCompare != 0) {
            return urgencyCompare;
          }
          return metaB.trackedSeconds.compareTo(metaA.trackedSeconds);
        });
        break;
    }
    return sorted;
  }

  /// Show project detail sheet with burndown chart
  void _showProjectDetailSheet(BuildContext context, ProjectModel project) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Detail header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.name,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                project.description ?? l10n.noDescription,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: l10n.closeButton,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),

                    // Burndown Chart Section
                    Text(
                      l10n.burndownProgressTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 12.h),
                    _buildBurndownChart(context, project),
                    SizedBox(height: 12.h),

                    // Chart legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12.w,
                              height: 3.h,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              l10n.actualProgressLabel,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                        SizedBox(width: 20.w),
                        Row(
                          children: [
                            Container(
                              width: 12.w,
                              height: 3.h,
                              color: Colors.green,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              l10n.idealTrendLabel,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),

                    // Project stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          context,
                          l10n.progressLabel,
                          '${(project.progress * 100).toStringAsFixed(0)}%',
                          Colors.green,
                        ),
                        _buildStatCard(
                          context,
                          l10n.statusLabel,
                          project.status,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          context,
                          l10n.tasksTitle,
                          '${project.tasks.length}',
                          Colors.purple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Build burndown chart with animated LineChart
  Widget _buildBurndownChart(BuildContext context, ProjectModel project) {
    final l10n = AppLocalizations.of(context)!;
    final colors = _chartColors(context);
    // Mock burndown data - actual progress
    final List<FlSpot> burndownData = [
      const FlSpot(0, 100),
      const FlSpot(1, 95),
      const FlSpot(2, 85),
      const FlSpot(3, 75),
      const FlSpot(4, 65),
      const FlSpot(5, 50),
      const FlSpot(6, 40),
      const FlSpot(7, 30),
      const FlSpot(8, 20),
      const FlSpot(9, 15),
      const FlSpot(10, 5),
    ];

    // Ideal trend line (linear decrease)
    final List<FlSpot> idealTrendData = [
      const FlSpot(0, 100),
      const FlSpot(1, 91),
      const FlSpot(2, 82),
      const FlSpot(3, 73),
      const FlSpot(4, 64),
      const FlSpot(5, 55),
      const FlSpot(6, 46),
      const FlSpot(7, 37),
      const FlSpot(8, 28),
      const FlSpot(9, 19),
      const FlSpot(10, 10),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive chart height - gebruik beschikbare breedte om hoogte te bepalen
        // Aspect ratio ~2:1 voor goede leesbaarheid, min 200, max 400
        final chartHeight = (constraints.maxWidth * 0.5).clamp(200.0, 400.0);

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 2000),
          builder: (context, value, child) {
            return Semantics(
              label: l10n.burndownChartSemantics(
                project.name,
                _formatChartPoints(burndownData),
                _formatChartPoints(idealTrendData),
              ),
              child: SizedBox(
                height: chartHeight,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 20,
                      verticalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(color: colors.grid, strokeWidth: 0.5);
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(color: colors.grid, strokeWidth: 0.5);
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 2,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}d',
                              style: TextStyle(fontSize: 10.sp),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 20,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}',
                              style: TextStyle(fontSize: 10.sp),
                            );
                          },
                          reservedSize: 40,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: colors.grid, width: 1),
                        left: BorderSide(color: colors.grid, width: 1),
                        right: const BorderSide(color: Colors.transparent),
                        top: const BorderSide(color: Colors.transparent),
                      ),
                    ),
                    minX: 0,
                    maxX: 10,
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      // Actual burndown line
                      LineChartBarData(
                        spots: burndownData,
                        isCurved: true,
                        color: colors.primary,
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: colors.primary,
                              strokeWidth: 2,
                              strokeColor: colors.surface,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: colors.primary.withValues(alpha: 0.12),
                        ),
                      ),
                      // Ideal trend line
                      LineChartBarData(
                        spots: idealTrendData,
                        isCurved: true,
                        color: colors.secondary.withValues(alpha: 0.6),
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dashArray: [5, 5],
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                    lineTouchData: LineTouchData(enabled: true),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Build stat card for project details
  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      color: colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AI Usage Widget - displays token usage with chart and compliance note
class _AiUsageWidget extends ConsumerWidget {
  const _AiUsageWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiUsageAsync = ref.watch(aiUsageProvider);
    final theme = Theme.of(context);
    final colors = _ChartColors(
      primary: theme.colorScheme.primary,
      secondary: theme.colorScheme.secondary,
      success: theme.colorScheme.tertiary,
      neutral: theme.colorScheme.outlineVariant,
      grid: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
      surface: theme.colorScheme.surface,
    );

    return aiUsageAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          'Error loading AI usage: $error',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      data: (aiUsage) {
        // Mock monthly data for chart - in production, fetch from Supabase
        final monthlyData = [
          FlSpot(1, 12000), // Jan
          FlSpot(2, 15000), // Feb
          FlSpot(3, 18000), // Mar
          FlSpot(4, 14000), // Apr
          FlSpot(5, 22000), // May
          FlSpot(6, aiUsage.tokensUsed.toDouble()), // Current month
        ];

        final usagePercentage = aiUsage.tokensUsed / aiUsage.monthlyLimit;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Usage',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // Current usage display
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tokens Used: ${aiUsage.tokensUsed.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Monthly Limit: ${aiUsage.monthlyLimit.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                CircularProgressIndicator(
                  value: usagePercentage.clamp(0.0, 1.0),
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    usagePercentage > 0.8
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Monthly breakdown chart
            Text(
              'Monthly Usage Trend',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 5000,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: colors.grid, strokeWidth: 0.5);
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(color: colors.grid, strokeWidth: 0.5);
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                          if (value.toInt() >= 1 && value.toInt() <= months.length) {
                            return Text(
                              months[value.toInt() - 1],
                              style: TextStyle(fontSize: 10.sp),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 5000,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(0)}k',
                            style: TextStyle(fontSize: 10.sp),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: monthlyData,
                      isCurved: true,
                      color: colors.primary,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: colors.primary.withValues(alpha: 0.1),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: colors.primary,
                            strokeWidth: 2,
                            strokeColor: colors.surface,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Compliance note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI usage is monitored for compliance with worldwide privacy regulations (GDPR, CCPA, etc.). Only aggregate usage data is stored.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
