import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';
import 'package:my_project_management_app/core/auth/permissions.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:my_project_management_app/features/project/pdf_export.dart';
// ignore_for_file: use_build_context_synchronously, unnecessary_underscores
import 'package:my_project_management_app/core/providers/project_providers.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/theme_providers.dart';
import '../../core/providers/active_viewers_provider.dart';
import '../../models/project_meta.dart';
import '../../models/project_model.dart';
import '../../models/project_sort.dart';
import 'widgets/project_filter_dialog.dart';
import 'widgets/project_views.dart';
import 'widgets/active_viewers_indicator.dart';
import 'widgets/recent_filters_menu.dart';

/// Project management screen - displays list of all projects
class ProjectScreen extends ConsumerStatefulWidget {
  const ProjectScreen({super.key});

  @override
  ConsumerState<ProjectScreen> createState() => _ProjectScreenState();
}

/// Keyboard shortcut intents for project screen
class FocusSearchIntent extends Intent {
  const FocusSearchIntent();
}

class OpenFilterDialogIntent extends Intent {
  const OpenFilterDialogIntent();
}

class QuickSwitchViewIntent extends Intent {
  const QuickSwitchViewIntent();
}

class ExportCsvIntent extends Intent {
  const ExportCsvIntent();
}

/// Keyboard shortcut actions for project screen
class FocusSearchAction extends Action<FocusSearchIntent> {
  final FocusNode searchFocusNode;

  FocusSearchAction({required this.searchFocusNode});

  @override
  void invoke(covariant FocusSearchIntent intent) {
    searchFocusNode.requestFocus();
  }
}

class OpenFilterDialogAction extends Action<OpenFilterDialogIntent> {
  final BuildContext context;
  final WidgetRef ref;

  OpenFilterDialogAction({required this.context, required this.ref});

  @override
  Future<void> invoke(covariant OpenFilterDialogIntent intent) async {
    final currentFilter = ref.read(persistentProjectFilterProvider);
    final savedViews = ref.read(savedProjectViewsProvider);
    final result = await showProjectFilterDialog(
      context,
      currentFilter,
      () => ref.read(persistentProjectFilterProvider.notifier).saveAsDefault(),
      null, // filteredProjects
      savedViews,
      (filter, name) => ref.read(savedProjectViewsProvider.notifier).saveView(filter, name),
      (viewName) => ref.read(savedProjectViewsProvider.notifier).deleteView(viewName),
      (view) => ref.read(persistentProjectFilterProvider.notifier).loadView(view),
    );
    if (result != null) {
      ref.read(persistentProjectFilterProvider.notifier).updateFilter(result);
      // Note: _resetPagination() is called in the screen state, but we can't access it here
      // The screen will handle pagination reset through the filter change
    }
  }
}

class QuickSwitchViewAction extends Action<QuickSwitchViewIntent> {
  final BuildContext context;
  final WidgetRef ref;

  QuickSwitchViewAction({required this.context, required this.ref});

  @override
  Future<void> invoke(covariant QuickSwitchViewIntent intent) async {
    final savedViews = ref.read(savedProjectViewsProvider);
    if (savedViews.isEmpty) return;

    // Show a simple dialog to select a view
    final selectedView = await showDialog<ProjectFilter>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Quick Switch View'),
        children: [
          ...savedViews.map((view) => SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(view),
            child: Text(view.viewName ?? 'Unnamed View'),
          )),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedView != null) {
      ref.read(persistentProjectFilterProvider.notifier).loadView(selectedView);
    }
  }
}

class ExportCsvAction extends Action<ExportCsvIntent> {
  final BuildContext context;
  final WidgetRef ref;

  ExportCsvAction({required this.context, required this.ref});

  @override
  Future<void> invoke(covariant ExportCsvIntent intent) async {
    try {
      final projects = ref.read(visibleProjectsProvider);
      final currentFilter = ref.read(persistentProjectFilterProvider);

      if (projects is AsyncData<List<ProjectModel>>) {
        final filteredProjects = projects.value.where((project) {
          // Apply current filter logic here (simplified)
          if (currentFilter.status != null && project.status != currentFilter.status) return false;
          if (currentFilter.priority != null && project.priority != currentFilter.priority) return false;
          if (currentFilter.searchQuery != null && currentFilter.searchQuery!.isNotEmpty) {
            final query = currentFilter.searchQuery!.toLowerCase();
            if (!project.name.toLowerCase().contains(query) &&
                !(project.description?.toLowerCase().contains(query) ?? false)) {
              return false;
            }
          }
          return true;
        }).toList();

        await _exportToCsv(context, filteredProjects);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _exportToCsv(BuildContext context, List<ProjectModel> projects) async {
    final csvData = [
      ['Name', 'Status', 'Priority', 'Progress', 'Start Date', 'Due Date', 'Description'],
      ...projects.map((p) => [
        p.name,
        p.status,
        p.priority,
        '${p.progress}%',
        p.startDate?.toString() ?? '',
        p.dueDate?.toString() ?? '',
        p.description ?? '',
      ]),
    ];

    final csv = const ListToCsvConverter().convert(csvData);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/projects_export.csv');
    await file.writeAsString(csv);

    await Share.shareXFiles([XFile(file.path)], text: 'Projects export');
  }
}

class _ProjectScreenState extends ConsumerState<ProjectScreen> {
  final ScrollController _scrollController = ScrollController();
  late final ProviderSubscription<String> _searchSubscription;
  static const int _pageSize = 12;

  // search field controller and debounce
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  // pagination state
  final List<ProjectModel> _projects = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;

  // Focus node for search field to enable keyboard shortcuts
  final FocusNode _searchFocusNode = FocusNode();

  // Keyboard shortcuts definitions
  late final Map<ShortcutActivator, Intent> _shortcuts;
  late final Map<Type, Action<Intent>> _actions;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchSubscription = ref.listenManual<String>(
      searchQueryProvider,
      (_, __) {
        if (!mounted) return;
        _resetPagination();
      },
    );
    _searchController.text = ref.read(searchQueryProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _resetPagination());

    // Initialize shortcuts and actions
    _shortcuts = <ShortcutActivator, Intent>{
      // Ctrl/Cmd + F: Focus search field
      const SingleActivator(LogicalKeyboardKey.keyF, control: true): const FocusSearchIntent(),
      // Ctrl/Cmd + Shift + F: Open filter dialog
      const SingleActivator(LogicalKeyboardKey.keyF, control: true, shift: true): const OpenFilterDialogIntent(),
      // Ctrl/Cmd + K: Quick switch saved view
      const SingleActivator(LogicalKeyboardKey.keyK, control: true): const QuickSwitchViewIntent(),
      // Ctrl/Cmd + E: Export CSV
      const SingleActivator(LogicalKeyboardKey.keyE, control: true): const ExportCsvIntent(),
    };

    _actions = <Type, Action<Intent>>{
      FocusSearchIntent: FocusSearchAction(searchFocusNode: _searchFocusNode),
      OpenFilterDialogIntent: OpenFilterDialogAction(context: context, ref: ref),
      QuickSwitchViewIntent: QuickSwitchViewAction(context: context, ref: ref),
      ExportCsvIntent: ExportCsvAction(context: context, ref: ref),
    };
  }

  String _selectedStatus = 'All';
  ProjectSort _sortBy = ProjectSort.name;
  bool _sortAscending = true;
  String? _loadError;

  @override
  void dispose() {
    _searchSubscription.close();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoading || !_hasMore) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadPage();
    }
  }

  void _resetPagination() {
    setState(() {
      _page = 1;
      _projects.clear();
      _hasMore = true;
      _isLoading = false;
      _loadError = null;
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    _loadPage();
  }

  Future<void> _loadPage() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    try {
      final filter = ProjectFilter(
        status: _selectedStatus == 'All' ? null : _selectedStatus,
        searchQuery: ref.watch(searchQueryProvider).isEmpty
            ? null
            : ref.watch(searchQueryProvider),
      );
      final params = ProjectParams(
        page: _page,
        limit: _pageSize,
        filter: filter,
        sortBy: _sortBy.name,
        sortAscending: _sortAscending,
      );
      final newItems = await ref.read(projectsCombinedProvider(params).future);
      if (newItems.isEmpty || newItems.length < _pageSize) {
        _hasMore = false;
      }
      _projects.addAll(newItems);
      _page += 1;
    } catch (e) {
      _loadError = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleSelectionMode() {
    final isSelectionMode = ref.read(isSelectionModeProvider);
    if (isSelectionMode) {
      // Exit selection mode
      ref.read(selectedProjectIdsProvider.notifier).state = {};
      ref.read(isSelectionModeProvider.notifier).state = false;
    } else {
      // Enter selection mode
      ref.read(isSelectionModeProvider.notifier).state = true;
    }
  }

  void _showBulkActionsSheet() {
    final selectedIds = ref.read(selectedProjectIdsProvider);
    if (selectedIds.isEmpty) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => BulkActionsBottomSheet(
        selectedProjectIds: selectedIds,
        onActionCompleted: () {
          Navigator.of(context).pop();
          _resetPagination();
          _toggleSelectionMode();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metaByProjectId = ref.watch(projectMetaProvider);
    final canEditProjects =
        ref.watch(hasPermissionProvider(AppPermissions.editProjects));
    final isSelectionMode = ref.watch(isSelectionModeProvider);
    final selectedIds = ref.watch(selectedProjectIdsProvider);
    final currentFilter = ref.watch(persistentProjectFilterProvider);

    if (_projects.isEmpty && _isLoading) {
      return _buildLoadingContent(context, canEditProjects);
    }
    if (_loadError != null && _projects.isEmpty) {
      return _buildErrorContent(context, _loadError!, canEditProjects);
    }
    return Shortcuts(
      shortcuts: _shortcuts,
      child: Actions(
        actions: _actions,
        child: _buildProjectView(
          context,
          _projects,
          metaByProjectId,
          canEditProjects,
          isSelectionMode,
          selectedIds,
          currentFilter.viewMode,
        ),
      ),
    );
  }

  Widget _buildProjectView(
    BuildContext context,
    List<ProjectModel> projects,
    Map<String, ProjectMeta> metaByProjectId,
    bool canEditProjects,
    bool isSelectionMode,
    Set<String> selectedIds,
    String viewMode,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = _filterProjects(projects);
    final sorted = _sortProjects(filtered, metaByProjectId);

    const baseCount = 4; // title + search + filters/sort + view mode
    final itemCount = baseCount; // view content handles empty state internally

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16.w),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      isSelectionMode
                          ? l10n.selectProjectsTitle(selectedIds.length)
                          : l10n.projectsTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  // View mode switcher
                  _buildViewModeSwitcher(context, ref),
                  SizedBox(width: 16.w),
                  // Selection mode actions or Filter and Saved Views
                  if (isSelectionMode) ...[
                    if (selectedIds.isNotEmpty) ...[
                      IconButton(
                        icon: const Icon(Icons.checklist),
                        tooltip: l10n.bulkActionsTooltip,
                        onPressed: _showBulkActionsSheet,
                      ),
                      SizedBox(width: 8.w),
                    ],
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: l10n.exitSelectionModeTooltip,
                      onPressed: _toggleSelectionMode,
                    ),
                  ] else ...[
                    Row(
                      children: [
                        // Saved Views Dropdown
                        Consumer(
                          builder: (context, ref, child) {
                            final savedViews = ref.watch(savedProjectViewsProvider);
                            final currentFilter = ref.watch(persistentProjectFilterProvider);
                            return DropdownButton<String>(
                              value: currentFilter.viewName,
                              hint: Text(l10n.savedViewsLabel),
                              items: [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Text(l10n.allViewsLabel),
                                ),
                                ...savedViews.map((view) => DropdownMenuItem<String>(
                                  value: view.viewName,
                                  child: Text(view.viewName!),
                                )),
                              ],
                              onChanged: (value) {
                                if (value == null) {
                                  // Load default filter
                                  ref.read(persistentProjectFilterProvider.notifier).updateFilter(const ProjectFilter());
                                } else {
                                  final view = savedViews.firstWhere((v) => v.viewName == value);
                                  ref.read(persistentProjectFilterProvider.notifier).loadView(view);
                                }
                                _resetPagination();
                              },
                            );
                          },
                        ),
                        SizedBox(width: 8.w),
                        // Filter Button
                        IconButton(
                          icon: const Icon(Icons.filter_list),
                          tooltip: l10n.filterProjectsTooltip,
                          onPressed: () async {
                            final currentFilter = ref.watch(persistentProjectFilterProvider);
                            final savedViews = ref.watch(savedProjectViewsProvider);
                            final result = await showProjectFilterDialog(
                              context,
                              currentFilter,
                              () => ref.read(persistentProjectFilterProvider.notifier).saveAsDefault(),
                              null, // filteredProjects
                              savedViews,
                              (filter, name) => ref.read(savedProjectViewsProvider.notifier).saveView(filter, name),
                              (viewName) => ref.read(savedProjectViewsProvider.notifier).deleteView(viewName),
                              (view) => ref.read(persistentProjectFilterProvider.notifier).loadView(view),
                            );
                            if (result != null) {
                              ref.read(persistentProjectFilterProvider.notifier).updateFilter(result);
                              _resetPagination();
                              // Broadcast filter change to active viewers
                              ref.read(activeViewersProvider.notifier).updateCurrentFilter(result.toJson());
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        // Recent Filters Menu
                        const RecentFiltersMenu(),
                        const SizedBox(width: 8),
                        // Active Viewers Indicator
                        const ActiveViewersIndicator(),
                      ],
                    ),
                  ],
                  SizedBox(width: 16.w),
                  Flexible(
                    child: FloatingActionButton.extended(
                      onPressed: canEditProjects
                          ? () => _showAddProjectDialog(context, ref)
                          : null,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.newProjectButton),
                      isExtended: MediaQuery.of(context).size.width > 400,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        if (index == 1) {
          // search field
          return Padding(
            padding: EdgeInsets.only(top: 12.h, bottom: 12.h),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search projects...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchQueryProvider.notifier).setQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  onChanged: (value) {
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                      ref.read(searchQueryProvider.notifier).setQuery(value);
                    });
                  },
                ),
                // Tag suggestions
                if (_searchController.text.isNotEmpty) _buildTagSuggestions(context, ref),
              ],
            ),
          );
        }
        if (index == 2) {
          return Padding(
            padding: EdgeInsets.only(top: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusFilters(context, projects),
                SizedBox(height: 12.h),
                _buildSortControls(context),
              ],
            ),
          );
        }
        if (index == 3) {
          // View mode content
          return Padding(
            padding: EdgeInsets.only(top: 16.h),
            child: _buildViewContent(context, sorted, metaByProjectId, canEditProjects, isSelectionMode, selectedIds, viewMode),
          );
        }
        // This should never be reached, but satisfies the analyzer
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildViewModeSwitcher(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(persistentProjectFilterProvider);
    final l10n = AppLocalizations.of(context)!;

    return SegmentedButton<String>(
      segments: [
        ButtonSegment<String>(
          value: 'list',
          icon: const Icon(Icons.list),
          tooltip: l10n.listViewTooltip,
        ),
        ButtonSegment<String>(
          value: 'kanban',
          icon: const Icon(Icons.view_kanban),
          tooltip: l10n.kanbanViewTooltip,
        ),
        ButtonSegment<String>(
          value: 'table',
          icon: const Icon(Icons.table_chart),
          tooltip: l10n.tableViewTooltip,
        ),
      ],
      selected: {currentFilter.viewMode},
      onSelectionChanged: (Set<String> selected) {
        final newViewMode = selected.first;
        ref.read(persistentProjectFilterProvider.notifier).updateFilter(
          currentFilter.copyWith(viewMode: newViewMode),
        );
      },
      showSelectedIcon: false,
    );
  }

  Widget _buildViewContent(
    BuildContext context,
    List<ProjectModel> projects,
    Map<String, ProjectMeta> metaByProjectId,
    bool canEditProjects,
    bool isSelectionMode,
    Set<String> selectedIds,
    String viewMode,
  ) {
    switch (viewMode) {
      case 'kanban':
        return ProjectKanbanView(
          projects: projects,
          metaByProjectId: metaByProjectId,
          canEditProjects: canEditProjects,
          isSelectionMode: isSelectionMode,
          selectedIds: selectedIds,
          onLongPress: _toggleSelectionMode,
          onSelectionChanged: (selected) {
            // Selection is handled internally by the view widgets
          },
          onStatusChanged: (projectId, newStatus) => _updateProjectStatus(projectId, newStatus),
        );
      case 'table':
        return ProjectTableView(
          projects: projects,
          metaByProjectId: metaByProjectId,
          canEditProjects: canEditProjects,
          isSelectionMode: isSelectionMode,
          selectedIds: selectedIds,
          onLongPress: _toggleSelectionMode,
          onSelectionChanged: (selected) {
            // Selection is handled internally by the view widgets
          },
          onStatusChanged: (projectId, newStatus) => _updateProjectStatus(projectId, newStatus),
        );
      case 'list':
      default:
        return ProjectListView(
          projects: projects,
          metaByProjectId: metaByProjectId,
          canEditProjects: canEditProjects,
          isSelectionMode: isSelectionMode,
          selectedIds: selectedIds,
          onLongPress: _toggleSelectionMode,
          onSelectionChanged: (selected) {
            // Selection is handled internally by the view widgets
          },
          onStatusChanged: (projectId, newStatus) => _updateProjectStatus(projectId, newStatus),
        );
    }
  }

  Future<void> _updateProjectStatus(String projectId, String newStatus) async {
    try {
      // Find the current project
      final currentProject = _projects.firstWhere((p) => p.id == projectId);
      final updatedProject = ProjectModel(
        id: currentProject.id,
        name: currentProject.name,
        progress: currentProject.progress,
        directoryPath: currentProject.directoryPath,
        tasks: currentProject.tasks,
        status: newStatus, // Updated status
        description: currentProject.description,
        category: currentProject.category,
        aiAssistant: currentProject.aiAssistant,
        planJson: currentProject.planJson,
        helpLevel: currentProject.helpLevel,
        complexity: currentProject.complexity,
        history: currentProject.history,
        sharedUsers: currentProject.sharedUsers,
        sharedGroups: currentProject.sharedGroups,
        priority: currentProject.priority,
        startDate: currentProject.startDate,
        dueDate: currentProject.dueDate,
        tags: currentProject.tags,
      );
      
      await ref.read(projectsProvider.notifier).updateProject(
        projectId,
        updatedProject,
        changeDescription: 'Status changed to $newStatus via drag-and-drop',
      );
      // The provider will handle realtime updates via Supabase
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update project status: $e')),
        );
      }
    }
  }

  Widget _buildLoadingContent(BuildContext context, bool canEditProjects) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.all(16.w),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.projectsTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 16.w),
                Flexible(
                  child: FloatingActionButton.extended(
                    onPressed: canEditProjects
                        ? () => _showAddProjectDialog(context, ref)
                        : null,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.newProjectButton),
                    isExtended: MediaQuery.of(context).size.width > 400,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 24.h),
        SizedBox(height: 12.h),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget _buildErrorContent(
    BuildContext context,
    Object error,
    bool canEditProjects,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.all(16.w),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.projectsTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 16.w),
                Flexible(
                  child: FloatingActionButton.extended(
                    onPressed: canEditProjects
                        ? () => _showAddProjectDialog(context, ref)
                        : null,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.newProjectButton),
                    isExtended: MediaQuery.of(context).size.width > 400,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 24.h),
        SizedBox(height: 12.h),
        _buildLoadError(context, error),
      ],
    );
  }

  // old filtering now mostly handled by repository; keep for fallback
  List<ProjectModel> _filterProjects(List<ProjectModel> projects) {
    final query = ref.watch(searchQueryProvider).toLowerCase();
    return projects
        .where((project) =>
            project.name.toLowerCase().contains(query) ||
            project.status.toLowerCase().contains(query))
        .where(
          (project) =>
              _selectedStatus == 'All' || project.status == _selectedStatus,
        )
        .toList();
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
      case ProjectSort.createdDate:
        // no created-at on model; keep order
        break;
      case ProjectSort.status:
        sorted.sort((a, b) => a.status.compareTo(b.status));
        break;
    }
    return sorted;
  }

  Widget _buildStatusFilters(
    BuildContext context,
    List<ProjectModel> projects,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    final statuses = <String>{'All'};
    for (final project in projects) {
      statuses.add(project.status);
    }

    final items = statuses.toList()..sort();
    if (items.first != 'All') {
      items.remove('All');
      items.insert(0, 'All');
    }

    return Wrap(
      spacing: isCompact ? 4.w : 8.w,
      runSpacing: isCompact ? 4.h : 8.h,
      children: items.map((status) {
        final isSelected = _selectedStatus == status;
        return ChoiceChip(
          label: Text(
            status == 'All' ? l10n.allLabel : status,
            style: TextStyle(fontSize: isCompact ? 12.sp : 14.sp),
          ),
          selected: isSelected,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8.w : 12.w,
            vertical: isCompact ? 4.h : 8.h,
          ),
          onSelected: (_) {
            setState(() {
              _selectedStatus = status;
            });
            _resetPagination();
          },
        );
      }).toList(),
    );
  }

  Widget _buildSortControls(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;

    final options = <Map<String, dynamic>>[
      {'label': 'Name (A-Z)', 'sort': ProjectSort.name, 'asc': true},
      {'label': 'Name (Z-A)', 'sort': ProjectSort.name, 'asc': false},
      {'label': 'Progress (High→Low)', 'sort': ProjectSort.progress, 'asc': false},
      {'label': 'Progress (Low→High)', 'sort': ProjectSort.progress, 'asc': true},
      {'label': 'Created (Newest)', 'sort': ProjectSort.createdDate, 'asc': false},
      {'label': 'Created (Oldest)', 'sort': ProjectSort.createdDate, 'asc': true},
      {'label': 'Status', 'sort': ProjectSort.status, 'asc': true},
    ];

    if (isCompact) {
      return PopupMenuButton<int>(
        initialValue: options.indexWhere((o) => o['sort'] == _sortBy && o['asc'] == _sortAscending),
        onSelected: (i) {
          setState(() {
            _sortBy = options[i]['sort'] as ProjectSort;
            _sortAscending = options[i]['asc'] as bool;
          });
          _resetPagination();
        },
        itemBuilder: (context) => options
            .asMap()
            .entries
            .map((e) => PopupMenuItem<int>(
                  value: e.key,
                  child: Text(e.value['label'] as String),
                ))
            .toList(),
        child: Row(
          children: [
            Text(l10n.sortByLabel),
            Icon(Icons.arrow_drop_down),
          ],
        ),
      );
    }

    return Row(
      children: [
        Text(
          l10n.sortByLabel,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        SizedBox(width: 12.w),
        PopupMenuButton<int>(
          initialValue: options.indexWhere((o) => o['sort'] == _sortBy && o['asc'] == _sortAscending),
          onSelected: (i) {
            setState(() {
              _sortBy = options[i]['sort'] as ProjectSort;
              _sortAscending = options[i]['asc'] as bool;
            });
            _resetPagination();
          },
          itemBuilder: (context) => options
              .asMap()
              .entries
              .map((e) => PopupMenuItem<int>(
                    value: e.key,
                    child: Text(e.value['label'] as String),
                  ))
              .toList(),
          child: Row(
            children: [
              Text(_sortAscending ? '${_sortBy.toString().split('.').last} ↑' : '${_sortBy.toString().split('.').last} ↓'),
              Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTagSuggestions(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(filteredProjectsProvider(ref.watch(persistentProjectFilterProvider))).maybeWhen(
      data: (data) => data,
      orElse: () => <ProjectModel>[],
    );

    final allTags = <String>{};
    for (final project in projects) {
      allTags.addAll(project.tags);
    }

    final query = _searchController.text.toLowerCase();
    final matchingTags = allTags.where((tag) => tag.toLowerCase().contains(query)).toList()..sort();

    if (matchingTags.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(top: 4.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tag suggestions:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 4.h),
          Wrap(
            spacing: 4.w,
            runSpacing: 4.h,
            children: matchingTags.take(5).map((tag) => ActionChip(
              label: Text('#$tag'),
              onPressed: () {
                final currentQuery = _searchController.text;
                final newQuery = currentQuery.isEmpty ? '#$tag' : '$currentQuery #$tag';
                _searchController.text = newQuery;
                ref.read(searchQueryProvider.notifier).setQuery(newQuery);
              },
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadError(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: Column(
        children: [
          Text(
            l10n.loadProjectsFailed,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8.h),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _showAddProjectDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final customCategoryController = TextEditingController();
    UrgencyLevel urgency = UrgencyLevel.medium;
    String? category;
    Set<String> selectedPlatforms = {};
    Set<String> selectedRegions = {};
    String? selectedAIAgent;
    String hulpniveau = 'Basis';
    String complexiteit = 'Simpel';
    bool isDiscussing = false;

    Future<void> onDiscuss() async {
      final dialogContext = context;
      setState(() => isDiscussing = true);
      try {
        final selectedCategory = category == 'Custom' ? customCategoryController.text.trim() : category;
        final data = {
          'name': nameController.text,
          'category': selectedCategory,
          'description': descriptionController.text,
          'platforms': selectedPlatforms.toList(),
          'regions': selectedRegions.toList(),
          'aiAgent': selectedAIAgent,
          'hulpniveau': hulpniveau,
          'complexiteit': complexiteit,
        };
        final prompt = 'Discuss this project: ${jsonEncode(data)}';
        final response = await http.post(
          Uri.parse('https://api.x.ai/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer YOUR_API_KEY',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'grok-1',
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
          }),
        );
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final reply = responseData['choices'][0]['message']['content'];
          final parsed = jsonDecode(reply);
          final questions = parsed['questions'] as List<dynamic>? ?? [];
          final proposals = parsed['proposals'] as List<dynamic>? ?? [];
          showDialog(
            context: dialogContext,
            builder: (context) => StatefulBuilder(
              builder: (context, setState) {
                final acceptedQuestions = <int>{};
                final selectedProposals = <int>{};
                return AlertDialog(
                  title: const Text('Grok Response'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (questions.isNotEmpty) ...[
                          const Text('Questions:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ...questions.asMap().entries.map((entry) {
                            final index = entry.key;
                            final question = entry.value as String;
                            return Row(
                              children: [
                                Expanded(child: Text(question)),
                                TextButton(
                                  onPressed: acceptedQuestions.contains(index) ? null : () => setState(() => acceptedQuestions.add(index)),
                                  child: const Text('Accept'),
                                ),
                                TextButton(
                                  onPressed: acceptedQuestions.contains(index) ? () => setState(() => acceptedQuestions.remove(index)) : null,
                                  child: const Text('Refuse'),
                                ),
                              ],
                            );
                          }),
                        ] else const Text('No questions'),
                        const SizedBox(height: 16),
                        if (proposals.isNotEmpty) ...[
                          const Text('Proposals:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ...proposals.asMap().entries.map((entry) {
                            final index = entry.key;
                            final proposal = entry.value as String;
                            return CheckboxListTile(
                              title: Text(proposal),
                              value: selectedProposals.contains(index),
                              onChanged: (value) => setState(() {
                                if (value == true) {
                                  selectedProposals.add(index);
                                } else {
                                  selectedProposals.remove(index);
                                }
                              }),
                            );
                          }),
                        ] else const Text('No proposals'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            ),
          );
        } else {
          throw Exception('Failed to get response: ${response.statusCode}');
        }
      } catch (e) {
        showDialog(
          context: dialogContext,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } finally {
        setState(() => isDiscussing = false);
      }
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.newProjectDialogTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: l10n.projectNameLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: l10n.descriptionLabel,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: InputDecoration(
                      labelText: 'Category',
                    ),
                    items: [
                      'Software',
                      'Hardware',
                      'Board Game',
                      'Kunst',
                      'Marketing',
                      'Architectuur',
                      'Onderwijs',
                      'Bedrijfsontwikkeling',
                      'Wetenschap',
                      'Overig',
                      'Custom',
                    ].map((cat) => DropdownMenuItem<String>(
                      value: cat,
                      child: Text(cat),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        category = value;
                      });
                    },
                  ),
                  if (category == 'Custom') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: customCategoryController,
                      decoration: InputDecoration(
                        labelText: 'Custom Category',
                      ),
                    ),
                  ],
                  if (category == 'Software') ...[
                    const SizedBox(height: 12),
                    const Text('Platforms:', style: TextStyle(fontWeight: FontWeight.bold)),
                    CheckboxListTile(
                      title: const Text('iOS'),
                      value: selectedPlatforms.contains('iOS'),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedPlatforms.add('iOS');
                          } else {
                            selectedPlatforms.remove('iOS');
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Android'),
                      value: selectedPlatforms.contains('Android'),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedPlatforms.add('Android');
                          } else {
                            selectedPlatforms.remove('Android');
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Web'),
                      value: selectedPlatforms.contains('Web'),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedPlatforms.add('Web');
                          } else {
                            selectedPlatforms.remove('Web');
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Regions:', style: TextStyle(fontWeight: FontWeight.bold)),
                    CheckboxListTile(
                      title: const Text('EU'),
                      value: selectedRegions.contains('EU'),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedRegions.add('EU');
                          } else {
                            selectedRegions.remove('EU');
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('US'),
                      value: selectedRegions.contains('US'),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedRegions.add('US');
                          } else {
                            selectedRegions.remove('US');
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Wereldwijd'),
                      value: selectedRegions.contains('Wereldwijd'),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedRegions.add('Wereldwijd');
                          } else {
                            selectedRegions.remove('Wereldwijd');
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedAIAgent,
                      decoration: const InputDecoration(labelText: 'AI Agent'),
                      items: ['GPT-4', 'Claude', 'Gemini', 'Custom'].map((agent) => DropdownMenuItem<String>(
                        value: agent,
                        child: Text(agent),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedAIAgent = value;
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UrgencyLevel>(
                    initialValue: urgency,
                    decoration: InputDecoration(
                      labelText: l10n.urgencyLabel,
                    ),
                    items: UrgencyLevel.values
                        .map(
                          (level) => DropdownMenuItem(
                            value: level,
                            child: Text(_urgencyLabel(level, l10n)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      urgency = value;
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text('Hulpniveau:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Basis', label: Text('Basis')),
                      ButtonSegment(value: 'Gedetailleerd', label: Text('Gedetailleerd')),
                      ButtonSegment(value: 'Stap-voor-stap', label: Text('Stap-voor-stap')),
                    ],
                    selected: {hulpniveau},
                    onSelectionChanged: (selected) => setState(() => hulpniveau = selected.first),
                  ),
                  const SizedBox(height: 12),
                  const Text('Complexiteit:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Simpel', label: Text('Simpel')),
                      ButtonSegment(value: 'Middel', label: Text('Middel')),
                      ButtonSegment(value: 'Complex', label: Text('Complex')),
                    ],
                    selected: {complexiteit},
                    onSelectionChanged: (selected) => setState(() => complexiteit = selected.first),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancelButton),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n.saveButton),
                ),
                TextButton(
                  onPressed: isDiscussing ? null : () async => await onDiscuss(),
                  child: isDiscussing ? const CircularProgressIndicator() : const Text('Discuss with Grok'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) {
      return;
    }

    final name = nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    // Get current user for sharing
    final authState = ref.read(authProvider).value!;
    final currentUsername = authState.username ?? '';

    final project = ProjectModel.create(
      name: name,
      progress: 0.0,
      status: 'In Progress',
      description: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      category: category == 'Custom' ? customCategoryController.text.trim() : category,
      directoryPath: null,
      tasks: const [],
      sharedUsers: currentUsername.isNotEmpty ? [currentUsername] : [],
    );

    await ref.read(projectsProvider.notifier).addProject(project);
    final metaRepo = await ref.read(projectMetaRepositoryProvider.future);
    await metaRepo.setUrgency(project.id, urgency);
    ref.invalidate(projectMetaProvider);

    if (!context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.projectCreatedMessage(project.name))),
    );
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
}

/// Bottom sheet for bulk actions on selected projects
class BulkActionsBottomSheet extends ConsumerStatefulWidget {
  const BulkActionsBottomSheet({
    super.key,
    required this.selectedProjectIds,
    required this.onActionCompleted,
  });

  final Set<String> selectedProjectIds;
  final VoidCallback onActionCompleted;

  @override
  ConsumerState<BulkActionsBottomSheet> createState() => _BulkActionsBottomSheetState();
}

class _BulkActionsBottomSheetState extends ConsumerState<BulkActionsBottomSheet> {
  String? _selectedPriority;
  String? _selectedStatus;
  String? _selectedUserId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final usersAsync = ref.watch(authUsersProvider);

    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.bulkActionsTitle(widget.selectedProjectIds.length),
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          // Delete action
          ElevatedButton.icon(
            onPressed: () => _showDeleteConfirmation(context, ref, l10n),
            icon: const Icon(Icons.delete, color: Colors.white),
            label: Text(l10n.deleteSelectedProjectsLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
          SizedBox(height: 12.h),
          // Priority dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedPriority,
            decoration: InputDecoration(
              labelText: l10n.changePriorityLabel,
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: 'High', child: Text(l10n.priorityHigh)),
              DropdownMenuItem(value: 'Medium', child: Text(l10n.priorityMedium)),
              DropdownMenuItem(value: 'Low', child: Text(l10n.priorityLow)),
            ],
            onChanged: (value) => setState(() => _selectedPriority = value),
          ),
          SizedBox(height: 12.h),
          // Status dropdown
          DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            decoration: InputDecoration(
              labelText: l10n.changeStatusLabel,
              border: const OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
              DropdownMenuItem(value: 'In Review', child: Text('In Review')),
              DropdownMenuItem(value: 'Completed', child: Text('Completed')),
            ],
            onChanged: (value) => setState(() => _selectedStatus = value),
          ),
          SizedBox(height: 12.h),
          // User assignment
          usersAsync.when(
            data: (users) => DropdownButtonFormField<String>(
              initialValue: _selectedUserId,
              decoration: InputDecoration(
                labelText: l10n.assignToUserLabel,
                border: const OutlineInputBorder(),
              ),
              items: users.map((user) => DropdownMenuItem(
                value: user.username,
                child: Text(user.username),
              )).toList(),
              onChanged: (value) => setState(() => _selectedUserId = value),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (error, stack) => Text('Error loading users: $error'),
          ),
          SizedBox(height: 12.h),
          // Export action
          OutlinedButton.icon(
            onPressed: () => _exportSelectedProjects(context, ref, l10n),
            icon: const Icon(Icons.download),
            label: Text(l10n.exportSelectedToCsvLabel),
          ),
          SizedBox(height: 8.h),
          OutlinedButton.icon(
            onPressed: () => _exportSelectedProjectsToPdf(context, ref, l10n),
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(l10n.exportToPdfLabel),
          ),
          SizedBox(height: 16.h),
          // Apply actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancelLabel),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _applyActions(context, ref, l10n),
                  child: Text(l10n.applyActionsLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteUserDialogTitle),
        content: Text(l10n.confirmDeleteSelectedProjectsMessage(widget.selectedProjectIds.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(persistentProjectFilterProvider.notifier).bulkDeleteProjects(widget.selectedProjectIds, ref);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.bulkDeleteSuccessMessage(widget.selectedProjectIds.length))),
          );
        }
        widget.onActionCompleted();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete projects: $e')),
          );
        }
      }
    }
  }

  Future<void> _exportSelectedProjects(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    try {
      // Migrated to use projectByIdProvider for consistency with Riverpod patterns.
      final projects = <ProjectModel>[];
      
      for (final id in widget.selectedProjectIds) {
        final project = await ref.read(projectByIdProvider(id).future);
        if (project != null) {
          projects.add(project);
        }
      }

      final csvData = [
        ['ID', 'Name', 'Priority', 'Status', 'Start Date', 'Due Date', 'Progress', 'Assigned User'],
        ...projects.map((project) => [
          project.id,
          project.name,
          project.priority ?? '',
          project.status,
          project.startDate != null ? DateFormat('dd MMM yyyy').format(project.startDate!) : '',
          project.dueDate != null ? DateFormat('dd MMM yyyy').format(project.dueDate!) : '',
          '${(project.progress * 100).round()}%',
          project.sharedUsers.isNotEmpty ? project.sharedUsers.first : '',
        ]),
      ];

      final csvString = const ListToCsvConverter().convert(csvData);

      // Save to Downloads folder
      final directory = await getDownloadsDirectory();
      if (directory == null) return;

      final fileName = 'selected_projects_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvString);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Selected projects export',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.csvExportSuccessMessage)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportSelectedProjectsToPdf(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    try {
      // Migrated to use projectByIdProvider for consistency with Riverpod patterns.
      final projects = <ProjectModel>[];

      for (final id in widget.selectedProjectIds) {
        final project = await ref.read(projectByIdProvider(id).future);
        if (project != null) {
          projects.add(project);
        }
      }

      // Create a filter for selected projects
      final filter = ProjectFilter(); // Empty filter since we're exporting selected projects

      await PdfExporter.exportProjectsToPdf(
        context: context,
        projects: projects,
        filter: filter,
        searchQuery: 'Selected Projects (${projects.length})',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF export failed: $e')),
        );
      }
    }
  }

  Future<void> _applyActions(BuildContext context, WidgetRef ref, l10n) async {
    try {
      final notifier = ref.read(persistentProjectFilterProvider.notifier);
      int actionsApplied = 0;

      if (_selectedPriority != null) {
        await notifier.bulkUpdatePriority(widget.selectedProjectIds, _selectedPriority!, ref);
        actionsApplied++;
      }

      if (_selectedStatus != null) {
        await notifier.bulkUpdateStatus(widget.selectedProjectIds, _selectedStatus!, ref);
        actionsApplied++;
      }

      if (_selectedUserId != null) {
        await notifier.bulkAssignUser(widget.selectedProjectIds, _selectedUserId!, ref);
        actionsApplied++;
      }

      if (context.mounted && actionsApplied > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.bulkActionsAppliedMessage(actionsApplied, widget.selectedProjectIds.length))),
        );
      }

      widget.onActionCompleted();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply actions: $e')),
        );
      }
    }
  }
}
