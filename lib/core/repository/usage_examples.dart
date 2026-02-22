// Usage Examples for ProjectRepository with Riverpod

// ============================================================================
// 1. BASIC USAGE - Watch projects in a widget
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_project_management_app/core/providers/project_providers.dart';
import 'package:my_project_management_app/models/project_model.dart';

class ProjectListWidget extends ConsumerStatefulWidget {
  const ProjectListWidget({super.key});

  @override
  ConsumerState<ProjectListWidget> createState() => _ProjectListWidgetState();
}

class _ProjectListWidgetState extends ConsumerState<ProjectListWidget> {
  final ScrollController _scrollController = ScrollController();
  final List<ProjectModel> _items = [];
  int _page = 1;
  static const int _limit = 20;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPage());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoading || !_hasMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadPage();
    }
  }

  Future<void> _loadPage() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    try {
      final params = ProjectPaginationParams(page: _page, limit: _limit);
      final newItems = await ref.read(projectsPaginatedProvider(params).future);
      if (newItems.isEmpty || newItems.length < _limit) {
        _hasMore = false;
      }
      _items.addAll(newItems);
      _page += 1;
    } catch (e) {
      // ignore errors for now; could show snackbar
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _items.length) {
          final project = _items[index];
          return ListTile(
            title: Text(project.name),
            subtitle: Text('Progress: ${(project.progress * 100).toStringAsFixed(1)}%'),
            onTap: () {},
          );
        }
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        );
      },
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
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectsPaginatedProvider(ProjectPaginationParams(page: 1, limit: 100)));

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
    final repository = ref.read(projectRepositoryProvider);
    final newProject = ProjectModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'New Project',
      progress: 0.0,
      tasks: [],
    );
    await repository.addProject(newProject);
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
      final repository = ref.read(projectRepositoryProvider);
      await repository.deleteProject(projectId);
    }
  }
}

// ============================================================================
// 7. OFFLINE HANDLING - AUTO-LOAD FROM HIVE
// ============================================================================

// The offline-first functionality is automatically handled by:
// 1. ProjectRepository.getAllProjects() loads from local Hive storage
// 2. projectsPaginatedProvider fetches data reactively from repository
// 3. When a user adds/updates/deletes, Hive is updated immediately
// 4. The UI updates automatically via Riverpod's reactive system
// 5. When internet is available, sync with backend (implement separately)

// Example: Initialize on app startup
void setupOfflineSync(WidgetRef ref) {
  // This ensures Hive is loaded before any screens are shown
  ref.watch(projectRepositoryProvider);
}
