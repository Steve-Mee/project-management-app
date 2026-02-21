import 'package:flutter/material.dart';
import 'package:my_project_management_app/core/providers/project_providers.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';
import 'package:my_project_management_app/models/project_model.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';

/// Dialog for filtering projects by priority, start date, and end date
class ProjectFilterDialog extends StatefulWidget {
  final ProjectFilter initialFilter;
  final VoidCallback? onSaveAsDefault;
  final List<ProjectModel>? filteredProjects;
  final List<ProjectFilter>? savedViews;
  final Function(ProjectFilter, String)? onSaveView;
  final Function(String)? onDeleteView;
  final Function(ProjectFilter)? onLoadView;

  const ProjectFilterDialog({
    super.key,
    required this.initialFilter,
    this.onSaveAsDefault,
    this.filteredProjects,
    this.savedViews,
    this.onSaveView,
    this.onDeleteView,
    this.onLoadView,
  });

  @override
  State<ProjectFilterDialog> createState() => _ProjectFilterDialogState();
}

class _ProjectFilterDialogState extends State<ProjectFilterDialog> with TickerProviderStateMixin {
  late ProjectFilter _filter;
  String? _activePreset;
  late TabController _tabController;
  final TextEditingController _viewNameController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viewNameController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Widget _buildPresetButton(String presetKey, String label) {
    final isActive = _activePreset == presetKey;
    return FilledButton(
      onPressed: () => _applyPreset(presetKey),
      style: FilledButton.styleFrom(
        backgroundColor: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: isActive
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      child: Text(label),
    );
  }

  Color _getPriorityColor(String priority) {
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

  DropdownMenuItem<String?> _buildPriorityDropdownItem(String? value, String text) {
    return DropdownMenuItem<String?>(
      value: value,
      child: Row(
        children: [
          if (value != null) ...[
            Icon(
              Icons.circle,
              size: 12,
              color: _getPriorityColor(value),
            ),
            const SizedBox(width: 8),
          ],
          Text(text),
        ],
      ),
    );
  }

  void _applyPreset(String presetKey) {
    setState(() {
      _activePreset = presetKey;
      switch (presetKey) {
        case 'all':
          _filter = ProjectFilter();
          break;
        case 'high':
          _filter = ProjectFilter(priority: 'High');
          break;
        case 'week':
          // Due this week - need to calculate dates
          final now = DateTime.now();
          final weekFromNow = now.add(const Duration(days: 7));
          _filter = ProjectFilter(
            dueDateStart: now,
            dueDateEnd: weekFromNow,
          );
          break;
        case 'overdue':
          _filter = ProjectFilter(
            dueDateEnd: DateTime.now(),
          );
          break;
        case 'my':
          // My projects - assuming current user, but for now just clear other filters
          _filter = ProjectFilter();
          break;
      }
    });
  }

  String _getSortLabel(String sortBy, AppLocalizations l10n) {
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

  Future<void> _exportToCsv() async {
    try {
      final projects = widget.filteredProjects ?? [];
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

      final fileName = 'projects_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvString);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Projects export',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.csvExportSuccessMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Widget _buildSavedViewsTab(BuildContext context, AppLocalizations l10n) {
    final savedViews = widget.savedViews ?? [];

    return Column(
      children: [
        // Save current as new view
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _viewNameController,
                  decoration: InputDecoration(
                    labelText: l10n.viewNameLabel,
                    hintText: l10n.viewNameHint,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  final name = _viewNameController.text.trim();
                  if (name.isNotEmpty && widget.onSaveView != null) {
                    widget.onSaveView!(_filter, name);
                    _viewNameController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.viewSavedMessage)),
                    );
                  }
                },
                icon: const Icon(Icons.save),
                label: Text(l10n.saveCurrentAsViewLabel),
              ),
            ],
          ),
        ),
        const Divider(),
        // List of saved views
        Expanded(
          child: savedViews.isEmpty
              ? Center(child: Text(l10n.noSavedViewsMessage))
              : ListView.builder(
                  itemCount: savedViews.length,
                  itemBuilder: (context, index) {
                    final view = savedViews[index];
                    return ListTile(
                      title: Text(view.viewName ?? ''),
                      subtitle: _buildViewPreview(view, l10n),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          if (widget.onDeleteView != null && view.viewName != null) {
                            widget.onDeleteView!(view.viewName!);
                          }
                        },
                      ),
                      onTap: () {
                        if (widget.onLoadView != null) {
                          widget.onLoadView!(view);
                          Navigator.of(context).pop(view);
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildViewPreview(ProjectFilter filter, AppLocalizations l10n) {
    final chips = <Widget>[];

    if (filter.status != null) {
      chips.add(Chip(label: Text(filter.status!), backgroundColor: Colors.blue.shade100));
    }
    if (filter.priority != null) {
      chips.add(Chip(label: Text(filter.priority!), backgroundColor: _getPriorityColor(filter.priority!)));
    }
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      chips.add(Chip(label: Text('"${filter.searchQuery!}"'), backgroundColor: Colors.grey.shade200));
    }
    if (filter.tags != null && filter.tags!.isNotEmpty) {
      for (final tag in filter.tags!) {
        chips.add(Chip(label: Text('#$tag'), backgroundColor: Colors.purple.shade100));
      }
    }
    if (filter.startDate != null) {
      chips.add(Chip(label: Text('From ${DateFormat('MMM dd').format(filter.startDate!)}'), backgroundColor: Colors.green.shade100));
    }
    if (filter.endDate != null) {
      chips.add(Chip(label: Text('To ${DateFormat('MMM dd').format(filter.endDate!)}'), backgroundColor: Colors.red.shade100));
    }

    return Wrap(
      spacing: 4,
      children: chips.take(3).toList(), // Limit to 3 chips for preview
    );
  }

  Widget _buildFiltersTab(BuildContext context, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Preset Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPresetButton('all', l10n.allProjectsPresetLabel),
                const SizedBox(width: 8),
                _buildPresetButton('high', l10n.highPriorityPresetLabel),
                const SizedBox(width: 8),
                _buildPresetButton('week', l10n.dueThisWeekPresetLabel),
                const SizedBox(width: 8),
                _buildPresetButton('overdue', l10n.overduePresetLabel),
                const SizedBox(width: 8),
                _buildPresetButton('my', l10n.myProjectsPresetLabel),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Sort by Dropdown
          DropdownButtonFormField<String>(
            initialValue: _filter.sortBy ?? 'name',
            decoration: InputDecoration(
              labelText: l10n.sortByLabel,
            ),
            items: ProjectFilter.sortOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(_getSortLabel(option, l10n)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _filter = _filter.copyWith(sortBy: value);
                });
              }
            },
          ),
          const SizedBox(height: 8),
          // Sort Direction
          Row(
            children: [
              Text(l10n.sortDirectionLabel, style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text(l10n.sortAscendingLabel),
                    icon: const Icon(Icons.arrow_upward, size: 16),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text(l10n.sortDescendingLabel),
                    icon: const Icon(Icons.arrow_downward, size: 16),
                  ),
                ],
                selected: {_filter.sortAscending},
                onSelectionChanged: (Set<bool> selected) {
                  setState(() {
                    _filter = _filter.copyWith(sortAscending: selected.first);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search Query
          TextField(
            controller: TextEditingController(text: _filter.searchQuery ?? ''),
            decoration: InputDecoration(
              labelText: l10n.searchProjectsLabel,
              hintText: l10n.searchProjectsHint,
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _filter = _filter.copyWith(searchQuery: null);
                  });
                },
              ),
            ),
            onChanged: (value) {
              setState(() {
                _filter = _filter.copyWith(searchQuery: value.isEmpty ? null : value);
              });
            },
          ),
          const SizedBox(height: 16),
          // Tags Multi-Select
          _buildTagsSection(context, l10n),
          const SizedBox(height: 16),
          // Priority Dropdown
          DropdownButtonFormField<String?>(
            initialValue: _filter.priority,
            decoration: InputDecoration(
              labelText: l10n.filterPriorityLabel,
            ),
            items: [
              _buildPriorityDropdownItem(null, 'All'),
              _buildPriorityDropdownItem('Low', l10n.priorityLow),
              _buildPriorityDropdownItem('Medium', l10n.priorityMedium),
              _buildPriorityDropdownItem('High', l10n.priorityHigh),
            ],
            onChanged: (value) {
              setState(() {
                _filter = _filter.copyWith(priority: value);
              });
            },
          ),
          const SizedBox(height: 16),
          // Start Date
          TextFormField(
            decoration: InputDecoration(
              labelText: l10n.filterStartDateLabel,
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _filter.startDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _filter = _filter.copyWith(startDate: date);
                    });
                  }
                },
              ),
            ),
            readOnly: true,
            controller: TextEditingController(
              text: _filter.startDate != null
                  ? _filter.startDate!.toLocal().toString().split(' ')[0]
                  : '',
            ),
          ),
          const SizedBox(height: 16),
          // End Date
          TextFormField(
            decoration: InputDecoration(
              labelText: l10n.filterEndDateLabel,
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _filter.endDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() {
                      _filter = _filter.copyWith(endDate: date);
                    });
                  }
                },
              ),
            ),
            readOnly: true,
            controller: TextEditingController(
              text: _filter.endDate != null
                  ? _filter.endDate!.toLocal().toString().split(' ')[0]
                  : '',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.projectFiltersTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: l10n.savedViewsTabLabel),
                Tab(text: l10n.filtersTabLabel),
              ],
            ),
            SizedBox(
              height: 400,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSavedViewsTab(context, l10n),
                  _buildFiltersTab(context, l10n),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(const ProjectFilter()),
          child: Text(l10n.clearAllLabel),
        ),
        if (widget.onSaveAsDefault != null)
          ElevatedButton.icon(
            onPressed: () {
              widget.onSaveAsDefault!();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.saveAsDefaultSuccessMessage)),
              );
              Navigator.of(context).pop(_filter);
            },
            icon: const Icon(Icons.star),
            label: Text(l10n.saveAsDefaultViewLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ElevatedButton.icon(
          onPressed: _exportToCsv,
          icon: const Icon(Icons.download),
          label: Text(l10n.exportToCsvLabel),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_filter),
          child: Text(l10n.applyFiltersLabel),
        ),
      ],
    );
  }

  Widget _buildTagsSection(BuildContext context, AppLocalizations l10n) {
    final allTags = _getAllAvailableTags();
    final selectedTags = _filter.tags ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.filterTagsLabel, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        // Selected tags chips
        if (selectedTags.isNotEmpty) ...[
          Wrap(
            spacing: 4,
            children: selectedTags.map((tag) => Chip(
              label: Text('#$tag'),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                setState(() {
                  final newTags = List<String>.from(selectedTags)..remove(tag);
                  _filter = _filter.copyWith(tags: newTags.isEmpty ? null : newTags);
                });
              },
            )).toList(),
          ),
          const SizedBox(height: 8),
        ],
        // Add new tag input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  labelText: l10n.addTagLabel,
                  hintText: l10n.addTagHint,
                ),
                onSubmitted: (value) => _addTag(value.trim()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addTag(_tagController.text.trim()),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Available tags
        if (allTags.isNotEmpty) ...[
          Text(l10n.availableTagsLabel, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            children: allTags.where((tag) => !selectedTags.contains(tag)).map((tag) => ActionChip(
              label: Text('#$tag'),
              onPressed: () => _addTag(tag),
            )).toList(),
          ),
        ],
      ],
    );
  }

  List<String> _getAllAvailableTags() {
    final allTags = <String>{};
    for (final project in widget.filteredProjects ?? []) {
      allTags.addAll(project.tags);
    }
    return allTags.toList()..sort();
  }

  void _addTag(String tag) {
    if (tag.isEmpty) return;
    final selectedTags = _filter.tags ?? [];
    if (!selectedTags.contains(tag)) {
      setState(() {
        _filter = _filter.copyWith(tags: [...selectedTags, tag]);
      });
    }
    _tagController.clear();
  }
}

/// Function to show the project filter dialog
Future<ProjectFilter?> showProjectFilterDialog(
  BuildContext context,
  ProjectFilter initialFilter,
  VoidCallback? onSaveAsDefault, [
  List<ProjectModel>? filteredProjects,
  List<ProjectFilter>? savedViews,
  Function(ProjectFilter, String)? onSaveView,
  Function(String)? onDeleteView,
  Function(ProjectFilter)? onLoadView,
]) {
  return showDialog<ProjectFilter>(
    context: context,
    builder: (context) => ProjectFilterDialog(
      initialFilter: initialFilter,
      onSaveAsDefault: onSaveAsDefault,
      filteredProjects: filteredProjects,
      savedViews: savedViews,
      onSaveView: onSaveView,
      onDeleteView: onDeleteView,
      onLoadView: onLoadView,
    ),
  );
}