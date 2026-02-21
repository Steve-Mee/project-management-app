import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:my_project_management_app/core/providers/project_providers.dart';
import 'package:my_project_management_app/core/providers/notification_providers.dart';
import 'package:my_project_management_app/core/providers/task_providers.dart';
import 'package:my_project_management_app/core/services/app_logger.dart';
import 'package:my_project_management_app/models/task_model.dart';
import 'package:my_project_management_app/core/repository/settings_repository.dart';

/// Helper class for initializing Hive and projects on app startup
/// 
/// Usage in main():
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await HiveInitializer.initialize();
///   runApp(const MyApp());
/// }
/// ```
class HiveInitializer {
  static const int _backupVersion = 1;
  static const String _backupFolderName = 'hive_backups';

  /// Initialize Hive and load projects from local storage
  /// Call this in main() before running the app
  static Future<void> initialize() async {
    try {
      // Initialize the repository
      // This will set up Hive and open the projects box
      AppLogger.instance.i('Initializing Hive data persistence...');
      
      // Note: The actual initialization happens when projectRepositoryProvider
      // is first accessed, so no need to do anything here.
      // The below is optional for eager initialization.
      
      AppLogger.instance.i('Hive initialized successfully');
    } catch (e) {
      AppLogger.instance.e('Error initializing Hive', error: e);
      rethrow;
    }
  }

  /// Close Hive when app shuts down
  /// Call this in runApp's cleanup
  static Future<void> cleanup() async {
    try {
      // Close all Hive boxes
      // This is handled automatically by Riverpod providers
      AppLogger.instance.i('Hive cleanup completed');
    } catch (e) {
      AppLogger.instance.e('Error during Hive cleanup', error: e);
    }
  }

  /// Create a JSON backup of Hive boxes on disk.
  static Future<File> backupHive({String? fileName}) async {
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/$_backupFolderName');
    if (!backupDir.existsSync()) {
      backupDir.createSync(recursive: true);
    }

    final timestamp = _formatTimestamp(DateTime.now());
    final resolvedName = fileName ?? 'hive_backup_$timestamp.json';
    final file = File('${backupDir.path}/$resolvedName');

    final data = <String, dynamic>{
      'version': _backupVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'boxes': {
        'projects': await _exportProjectsBox(),
        'tasks': await _exportTasksBox(),
        'project_meta': await _exportProjectMetaBox(),
        'settings': await _exportGenericBox('settings'),
        'auth': await _exportGenericBox('auth'),
      },
    };

    await file.writeAsString(jsonEncode(data));
    final settingsBox = await _openGenericBox('settings');
    await settingsBox.put(
      SettingsRepository.lastBackupKey,
      DateTime.now().toIso8601String(),
    );
    await settingsBox.put(
      SettingsRepository.lastBackupPathKey,
      file.path,
    );
    return file;
  }

  /// Restore Hive data from a JSON backup file.
  static Future<void> restoreHive(File file) async {
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Invalid backup format');
    }

    final boxes = decoded['boxes'];
    if (boxes is! Map<String, dynamic>) {
      throw FormatException('Backup data is missing boxes');
    }

    await _restoreProjectsBox(boxes['projects']);
    await _restoreTasksBox(boxes['tasks']);
    await _restoreProjectMetaBox(boxes['project_meta']);
    await _restoreGenericBox('settings', boxes['settings']);
    await _restoreGenericBox('auth', boxes['auth']);
  }

  static Future<Map<String, dynamic>> _exportProjectsBox() async {
    final box = await _openMapBox('projects');
    final data = <String, dynamic>{};
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        data[key.toString()] = _jsonSafe(Map<String, dynamic>.from(value));
      }
    }
    return data;
  }

  static Future<Map<String, dynamic>> _exportTasksBox() async {
    final box = await _openTasksBox();
    final data = <String, dynamic>{};
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Task) {
        data[key.toString()] = value.toJson();
      }
    }
    return data;
  }

  static Future<Map<String, dynamic>> _exportProjectMetaBox() async {
    final box = await _openMapBox('project_meta');
    final data = <String, dynamic>{};
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is Map) {
        data[key.toString()] = _jsonSafe(Map<String, dynamic>.from(value));
      }
    }
    return data;
  }

  static Future<Map<String, dynamic>> _exportGenericBox(String name) async {
    final box = await _openGenericBox(name);
    final data = <String, dynamic>{};
    for (final key in box.keys) {
      data[key.toString()] = _jsonSafe(box.get(key));
    }
    return data;
  }

  static Future<void> _restoreProjectsBox(dynamic payload) async {
    final box = await _openMapBox('projects');
    await box.clear();
    if (payload is! Map) {
      return;
    }
    for (final entry in payload.entries) {
      final value = entry.value;
      if (value is Map) {
        await box.put(entry.key.toString(), Map<String, dynamic>.from(value));
      }
    }
  }

  static Future<void> _restoreTasksBox(dynamic payload) async {
    final box = await _openTasksBox();
    await box.clear();
    if (payload is! Map) {
      return;
    }
    for (final entry in payload.entries) {
      final value = entry.value;
      if (value is Map) {
        final task = Task.fromJson(Map<String, dynamic>.from(value));
        await box.put(entry.key.toString(), task);
      }
    }
  }

  static Future<void> _restoreProjectMetaBox(dynamic payload) async {
    final box = await _openMapBox('project_meta');
    await box.clear();
    if (payload is! Map) {
      return;
    }
    for (final entry in payload.entries) {
      final value = entry.value;
      if (value is Map) {
        await box.put(entry.key.toString(), Map<String, dynamic>.from(value));
      }
    }
  }

  static Future<void> _restoreGenericBox(String name, dynamic payload) async {
    final box = await _openGenericBox(name);
    await box.clear();
    if (payload is! Map) {
      return;
    }
    for (final entry in payload.entries) {
      await box.put(entry.key.toString(), entry.value);
    }
  }

  static Future<Box<Map<dynamic, dynamic>>> _openMapBox(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box<Map<dynamic, dynamic>>(name);
    }
    return Hive.openBox<Map<dynamic, dynamic>>(name);
  }

  static Future<Box<Task>> _openTasksBox() async {
    if (Hive.isBoxOpen('tasks')) {
      return Hive.box<Task>('tasks');
    }
    return Hive.openBox<Task>('tasks');
  }

  static Future<Box> _openGenericBox(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box(name);
    }
    return Hive.openBox(name);
  }

  static dynamic _jsonSafe(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nested) => MapEntry(key.toString(), _jsonSafe(nested)),
      );
    }
    if (value is Iterable) {
      return value.map(_jsonSafe).toList();
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    return value;
  }

  static String _formatTimestamp(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}${two(date.month)}${two(date.day)}_${two(date.hour)}${two(date.minute)}${two(date.second)}';
  }
}

/// Widget that initializes projects on mount
/// Use this as a wrapper for your main app content
class ProjectsInitializer extends ConsumerStatefulWidget {
  final Widget child;

  const ProjectsInitializer({
    required this.child,
    super.key,
  });

  @override
  ConsumerState<ProjectsInitializer> createState() =>
      _ProjectsInitializerState();
}

class _ProjectsInitializerState extends ConsumerState<ProjectsInitializer> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeProjects();
  }

  Future<void> _initializeProjects() async {
    try {
      // Get the repository instance
      final repository = ref.read(projectRepositoryProvider);
      
      // Initialize the projects notifier with the repository
      await ref.read(projectsProvider.notifier).initialize(repository);

      final notificationsEnabled = ref.read(notificationsProvider);
      if (notificationsEnabled) {
        final taskRepository = await ref.read(taskRepositoryProvider.future);
        final notificationService = ref.read(notificationServiceProvider);
        await notificationService.scheduleTasks(taskRepository.getAllTasks());
      }
      
      setState(() {
        _initialized = true;
      });
      
      AppLogger.instance.i('Projects loaded from Hive successfully');
    } catch (e) {
      setState(() {
        _error = 'Failed to load projects: $e';
      });
      AppLogger.instance.e('Error initializing projects', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: AlertDialog(
              title: const Text('Projecten laden mislukt'),
              content: Text(_error!),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _initialized = false;
                    });
                    _initializeProjects();
                  },
                  child: const Text('Opnieuw proberen'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading projects...'),
              ],
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}

/// Example of how to use the initializer in your app
/// 
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await HiveInitializer.initialize();
///   
///   runApp(
///     ProviderScope(
///       child: ProjectsInitializer(
///         child: MyApp(),
///       ),
///     ),
///   );
/// }
/// 
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       title: 'Project Management',
///       home: HomePage(),
///     );
///   }
/// }
/// ```
