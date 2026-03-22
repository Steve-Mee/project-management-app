library;

import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/models/project_model.dart';
import 'package:pma_core/models/task_model.dart';
import 'package:pma_core/providers/project/project_providers.dart';
import 'package:pma_core/providers/task/task_providers.dart';

import '../../features/mirror/services/mirror_draft_cache_service.dart';
import 'mirror_provider.dart';
import 'mirror_session_bootstrap.dart';

final mirrorDraftCacheServiceProvider = Provider<MirrorDraftCacheService>((ref) {
  return const MirrorDraftCacheService();
});

final mirrorSessionRepositoryBootstrapTimeoutProvider =
    Provider<Duration>((ref) {
  return const Duration(milliseconds: 1500);
});

class MirrorSessionState {
  const MirrorSessionState({
    required this.projectId,
    required this.taskId,
    required this.files,
    required this.selectedFile,
    required this.liveOutput,
    required this.terminalLog,
    this.contextFingerprint,
    this.contextVersion,
    this.compileFingerprint,
    this.compileServerVersionToken,
    this.bootstrapPhase = MirrorSessionBootstrapPhase.initial,
    this.bootstrapSource = 'baseline',
  });

  final String projectId;
  final String taskId;
  final Map<String, String> files;
  final String selectedFile;
  final List<String> liveOutput;
  final List<String> terminalLog;
  final String? contextFingerprint;
  final int? contextVersion;
  final String? compileFingerprint;
  final String? compileServerVersionToken;
  final MirrorSessionBootstrapPhase bootstrapPhase;
  final String bootstrapSource;

  MirrorSessionState copyWith({
    String? projectId,
    String? taskId,
    Map<String, String>? files,
    String? selectedFile,
    List<String>? liveOutput,
    List<String>? terminalLog,
    String? contextFingerprint,
    int? contextVersion,
    String? compileFingerprint,
    String? compileServerVersionToken,
    MirrorSessionBootstrapPhase? bootstrapPhase,
    String? bootstrapSource,
  }) {
    return MirrorSessionState(
      projectId: projectId ?? this.projectId,
      taskId: taskId ?? this.taskId,
      files: files ?? this.files,
      selectedFile: selectedFile ?? this.selectedFile,
      liveOutput: liveOutput ?? this.liveOutput,
      terminalLog: terminalLog ?? this.terminalLog,
      contextFingerprint: contextFingerprint ?? this.contextFingerprint,
      contextVersion: contextVersion ?? this.contextVersion,
      compileFingerprint: compileFingerprint ?? this.compileFingerprint,
      compileServerVersionToken:
          compileServerVersionToken ?? this.compileServerVersionToken,
      bootstrapPhase: bootstrapPhase ?? this.bootstrapPhase,
      bootstrapSource: bootstrapSource ?? this.bootstrapSource,
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
      contextFingerprint: _computeContextFingerprint(defaultFiles),
      contextVersion: _draftContextVersion,
      compileFingerprint: null,
      compileServerVersionToken: null,
      bootstrapPhase: MirrorSessionBootstrapPhase.initial,
      bootstrapSource: 'baseline',
    );
  }

  static Map<String, String> _defaultFiles({
    required String projectId,
    required String taskId,
  }) {
    return <String, String>{
      'README.md': '# Mirror Session\n\nProject: $projectId\nTask: $taskId\n',
      'lib/main.dart':
          "void main() {\n  print('Mirror session: $projectId::$taskId');\n}\n",
    };
  }
}

const int _draftContextVersion = 1;

String _computeContextFingerprint(Map<String, String> files) {
  final entries = files.entries.toList(growable: false)
    ..sort((a, b) => a.key.compareTo(b.key));

  final buffer = StringBuffer();
  for (final entry in entries) {
    buffer
      ..write(entry.key)
      ..write('::')
      ..write(entry.value)
      ..write('\n');
  }

  return sha256.convert(utf8.encode(buffer.toString())).toString();
}

class MirrorSessionNotifier
    extends AutoDisposeFamilyNotifier<MirrorSessionState, String> {
  static const Duration _draftPersistDebounce = Duration(milliseconds: 500);

  int _bootstrapGeneration = 0;
  bool _bootstrapStarted = false;
  Timer? _draftPersistTimer;
  String? _activeSessionKey;
  String _lastMode = 'private';
  String? _lastOfflineWarningKey;

  @override
  MirrorSessionState build(String sessionKey) {
    _activeSessionKey = sessionKey;
    _lastMode = ref.read(mirrorModeProvider);
    _lastOfflineWarningKey = ref.read(mirrorOfflineWarningProvider);
    final draftCacheService = ref.read(mirrorDraftCacheServiceProvider);

    ref.listen<String>(mirrorModeProvider, (_, String next) {
      _lastMode = next;
    });
    ref.listen<String?>(mirrorOfflineWarningProvider, (_, String? next) {
      _lastOfflineWarningKey = next;
    });

    ref.onDispose(() {
      _draftPersistTimer?.cancel();
      _draftPersistTimer = null;
      final activeKey = _activeSessionKey;
      if (activeKey != null && state.files.isNotEmpty) {
        final files = Map<String, String>.of(state.files);
        final selectedFile = state.selectedFile;
        final contextFingerprint =
            state.contextFingerprint ?? _computeContextFingerprint(files);
        final contextVersion = state.contextVersion ?? _draftContextVersion;
        unawaited(draftCacheService.writeDraft(
          sessionKey: activeKey,
          files: files,
          selectedFile: selectedFile,
          mode: _lastMode,
          offlineWarningKey: _lastOfflineWarningKey,
          contextFingerprint: contextFingerprint,
          contextVersion: contextVersion,
        ));
      }
    });

    if (!_bootstrapStarted) {
      _bootstrapStarted = true;
      unawaited(_bootstrapSession(sessionKey));
    }

    final parts = sessionKey.split('::');
    final projectId = parts.isNotEmpty ? parts[0] : '';
    final taskId = parts.length > 1 ? parts[1] : '';
    return MirrorSessionState.initial(projectId: projectId, taskId: taskId);
  }

  Future<void> _bootstrapSession(String sessionKey) async {
    final generation = ++_bootstrapGeneration;
    final parts = sessionKey.split('::');
    final projectId = parts.isNotEmpty ? parts[0] : '';
    final taskId = parts.length > 1 ? parts[1] : '';
    final baseline = MirrorSessionState.initial(
      projectId: projectId,
      taskId: taskId,
    );

    final draftFuture =
        ref.read(mirrorSessionDraftBootstrapProvider(sessionKey).future);
    final repositoryFuture =
        ref.read(mirrorSessionRepositoryBootstrapProvider(sessionKey).future);
    final repositoryTimeout =
      ref.read(mirrorSessionRepositoryBootstrapTimeoutProvider);

    final draft = await draftFuture;
    if (!_isCurrentBootstrap(generation, sessionKey)) {
      return;
    }

    final repository = await repositoryFuture.timeout(
      repositoryTimeout,
      onTimeout: () => const MirrorSessionBootstrapRepository(
        files: <String, String>{},
        preferredSelectedFile: '',
        errorMessage: MirrorSessionBootstrapMessages.repositoryTimeout,
      ),
    );
    if (!_isCurrentBootstrap(generation, sessionKey)) {
      return;
    }

    final bootstrap = resolveMirrorSessionBootstrap(
      baselineFiles: baseline.files,
      baselineSelectedFile: baseline.selectedFile,
      baselineContextVersion: baseline.contextVersion ?? _draftContextVersion,
      draft: draft,
      repository: repository,
    );

    state = baseline.copyWith(
      files: bootstrap.files,
      selectedFile: bootstrap.selectedFile,
      contextFingerprint: _computeContextFingerprint(bootstrap.files),
      contextVersion: bootstrap.contextVersion,
      terminalLog: bootstrap.terminalLines,
      bootstrapPhase: bootstrap.phase,
      bootstrapSource: bootstrap.sourceSummary,
    );
  }

  void selectFile(String path) {
    if (!state.files.containsKey(path)) {
      return;
    }
    state = state.copyWith(selectedFile: path);
    _scheduleDraftPersist();
  }

  void updateSelectedFileContent(String content) {
    final updatedFiles = Map<String, String>.from(state.files);
    updatedFiles[state.selectedFile] = content;
    state = state.copyWith(
      files: updatedFiles,
      contextFingerprint: _computeContextFingerprint(updatedFiles),
      contextVersion: _draftContextVersion,
    );
    _scheduleDraftPersist();
  }

  void upsertFileContent({required String path, required String content}) {
    final updatedFiles = Map<String, String>.from(state.files);
    updatedFiles[path] = content;
    state = state.copyWith(
      files: updatedFiles,
      contextFingerprint: _computeContextFingerprint(updatedFiles),
      contextVersion: _draftContextVersion,
    );
    _scheduleDraftPersist();
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

  void setCompileValidationArtifacts({
    required String compileFingerprint,
    String? serverVersionToken,
  }) {
    final normalizedFingerprint = compileFingerprint.trim();
    if (normalizedFingerprint.isEmpty) {
      return;
    }

    final normalizedToken = serverVersionToken?.trim();
    state = state.copyWith(
      compileFingerprint: normalizedFingerprint,
      compileServerVersionToken:
          (normalizedToken == null || normalizedToken.isEmpty)
              ? null
              : normalizedToken,
    );
    _scheduleDraftPersist();
  }

  void _scheduleDraftPersist() {
    final sessionKey = _activeSessionKey;
    if (sessionKey == null || sessionKey.isEmpty) {
      return;
    }

    _draftPersistTimer?.cancel();
    _draftPersistTimer = Timer(_draftPersistDebounce, () {
      unawaited(_persistDraftNow(sessionKey));
    });
  }

  Future<void> _persistDraftNow(String sessionKey) async {
    if (state.files.isEmpty) {
      return;
    }

    try {
      final draftCacheService = ref.read(mirrorDraftCacheServiceProvider);
      await draftCacheService.writeDraft(
        sessionKey: sessionKey,
        files: state.files,
        selectedFile: state.selectedFile,
        mode: _lastMode,
        offlineWarningKey: _lastOfflineWarningKey,
        contextFingerprint:
            state.contextFingerprint ?? _computeContextFingerprint(state.files),
        contextVersion: state.contextVersion ?? _draftContextVersion,
      );
    } catch (_) {
      // Keep editing responsive when draft persistence is unavailable.
    }
  }

  bool _isCurrentBootstrap(int generation, String sessionKey) {
    return generation == _bootstrapGeneration && _activeSessionKey == sessionKey;
  }
}

final mirrorSessionDraftBootstrapProvider =
    FutureProvider.autoDispose.family<MirrorSessionBootstrapDraft?, String>(
        (ref, sessionKey) async {
  try {
    final draftCacheService = ref.read(mirrorDraftCacheServiceProvider);
    final snapshot = await draftCacheService.readDraft(sessionKey);
    if (snapshot == null || snapshot.files.isEmpty) {
      return null;
    }

    final preferredSelected = snapshot.selectedFile;
    final selectedFile = snapshot.files.containsKey(preferredSelected)
        ? preferredSelected
        : snapshot.files.keys.first;

    return MirrorSessionBootstrapDraft(
      files: Map<String, String>.from(snapshot.files),
      selectedFile: selectedFile,
      contextVersion: snapshot.contextVersion ?? _draftContextVersion,
    );
  } catch (_) {
    return null;
  }
});

final mirrorSessionRepositoryBootstrapProvider = FutureProvider.autoDispose
    .family<MirrorSessionBootstrapRepository?, String>((ref, sessionKey) async {
  final parts = sessionKey.split('::');
  final projectId = parts.isNotEmpty ? parts[0] : '';
  final taskId = parts.length > 1 ? parts[1] : '';

  if (projectId.isEmpty) {
    return null;
  }

  try {
    final project = await ref.read(projectByIdProvider(projectId).future);
    final taskRepository = await ref.read(taskRepositoryProvider.future);
    final tasks = taskRepository.getTasksForProject(projectId);

    Task? selectedTask;
    if (taskId.isNotEmpty) {
      for (final task in tasks) {
        if (task.id == taskId) {
          selectedTask = task;
          break;
        }
      }
    }

    final files = _buildSessionContextFiles(
      project: project,
      tasks: tasks,
      selectedTask: selectedTask,
      taskId: taskId,
    );

    if (files.isEmpty) {
      return null;
    }

    final preferred =
        selectedTask != null ? 'context/task_${selectedTask.id}.md' : 'README.md';
    return MirrorSessionBootstrapRepository(
      files: files,
      preferredSelectedFile: preferred,
      infoMessage:
          'Mirror session loaded from repository context for project $projectId.',
    );
  } catch (error) {
    return MirrorSessionBootstrapRepository(
      files: const <String, String>{},
      preferredSelectedFile: '',
      errorMessage:
          'Mirror session fallback active: unable to load repository context ($error).',
    );
  }
});

Map<String, String> _buildSessionContextFiles({
  required ProjectModel project,
  required List<Task> tasks,
  required Task? selectedTask,
  required String taskId,
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
      if (tasks.isEmpty)
        '- No tasks found for this project.'
      else
        taskSummaries,
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
      selectedTask == null ? 'Task ID in session: $taskId' : 'Task ID: ${selectedTask.id}',
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

final mirrorSessionProvider = NotifierProvider.autoDispose
    .family<MirrorSessionNotifier, MirrorSessionState, String>(
        MirrorSessionNotifier.new);
