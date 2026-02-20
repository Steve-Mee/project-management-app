import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_project_management_app/models/task_model.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Handles local notifications for task due dates.
class NotificationService {
  static const String _channelId = 'task_due_dates';
  static const String _channelName = 'Task Due Dates';
  static const String _channelDescription = 'Notifications for task due dates.';
  static const String _updateChannelId = 'task_updates';
  static const String _updateChannelName = 'Task Updates';
  static const String _updateChannelDescription =
      'Notifications for task updates and AI responses.';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const windowsSettings = WindowsInitializationSettings(
      appName: 'Project Management App',
      appUserModelId: 'com.example.my_project_management_app',
      guid: '65b05323-5b2d-4b6d-9b85-6e3d4b5a6c7d',
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      windows: windowsSettings,
    );

    await _plugin.initialize(initSettings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
      IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
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
    if (task.dueDate == null) {
      return;
    }

    final scheduledAt = task.dueDate!;
    if (scheduledAt.isBefore(DateTime.now())) {
      return;
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    final scheduledLocal = tz.TZDateTime.from(scheduledAt, tz.local);

    await _plugin.zonedSchedule(
      _notificationId(task.id),
      'Taak is vervallen',
      task.title,
      scheduledLocal,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelTaskNotification(String taskId) async {
    if (!_initialized) {
      await initialize();
    }
    await _plugin.cancel(_notificationId(taskId));
  }

  Future<void> scheduleTasks(List<Task> tasks) async {
    if (!_initialized) {
      await initialize();
    }
    await cancelAll();
    for (final task in tasks) {
      if (task.status == TaskStatus.done) {
        continue;
      }
      await scheduleTaskDueNotification(task);
    }
  }

  Future<void> cancelAll() async {
    if (!_initialized) {
      await initialize();
    }
    await _plugin.cancelAll();
  }

  Future<void> notifyUpdate(Task task) async {
    if (!_initialized) {
      await initialize();
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _updateChannelId,
        _updateChannelName,
        channelDescription: _updateChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.show(
      _notificationId('${task.id}_${DateTime.now().millisecondsSinceEpoch}'),
      'AI update',
      '${task.title} • ${task.statusLabel}',
      details,
    );
  }

  int _notificationId(String taskId) {
    return taskId.hashCode & 0x7fffffff;
  }
}
