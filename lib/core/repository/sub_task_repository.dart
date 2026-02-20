import 'package:hive/hive.dart';
import 'package:my_project_management_app/models/sub_task_model.dart';
import 'package:uuid/uuid.dart';

/// Repository for managing sub-tasks using Hive
class SubTaskRepository {
  static const String _boxName = 'subTasks';
  final Uuid _uuid = Uuid();
  late Box<SubTask> _box;

  Future<void> init() async {
    _box = await Hive.openBox<SubTask>(_boxName);
  }

  /// Get all sub-tasks
  List<SubTask> getAllSubTasks() {
    return _box.values.toList();
  }

  /// Get sub-tasks by task ID
  List<SubTask> getSubTasksByTaskId(String taskId) {
    return _box.values.where((subTask) => subTask.taskId == taskId).toList();
  }

  /// Add a new sub-task
  Future<void> addSubTask(SubTask subTask) async {
    await _box.put(subTask.id, subTask);
  }

  /// Add multiple sub-tasks
  Future<void> addSubTasks(List<SubTask> subTasks) async {
    final map = {for (final subTask in subTasks) subTask.id: subTask};
    await _box.putAll(map);
  }

  /// Update a sub-task
  Future<void> updateSubTask(SubTask subTask) async {
    await _box.put(subTask.id, subTask);
  }

  /// Delete a sub-task
  Future<void> deleteSubTask(String subTaskId) async {
    await _box.delete(subTaskId);
  }

  /// Delete all sub-tasks for a task
  Future<void> deleteSubTasksByTaskId(String taskId) async {
    final subTasksToDelete = _box.values
        .where((subTask) => subTask.taskId == taskId)
        .map((subTask) => subTask.id)
        .toList();

    await _box.deleteAll(subTasksToDelete);
  }

  /// Toggle sub-task completion
  Future<void> toggleSubTaskCompletion(String subTaskId) async {
    final subTask = _box.get(subTaskId);
    if (subTask != null) {
      final updatedSubTask = subTask.copyWith(isCompleted: !subTask.isCompleted);
      await _box.put(subTaskId, updatedSubTask);
    }
  }

  /// Assign sub-task to user
  Future<void> assignSubTask(String subTaskId, String? userId) async {
    final subTask = _box.get(subTaskId);
    if (subTask != null) {
      final updatedSubTask = subTask.copyWith(assignedTo: userId);
      await _box.put(subTaskId, updatedSubTask);
    }
  }

  /// Create sub-task with generated ID
  SubTask createSubTask({
    required String taskId,
    required String title,
    required String description,
    String? assignedTo,
  }) {
    return SubTask(
      id: _uuid.v4(),
      taskId: taskId,
      title: title,
      description: description,
      assignedTo: assignedTo,
      createdAt: DateTime.now(),
    );
  }
}