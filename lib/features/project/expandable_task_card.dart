import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_management_app/generated/app_localizations.dart';
import 'package:pma_core/providers/task/task_providers.dart';
import 'package:pma_core/providers/project_providers.dart';
import 'package:pma_core/providers/auth/auth_providers.dart';
import 'package:pma_core/services/sub_task_generation_service.dart';
import 'package:pma_core/models/task_model.dart';
import 'package:pma_core/models/sub_task_model.dart';
import 'package:project_management_app/features/project/task_help_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:project_management_app/core/providers/ai_chat_provider.dart';
import 'package:project_management_app/core/routes.dart';
import 'package:project_management_app/features/mirror/mirror_launch_feedback.dart';
import 'package:project_management_app/features/three_d_visualization/presentation/widgets/three_d_preview_widget.dart';
import 'package:project_management_app/features/three_d_visualization/presentation/widgets/three_d_visualize_assistant.dart';
import 'package:project_management_app/features/three_d_visualization/providers/three_d_visualization_providers.dart';
import 'package:pma_core/core/feature_flags/feature_flag_resolver.dart';
import 'package:pma_core/core/providers/feature_flag_provider.dart';
import 'package:pma_core/models/generated_asset.dart';
import 'package:project_management_app/core/config/feature_flags.dart';

/// Expandable task card with sub-tasks and assignment functionality
class ExpandableTaskCard extends ConsumerStatefulWidget {
  final Task task;
  final VoidCallback? onTap;

  const ExpandableTaskCard({
    super.key,
    required this.task,
    this.onTap,
  });

  @override
  ConsumerState<ExpandableTaskCard> createState() => _ExpandableTaskCardState();
}

class _ExpandableTaskCardState extends ConsumerState<ExpandableTaskCard> {
  bool _isGeneratingSubTasks = false;

  @override
  Widget build(BuildContext context) {
    final isExpanded = ref.watch(taskExpansionProvider.select((state) => state[widget.task.id] ?? false));
    final subTasksAsync = ref.watch(subTasksByTaskProvider(widget.task.id));
    final generationState = ref.watch(subTaskGenerationProvider.select((state) => state[widget.task.id]));
    final featureFlags = ref.watch(featureFlagProvider);
    final isThreeDEnabled = featureFlags.maybeWhen(
      data: (flags) => FeatureFlagResolver.isEnabled(
        flags,
        AppFeatureFlags.threeDVisualizationEnabled,
        defaultValue: true,
      ),
      orElse: () => true,
    );
    final generatedAssetsAsync = ref.watch(
      generatedAssetsProvider(
        GeneratedAssetsQuery(
          projectId: widget.task.projectId,
          taskId: widget.task.id,
          limit: 1,
        ),
      ),
    );
    final previewAsset = generatedAssetsAsync.valueOrNull == null
        ? null
        : _firstGlbAsset(generatedAssetsAsync.valueOrNull!);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          // Main task header
          ListTile(
            title: Text(widget.task.title),
            subtitle: Text(widget.task.description),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // AI Help button
                IconButton(
                  icon: const Icon(Icons.smart_toy),
                  onPressed: () => _showTaskHelpDialog(),
                  tooltip: 'AI Help',
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => _openMirrorEditor(),
                  tooltip: AppLocalizations.of(context)!.mirrorOpenEditorTooltip,
                ),
                // Assignment button
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () => _showAssignmentDialog(context),
                  tooltip: 'Assign task',
                ),
                // Expand button
                IconButton(
                  icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => _toggleExpansion(),
                  tooltip: isExpanded ? 'Collapse' : 'Expand',
                ),
              ],
            ),
            onTap: widget.onTap,
          ),

          if (previewAsset != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ThreeDPreviewWidget(
                glbUrl: previewAsset.fileUrl,
                height: 180,
              ),
            ),

          // Expanded content
          if (isExpanded) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sub-tasks section
                  Row(
                    children: [
                      Text(
                        'Sub-tasks',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (widget.task.subTaskIds.isEmpty)
                        ElevatedButton.icon(
                          onPressed: _isGeneratingSubTasks ? null : () => _generateSubTasks(),
                          icon: _isGeneratingSubTasks
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.auto_awesome),
                          label: const Text('Generate'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                    ],
                  ),
                  if (isThreeDEnabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FloatingActionButton.extended(
                          heroTag: 'visualize-task-${widget.task.id}',
                          onPressed: () {
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) {
                                return FractionallySizedBox(
                                  heightFactor: 0.9,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: ThreeDVisualizeAssistant(
                                      projectId: widget.task.projectId,
                                      taskId: widget.task.id,
                                      taskDescription: widget.task.description,
                                      attachments: widget.task.attachments,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.view_in_ar_outlined),
                          label: const Text('Visualiseer deze taak'),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),

                  // Generation loading/error state
                  generationState?.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('Failed to generate sub-tasks: $error'),
                      ),
                    ),
                    data: (_) => const SizedBox.shrink(),
                  ) ?? const SizedBox.shrink(),

                  // Sub-tasks list
                  subTasksAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Text('Error loading sub-tasks: $error'),
                    data: (subTasks) {
                      if (subTasks.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No sub-tasks yet. Click "Generate" to create sub-tasks.'),
                        );
                      }

                      return Column(
                        children: subTasks.map((subTask) => _buildSubTaskItem(subTask)).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  GeneratedAsset? _firstGlbAsset(List<GeneratedAsset> assets) {
    for (final asset in assets) {
      if (asset.format == GeneratedAssetFormat.glb && asset.fileUrl.isNotEmpty) {
        return asset;
      }
    }
    return null;
  }

  Widget _buildSubTaskItem(SubTask subTask) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: subTask.isCompleted,
          onChanged: (value) => _toggleSubTaskCompletion(subTask.id, value ?? false),
        ),
        title: Text(
          subTask.title,
          style: TextStyle(
            decoration: subTask.isCompleted ? TextDecoration.lineThrough : null,
            color: subTask.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subTask.description),
            if (subTask.assignedTo != null)
              Text(
                'Assigned to: ${subTask.assignedTo}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.person_add),
          onPressed: () => _showSubTaskAssignmentDialog(context, subTask),
          tooltip: 'Assign sub-task',
        ),
        onTap: () => _toggleSubTaskCompletion(subTask.id, !subTask.isCompleted),
      ),
    );
  }

  void _toggleExpansion() {
    ref.read(taskExpansionProvider.notifier).toggleExpansion(widget.task.id);
  }

  /// Get the project category for this task
  String? _getProjectCategory() {
    final projectsAsync = ref.read(projectsProvider);
    return projectsAsync.maybeWhen(
      data: (projects) {
        try {
          final project = projects.firstWhere((p) => p.id == widget.task.projectId);
          return project.category;
        } catch (e) {
          return null;
        }
      },
      orElse: () => null,
    );
  }

  /// Show the AI task help dialog with category-specific helpers
  void _showTaskHelpDialog() {
    final projectCategory = _getProjectCategory();
    final aiAssistant = _getAiAssistant();

    showDialog(
      context: context,
      builder: (context) => TaskHelpDialog(
        task: widget.task,
        projectCategory: projectCategory,
        aiAssistant: aiAssistant,
      ),
    );
  }

  /// Get the AI assistant for this project
  String? _getAiAssistant() {
    final projectsAsync = ref.read(projectsProvider);
    return projectsAsync.maybeWhen(
      data: (projects) {
        try {
          final project = projects.firstWhere((p) => p.id == widget.task.projectId);
          return project.aiAssistant;
        } catch (e) {
          return null;
        }
      },
      orElse: () => null,
    );
  }

  Future<void> _generateSubTasks() async {
    setState(() {
      _isGeneratingSubTasks = true;
    });

    try {
      ref.read(subTaskGenerationProvider.notifier).startGeneration(widget.task.id);

      final service = SubTaskGenerationService();
      final subTasks = await service.generateSubTasks(widget.task);

      // Save sub-tasks to repository
      final repo = await ref.read(subTaskRepositoryProvider.future);
      await repo.addSubTasks(subTasks);

      // Update task with sub-task IDs
      final subTaskIds = subTasks.map((st) => st.id).toList();
      await ref.read(tasksProvider.notifier).addSubTasksToTask(widget.task.id, subTaskIds);

      ref.read(subTaskGenerationProvider.notifier).completeGeneration(widget.task.id, subTasks);

      // Refresh sub-tasks
      ref.invalidate(subTasksByTaskProvider(widget.task.id));
    } catch (e) {
      ref.read(subTaskGenerationProvider.notifier).failGeneration(widget.task.id, e);
    } finally {
      setState(() {
        _isGeneratingSubTasks = false;
      });
    }
  }

  Future<void> _openMirrorEditor() async {
    final result = await ref
        .read(aiChatBridgeProvider.notifier)
        .openMirrorFromTask(
          projectId: widget.task.projectId,
          taskId: widget.task.id,
          preferredMode: 'private',
        );

    if (!mounted) {
      return;
    }

    if (!result.isSuccess || result.payload == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mirrorLaunchFailureMessage(
              AppLocalizations.of(context)!,
              result,
            ),
          ),
        ),
      );
      return;
    }

    final payload = result.payload!;
    context.push(
      AppRoutes.mirrorEditorPath(payload.projectId, payload.taskId),
    );
  }

  Future<void> _toggleSubTaskCompletion(String subTaskId, bool isCompleted) async {
    final repo = await ref.read(subTaskRepositoryProvider.future);
    if (isCompleted) {
      await repo.toggleSubTaskCompletion(subTaskId);
    } else {
      // For unchecking, we need to set it to not completed
      final subTasks = repo.getAllSubTasks();
      final subTask = subTasks.firstWhere((st) => st.id == subTaskId);
      await repo.updateSubTask(subTask.copyWith(isCompleted: false));
    }

    // Refresh sub-tasks
    ref.invalidate(subTasksByTaskProvider(widget.task.id));
  }

  void _showAssignmentDialog(BuildContext context) {
    final usersAsync = ref.watch(authUsersProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Task'),
        content: usersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error loading users: $error'),
          data: (users) => DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Select User'),
            items: users.map((user) {
              return DropdownMenuItem(
                value: user.username,
                child: Text(user.username),
              );
            }).toList(),
            onChanged: (userId) async {
              if (userId != null) {
                // Update task assignee
                final updatedTask = widget.task.copyWith(assignee: userId);
                await ref.read(tasksProvider.notifier).updateTask(updatedTask);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
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

  void _showSubTaskAssignmentDialog(BuildContext context, SubTask subTask) {
    final usersAsync = ref.watch(authUsersProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Sub-task'),
        content: usersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error loading users: $error'),
          data: (users) => DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Select User'),
            initialValue: subTask.assignedTo,
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Unassigned'),
              ),
              ...users.map((user) {
                return DropdownMenuItem(
                  value: user.username,
                  child: Text(user.username),
                );
              }),
            ],
            onChanged: (userId) async {
              final repo = await ref.read(subTaskRepositoryProvider.future);
              await repo.assignSubTask(subTask.id, userId);

              // Refresh sub-tasks
              ref.invalidate(subTasksByTaskProvider(widget.task.id));
              if (context.mounted) {
                Navigator.of(context).pop();
              }
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
}
