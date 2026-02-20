import 'package:riverpod/riverpod.dart';
import 'package:my_project_management_app/core/repository/sub_task_repository.dart';
import 'package:my_project_management_app/models/sub_task_model.dart';

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