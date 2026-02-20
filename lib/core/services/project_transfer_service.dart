import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:file_picker/file_picker.dart';
import '../repository/i_project_repository.dart';
import 'package:my_project_management_app/core/repository/task_repository.dart';
import 'package:my_project_management_app/models/project_model.dart';
import 'package:my_project_management_app/models/task_model.dart';

class ProjectTransferResult {
  final String projectsPath;
  final String tasksPath;

  const ProjectTransferResult({
    required this.projectsPath,
    required this.tasksPath,
  });
}

class ProjectTransferService {
  Future<ProjectTransferResult?> exportData({
    required IProjectRepository projectRepository,
    required TaskRepository taskRepository,
    required String password,
  }) async {
    final directory = await FilePicker.platform.getDirectoryPath();
    if (directory == null) {
      return null;
    }

    final trimmedPassword = password.trim();
    if (trimmedPassword.isEmpty) {
      throw 'Export password is required.';
    }

    final projects = await projectRepository.getAllProjects();
    final tasks = taskRepository.getAllTasks();

    final projectsCsv = _buildProjectsCsv(projects);
    final tasksJson = jsonEncode(tasks.map(_taskToJson).toList());

    final encryptedProjects = _encryptText(projectsCsv, trimmedPassword);
    final encryptedTasks = _encryptText(tasksJson, trimmedPassword);

    final projectsPath = '$directory/projects.csv.enc';
    final tasksPath = '$directory/tasks.json.enc';

    await File(projectsPath).writeAsString(encryptedProjects);
    await File(tasksPath).writeAsString(encryptedTasks);

    return ProjectTransferResult(
      projectsPath: projectsPath,
      tasksPath: tasksPath,
    );
  }

  Future<ProjectTransferResult?> importData({
    required IProjectRepository projectRepository,
    required TaskRepository taskRepository,
  }) async {
    final originalProjectsById = <String, ProjectModel?>{};
    final originalTasksById = <String, Task?>{};
    final importedProjectIds = <String>[];
    final importedTaskIds = <String>[];
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: const ['csv', 'json'],
      );

      if (result == null) {
        return null;
      }

      String? projectsPath;
      String? tasksPath;
      for (final file in result.files) {
        final path = file.path;
        if (path == null) {
          continue;
        }
        if (path.toLowerCase().endsWith('.csv')) {
          projectsPath = path;
        } else if (path.toLowerCase().endsWith('.json')) {
          tasksPath = path;
        }
      }

      if (projectsPath == null || tasksPath == null) {
        return null;
      }

      final projects = await _importProjects(projectsPath);
      final taskList = await _importTasks(tasksPath);
      final existingTasksById = {
        for (final task in taskRepository.getAllTasks()) task.id: task,
      };

      for (final project in projects) {
        final existing = await projectRepository.getProjectById(project.id);
        originalProjectsById[project.id] = existing;
        await projectRepository.addProject(project);
        importedProjectIds.add(project.id);
      }

      for (final task in taskList) {
        final existing = existingTasksById[task.id];
        if (existing != null) {
          originalTasksById[task.id] = existing;
        }
        await taskRepository.upsertTask(task);
        importedTaskIds.add(task.id);
      }

      final groupedTitles = <String, List<String>>{};
      for (final task in taskList) {
        groupedTitles.putIfAbsent(task.projectId, () => []).add(task.title);
      }

      for (final entry in groupedTitles.entries) {
        await projectRepository.updateTasks(entry.key, entry.value);
      }

      return ProjectTransferResult(
        projectsPath: projectsPath,
        tasksPath: tasksPath,
      );
    } catch (e) {
      await _rollbackImport(
        projectRepository: projectRepository,
        taskRepository: taskRepository,
        originalProjectsById: originalProjectsById,
        originalTasksById: originalTasksById,
        importedProjectIds: importedProjectIds,
        importedTaskIds: importedTaskIds,
      );
      throw 'Import error: $e';
    }
  }

  Future<void> _rollbackImport({
    required IProjectRepository projectRepository,
    required TaskRepository taskRepository,
    required Map<String, ProjectModel?> originalProjectsById,
    required Map<String, Task?> originalTasksById,
    required List<String> importedProjectIds,
    required List<String> importedTaskIds,
  }) async {
    try {
      for (final taskId in importedTaskIds) {
        final original = originalTasksById[taskId];
        if (original != null) {
          await taskRepository.upsertTask(original);
        } else {
          await taskRepository.deleteTask(taskId);
        }
      }

      for (final projectId in importedProjectIds) {
        final original = originalProjectsById[projectId];
        if (original != null) {
          await projectRepository.addProject(original);
        } else {
          await projectRepository.deleteProject(projectId);
        }
      }
    } catch (_) {
      // Best-effort rollback; avoid masking original import error.
    }
  }

  String _buildProjectsCsv(List<ProjectModel> projects) {
    final buffer = StringBuffer();
    buffer.writeln('id,name,progress,status,description,directoryPath');
    for (final project in projects) {
      final row = [
        _toCsvValue(project.id),
        _toCsvValue(project.name),
        project.progress.toString(),
        _toCsvValue(project.status),
        _toCsvValue(project.description ?? ''),
        _toCsvValue(project.directoryPath ?? ''),
      ].join(',');
      buffer.writeln(row);
    }
    return buffer.toString();
  }

  List<ProjectModel> _parseProjectsCsv(String csv) {
    final lines = const LineSplitter().convert(csv);
    if (lines.isEmpty) {
      return [];
    }

    final rows = lines.skip(1);
    final projects = <ProjectModel>[];
    for (final line in rows) {
      if (line.trim().isEmpty) {
        continue;
      }
      final values = _parseCsvLine(line);
      if (values.length < 6) {
        throw 'Invalid CSV row format.';
      }
      final progress = double.tryParse(values[2]);
      if (progress == null) {
        throw 'Invalid progress value.';
      }
      projects.add(
        ProjectModel(
          id: values[0],
          name: values[1],
          progress: progress,
          status: values[3],
          description: values[4].isEmpty ? null : values[4],
          directoryPath: values[5].isEmpty ? null : values[5],
        ),
      );
    }
    return projects;
  }

  List<Task> _parseTasksJson(String jsonText) {
    final decoded = jsonDecode(jsonText);
    if (decoded is! List) {
      throw 'Invalid JSON format.';
    }
    return decoded
        .whereType<Map>()
        .map((entry) => Task.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
  }

  Map<String, dynamic> _taskToJson(Task task) {
    return task.toJson();
  }

  Future<List<ProjectModel>> _importProjects(String projectsPath) async {
    try {
      final content = await File(projectsPath).readAsString();
      final lines = const LineSplitter().convert(content);
      if (lines.isEmpty) {
        throw 'Invalid CSV format.';
      }

      const expectedHeader = 'id,name,progress,status,description,directoryPath';
      final header = lines.first.trim();
      if (header != expectedHeader) {
        throw 'Invalid CSV header.';
      }

      final projects = _parseProjectsCsv(content);
      final seenIds = <String>{};
      for (final project in projects) {
        final id = project.id.trim();
        if (id.isEmpty) {
          throw 'Invalid project ID.';
        }
        if (seenIds.contains(id)) {
          throw 'Duplicate project ID: $id';
        }
        if (project.name.trim().isEmpty) {
          throw 'Invalid project name.';
        }
        if (project.status.trim().isEmpty) {
          throw 'Invalid project status.';
        }
        if (project.progress < 0 || project.progress > 1) {
          throw 'Invalid project progress for $id.';
        }
        seenIds.add(id);
      }

      return projects;
    } catch (e) {
      throw 'Import error: $e';
    }
  }

  Future<List<Task>> _importTasks(String tasksPath) async {
    try {
      final content = await File(tasksPath).readAsString();
      final tasks = _parseTasksJson(content);
      final seenIds = <String>{};
      for (final task in tasks) {
        final id = task.id.trim();
        if (id.isEmpty) {
          throw 'Invalid task ID.';
        }
        if (seenIds.contains(id)) {
          throw 'Duplicate task ID: $id';
        }
        if (task.projectId.trim().isEmpty) {
          throw 'Invalid task project ID.';
        }
        if (task.title.trim().isEmpty) {
          throw 'Invalid task title.';
        }
        seenIds.add(id);
      }
      return tasks;
    } catch (e) {
      throw 'Import error: $e';
    }
  }

  String _toCsvValue(String value) {
    final needsQuotes = value.contains(',') || value.contains('"') || value.contains('\n');
    var escaped = value.replaceAll('"', '""');
    if (needsQuotes) {
      escaped = '"$escaped"';
    }
    return escaped;
  }

  List<String> _parseCsvLine(String line) {
    final values = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        final nextIsQuote = i + 1 < line.length && line[i + 1] == '"';
        if (nextIsQuote) {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        values.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    values.add(buffer.toString());
    return values;
  }

  String _encryptText(String plainText, String password) {
    final key = _deriveKey(password);
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    final iv = IV.fromSecureRandom(12);
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    final combined = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
    return base64Encode(combined);
  }

  Key _deriveKey(String password) {
    final digest = sha256.convert(utf8.encode(password));
    return Key(Uint8List.fromList(digest.bytes));
  }
}
