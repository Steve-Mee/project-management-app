/// Task-related providers
/// (moved from providers.dart – part 2/4)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_management_app/core/providers/project_providers.dart' show projectRepositoryProvider, projectByIdProvider;
import 'package:project_management_app/core/providers/notification_providers.dart';
import 'package:project_management_app/core/services/app_logger.dart';
import 'package:project_management_app/models/task_model.dart';
import 'package:project_management_app/core/repository/impl/hive_task_repository.dart';
import 'package:project_management_app/core/repository/impl/sub_task_repository.dart';
import 'package:project_management_app/models/sub_task_model.dart';

/// Repository provider for tasks
final taskRepositoryProvider = FutureProvider<HiveTaskRepository>((ref) async {
  final repository = HiveTaskRepository();
  await repository.initialize();
  return repository;
});

/// Task state notifier for managing tasks
class TaskNotifier extends AsyncNotifier<List<Task>> {
  String? _activeProjectId;
  final Map<String, List<Task>> _cacheByProjectId = {};
  final Map<String, List<Task>> _fullCacheByProjectId = {};

  static const int pageSize = 20;

  /// Current page of tasks loaded into [state] for the active project.
  int currentPage = 1;

  /// True when there are more tasks available for the active project.
  bool hasMore = true;

  /// True while [loadMoreTasks] is appending the next page.
  bool isLoadingMore = false;

  /// Stores non-fatal pagination errors from [loadMoreTasks].
  /// Existing task items remain visible and recoverable via retry.
  Object? loadMoreError;

  @override
  Future<List<Task>> build() async {
    return [];
  }

  List<Task> _firstPage(List<Task> allTasks) {
    return allTasks.take(pageSize).toList();
  }

  List<Task> _pageSlice(List<Task> allTasks, int page) {
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= allTasks.length) {
      return const <Task>[];
    }
    return allTasks.skip(startIndex).take(pageSize).toList();
  }

  void _setPagingFromLoaded(List<Task> loaded, List<Task> allTasks, int page) {
    currentPage = page;
    hasMore = loaded.length < allTasks.length;
  }

  int _pageFromLoadedCount(int loadedCount) {
    if (loadedCount <= 0) {
      return 1;
    }
    return ((loadedCount - 1) ~/ pageSize) + 1;
  }

  /// Load tasks for a project from Hive-backed project data.
  Future<void> loadTasks(String projectId) async {
    _activeProjectId = projectId;
    final cached = _cacheByProjectId[projectId];
    final fullCached = _fullCacheByProjectId[projectId];
    if (cached != null) {
      state = AsyncValue.data(List<Task>.from(cached));
      if (fullCached != null) {
        _setPagingFromLoaded(cached, fullCached, _pageFromLoadedCount(cached.length));
      } else {
        currentPage = _pageFromLoadedCount(cached.length);
        hasMore = false;
      }
    } else {
      state = const AsyncValue.loading();
      currentPage = 1;
      hasMore = true;
    }
    loadMoreError = null;

    try {
      final repository = await ref.read(taskRepositoryProvider.future);
      var tasks = repository.getTasksForProject(projectId);

      if (tasks.isEmpty) {
        // Migrated to use projectByIdProvider for consistency with Riverpod patterns.
        final project = await ref.read(projectByIdProvider(projectId).future);
        final legacyTitles = project.tasks;
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

      // Keep a full in-memory cache, then expose only the first page for infinite scroll.
      _fullCacheByProjectId[projectId] = List<Task>.from(tasks);
      final firstPage = _firstPage(tasks);
      _cacheByProjectId[projectId] = List<Task>.from(firstPage);
      _setPagingFromLoaded(firstPage, tasks, 1);
      state = AsyncValue.data(firstPage);

      // Keep existing behavior by scheduling notifications for all project tasks.
      await _rescheduleNotifications(tasks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Load and append the next page of tasks for the active project.
  ///
  /// Uses `TaskRepository.getTasksForProject(projectId)` as source, then slices
  /// in-memory for compatibility with the existing repository API.
  ///
  /// Pagination logic (issue #064):
  /// 1. Read all project tasks from repository.
  /// 2. Compute next page start index as `(nextPage - 1) * pageSize`.
  /// 3. Append `skip(startIndex).take(pageSize)` to current state.
  /// 4. Mark [hasMore] false when no next slice is available.
  Future<void> loadMoreTasks() async {
    final projectId = _activeProjectId;
    if (projectId == null || isLoadingMore || !hasMore) {
      return;
    }

    final currentItems = state.value ?? const <Task>[];
    isLoadingMore = true;
    loadMoreError = null;

    try {
      final repository = await ref.read(taskRepositoryProvider.future);
      final allTasks = repository.getTasksForProject(projectId);
      _fullCacheByProjectId[projectId] = List<Task>.from(allTasks);

      final nextPage = currentPage + 1;
      final nextItems = _pageSlice(allTasks, nextPage);

      if (nextItems.isEmpty) {
        hasMore = false;
        return;
      }

      final combined = [...currentItems, ...nextItems];
      _cacheByProjectId[projectId] = List<Task>.from(combined);
      _setPagingFromLoaded(combined, allTasks, nextPage);
      state = AsyncValue.data(combined);
    } catch (e, st) {
      loadMoreError = e;
      if (currentItems.isEmpty) {
        state = AsyncValue.error(e, st);
      } else {
        state = AsyncValue.data(currentItems);
      }
    } finally {
      isLoadingMore = false;
    }
  }

  void clearLoadMoreError() {
    loadMoreError = null;
  }

  /// Update task status
  void updateTaskStatus(String taskId, TaskStatus newStatus) {
    final tasks = state.value;
    if (tasks == null) {
      return;
    }

    final projectId = _activeProjectId;

    final updated = [
      for (final task in tasks)
        if (task.id == taskId) task.copyWith(status: newStatus) else task,
    ];

    final updatedAll = projectId == null
        ? updated
        : [
            for (final task in (_fullCacheByProjectId[projectId] ?? tasks))
              if (task.id == taskId) task.copyWith(status: newStatus) else task,
          ];

    if (projectId != null) {
      _fullCacheByProjectId[projectId] = List<Task>.from(updatedAll);
      hasMore = updated.length < updatedAll.length;
    }

    _updateCacheForActiveProject(updated);
    state = AsyncValue.data(updated);

    // Persist task list after drag-and-drop updates.
    _persistTasks(updatedAll);
    final updatedTask = updated.firstWhere((task) => task.id == taskId);
    AppLogger.event(
      'task_status_updated',
      params: {
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

    final projectId = _activeProjectId;

    final updated = [
      for (final task in tasks)
        if (task.id == updatedTask.id) updatedTask else task,
    ];

    final updatedAll = projectId == null
        ? updated
        : [
            for (final task in (_fullCacheByProjectId[projectId] ?? tasks))
              if (task.id == updatedTask.id) updatedTask else task,
          ];

    if (projectId != null) {
      _fullCacheByProjectId[projectId] = List<Task>.from(updatedAll);
      hasMore = updated.length < updatedAll.length;
    }

    _updateCacheForActiveProject(updated);
    state = AsyncValue.data(updated);
    await _persistTasks(updatedAll);
    AppLogger.event(
      'task_updated',
      params: {
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
    final projectId = _activeProjectId;
    List<Task> updatedAll = updated;

    if (projectId != null) {
      final full = List<Task>.from(_fullCacheByProjectId[projectId] ?? tasks)
        ..add(task);
      _fullCacheByProjectId[projectId] = full;
      updatedAll = full;
      hasMore = updated.length < full.length;
    }

    _updateCacheForActiveProject(updated);
    state = AsyncValue.data(updated);
    await _persistTasks(updatedAll);
    AppLogger.event(
      'task_created',
      params: {
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
    final projectId = _activeProjectId;
    List<Task> updatedAll = updated;

    if (projectId != null) {
      final full = List<Task>.from(_fullCacheByProjectId[projectId] ?? const <Task>[])
        ..removeWhere((task) => task.id == taskId);
      _fullCacheByProjectId[projectId] = full;
      updatedAll = full;
      hasMore = updated.length < full.length;
      if (updated.length >= full.length) {
        hasMore = false;
      }
    }

    _updateCacheForActiveProject(updated);
    state = AsyncValue.data(updated);
    await _persistTasks(updatedAll);
    AppLogger.event(
      'task_deleted',
      params: {
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
    } catch (e) {
      // ignore
    }
  }

  Future<void> _syncTaskNotification(Task task) async {
    final enabled = ref.watch(notificationsProvider).maybeWhen(
      data: (e) => e,
      orElse: () => false,
    );
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
    final enabled = ref.watch(notificationsProvider).maybeWhen(
      data: (e) => e,
      orElse: () => false,
    );
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

    final projectId = _activeProjectId;

    final updated = [
      for (final task in tasks)
        if (task.id == taskId)
          task.copyWith(subTaskIds: [...task.subTaskIds, ...subTaskIds])
        else
          task,
    ];

    final updatedAll = projectId == null
        ? updated
        : [
            for (final task in (_fullCacheByProjectId[projectId] ?? tasks))
              if (task.id == taskId)
                task.copyWith(subTaskIds: [...task.subTaskIds, ...subTaskIds])
              else
                task,
          ];

    if (projectId != null) {
      _fullCacheByProjectId[projectId] = List<Task>.from(updatedAll);
      hasMore = updated.length < updatedAll.length;
    }

    _updateCacheForActiveProject(updated);
    state = AsyncValue.data(updated);
    await _persistTasks(updatedAll);
  }

  /// Remove sub-task from task
  Future<void> removeSubTaskFromTask(String taskId, String subTaskId) async {
    final tasks = state.value;
    if (tasks == null) return;

    final projectId = _activeProjectId;

    final updated = [
      for (final task in tasks)
        if (task.id == taskId)
          task.copyWith(subTaskIds: task.subTaskIds.where((id) => id != subTaskId).toList())
        else
          task,
    ];

    final updatedAll = projectId == null
        ? updated
        : [
            for (final task in (_fullCacheByProjectId[projectId] ?? tasks))
              if (task.id == taskId)
                task.copyWith(subTaskIds: task.subTaskIds.where((id) => id != subTaskId).toList())
              else
                task,
          ];

    if (projectId != null) {
      _fullCacheByProjectId[projectId] = List<Task>.from(updatedAll);
      hasMore = updated.length < updatedAll.length;
    }

    _updateCacheForActiveProject(updated);
    state = AsyncValue.data(updated);
    await _persistTasks(updatedAll);
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

// -----------------------------------------------------------------------------
// Sub-task related providers (previously in sub_task_provider.dart)


// -----------------------------------------------------------------------------
// Sub-task related providers (previously in sub_task_provider.dart)

/// Repository provider for sub-tasks
final subTaskRepositoryProvider = FutureProvider<SubTaskRepository>((ref) async {
  final repo = SubTaskRepository();
  await repo.init();
  return repo;
});

/// Provider for all sub-tasks
final subTasksProvider = FutureProvider<List<SubTask>>((ref) async {
  final repo = await ref.watch(subTaskRepositoryProvider.future);
  return repo.getAllSubTasks();
});

/// Provider for sub-tasks by task ID
final subTasksByTaskProvider = FutureProvider.family<List<SubTask>, String>((ref, taskId) async {
  final repo = await ref.watch(subTaskRepositoryProvider.future);
  return repo.getSubTasksByTaskId(taskId);
});

/// Provider for sub-task expansion state
final taskExpansionProvider = NotifierProvider<TaskExpansionNotifier, Map<String, bool>>(() {
  return TaskExpansionNotifier();
});

/// Notifier for managing task expansion states
class TaskExpansionNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() {
    return {};
  }

  void toggleExpansion(String taskId) {
    state = {
      ...state,
      taskId: !(state[taskId] ?? false),
    };
  }

  void setExpansion(String taskId, bool expanded) {
    state = {
      ...state,
      taskId: expanded,
    };
  }
}

/// Provider for sub-task generation loading state
final subTaskGenerationProvider = NotifierProvider<SubTaskGenerationNotifier, Map<String, AsyncValue<List<SubTask>>>>(() {
  return SubTaskGenerationNotifier();
});

/// Notifier for managing sub-task generation
class SubTaskGenerationNotifier extends Notifier<Map<String, AsyncValue<List<SubTask>>>> {
  @override
  Map<String, AsyncValue<List<SubTask>>> build() {
    return {};
  }

  void startGeneration(String taskId) {
    state = {
      ...state,
      taskId: const AsyncValue.loading(),
    };
  }

  void completeGeneration(String taskId, List<SubTask> subTasks) {
    state = {
      ...state,
      taskId: AsyncValue.data(subTasks),
    };
  }

  void failGeneration(String taskId, Object error) {
    state = {
      ...state,
      taskId: AsyncValue.error(error, StackTrace.current),
    };
  }
}

