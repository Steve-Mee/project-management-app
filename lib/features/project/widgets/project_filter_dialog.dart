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

  const ProjectFilterDialog({
    super.key,
    required this.initialFilter,
    this.onSaveAsDefault,
    this.filteredProjects,
  });

  @override
  State<ProjectFilterDialog> createState() => _ProjectFilterDialogState();
}

class _ProjectFilterDialogState extends State<ProjectFilterDialog> {
  late ProjectFilter _filter;
  String? _activePreset;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.projectFiltersTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  _filter = ProjectFilter(
                    status: _filter.status,
                    ownerId: _filter.ownerId,
                    searchQuery: _filter.searchQuery,
                    priority: value,
                    startDate: _filter.startDate,
                    endDate: _filter.endDate,
                  );
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
                        _filter = ProjectFilter(
                          status: _filter.status,
                          ownerId: _filter.ownerId,
                          searchQuery: _filter.searchQuery,
                          priority: _filter.priority,
                          startDate: date,
                          endDate: _filter.endDate,
                        );
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
                        _filter = ProjectFilter(
                          status: _filter.status,
                          ownerId: _filter.ownerId,
                          searchQuery: _filter.searchQuery,
                          priority: _filter.priority,
                          startDate: _filter.startDate,
                          endDate: date,
                        );
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
}

/// Function to show the project filter dialog
Future<ProjectFilter?> showProjectFilterDialog(
  BuildContext context,
  ProjectFilter initialFilter,
  VoidCallback? onSaveAsDefault, [
  List<ProjectModel>? filteredProjects,
]) {
  return showDialog<ProjectFilter>(
    context: context,
    builder: (context) => ProjectFilterDialog(
      initialFilter: initialFilter,
      onSaveAsDefault: onSaveAsDefault,
      filteredProjects: filteredProjects,
    ),
  );
}