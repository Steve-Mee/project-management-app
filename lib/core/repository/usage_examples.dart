// Usage Examples for ProjectRepository with Riverpod

// ============================================================================
// 1. BASIC USAGE - Watch projects in a widget
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_project_management_app/core/providers.dart';
import 'package:my_project_management_app/models/project_model.dart';

class ProjectListWidget extends ConsumerWidget {
  const ProjectListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);

    return projectsAsync.when(
      data: (projects) {
        return ListView.builder(
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return ListTile(
              title: Text(project.name),
              subtitle: Text('Progress: ${(project.progress * 100).toStringAsFixed(1)}%'),
              onTap: () {
                // Handle project tap
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, st) => Center(child: Text('Error: $error')),
    );
  }
}

// ============================================================================
// 2. ADD A NEW PROJECT
// ============================================================================

Future<void> addNewProject(WidgetRef ref) async {
  final notifier = ref.read(projectsProvider.notifier);
  
  final newProject = ProjectModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    name: 'New Project',
    progress: 0.0,
    tasks: [],
    status: 'In Progress',
    description: 'Project description',
  );

  await notifier.addProject(newProject);
}

// ============================================================================
// 3. UPDATE PROJECT PROGRESS
// ============================================================================

Future<void> updateProjectProgress(
  WidgetRef ref,
  String projectId,
  double newProgress,
) async {
  final notifier = ref.read(projectsProvider.notifier);
  await notifier.updateProgress(projectId, newProgress);
}

// ============================================================================
// 4. UPDATE PROJECT TASKS
// ============================================================================

Future<void> updateProjectTasks(
  WidgetRef ref,
  String projectId,
  List<String> newTasks,
) async {
  final notifier = ref.read(projectsProvider.notifier);
  await notifier.updateTasks(projectId, newTasks);
}

// ============================================================================
// 5. DELETE A PROJECT
// ============================================================================

Future<void> deleteProject(
  WidgetRef ref,
  String projectId,
) async {
  final notifier = ref.read(projectsProvider.notifier);
  await notifier.deleteProject(projectId);
}

// ============================================================================
// 6. COMPLETE EXAMPLE WIDGET
// ============================================================================

class ProjectManagementPage extends ConsumerStatefulWidget {
  const ProjectManagementPage({super.key});

  @override
  ConsumerState<ProjectManagementPage> createState() =>
      _ProjectManagementPageState();
}

class _ProjectManagementPageState extends ConsumerState<ProjectManagementPage> {
  @override
  void initState() {
    super.initState();
    // Initialize projects from Hive on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProjects();
    });
  }

  Future<void> _initializeProjects() async {
    final repository =
        await ref.read(projectRepositoryProvider.future);
    await ref
        .read(projectsProvider.notifier)
        .initialize(repository);
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      body: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            return const Center(
              child: Text('No projects. Add one to get started!'),
            );
          }
          return ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(project.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Progress: ${(project.progress * 100).toStringAsFixed(1)}%'),
                      Text('Tasks: ${project.tasks.length}'),
                      Text('Status: ${project.status}'),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text('Edit'),
                        onTap: () => _editProject(project),
                      ),
                      PopupMenuItem(
                        child: const Text('Delete'),
                        onTap: () => _deleteProjectConfirm(project.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) =>
            Center(child: Text('Error loading projects: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewProject,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addNewProject() async {
    final notifier = ref.read(projectsProvider.notifier);
    final newProject = ProjectModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'New Project',
      progress: 0.0,
      tasks: [],
    );
    await notifier.addProject(newProject);
  }

  void _editProject(ProjectModel project) {
    // Show edit dialog
  }

  Future<void> _deleteProjectConfirm(String projectId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      final notifier = ref.read(projectsProvider.notifier);
      await notifier.deleteProject(projectId);
    }
  }
}

// ============================================================================
// 7. OFFLINE HANDLING - AUTO-LOAD FROM HIVE
// ============================================================================

// The offline-first functionality is automatically handled by:
// 1. ProjectRepository.getAllProjects() loads from local Hive storage
// 2. ProjectsNotifier.build() initializes with local data
// 3. When a user adds/updates/deletes, Hive is updated immediately
// 4. The UI updates automatically via Riverpod's reactive system
// 5. When internet is available, sync with backend (implement separately)

// Example: Initialize on app startup
void setupOfflineSync(WidgetRef ref) {
  // This ensures Hive is loaded before any screens are shown
  ref.watch(projectRepositoryProvider);
}
