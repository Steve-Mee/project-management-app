library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/models/project_model.dart';
import 'package:pma_core/models/task_model.dart';
import 'package:pma_core/providers/project/project_providers.dart';
import 'package:pma_core/providers/task/task_providers.dart';

class MirrorSessionState {
  const MirrorSessionState({
    required this.projectId,
    required this.taskId,
    required this.files,
    required this.selectedFile,
    required this.liveOutput,
    required this.terminalLog,
  });

  final String projectId;
  final String taskId;
  final Map<String, String> files;
  final String selectedFile;
  final List<String> liveOutput;
  final List<String> terminalLog;

  MirrorSessionState copyWith({
    String? projectId,
    String? taskId,
    Map<String, String>? files,
    String? selectedFile,
    List<String>? liveOutput,
    List<String>? terminalLog,
  }) {
    return MirrorSessionState(
      projectId: projectId ?? this.projectId,
      taskId: taskId ?? this.taskId,
      files: files ?? this.files,
      selectedFile: selectedFile ?? this.selectedFile,
      liveOutput: liveOutput ?? this.liveOutput,
      terminalLog: terminalLog ?? this.terminalLog,
    );
  }

  static MirrorSessionState initial({
    required String projectId,
    required String taskId,
  }) {
    final defaultFiles = _defaultFiles(projectId: projectId, taskId: taskId);

    return MirrorSessionState(
      projectId: projectId,
      taskId: taskId,
      files: Map<String, String>.from(defaultFiles),
      selectedFile: 'lib/main.dart',
      liveOutput: <String>[],
      terminalLog: <String>[],
    );
  }

  static Map<String, String> _defaultFiles({
    required String projectId,
    required String taskId,
  }) {
    return <String, String>{
      'README.md': '# Mirror Session\n\nProject: $projectId\nTask: $taskId\n',
      'lib/main.dart': "void main() {\n  print('Mirror session: $projectId::$taskId');\n}\n",
    };
  }
}

class MirrorSessionNotifier
  extends AutoDisposeFamilyNotifier<MirrorSessionState, String> {
  bool _cacheHydrated = false;

  @override
  MirrorSessionState build(String sessionKey) {
    if (!_cacheHydrated) {
      _cacheHydrated = true;
      unawaited(_hydrateFromRepository(sessionKey));
    }

    final parts = sessionKey.split('::');
    final projectId = parts.isNotEmpty ? parts[0] : '';
    final taskId = parts.length > 1 ? parts[1] : '';
    return MirrorSessionState.initial(projectId: projectId, taskId: taskId);
  }

  Future<void> _hydrateFromRepository(String sessionKey) async {
    final parts = sessionKey.split('::');
    final projectId = parts.isNotEmpty ? parts[0] : '';
    final taskId = parts.length > 1 ? parts[1] : '';

    if (projectId.isEmpty) {
      return;
    }

    try {
      final project = await ref.read(projectByIdProvider(projectId).future);
      final taskRepository = await ref.read(taskRepositoryProvider.future);
      final tasks = taskRepository.getTasksForProject(projectId);

      final selectedTask = _findTaskById(tasks, taskId);
      final files = _buildContextFiles(
        project: project,
        tasks: tasks,
        selectedTask: selectedTask,
      );

      if (files.isEmpty) {
        return;
      }

      final preferred = selectedTask != null
          ? 'context/task_${selectedTask.id}.md'
          : 'README.md';
      final selectedFile = files.containsKey(preferred)
          ? preferred
          : files.keys.first;

      state = state.copyWith(
        projectId: projectId,
        taskId: taskId,
        files: files,
        selectedFile: selectedFile,
      );

      appendTerminalLine(
        'Mirror session loaded from repository context for project $projectId.',
      );
    } catch (error) {
      appendTerminalLine(
        'Mirror session fallback active: unable to load repository context ($error).',
      );
    }
  }

  Task? _findTaskById(List<Task> tasks, String taskId) {
    if (taskId.isEmpty) {
      return null;
    }

    for (final task in tasks) {
      if (task.id == taskId) {
        return task;
      }
    }
    return null;
  }

  Map<String, String> _buildContextFiles({
    required ProjectModel project,
    required List<Task> tasks,
    required Task? selectedTask,
  }) {
    final taskSummaries = tasks
        .map(
          (task) => '- [${task.status.name}] ${task.title} (${task.id})',
        )
        .join('\n');

    final selectedTaskDescription = selectedTask == null
        ? 'No task found for the current taskId.'
        : selectedTask.description.trim().isEmpty
            ? 'No task description available.'
            : selectedTask.description.trim();

    final files = <String, String>{
      'README.md': [
        '# ${project.name}',
        '',
        '## Project Context',
        'Project ID: ${project.id}',
        'Status: ${project.status}',
        if ((project.description ?? '').trim().isNotEmpty)
          'Description: ${project.description!.trim()}',
        '',
        '## Task Overview',
        if (tasks.isEmpty) '- No tasks found for this project.' else taskSummaries,
      ].join('\n'),
      'context/project.json': const JsonEncoder.withIndent('  ').convert(
        project.toJson(),
      ),
      'context/tasks.json': const JsonEncoder.withIndent('  ').convert(
        tasks.map((task) => task.toJson()).toList(),
      ),
      'lib/main.dart': [
        "import 'dart:developer' as dev;",
        '',
        'void main() {',
        "  dev.log('Mirror project: ${project.id}');",
        selectedTask == null
            ? "  dev.log('No selected task in session.');"
            : "  dev.log('Selected task: ${selectedTask.id} - ${selectedTask.title}');",
        '}',
      ].join('\n'),
      'context/current_task.md': [
        '# Current Task',
        '',
        selectedTask == null
            ? 'Task ID in session: ${state.taskId}'
            : 'Task ID: ${selectedTask.id}',
        selectedTask == null
            ? ''
            : 'Title: ${selectedTask.title}\nStatus: ${selectedTask.status.name}',
        '',
        selectedTaskDescription,
      ].join('\n'),
    };

    if (selectedTask != null) {
      files['context/task_${selectedTask.id}.md'] = [
        '# ${selectedTask.title}',
        '',
        'Task ID: ${selectedTask.id}',
        'Project ID: ${selectedTask.projectId}',
        'Status: ${selectedTask.status.name}',
        '',
        selectedTaskDescription,
      ].join('\n');
    }

    final planJson = project.planJson?.trim();
    if (planJson != null && planJson.isNotEmpty) {
      files['context/project_plan.json'] = planJson;
    }

    return files;
  }

  void selectFile(String path) {
    if (!state.files.containsKey(path)) {
      return;
    }
    state = state.copyWith(selectedFile: path);
  }

  void updateSelectedFileContent(String content) {
    final updatedFiles = Map<String, String>.from(state.files);
    updatedFiles[state.selectedFile] = content;
    state = state.copyWith(files: updatedFiles);
  }

  void upsertFileContent({required String path, required String content}) {
    final updatedFiles = Map<String, String>.from(state.files);
    updatedFiles[path] = content;
    state = state.copyWith(files: updatedFiles);
  }

  void appendLiveOutput(List<String> lines, {int maxLines = 500}) {
    if (lines.isEmpty) {
      return;
    }
    final merged = <String>[...state.liveOutput, ...lines];
    final capped = merged.length <= maxLines
        ? merged
        : merged.sublist(merged.length - maxLines);
    state = state.copyWith(liveOutput: capped);
  }

  void appendTerminalLine(String line, {int maxLines = 1000}) {
    if (line.trim().isEmpty) {
      return;
    }
    final merged = <String>[...state.terminalLog, line];
    final capped = merged.length <= maxLines
        ? merged
        : merged.sublist(merged.length - maxLines);
    state = state.copyWith(terminalLog: capped);
  }
}

final mirrorSessionProvider = NotifierProvider.autoDispose.family<
  MirrorSessionNotifier,
  MirrorSessionState,
  String
>(MirrorSessionNotifier.new);
