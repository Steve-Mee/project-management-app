// EXAMPLE WIDGETS - Ready-to-use widgets for project management UI

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/providers/project_providers.dart';
import 'package:pma_core/providers/task/task_providers.dart';
import 'package:pma_core/utils/accessibility_helper.dart';
import 'package:pma_core/widgets/modern_gantt_chart.dart';
import 'package:pma_core/widgets/offline_indicator.dart';
import 'package:pma_core/models/project_model.dart';
import 'package:pma_core/models/task_model.dart';

// ignore_for_file: prefer_const_constructors

// ============================================================================
// 1. PROJECT LIST WIDGET
// ============================================================================

class ProjectListWidget extends ConsumerStatefulWidget {
  const ProjectListWidget({super.key});

  @override
  ConsumerState<ProjectListWidget> createState() => _ProjectListWidgetState();
}

class _ProjectListWidgetState extends ConsumerState<ProjectListWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _isRequestInFlight = false;
  Timer? _scrollDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final pixelsFromBottom = position.maxScrollExtent - position.pixels;

    // Trigger loading before the user reaches the end for a smoother UX.
    if (pixelsFromBottom < 200) {
      if (_scrollDebounce?.isActive ?? false) {
        return;
      }
      _scrollDebounce = Timer(const Duration(milliseconds: 180), _loadMoreProjects);
    }
  }

  Future<void> _loadMoreProjects() async {
    if (_isRequestInFlight) {
      return;
    }

    final notifier = ref.read(projectsProvider.notifier);
    if (notifier.isLoadingMore || !notifier.hasMore) {
      return;
    }

    notifier.clearLoadMoreError();

    _isRequestInFlight = true;
    final loadFuture = notifier.loadMoreProjects();

    if (mounted) {
      setState(() {});
    }

    await loadFuture;

    if (mounted) {
      setState(() {});
    }
    _isRequestInFlight = false;
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);
    final projectsNotifier = ref.read(projectsProvider.notifier);
    final isLoadingMore = projectsNotifier.isLoadingMore;
    final hasMore = projectsNotifier.hasMore;
    final loadMoreError = projectsNotifier.loadMoreError;

    return projectsAsync.when(
      data: (projects) {
        if (projects.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.read(projectsProvider.notifier).refresh(),
            child: wrapSemanticList(
              label: AccessibilityLabels.projectsList,
              itemCount: 0,
              hint: 'No projects available',
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          labeledIcon(
                            icon: Icons.inbox,
                            label: 'Empty projects inbox icon',
                            color: Colors.grey,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          const Text('No projects yet').withSemantics(
                            'No projects yet',
                            hint: 'Use create first project button to add one',
                          ),
                          const SizedBox(height: 16),
                          labeledElevatedButton(
                            label: 'Create First Project',
                            hint: 'Opens the form to create your first project',
                            onPressed: () {
                              // Navigate to create project screen
                            },
                            leadingIcon: Icons.add,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(projectsProvider.notifier).refresh(),
          child: wrapSemanticList(
            label: AccessibilityLabels.projectsList,
            itemCount: projects.length,
            hint: 'Swipe up or down to navigate projects',
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              itemCount: projects.length + 1,
              itemBuilder: (context, index) {
                if (index == projects.length) {
                  if (isLoadingMore) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator().withSemantics(
                          'Loading more projects',
                          hint: 'Please wait while additional projects are fetched',
                        ),
                      ),
                    );
                  }

                  if (loadMoreError != null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          Text(
                            'Could not load more projects',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ).withSemantics(
                            'Could not load more projects',
                            hint: 'Use retry to load more projects',
                          ),
                          const SizedBox(height: 8),
                          labeledTextButton(
                            label: AccessibilityLabels.retryAction,
                            hint: 'Retries loading more projects',
                            onPressed: _loadMoreProjects,
                            leadingIcon: Icons.refresh,
                          ),
                        ],
                      ),
                    );
                  }

                  if (!hasMore) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'End reached',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ).withSemantics(
                          'End of projects list',
                          hint: 'No more projects to load',
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                }

                return ProjectCard(project: projects[index]);
              },
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, st) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              labeledIcon(
                icon: Icons.error,
                label: 'Error icon',
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text('Error loading projects: $error').withSemantics(
                'Error loading projects',
                value: '$error',
              ),
              const SizedBox(height: 16),
              labeledElevatedButton(
                label: AccessibilityLabels.retryAction,
                hint: 'Attempts to reload the projects list',
                onPressed: () => ref.invalidate(projectsProvider),
                leadingIcon: Icons.refresh,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// 2. PROJECT CARD WIDGET
// ============================================================================

class ProjectCard extends ConsumerWidget {
  final ProjectModel project;

  const ProjectCard({
    required this.project,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressPercent = (project.progress * 100).toStringAsFixed(1);
    final description = project.description?.trim();

    return Semantics(
      container: true,
      button: true,
      label: 'Project ${project.name}',
      hint: 'Double tap to open project details',
      value: 'Status ${project.status}, $progressPercent percent complete',
      child: MergeSemantics(
        // Merge keeps card information announced as one coherent item.
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              project.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ).withSemantics(
              'Project name ${project.name}',
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status: ${project.status}').withSemantics(
                      'Project status ${project.status}',
                    ),
                    Text('Tasks: ${project.tasks.length}').withSemantics(
                      'Task count ${project.tasks.length}',
                    ),
                  ],
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ).withSemantics(
                    'Project description $description',
                  ),
                ],
                const SizedBox(height: 12),
                Semantics(
                  label: 'Project progress',
                  value: '$progressPercent percent complete',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: project.progress,
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$progressPercent% Complete',
                  style: Theme.of(context).textTheme.bodySmall,
                ).withSemantics(
                  'Progress $progressPercent percent complete',
                ),
              ],
            ),
            trailing: Semantics(
              button: true,
              label: 'Project actions menu',
              hint: 'Double tap to open actions for ${project.name}',
              child: PopupMenuButton<String>(
                tooltip: 'Project actions',
                icon: labeledIcon(
                  icon: Icons.more_vert,
                  label: 'Project actions icon',
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditDialog(context, ref);
                      break;
                    case 'delete':
                      _deleteProject(ref);
                      break;
                    default:
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: const Text('Edit Progress').withSemantics(
                      AccessibilityLabels.editProjectProgress,
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: const Text('Delete').withSemantics(
                      AccessibilityLabels.deleteProject,
                    ),
                  ),
                ],
              ),
            ),
            onTap: () {
              // Navigate to project details
            },
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(
      text: (project.progress * 100).toStringAsFixed(1),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Progress').withSemantics(
          'Update progress dialog',
          hint: 'Enter progress as a percentage from zero to one hundred',
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Progress (%)',
            hintText: '0-100',
          ),
        ),
        actions: [
          labeledTextButton(
            label: AccessibilityLabels.cancelAction,
            hint: 'Closes the dialog without saving progress',
            onPressed: () => Navigator.pop(context),
          ),
          labeledElevatedButton(
            label: AccessibilityLabels.saveChanges,
            hint: 'Saves the updated project progress',
            onPressed: () {
              final progress = double.tryParse(controller.text) ?? 0;
              final normalized = (progress / 100).clamp(0.0, 1.0);

              ref
                  .read(projectsProvider.notifier)
                  .updateProgress(project.id, normalized);

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Progress updated')),
              );
            },
            leadingIcon: Icons.save,
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProject(WidgetRef ref) async {
    ref.read(projectsProvider.notifier).deleteProject(project.id);
  }
}

// ============================================================================
// 3. ADD PROJECT DIALOG
// ============================================================================

class AddProjectDialog extends ConsumerStatefulWidget {
  const AddProjectDialog({super.key});

  @override
  ConsumerState<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends ConsumerState<AddProjectDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Project').withSemantics(
        'Create new project dialog',
        hint: 'Fill in the project details and activate create',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              textField: true,
              label: 'Project name input',
              hint: 'Required field',
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name',
                  hintText: 'Enter project name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              textField: true,
              label: 'Project description input',
              hint: 'Optional field',
              child: TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Enter project description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ),
          ],
        ),
      ),
      actions: [
        labeledTextButton(
          label: AccessibilityLabels.cancelAction,
          hint: 'Closes create project dialog',
          onPressed: () => Navigator.pop(context),
        ),
        labeledElevatedButton(
          label: 'Create',
          hint: 'Creates a new project',
          onPressed: () => _createProject(),
          leadingIcon: Icons.add,
        ),
      ],
    );
  }

  Future<void> _createProject() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a project name')),
      );
      return;
    }

    final project = ProjectModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      progress: 0.0,
      tasks: [],
      status: 'In Progress',
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
    );

    await ref.read(projectsProvider.notifier).addProject(project);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project created successfully')),
      );
    }
  }
}

// ============================================================================
// 4. PROJECT DETAILS WIDGET
// ============================================================================

class ProjectDetailsWidget extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailsWidget({
    required this.projectId,
    super.key,
  });

  @override
  ConsumerState<ProjectDetailsWidget> createState() =>
      _ProjectDetailsWidgetState();
}

class _ProjectDetailsWidgetState extends ConsumerState<ProjectDetailsWidget> {
  @override
  void initState() {
    super.initState();
    // Load project-scoped tasks into Riverpod state (Hive-backed, offline-first).
    Future.microtask(
      () => ref.read(tasksProvider.notifier).loadTasks(widget.projectId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectByIdProvider(widget.projectId));
    final tasksAsync = ref.watch(tasksProvider);

    return projectAsync.when(
      data: (projectData) {
        final project = projectData;
        final tasks = tasksAsync.maybeWhen(
          data: (items) => items.whereType<Task>().toList(),
          orElse: () => const <Task>[],
        );

        return Scaffold(
          appBar: OfflineIndicatorAppBar(
            appBar: AppBar(title: Text(project.name)),
          ),
          body: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Overview'),
                    Tab(text: 'Gantt View'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildOverviewTab(project, tasks),
                      _buildGanttTab(project, tasks),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, st) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildOverviewTab(ProjectModel project, List<Task> tasks) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Status', project.status),
          _buildSection(
            'Progress',
            '${(project.progress * 100).toStringAsFixed(1)}%',
          ),
          _buildProgressBar(project.progress),
          if (project.description != null)
            _buildSection('Description', project.description!),
          _buildTasksSection(tasks),
        ],
      ),
    );
  }

  Widget _buildGanttTab(ProjectModel project, List<Task> tasks) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: tasks.isEmpty
          ? Text(
              'No tasks available for Gantt view yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            )
          // BEFORE: Project details showed only text-based task rows.
          // AFTER: Replaced with ModernGanttChart bound to real Riverpod tasks data.
          : ModernGanttChart(
              tasks: tasks,
              project: project,
              enableDragReschedule: true,
              onTaskRescheduleCommit: (task, newStartDate, newEndDate) async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final updatedTask = task.copyWith(
                    createdAt: newStartDate,
                    dueDate: newEndDate,
                  );
                  await ref.read(tasksProvider.notifier).updateTask(updatedTask);
                } catch (error) {
                  if (!mounted) {
                    return;
                  }
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to reschedule task: $error'),
                    ),
                  );
                }
              },
            ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProgressBar(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Progress',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTasksSection(List<Task> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tasks (${tasks.length})',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          const Text('No tasks added yet')
        else
          ...tasks.map(
            (task) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: task.status.toThemeColor(Theme.of(context).colorScheme),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(task.title)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// 5. HOW TO USE THESE WIDGETS
// ============================================================================

/*
In your dashboard page:

class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      body: const ProjectListWidget(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddProjectDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

To view project details, navigate with:

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ProjectDetailsWidget(projectId: project.id),
  ),
);
*/
