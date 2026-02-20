import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/services/app_logger.dart';
import '../../models/task_model.dart';
import 'package:my_project_management_app/core/repository/task_repository.dart';
import 'package:my_project_management_app/core/services/notification_service.dart';

/// Repository provider for tasks
final taskRepositoryProvider = FutureProvider<TaskRepository>((ref) async {
  final repository = TaskRepository();
  await repository.initialize();
  return repository;
});

/// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  service.initialize();
  return service;
});

/// Task state notifier for managing tasks
class TaskNotifier extends AsyncNotifier<List<Task>> {
  String? _activeProjectId;
  final Map<String, List<Task>> _cacheByProjectId = {};

  @override
  Future<List<Task>> build() async {
    return [];
  }

  /// Load tasks for a project from Hive-backed project data.
  Future<void> loadTasks(String projectId) async {
    _activeProjectId = projectId;
    final cached = _cacheByProjectId[projectId];
    if (cached != null) {
      state = AsyncValue.data(List<Task>.from(cached));
    } else {
      state = const AsyncValue.loading();
    }

    try {
      final repository = await ref.read(taskRepositoryProvider.future);
      var tasks = repository.getTasksForProject(projectId);

      if (tasks.isEmpty) {
        final projectRepository = ref.read(projectRepositoryProvider);
        final project = await projectRepository.getProjectById(projectId);
        final legacyTitles = project?.tasks ?? const <String>[];
        if (legacyTitles.isNotEmpty) {
          tasks = List.generate(legacyTitles.length, (index) {
            final title = legacyTitles[index];
            return Task(
              id: '${projectId}_legacy_$index',
              projectId: projectId,
              title: title,
              description: '',
              status: TaskStatus.todo,
              assignee: '',
              createdAt: DateTime.now(),
              priority: 0.5,
            );
          });

          await repository.deleteTasksForProject(projectId);
          for (final task in tasks) {
            await repository.upsertTask(task);
          }
        }
      }
      _cacheByProjectId[projectId] = List<Task>.from(tasks);
      state = AsyncValue.data(tasks);
      await _rescheduleNotifications(tasks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update task status
  void updateTaskStatus(String taskId, TaskStatus newStatus) {
    final tasks = state.value;
    if (tasks == null) {
      return;
    }

    final updated = [
      for (final task in tasks)
        if (task.id == taskId) task.copyWith(status: newStatus) else task,
    ];

    _updateCacheForActiveProject(updated);
    state = AsyncValue.data(updated);

    // Persist task list after drag-and-drop updates.
    _persistTasks(updated);
    final updatedTask = updated.firstWhere((task) => task.id == taskId);
    AppLogger.event(
      'task_status_updated',
      details: {
        'id': updatedTask.id,
        'projectId': updatedTask.projectId,
        'status': newStatus.name,
      },
    );
    _syncTaskNotification(updatedTask);
  }

  /// Update full task details
  Future<void> updateTask(Task updatedTask) async {
    final tasks = state.value;
    if (tasks == null) {
      return;
    }

    final updated = [
      for (final task in tasks)
        if (task.id == updatedTask.id) updatedTask else task,
    ];

    _updateCacheForActiveProject(updated);
    state = AsyncValue.data(updated);
    await _persistTasks(updated);
    AppLogger.event(
      'task_updated',
      details: {
        'id': updatedTask.id,
        'projectId': updatedTask.projectId,
        'attachments': updatedTask.attachments.length,
      },
    );
    await _syncTaskNotification(updatedTask);
  }

  /// Add new task
  Future<void> addTask(Task task) async {
    final tasks = state.value ?? const <Task>[];
    final updated = [...tasks, task];
    _updateCacheForActiveProject(updated);
    state = AsyncValue.data(updated);
    await _persistTasks(updated);
    AppLogger.event(
      'task_created',
      details: {
        'id': task.id,
        'projectId': task.projectId,
        'title': task.title,
      },
    );
    await _syncTaskNotification(task);
  }

  /// Remove task
  Future<void> removeTask(String taskId) async {
    final tasks = state.value ?? const <Task>[];
    final updated = tasks.where((task) => task.id != taskId).toList();
    _updateCacheForActiveProject(updated);
    state = AsyncValue.data(updated);
    await _persistTasks(updated);
    AppLogger.event(
      'task_deleted',
      details: {
        'id': taskId,
        'projectId': _activeProjectId,
      },
    );
    await _cancelTaskNotification(taskId);
  }

  void _updateCacheForActiveProject(List<Task> tasks) {
    final projectId = _activeProjectId;
    if (projectId == null) {
      return;
    }
    _cacheByProjectId[projectId] = List<Task>.from(tasks);
  }

  /// Get tasks filtered by status
  List<Task> getTasksByStatus(TaskStatus status) {
    final tasks = state.value ?? const <Task>[];
    return tasks.where((task) => task.status == status).toList();
  }

  Future<void> _persistTasks(List<Task> tasks) async {
    final projectId = _activeProjectId;
    if (projectId == null) {
      return;
    }

    try {
      final taskRepository = await ref.read(taskRepositoryProvider.future);
      await taskRepository.deleteTasksForProject(projectId);
      for (final task in tasks) {
        await taskRepository.upsertTask(task);
      }

      // Keep legacy titles list in sync for UI counters.
      final projectRepository = ref.read(projectRepositoryProvider);
      final titles = tasks.map((task) => task.title).toList();
      await projectRepository.updateTasks(projectId, titles);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _syncTaskNotification(Task task) async {
    final enabled = ref.read(notificationsProvider);
    if (!enabled) {
      return;
    }

    final service = ref.read(notificationServiceProvider);
    await service.cancelTaskNotification(task.id);
    if (task.status != TaskStatus.done) {
      await service.scheduleTaskDueNotification(task);
    }
  }

  Future<void> _cancelTaskNotification(String taskId) async {
    final service = ref.read(notificationServiceProvider);
    await service.cancelTaskNotification(taskId);
  }

  Future<void> _rescheduleNotifications(List<Task> tasks) async {
    final enabled = ref.read(notificationsProvider);
    if (!enabled) {
      return;
    }

    final service = ref.read(notificationServiceProvider);
    await service.scheduleTasks(tasks);
  }

  /// Add sub-task IDs to a task
  Future<void> addSubTasksToTask(String taskId, List<String> subTaskIds) async {
    final tasks = state.value;
    if (tasks == null) return;

    final updated = [
      for (final task in tasks)
        if (task.id == taskId)
          task.copyWith(subTaskIds: [...task.subTaskIds, ...subTaskIds])
        else
          task,
    ];

    _updateCacheForActiveProject(updated);
    state = AsyncValue.data(updated);
    await _persistTasks(updated);
  }

  /// Remove sub-task from task
  Future<void> removeSubTaskFromTask(String taskId, String subTaskId) async {
    final tasks = state.value;
    if (tasks == null) return;

    final updated = [
      for (final task in tasks)
        if (task.id == taskId)
          task.copyWith(subTaskIds: task.subTaskIds.where((id) => id != subTaskId).toList())
        else
          task,
    ];

    _updateCacheForActiveProject(updated);
    state = AsyncValue.data(updated);
    await _persistTasks(updated);
  }
}

/// Riverpod provider for tasks (using AsyncNotifierProvider for Riverpod 3.x)
final tasksProvider = AsyncNotifierProvider<TaskNotifier, List<Task>>(
  TaskNotifier.new,
);

/// Provider for tasks grouped by status (for Kanban board)
final tasksByStatusProvider = Provider<Map<TaskStatus, List<Task>>>((ref) {
  final tasks = ref.watch(tasksProvider).maybeWhen(
        data: (items) => items,
        orElse: () => const <Task>[],
      );
  return {
    TaskStatus.todo: tasks.where((t) => t.status == TaskStatus.todo).toList(),
    TaskStatus.inProgress: tasks.where((t) => t.status == TaskStatus.inProgress).toList(),
    TaskStatus.review: tasks.where((t) => t.status == TaskStatus.review).toList(),
    TaskStatus.done: tasks.where((t) => t.status == TaskStatus.done).toList(),
  };
});

/// Provider for task statistics (for burndown chart)
final taskStatsProvider = Provider<TaskStats>((ref) {
  final tasks = ref.watch(tasksProvider).maybeWhen(
        data: (items) => items,
        orElse: () => const <Task>[],
      );
  final total = tasks.length;
  final completed = tasks.where((t) => t.status == TaskStatus.done).length;
  final inProgress = tasks.where((t) => t.status == TaskStatus.inProgress).length;
  
  return TaskStats(
    total: total,
    completed: completed,
    inProgress: inProgress,
    remaining: total - completed,
    completionPercentage: total > 0 ? (completed / total) * 100 : 0,
  );
});

/// Task statistics model
class TaskStats {
  final int total;
  final int completed;
  final int inProgress;
  final int remaining;
  final double completionPercentage;

  TaskStats({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.remaining,
    required this.completionPercentage,
  });
}
