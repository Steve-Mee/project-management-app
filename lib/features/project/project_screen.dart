import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';
import 'package:my_project_management_app/core/auth/permissions.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// ignore_for_file: use_build_context_synchronously
import '../../core/providers.dart';
import '../../models/project_meta.dart';
import '../../models/project_model.dart';
import '../../models/project_sort.dart';

/// Project management screen - displays list of all projects
class ProjectScreen extends ConsumerStatefulWidget {
  const ProjectScreen({super.key});

  @override
  ConsumerState<ProjectScreen> createState() => _ProjectScreenState();
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

  String _selectedStatus = 'All';
  ProjectSort _sortBy = ProjectSort.name;
  bool _sortAscending = true;
  String? _loadError;

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
  }

  @override
  void dispose() {
    _searchSubscription.close();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final metaByProjectId = ref.watch(projectMetaProvider);
    final canEditProjects =
        ref.watch(hasPermissionProvider(AppPermissions.editProjects));

    if (_projects.isEmpty && _isLoading) {
      return _buildLoadingContent(context, canEditProjects);
    }
    if (_loadError != null && _projects.isEmpty) {
      return _buildErrorContent(context, _loadError!, canEditProjects);
    }
    return _buildProjectList(
      context,
      _projects,
      metaByProjectId,
      canEditProjects,
    );
  }

  Widget _buildProjectList(
    BuildContext context,
    List<ProjectModel> projects,
    Map<String, ProjectMeta> metaByProjectId,
    bool canEditProjects,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = _filterProjects(projects);
    final sorted = _sortProjects(filtered, metaByProjectId);
    final visible = sorted; // pagination applied at repo level
    final hasMore = _hasMore;

    const baseCount = 3; // title + search + filters/sort
    final itemCount = baseCount + (sorted.isEmpty ? 1 : visible.length + 1);

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
          );
        }

        if (index == 1) {
          // search field
          return Padding(
            padding: EdgeInsets.only(top: 12.h, bottom: 12.h),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search projects',
                prefixIcon: const Icon(Icons.search),
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

        if (sorted.isEmpty) {
          return Padding(
            padding: EdgeInsets.only(top: 24.h),
            child: Center(
              child: Text(
                ref.watch(searchQueryProvider).isEmpty
                    ? l10n.noProjectsYet
                    : l10n.noProjectsFound,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );
        }

        final projectIndex = index - baseCount;
        if (projectIndex < visible.length) {
          final project = visible[projectIndex];
          return _buildProjectListItem(
            context,
            id: project.id,
            title: project.name,
            status: project.status,
          );
        }

        if (!hasMore) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
          child: Center(
            child: Column(
              children: [
                const CircularProgressIndicator(),
                SizedBox(height: 8.h),
                Text(
                  l10n.loadingMoreProjects,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
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

  Widget _buildProjectListItem(
    BuildContext context, {
    required String id,
    required String title,
    required String status,
  }) {
    final l10n = AppLocalizations.of(context)!;
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'In Progress':
        statusColor = Colors.blue;
        statusIcon = Icons.autorenew;
        break;
      case 'In Review':
        statusColor = Colors.orange;
        statusIcon = Icons.visibility;
        break;
      case 'Completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.schedule;
    }

    return GestureDetector(
      onTap: () {
        context.go('/projects/$id');
      },
      child: Semantics(
        label: l10n.projectSemanticsLabel(title),
        child: Card(
          margin: EdgeInsets.only(bottom: 12.h),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.folder,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Semantics(
                            label: l10n.statusSemanticsLabel(status),
                            child: Icon(
                              statusIcon,
                              size: 16.sp,
                              color: statusColor,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
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
    final authState = ref.read(authProvider);
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
