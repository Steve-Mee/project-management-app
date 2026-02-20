import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_project_management_app/models/task_model.dart';
import 'package:my_project_management_app/core/services/app_logger.dart';

/// Repository for managing task persistence using Hive
class TaskRepository {
  static const String _boxName = 'tasks';
  late Box<Task> _tasksBox;
  final Map<String, List<Task>> _tasksByProjectCache = {};
  List<Task> _allTasksCache = [];

  /// Initialize Hive and open the tasks box
  Future<void> initialize() async {
    if (Hive.isBoxOpen(_boxName)) {
      _tasksBox = Hive.box<Task>(_boxName);
      _rebuildCache();
      return;
    }

    _tasksBox = await Hive.openBox<Task>(_boxName);
    _rebuildCache();
  }

  /// Check if repository is initialized
  bool get isInitialized => _tasksBox.isOpen;

  /// Add or update a task in Hive
  Future<void> upsertTask(Task task) async {
    await _tasksBox.put(task.id, task);
    _cacheTask(task);
    _cacheAllTask(task);
  }

  /// Delete a task by ID
  Future<void> deleteTask(String taskId) async {
    final existing = _tasksBox.get(taskId);
    await _tasksBox.delete(taskId);
    if (existing != null) {
      _removeCachedTask(existing);
      _removeCachedAllTask(existing);
    }
  }

  /// Get tasks for a specific project
  List<Task> getTasksForProject(String projectId) {
    try {
      final cached = _tasksByProjectCache[projectId];
      if (cached != null) {
        return List<Task>.from(cached);
      }
      final tasks = _tasksBox.values
          .where((task) => task.projectId == projectId)
          .toList();
      _tasksByProjectCache[projectId] = tasks;
      return List<Task>.from(tasks);
    } catch (e) {
      AppLogger.instance.e(
        'Error reading tasks for project $projectId',
        error: e,
      );
      return [];
    }
  }

  /// Get all tasks
  List<Task> getAllTasks() {
    try {
      if (_allTasksCache.isNotEmpty) {
        return List<Task>.from(_allTasksCache);
      }
      final tasks = _tasksBox.values.toList();
      _allTasksCache = List<Task>.from(tasks);
      return List<Task>.from(tasks);
    } catch (e) {
      AppLogger.instance.e('Error reading all tasks', error: e);
      return [];
    }
  }

  /// Delete all tasks for a project
  Future<void> deleteTasksForProject(String projectId) async {
    try {
      final keysToDelete = _tasksBox.keys.where((key) {
        final task = _tasksBox.get(key);
        return task?.projectId == projectId;
      }).toList();

      for (final key in keysToDelete) {
        await _tasksBox.delete(key);
      }
      _tasksByProjectCache.remove(projectId);
      _allTasksCache.removeWhere((task) => task.projectId == projectId);
    } catch (e) {
      AppLogger.instance.e(
        'Error deleting tasks for project $projectId',
        error: e,
      );
      rethrow;
    }
  }

  /// Close the Hive box (call on app shutdown)
  Future<void> close() async {
    await _tasksBox.compact();
    await _tasksBox.close();
    _tasksByProjectCache.clear();
    _allTasksCache = [];
  }

  void _rebuildCache() {
    _tasksByProjectCache.clear();
    _allTasksCache = [];
    for (final task in _tasksBox.values) {
      _cacheTask(task);
      _allTasksCache.add(task);
    }
  }

  void _cacheTask(Task task) {
    final list = _tasksByProjectCache.putIfAbsent(task.projectId, () => []);
    final index = list.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      list.add(task);
    } else {
      list[index] = task;
    }
  }

  void _removeCachedTask(Task task) {
    final list = _tasksByProjectCache[task.projectId];
    if (list == null) {
      return;
    }
    list.removeWhere((item) => item.id == task.id);
    if (list.isEmpty) {
      _tasksByProjectCache.remove(task.projectId);
    }
  }

  void _cacheAllTask(Task task) {
    final index = _allTasksCache.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      _allTasksCache.add(task);
    } else {
      _allTasksCache[index] = task;
    }
  }

  void _removeCachedAllTask(Task task) {
    _allTasksCache.removeWhere((item) => item.id == task.id);
  }
}
