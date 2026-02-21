import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';
import 'package:my_project_management_app/core/auth/permissions.dart';
import 'package:my_project_management_app/core/providers/project_providers.dart';
import 'package:my_project_management_app/core/repository/i_project_repository.dart' as repo;
import '../../core/providers/auth_providers.dart';
import '../../core/theme.dart';
import '../../models/project_meta.dart';
import '../../models/project_model.dart';
import '../../models/project_sort.dart';
import '../ai_chat/ai_chat_modal.dart';
import 'widgets/error_state_widget.dart';
import 'widgets/loading_more_widget.dart';
import 'widgets/project_card_widget.dart';
import '../project/widgets/project_filter_dialog.dart';

/// Filter state for projects list
// final currentProjectFilterProvider = StateProvider<ProjectFilterParams>((ref) => const ProjectFilterParams());

/// Sorting state for projects list
final currentProjectSortProvider = StateProvider<ProjectSort>((ref) => ProjectSort.name);

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
  Timer? _debounce;
  static const int _pageSize = 9;

  // pagination state
  int _page = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  List<ProjectModel> _projects = [];

  // advanced filters state
  bool _showAdvancedFilters = false;
  RangeValues _progressRange = const RangeValues(0, 100);
  // ignore: prefer_final_fields
  Set<String> _selectedPriorities = {};
  // ignore: prefer_final_fields
  List<String> _selectedTags = [];
  String? _customConditionType;
  String? _customConditionValue;
  String? _selectedPriority;
  DateTime? _startDate;
  DateTime? _endDate;

  // we no longer keep local sort/status values; read from providers

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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

  // custom widget formatter removed; not needed for combined list UI

  /// Build shimmer loading skeleton
  Widget _buildFilterBar(BuildContext context, ProjectFilter filter) {
    final l10n = AppLocalizations.of(context)!;
    final sort = ref.watch(currentProjectSortProvider);
    final theme = Theme.of(context);

    // helper for readable sort labels
    String sortLabel(ProjectSort s) {
      switch (s) {
        case ProjectSort.name:
          return 'Name A–Z';
        case ProjectSort.progress:
          return 'Progress ↓';
        case ProjectSort.priority:
          return 'Priority';
        case ProjectSort.createdDate:
          return 'Created (new→old)';
        case ProjectSort.status:
          return 'Status';
      }
    }

    int countActiveFilters(ProjectFilter filter) {
      int count = 0;
      if (filter.priority != null) count++;
      if (filter.status != null && filter.status != 'All') count++;
      if (filter.ownerId != null) count++;
      if (filter.searchQuery?.isNotEmpty == true) count++;
      if (filter.startDate != null) count++;
      if (filter.endDate != null) count++;
      if (filter.dueDateStart != null) count++;
      if (filter.dueDateEnd != null) count++;
      return count;
    }

    String getSortChipLabel(ProjectFilter filter, AppLocalizations l10n) {
      final sortBy = filter.sortBy ?? 'name';
      switch (sortBy) {
        case 'name':
          return l10n.projectSortName;
        case 'priority':
          return l10n.projectSortPriority;
        case 'startDate':
          return l10n.projectSortStartDate;
        case 'dueDate':
          return l10n.projectSortDueDate;
        case 'status':
          return l10n.projectSortStatus;
        default:
          return sortBy;
      }
    }

    return Column(
      children: [
        Card(
          elevation: 2,
          color: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: l10n.searchTasksHint,
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: _updateSearch,
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<ProjectSort>(
                      value: sort,
                      dropdownColor: theme.colorScheme.surface,
                      style: theme.textTheme.bodyMedium,
                      items: ProjectSort.values
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(sortLabel(s)),
                              ))
                          .toList(),
                      onChanged: (s) {
                        if (s != null) {
                          _updateSort(s);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          ...['All', 'In Progress', 'Completed', 'On Hold', 'Cancelled']
                              .map((status) => FilterChip(
                                    label: Text(status),
                                    selected: (filter.status ?? 'All') == status,
                                    selectedColor: theme.colorScheme.secondaryContainer,
                                    checkmarkColor: theme.colorScheme.onSecondaryContainer,
                                    onSelected: (_) => _updateStatus(status),
                                  )),
                          // Sort Chip
                          FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(getSortChipLabel(filter, l10n)),
                                const SizedBox(width: 4),
                                Icon(
                                  filter.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                  size: 16,
                                ),
                              ],
                            ),
                            selected: false,
                            onSelected: (_) async {
                              final newFilter = await showProjectFilterDialog(
                                context,
                                filter,
                                () => ref.read(persistentProjectFilterProvider.notifier).saveAsDefault(),
                                _projects,
                              );
                              if (newFilter != null) {
                                ref.read(persistentProjectFilterProvider.notifier).updateFilter(newFilter);
                              }
                            },
                            avatar: const Icon(Icons.sort, size: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Badge.count(
                      count: countActiveFilters(filter),
                      isLabelVisible: countActiveFilters(filter) > 0,
                      child: IconButton(
                        icon: const Icon(Icons.filter_list),
                        tooltip: l10n.filterButtonTooltip,
                        onPressed: () async {
                          final currentFilter = ProjectFilter(
                            status: filter.status,
                            ownerId: filter.ownerId,
                            searchQuery: filter.searchQuery,
                            priority: filter.priority,
                            startDate: filter.startDate,
                            endDate: filter.endDate,
                          );
                          final newFilter = await showProjectFilterDialog(
                            context,
                            currentFilter,
                            () => ref.read(persistentProjectFilterProvider.notifier).saveAsDefault(),
                            _projects, // Pass current filtered projects for export
                          );
                          if (newFilter != null) {
                            ref.read(persistentProjectFilterProvider.notifier).updateFilter(newFilter);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: () {
                        setState(() {
                          _showAdvancedFilters = !_showAdvancedFilters;
                        });
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Advanced'),
                          const SizedBox(width: 4),
                          Icon(
                            _showAdvancedFilters ? Icons.expand_less : Icons.expand_more,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1.0,
              child: child,
            );
          },
          child: _showAdvancedFilters ? _buildAdvancedFiltersCard(context, filter) : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildAdvancedFiltersCard(BuildContext context, ProjectFilter filter) {
    final theme = Theme.of(context);

    return Card(
      key: const ValueKey('advanced_filters'),
      elevation: 2,
      margin: const EdgeInsets.only(top: 8),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
      surfaceTintColor: theme.colorScheme.surfaceTint,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Filters',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Progress Range Slider
            Text(
              'Progress Range',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            RangeSlider(
              values: _progressRange,
              min: 0,
              max: 100,
              divisions: 20,
              labels: RangeLabels(
                '${_progressRange.start.round()}%',
                '${_progressRange.end.round()}%',
              ),
              onChanged: (values) {
                setState(() {
                  _progressRange = values;
                });
                _applyAdvancedFilters();
              },
              activeColor: theme.colorScheme.primary,
              inactiveColor: theme.colorScheme.surfaceContainerHighest,
            ),

            const SizedBox(height: 16),

            // Priority Multi-select Chips (using complexity as priority)
            Text(
              'Complexity',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildComplexityChip('simpel', Colors.green),
                _buildComplexityChip('middel', Colors.orange),
                _buildComplexityChip('complex', Colors.red),
              ],
            ),

            const SizedBox(height: 16),

            // Priority Dropdown
            Text(
              AppLocalizations.of(context)!.filterPriorityLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButton<String?>(
              value: _selectedPriority,
              hint: const Text('Select Priority'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Any')),
                DropdownMenuItem(value: 'Low', child: Text(AppLocalizations.of(context)!.priorityLow)),
                DropdownMenuItem(value: 'Medium', child: Text(AppLocalizations.of(context)!.priorityMedium)),
                DropdownMenuItem(value: 'High', child: Text(AppLocalizations.of(context)!.priorityHigh)),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value;
                });
                _applyAdvancedFilters();
              },
            ),

            const SizedBox(height: 16),

            // Date Range
            Text(
              AppLocalizations.of(context)!.filterDateRangeLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.filterStartDateLabel,
                    ),
                    readOnly: true,
                    controller: TextEditingController(
                      text: _startDate != null ? _startDate!.toLocal().toString().split(' ')[0] : '',
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() {
                          _startDate = date;
                        });
                        _applyAdvancedFilters();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.filterEndDateLabel,
                    ),
                    readOnly: true,
                    controller: TextEditingController(
                      text: _endDate != null ? _endDate!.toLocal().toString().split(' ')[0] : '',
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() {
                          _endDate = date;
                        });
                        _applyAdvancedFilters();
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Category Multi-select
            Text(
              'Category',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._selectedTags.map((tag) {
                  return InputChip(
                    label: Text(tag),
                    onDeleted: () {
                      setState(() {
                        _selectedTags.remove(tag);
                      });
                      _applyAdvancedFilters();
                    },
                    deleteIcon: const Icon(Icons.close, size: 16),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    labelStyle: TextStyle(color: theme.colorScheme.onSecondaryContainer),
                  );
                }),
                ActionChip(
                  label: const Text('+ Add Category'),
                  onPressed: _showAddCategoryDialog,
                  backgroundColor: theme.colorScheme.surface,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Custom Condition Builder
            Text(
              'Custom Conditions',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    hint: const Text('Condition'),
                    initialValue: _customConditionType,
                    items: const [
                      DropdownMenuItem(value: 'progress_gt', child: Text('Progress >')),
                      DropdownMenuItem(value: 'progress_lt', child: Text('Progress <')),
                      DropdownMenuItem(value: 'name_contains', child: Text('Name contains')),
                      DropdownMenuItem(value: 'description_contains', child: Text('Description contains')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _customConditionType = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Value',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    onChanged: (value) {
                      _customConditionValue = value;
                      _applyAdvancedFilters();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearAdvancedFilters,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Clear Advanced'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _applyAdvancedFilters,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplexityChip(String complexity, Color color) {
    final isSelected = _selectedPriorities.contains(complexity);

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(complexity),
        ],
      ),
      selected: isSelected,
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedPriorities.add(complexity);
          } else {
            _selectedPriorities.remove(complexity);
          }
        });
        _applyAdvancedFilters();
      },
    );
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter category name'),
          onSubmitted: (value) {
            if (value.isNotEmpty && !_selectedTags.contains(value)) {
              setState(() {
                _selectedTags.add(value);
              });
              _applyAdvancedFilters();
            }
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty && !_selectedTags.contains(value)) {
                setState(() {
                  _selectedTags.add(value);
                });
                _applyAdvancedFilters();
              }
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _applyAdvancedFilters() {
    final conditions = <repo.ProjectFilterConditions>[];

    // Progress range condition
    if (_progressRange.start > 0 || _progressRange.end < 100) {
      conditions.add(repo.ProjectFilterConditions(
        (project) => project.progress >= _progressRange.start && project.progress <= _progressRange.end,
      ));
    }

    // Complexity conditions (using complexity as priority)
    if (_selectedPriorities.isNotEmpty) {
      conditions.add(repo.ProjectFilterConditions(
        (project) => _selectedPriorities.contains(project.complexity.name),
      ));
    }

    // Category conditions (using category as tags)
    if (_selectedTags.isNotEmpty) {
      conditions.add(repo.ProjectFilterConditions(
        (project) => project.category != null && _selectedTags.contains(project.category!),
      ));
    }

    // Custom condition
    if (_customConditionType != null && _customConditionValue != null && _customConditionValue!.isNotEmpty) {
      switch (_customConditionType) {
        case 'progress_gt':
          final value = double.tryParse(_customConditionValue!);
          if (value != null) {
            conditions.add(repo.ProjectFilterConditions(
              (project) => project.progress > value,
            ));
          }
          break;
        case 'progress_lt':
          final value = double.tryParse(_customConditionValue!);
          if (value != null) {
            conditions.add(repo.ProjectFilterConditions(
              (project) => project.progress < value,
            ));
          }
          break;
        case 'name_contains':
          conditions.add(repo.ProjectFilterConditions(
            (project) => project.name.toLowerCase().contains(_customConditionValue!.toLowerCase()),
          ));
          break;
        case 'description_contains':
          conditions.add(repo.ProjectFilterConditions(
            (project) => (project.description ?? '').toLowerCase().contains(_customConditionValue!.toLowerCase()),
          ));
          break;
      }
    }

    // Update the filter provider with extra conditions
    ref.read(persistentProjectFilterProvider.notifier).updateFilter(
      ProjectFilter(
        status: ref.read(persistentProjectFilterProvider).status,
        ownerId: ref.read(persistentProjectFilterProvider).ownerId,
        searchQuery: ref.read(persistentProjectFilterProvider).searchQuery,
        priority: _selectedPriority,
        startDate: _startDate,
        endDate: _endDate,
        extraConditions: conditions,
      ),
    );

    // Reset pagination to page 1
    setState(() {
      _page = 1;
      _projects = [];
      _hasMore = true;
    });
    // Projects will be reloaded automatically by the provider
  }

  void _clearAdvancedFilters() {
    setState(() {
      _progressRange = const RangeValues(0, 100);
      _selectedPriorities.clear();
      _selectedTags.clear();
      _customConditionType = null;
      _customConditionValue = null;
      _selectedPriority = null;
      _startDate = null;
      _endDate = null;
    });
    _applyAdvancedFilters();
  }

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
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || !_hasMore || _isLoading) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  void _loadNextPage() {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _page += 1;
    });
  }

  void _resetPagination() {
    setState(() {
      _page = 1;
      _projects.clear();
      _hasMore = true;
      _isLoading = false;
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _updateSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final current = ref.read(persistentProjectFilterProvider);
      ref.read(persistentProjectFilterProvider.notifier).updateFilter(
        current.copyWith(searchQuery: query.isEmpty ? null : query),
      );
      _resetPagination();
    });
  }

  void _updateStatus(String status) {
    final current = ref.read(persistentProjectFilterProvider);
    ref.read(persistentProjectFilterProvider.notifier).updateFilter(
      current.copyWith(status: status == 'All' ? null : status),
    );
    _resetPagination();
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


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filter = ref.watch(persistentProjectFilterProvider);
    final canUseAi = ref.watch(hasPermissionProvider(AppPermissions.useAi));

    // watch paginated filtered projects data
    final params = FilteredPaginationParams(
      filter: filter,
      page: _page,
      limit: _pageSize,
    );
    final pageState = ref.watch(filteredProjectsPaginatedProvider(params));

    // listen to new page results and append
    ref.listen<AsyncValue<List<ProjectModel>>>(filteredProjectsPaginatedProvider(params),
        (previous, next) {
      next.whenData((newProjects) {
        if (_page == 1) {
          _projects = List.from(newProjects);
        } else {
          _projects.addAll(newProjects);
        }
        if (newProjects.length < _pageSize) {
          _hasMore = false;
        }
        _sortProjectsLocal();
        _isLoading = false;
      });
    });

    Widget bodyContent;
    if (pageState.isLoading && _projects.isEmpty) {
      bodyContent = _buildShimmerLoading();
    } else if (pageState.hasError && _projects.isEmpty) {
      bodyContent = ErrorStateWidget(
        error: pageState.error!,
        onRetry: () {
          _resetPagination();
        },
      );
    } else {
      bodyContent = _buildListView();
    }

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
          child: Column(
            children: [
              _buildFilterBar(context, filter),
              Expanded(child: bodyContent),
            ],
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
  // legacy dashboard helpers removed; combined list UI no longer uses them


  // sort local accumulated projects according to provider state
  void _sortProjectsLocal() {
    final sort = ref.read(currentProjectSortProvider);
    final metaByProjectId = ref.read(projectMetaProvider);
    switch (sort) {
      case ProjectSort.name:
        _projects.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case ProjectSort.progress:
        _projects.sort((a, b) => b.progress.compareTo(a.progress));
        break;
      case ProjectSort.priority:
        _projects.sort((a, b) {
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
      case ProjectSort.createdDate:
        // model doesn't have a createdAt field yet; leave order unchanged
        break;
      case ProjectSort.status:
        _projects.sort((a, b) => a.status.compareTo(b.status));
        break;
    }
  }

  void _updateSort(ProjectSort sort) {
    ref.read(currentProjectSortProvider.notifier).state = sort;
    _resetPagination();
  }

  Widget _buildListView() {
    final filter = ref.watch(persistentProjectFilterProvider);
    final l10n = AppLocalizations.of(context)!;
    // center the list on wide layouts and cap the overall width so cards don't stretch
    return LayoutBuilder(builder: (context, constraints) {
      final maxWidth = constraints.maxWidth;
      // determine number of columns for grid view
      int columns = 1;
      if (maxWidth > 1200) {
        columns = 3;
      } else if (maxWidth > 800) {
        columns = 2;
      }

      List<Widget> activeFilterChips = [];

      Color getPriorityColor(String priority) {
        switch (priority) {
          case 'High':
            return Colors.red.shade600;
          case 'Medium':
            return Colors.orange.shade600;
          case 'Low':
            return Colors.green.shade600;
          default:
            return Theme.of(context).colorScheme.onSurface;
        }
      }

      if (filter.priority != null) {
        activeFilterChips.add(FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.circle,
                size: 12,
                color: getPriorityColor(filter.priority!),
              ),
              const SizedBox(width: 4),
              Text(l10n.activeFilterPriority(filter.priority!)),
            ],
          ),
          selected: false,
          onSelected: (_) {},
          onDeleted: () {
            ref.read(persistentProjectFilterProvider.notifier).updateFilter(
              ref.read(persistentProjectFilterProvider).copyWith(priority: null),
            );
          },
        ));
      }
      if (filter.startDate != null) {
        activeFilterChips.add(FilterChip(
          label: Text(l10n.activeFilterStartDate(DateFormat('dd MMM').format(filter.startDate!))),
          selected: false,
          onSelected: (_) {},
          onDeleted: () {
            ref.read(persistentProjectFilterProvider.notifier).updateFilter(
              ref.read(persistentProjectFilterProvider).copyWith(startDate: null),
            );
          },
        ));
      }
      if (filter.endDate != null) {
        activeFilterChips.add(FilterChip(
          label: Text(l10n.activeFilterEndDate(DateFormat('dd MMM').format(filter.endDate!))),
          selected: false,
          onSelected: (_) {},
          onDeleted: () {
            ref.read(persistentProjectFilterProvider.notifier).updateFilter(
              ref.read(persistentProjectFilterProvider).copyWith(endDate: null),
            );
          },
        ));
      }
      if (filter.tags != null && filter.tags!.isNotEmpty) {
        for (final tag in filter.tags!) {
          activeFilterChips.add(FilterChip(
            label: Text('#$tag'),
            backgroundColor: Colors.purple.shade100,
            selected: false,
            onSelected: (_) {},
            onDeleted: () {
              final newTags = List<String>.from(filter.tags!)..remove(tag);
              ref.read(persistentProjectFilterProvider.notifier).updateFilter(
                ref.read(persistentProjectFilterProvider).copyWith(
                  tags: newTags.isEmpty ? null : newTags,
                ),
              );
            },
          ));
        }
      }
      if (filter.requiredTags != null && filter.requiredTags!.isNotEmpty) {
        for (final tag in filter.requiredTags!) {
          activeFilterChips.add(FilterChip(
            label: Text('#$tag (required)'),
            backgroundColor: Colors.red.shade100,
            selected: false,
            onSelected: (_) {},
            onDeleted: () {
              final newTags = List<String>.from(filter.requiredTags!)..remove(tag);
              ref.read(persistentProjectFilterProvider.notifier).updateFilter(
                ref.read(persistentProjectFilterProvider).copyWith(
                  requiredTags: newTags.isEmpty ? null : newTags,
                ),
              );
            },
          ));
        }
      }

      Widget content;
      if (columns == 1) {
        content = ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(16.w),
          itemCount: _projects.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < _projects.length) {
              final project = _projects[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: AspectRatio(
                  aspectRatio: 1 / 0.75,
                  child: FadeInUp(
                    duration: Duration(milliseconds: 400 + index * 100),
                    child: ProjectCardWidget(
                      key: Key(project.id),
                      project: project,
                      onTap: () => _showProjectDetailSheet(context, project),
                    ),
                  ),
                ),
              );
            }
            return const LoadingMoreWidget();
          },
        );
      } else {
        content = GridView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(16.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 1 / 0.75,
          ),
          itemCount: _projects.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < _projects.length) {
              final project = _projects[index];
              return FadeInUp(
                duration: Duration(milliseconds: 400 + index * 100),
                child: ProjectCardWidget(
                  key: Key(project.id),
                  project: project,
                  onTap: () => _showProjectDetailSheet(context, project),
                ),
              );
            }
            // show loading indicator spanning columns
            return GridTile(
              child: Padding(
                padding: EdgeInsets.only(top: 24.h),
                child: const LoadingMoreWidget(),
              ),
            );
          },
        );
      }

      Widget filterIndicator;
      if (activeFilterChips.isNotEmpty) {
        final allProjectsAsync = ref.watch(projectsProvider);
        final totalCount = allProjectsAsync.maybeWhen(
          data: (projects) => projects.length,
          orElse: () => 0,
        );
        filterIndicator = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.showingProjectsCount(_projects.length, totalCount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Wrap(spacing: 8, children: activeFilterChips),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      ref.read(persistentProjectFilterProvider.notifier).clearAll();
                    },
                    icon: Icon(Icons.clear_all, color: Theme.of(context).colorScheme.error),
                    label: Text(l10n.clearAllFiltersButtonLabel),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      } else {
        final allProjectsAsync = ref.watch(projectsProvider);
        final totalCount = allProjectsAsync.maybeWhen(
          data: (projects) => projects.length,
          orElse: () => 0,
        );
        filterIndicator = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            l10n.showingProjectsCount(_projects.length, totalCount),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }

      content = Column(
        children: [
          filterIndicator,
          Expanded(
            child: _projects.isEmpty && activeFilterChips.isNotEmpty
                ? _buildEmptyState()
                : content,
          ),
        ],
      );

      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: min(1000.w, maxWidth)),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            color: Theme.of(context).colorScheme.surface,
            clipBehavior: Clip.antiAlias,
            child: content,
          ),
        ),
      );
    });
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noProjectsMatchFiltersTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noProjectsMatchFiltersSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                ref.read(persistentProjectFilterProvider.notifier).clearAll();
              },
              icon: const Icon(Icons.clear_all),
              label: Text(l10n.clearAllFiltersButtonLabel),
            ),
          ],
        ),
      ),
    );
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
