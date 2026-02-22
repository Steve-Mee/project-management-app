import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_project_management_app/core/providers/dashboard_providers.dart';
import 'package:my_project_management_app/core/models/requirements.dart';
import 'package:my_project_management_app/generated/app_localizations.dart';

/// Requirements List Widget
///
/// Displays a list of requirements that works fully offline.
/// Loads requirements from local storage and shows them in a scrollable list.
/// Shows priority and status with appropriate colors.
/// Handles offline mode gracefully with cached data.
///
/// Usage:
/// ```dart
/// Scaffold(
///   appBar: AppBar(title: Text('Requirements')),
///   body: RequirementsList(),
/// )
/// ```
///
/// Features:
/// - Offline-first: Works without network connection
/// - Cached data: Shows previously loaded requirements
/// - Status indicators: Visual status and priority badges
/// - Empty state: Helpful message when no requirements exist
class RequirementsList extends ConsumerStatefulWidget {
  const RequirementsList({super.key});

  @override
  ConsumerState<RequirementsList> createState() => _RequirementsListState();
}

class _RequirementsListState extends ConsumerState<RequirementsList> {
  List<Requirement> _requirements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequirements();
  }

  Future<void> _loadRequirements() async {
    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(dashboardConfigProvider.notifier);
      final requirements = await notifier.loadRequirements();
      if (mounted) {
        setState(() {
          _requirements = requirements;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Error is handled by the notifier's error provider
      }
    }
  }

  Future<void> _addRequirement() async {
    final titleController = TextEditingController();
    final priority = await showDialog<RequirementPriority>(
      context: context,
      builder: (context) => _PriorityDialog(),
    );

    if (!mounted || priority == null) return;

    if (!mounted) return;
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Requirement'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(hintText: 'Enter requirement title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(titleController.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (!mounted || title == null || title.isEmpty) return;
    final req = Requirement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      status: RequirementStatus.pending,
      priority: priority,
    );

    final notifier = ref.read(dashboardConfigProvider.notifier);
    await notifier.saveRequirement(req);
    await _loadRequirements(); // Refresh the list
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOffline = ref.watch(dashboardConfigProvider.notifier).isOffline;

    return Scaffold(
      appBar: AppBar(
        title: Text('Requirements'),
        actions: [
          if (isOffline)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.offline_mode,
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          IconButton(
            onPressed: _addRequirement,
            icon: const Icon(Icons.add),
            tooltip: 'Add Requirement',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requirements.isEmpty
              ? _buildEmptyState()
              : _buildRequirementsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No requirements yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first requirement',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requirements.length,
      itemBuilder: (context, index) {
        final req = _requirements[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: _buildStatusIcon(req.status),
            title: Text(
              req.title,
              style: TextStyle(
                decoration: req.status == RequirementStatus.completed
                    ? TextDecoration.lineThrough
                    : null,
                color: req.status == RequirementStatus.completed
                    ? Colors.grey
                    : null,
              ),
            ),
            subtitle: Text('${req.status.displayName} • ${req.priority.displayName}'),
            trailing: _buildPriorityBadge(req.priority),
            onTap: () => _showRequirementDetails(req),
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(RequirementStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case RequirementStatus.pending:
        icon = Icons.schedule;
        color = Colors.grey;
        break;
      case RequirementStatus.inProgress:
        icon = Icons.play_arrow;
        color = Colors.blue;
        break;
      case RequirementStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case RequirementStatus.cancelled:
        icon = Icons.cancel;
        color = Colors.red;
        break;
    }

    return Icon(icon, color: color);
  }

  Widget _buildPriorityBadge(RequirementPriority priority) {
    Color color;
    String text;

    switch (priority) {
      case RequirementPriority.low:
        color = Colors.green.shade100;
        text = 'Low';
        break;
      case RequirementPriority.medium:
        color = Colors.yellow.shade100;
        text = 'Med';
        break;
      case RequirementPriority.high:
        color = Colors.orange.shade100;
        text = 'High';
        break;
      case RequirementPriority.urgent:
        color = Colors.red.shade100;
        text = 'Urgent';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  void _showRequirementDetails(Requirement req) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(req.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${req.status.displayName}'),
            Text('Priority: ${req.priority.displayName}'),
            Text('ID: ${req.id}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Priority Selection Dialog
class _PriorityDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Priority'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: RequirementPriority.values.map((priority) {
          return ListTile(
            title: Text(priority.displayName),
            onTap: () => Navigator.of(context).pop(priority),
          );
        }).toList(),
      ),
    );
  }
}