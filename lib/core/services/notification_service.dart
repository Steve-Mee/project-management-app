// ignore_for_file: prefer_const_constructors
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:project_management_app/models/task_model.dart';

/// Handles notifications via Firebase Cloud Messaging (FCM) only.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _messaging.setAutoInitEnabled(true);
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    _initialized = true;
  }

  Future<void> scheduleTaskDueNotification(Task task) async {
    if (!_initialized) {
      await initialize();
    }
    // FCM-only service: local scheduling is intentionally not used.
    if (task.id.isEmpty) return;
  }

  Future<void> cancelTaskNotification(String taskId) async {
    if (!_initialized) {
      await initialize();
    }
    if (taskId.isEmpty) return;
  }

  Future<void> scheduleTasks(List<Task> tasks) async {
    if (!_initialized) {
      await initialize();
    }
    if (tasks.isEmpty) return;
  }

  Future<void> cancelAll() async {
    if (!_initialized) {
      await initialize();
    }
  }

  Future<void> notifyUpdate(Task task) async {
    if (!_initialized) {
      await initialize();
    }
    if (task.id.isEmpty) return;
  }
}
