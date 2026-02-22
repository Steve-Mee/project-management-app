import 'package:flutter/material.dart';
import 'package:my_project_management_app/models/project_model.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

/// Base class for project view widgets
abstract class ProjectView extends StatelessWidget {
  const ProjectView({
    super.key,
    required this.projects,
    required this.metaByProjectId,
    required this.canEditProjects,
    required this.isSelectionMode,
    required this.selectedIds,
    required this.onLongPress,
    required this.onSelectionChanged,
    this.onStatusChanged,
  });

  final List<ProjectModel> projects;
  final Map<String, dynamic> metaByProjectId;
  final bool canEditProjects;
  final bool isSelectionMode;
  final Set<String> selectedIds;
  final VoidCallback onLongPress;
  final ValueChanged<bool> onSelectionChanged;
  final void Function(String projectId, String newStatus)? onStatusChanged;
}

/// List view for projects
class ProjectListView extends ProjectView {
  const ProjectListView({
    super.key,
    required super.projects,
    required super.metaByProjectId,
    required super.canEditProjects,
    required super.isSelectionMode,
    required super.selectedIds,
    required super.onLongPress,
    required super.onSelectionChanged,
    super.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return _buildProjectListItem(context, project);
      },
    );
  }

  Widget _buildProjectListItem(BuildContext context, ProjectModel project) {
    final l10n = AppLocalizations.of(context)!;
    Color statusColor;
    IconData statusIcon;

    switch (project.status) {
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
      onLongPress: isSelectionMode ? null : onLongPress,
      onTap: isSelectionMode ? () => onSelectionChanged(!selectedIds.contains(project.id)) : () {
        context.go('/projects/${project.id}');
      },
      child: Semantics(
        label: l10n.projectSemanticsLabel(project.name),
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: selectedIds.contains(project.id) ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (isSelectionMode) ...[
                  Checkbox(
                    value: selectedIds.contains(project.id),
                    onChanged: (value) => onSelectionChanged(value ?? false),
                  ),
                  const SizedBox(width: 12),
                ],
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.folder,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Semantics(
                            label: l10n.statusSemanticsLabel(project.status),
                            child: Icon(
                              statusIcon,
                              size: 16,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            project.status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (project.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: project.tags.map((tag) => Chip(
                            label: Text('#$tag', style: const TextStyle(fontSize: 10)),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                            backgroundColor: _getTagColor(tag),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getTagColor(String tag) {
    // Simple hash-based color assignment for consistent colors per tag
    final hash = tag.hashCode;
    final colors = [
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.orange.shade100,
      Colors.purple.shade100,
      Colors.red.shade100,
      Colors.teal.shade100,
      Colors.pink.shade100,
      Colors.indigo.shade100,
      Colors.amber.shade100,
      Colors.cyan.shade100,
    ];
    return colors[hash.abs() % colors.length];
  }
}

/// Kanban view for projects
class ProjectKanbanView extends ProjectView {
  const ProjectKanbanView({
    super.key,
    required super.projects,
    required super.metaByProjectId,
    required super.canEditProjects,
    required super.isSelectionMode,
    required super.selectedIds,
    required super.onLongPress,
    required super.onSelectionChanged,
    super.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Group projects by status
    final groupedProjects = <String, List<ProjectModel>>{};
    for (final project in projects) {
      groupedProjects.putIfAbsent(project.status, () => []).add(project);
    }

    // Ensure all status columns exist
    const statuses = ['In Progress', 'In Review', 'Completed'];
    for (final status in statuses) {
      groupedProjects.putIfAbsent(status, () => []);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: statuses.map((status) {
          return _buildKanbanColumn(context, status, groupedProjects[status]!);
        }).toList(),
      ),
    );
  }

  Widget _buildKanbanColumn(BuildContext context, String status, List<ProjectModel> projects) {
    Color statusColor;
    switch (status) {
      case 'In Progress':
        statusColor = Colors.blue;
        break;
      case 'In Review':
        statusColor = Colors.orange;
        break;
      case 'Completed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return DragTarget<ProjectModel>(
      onAcceptWithDetails: (details) async {
        final draggedProject = details.data;
        if (draggedProject.status != status && onStatusChanged != null) {
          onStatusChanged!(draggedProject.id, status);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 300,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            border: candidateData.isNotEmpty
                ? Border.all(color: statusColor, width: 2)
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getStatusIcon(status),
                      color: statusColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${projects.length}',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Projects in this column
              Expanded(
                child: ListView.builder(
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    return _buildKanbanCard(context, projects[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKanbanCard(BuildContext context, ProjectModel project) {
    return Draggable<ProjectModel>(
      data: project,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            project.name,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildCardContent(context, project),
      ),
      child: _buildCardContent(context, project),
    );
  }

  Widget _buildCardContent(BuildContext context, ProjectModel project) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isSelectionMode) ...[
                  Checkbox(
                    value: selectedIds.contains(project.id),
                    onChanged: (value) => onSelectionChanged(value ?? false),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    project.name,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (project.description?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                project.description!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (project.priority != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(project.priority!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      project.priority!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (project.dueDate != null) ...[
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd').format(project.dueDate!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            if (project.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: project.tags.map((tag) => Chip(
                  label: Text('#$tag', style: const TextStyle(fontSize: 10)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                  backgroundColor: _getTagColor(tag),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'In Progress':
        return Icons.autorenew;
      case 'In Review':
        return Icons.visibility;
      case 'Completed':
        return Icons.check_circle;
      default:
        return Icons.schedule;
    }
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
        return Colors.grey;
    }
  }

  Color _getTagColor(String tag) {
    // Simple hash-based color assignment for consistent colors per tag
    final hash = tag.hashCode;
    final colors = [
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.orange.shade100,
      Colors.purple.shade100,
      Colors.red.shade100,
      Colors.teal.shade100,
      Colors.pink.shade100,
      Colors.indigo.shade100,
      Colors.amber.shade100,
      Colors.cyan.shade100,
    ];
    return colors[hash.abs() % colors.length];
  }
}

/// Table view for projects
class ProjectTableView extends ProjectView {
  const ProjectTableView({
    super.key,
    required super.projects,
    required super.metaByProjectId,
    required super.canEditProjects,
    required super.isSelectionMode,
    required super.selectedIds,
    required super.onLongPress,
    required super.onSelectionChanged,
    super.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: [
            if (isSelectionMode) const DataColumn(label: Text('')),
            DataColumn(label: Text(l10n.nameLabel)),
            DataColumn(label: Text(l10n.statusLabel)),
            DataColumn(label: Text(l10n.priorityLabel)),
            DataColumn(label: Text(l10n.startDateLabel)),
            DataColumn(label: Text(l10n.dueDateLabel)),
            DataColumn(label: Text(l10n.progressLabel)),
            DataColumn(label: Text(l10n.tagsLabel)),
          ],
          rows: projects.map((project) => DataRow(
            selected: selectedIds.contains(project.id),
            onSelectChanged: isSelectionMode ? (selected) => onSelectionChanged(selected ?? false) : null,
            cells: [
              if (isSelectionMode)
                DataCell(Checkbox(
                  value: selectedIds.contains(project.id),
                  onChanged: (value) => onSelectionChanged(value ?? false),
                )),
              DataCell(
                Text(project.name),
                onTap: () => context.go('/projects/${project.id}'),
              ),
              DataCell(Text(project.status)),
              DataCell(
                project.priority != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(project.priority!),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          project.priority!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : const Text(''),
              ),
              DataCell(
                Text(project.startDate != null
                    ? DateFormat('MMM dd, yyyy').format(project.startDate!)
                    : ''),
              ),
              DataCell(
                Text(project.dueDate != null
                    ? DateFormat('MMM dd, yyyy').format(project.dueDate!)
                    : ''),
              ),
              DataCell(
                LinearProgressIndicator(
                  value: project.progress,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
              DataCell(
                Wrap(
                  spacing: 4,
                  children: project.tags.map((tag) => Chip(
                    label: Text('#$tag', style: const TextStyle(fontSize: 10)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                    backgroundColor: _getTagColor(tag),
                  )).toList(),
                ),
              ),
            ],
          )).toList(),
        ),
      ),
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
        return Colors.grey;
    }
  }

  Color _getTagColor(String tag) {
    // Simple hash-based color assignment for consistent colors per tag
    final hash = tag.hashCode;
    final colors = [
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.orange.shade100,
      Colors.purple.shade100,
      Colors.red.shade100,
      Colors.teal.shade100,
      Colors.pink.shade100,
      Colors.indigo.shade100,
      Colors.amber.shade100,
      Colors.cyan.shade100,
    ];
    return colors[hash.abs() % colors.length];
  }
}