library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/models/project_model.dart';
import 'package:pma_core/models/task_model.dart';
import 'package:pma_core/providers/project/project_providers.dart';
import 'package:pma_core/providers/task/task_providers.dart';

import '../services/mirror_session_bootstrap_orchestration_service.dart';
import '../services/mirror_session_persistence_service.dart';
import '../services/mirror_session_state_mutation_service.dart';
import '../services/mirror_session_state_service.dart';
import '../../features/mirror/services/mirror_draft_cache_service.dart';
import 'mirror_mode_controller_provider.dart';
import 'mirror_session_bootstrap.dart';

const _mirrorSessionStateService = MirrorSessionStateService();
const _mirrorSessionBootstrapOrchestrationService =
  MirrorSessionBootstrapOrchestrationService();
const _mirrorSessionPersistenceService = MirrorSessionPersistenceService();
const _mirrorSessionStateMutationService = MirrorSessionStateMutationService();

final mirrorDraftCacheServiceProvider = Provider<MirrorDraftCacheService>((ref) {
  return const MirrorDraftCacheService();
});

final mirrorSessionRepositoryBootstrapTimeoutProvider =
    Provider<Duration>((ref) {
  return const Duration(seconds: 3);
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
    this.bootstrapReasonCode,
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
  final String? bootstrapReasonCode;

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
    String? bootstrapReasonCode,
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
      bootstrapReasonCode: bootstrapReasonCode ?? this.bootstrapReasonCode,
    );
  }

  static MirrorSessionState initial({
    required String projectId,
    required String taskId,
  }) {
    final baseline = _mirrorSessionStateService.buildBaseline(
      projectId: projectId,
      taskId: taskId,
    );

    return MirrorSessionState(
      projectId: projectId,
      taskId: taskId,
      files: Map<String, String>.from(baseline.files),
      selectedFile: baseline.selectedFile,
      liveOutput: <String>[],
      terminalLog: <String>[],
      contextFingerprint: baseline.contextFingerprint,
      contextVersion: baseline.contextVersion,
      compileFingerprint: null,
      compileServerVersionToken: null,
      bootstrapPhase: MirrorSessionBootstrapPhase.initial,
      bootstrapSource: 'baseline',
      bootstrapReasonCode: null,
    );
  }
}

/// Riverpod notifier that manages the in-editor Mirror session lifecycle.
///
/// Ownership axes (do not mix):
///  1. **Bootstrap orchestration** — `_bootstrapSession` reads draft-cache and
///     repository FutureProviders concurrently, applies a repository-load
///     timeout for responsiveness, then delegates the merge decision to the
///     pure `resolveMirrorSessionBootstrap()` function.
///  2. **In-session state mutations** — selectFile, updateSelectedFileContent,
///     upsertFileContent, appendLiveOutput, appendTerminalLine, and
///     setCompileValidationArtifacts each call `_replaceState` which bumps
///     `_stateGeneration` so stale persist work can be detected.
///  3. **Draft persistence lifecycle** — every mutation schedules a debounced
///     write; explicit checkpoints (persistOnRunStart, persistOnApply,
///     persistOnRouteExit) flush immediately. The dispose callback flushes
///     using a captured service reference to remain safe after `ref` teardown.
///  4. **Race-condition generation guards** — `_bootstrapGeneration` prevents
///     stale async bootstrap results from overwriting newer state; `_stateGeneration`
///     ensures a busy-write retry uses the latest snapshot.
class MirrorSessionNotifier
    extends AutoDisposeFamilyNotifier<MirrorSessionState, String> {
  static const Duration _draftPersistDebounce = Duration(milliseconds: 500);

  int _bootstrapGeneration = 0;
  int _stateGeneration = 0;
  bool _bootstrapStarted = false;
  bool _persistInFlight = false;
  Timer? _draftPersistTimer;
  String? _activeSessionKey;
  String _lastMode = 'private';
  String? _lastOfflineWarningKey;

  @override
  MirrorSessionState build(String sessionKey) {
    _activeSessionKey = sessionKey;
    _lastMode = ref.read(mirrorResolvedModeProvider);
    _lastOfflineWarningKey = ref.read(mirrorResolvedOfflineWarningProvider);
    final draftCacheService = ref.read(mirrorDraftCacheServiceProvider);

    ref.listen<String>(mirrorResolvedModeProvider, (_, String next) {
      _lastMode = next;
    });
    ref.listen<String?>(mirrorResolvedOfflineWarningProvider, (_, String? next) {
      _lastOfflineWarningKey = next;
    });

    ref.onDispose(() {
      _draftPersistTimer?.cancel();
      _draftPersistTimer = null;
      final activeKey = _activeSessionKey;
      if (activeKey != null && state.files.isNotEmpty) {
        unawaited(
          _persistDraftNow(
            activeKey,
            generation: _stateGeneration,
            draftCacheServiceOverride: draftCacheService,
          ),
        );
      }
    });

    if (!_bootstrapStarted) {
      _bootstrapStarted = true;
      unawaited(Future<void>.microtask(() => _bootstrapSession(sessionKey)));
    }

    final keyParts =
        _mirrorSessionBootstrapOrchestrationService.parseSessionKey(sessionKey);
    return MirrorSessionState.initial(
      projectId: keyParts.projectId,
      taskId: keyParts.taskId,
    );
  }

  Future<void> _bootstrapSession(String sessionKey) async {
    final generation = ++_bootstrapGeneration;
    final keyParts =
        _mirrorSessionBootstrapOrchestrationService.parseSessionKey(sessionKey);
    final baseline = MirrorSessionState.initial(
      projectId: keyParts.projectId,
      taskId: keyParts.taskId,
    );

    _replaceState(
      baseline.copyWith(
        bootstrapPhase: MirrorSessionBootstrapPhase.repositoryLoading,
        bootstrapSource: 'baseline',
        bootstrapReasonCode: null,
      ),
    );

    final draftFuture =
        ref.read(mirrorSessionDraftBootstrapProvider(sessionKey).future);
    final repositoryFuture =
        ref.read(mirrorSessionRepositoryBootstrapProvider(sessionKey).future);
    final repositoryTimeout = ref.read(
      mirrorSessionRepositoryBootstrapTimeoutProvider,
    );

    final loaded = await _mirrorSessionBootstrapOrchestrationService
        .loadBootstrapData(
      draftFuture: draftFuture,
      repositoryFuture: repositoryFuture,
      repositoryTimeout: repositoryTimeout,
    );
    if (!_isCurrentBootstrap(generation, sessionKey)) {
      return;
    }
    final draft = loaded.draft;
    final repository = loaded.repository;

    _replaceState(
      state.copyWith(
        bootstrapPhase: MirrorSessionBootstrapPhase.merging,
        bootstrapSource: _mirrorSessionBootstrapOrchestrationService
            .resolveMergingBootstrapSource(draft),
      ),
    );

    final bootstrapAssembly =
        _mirrorSessionBootstrapOrchestrationService.buildFinalAssembly(
      baselineFiles: baseline.files,
      baselineSelectedFile: baseline.selectedFile,
      baselineContextVersion:
          baseline.contextVersion ?? mirrorDraftContextVersion,
      draft: draft,
      repository: repository,
    );

    _replaceState(
      baseline.copyWith(
        files: bootstrapAssembly.files,
        selectedFile: bootstrapAssembly.selectedFile,
        contextFingerprint: bootstrapAssembly.contextFingerprint,
        contextVersion: bootstrapAssembly.contextVersion,
        terminalLog: bootstrapAssembly.terminalLog,
        bootstrapPhase: bootstrapAssembly.phase,
        bootstrapSource: bootstrapAssembly.source,
        bootstrapReasonCode: bootstrapAssembly.reasonCode,
      ),
    );
  }

  void selectFile(String path) {
    final next = _mirrorSessionStateMutationService.selectFile(state, path);
    if (next == null) {
      return;
    }
    _replaceState(next);
    _scheduleDraftPersist();
  }

  void updateSelectedFileContent(String content) {
    _replaceState(
      _mirrorSessionStateMutationService.updateSelectedFileContent(
        state,
        content,
      ),
    );
    _scheduleDraftPersist();
  }

  void upsertFileContent({required String path, required String content}) {
    _replaceState(
      _mirrorSessionStateMutationService.upsertFileContent(
        state,
        path: path,
        content: content,
      ),
    );
    _scheduleDraftPersist();
  }

  void appendLiveOutput(List<String> lines, {int maxLines = 500}) {
    final next = _mirrorSessionStateMutationService.appendLiveOutput(
      state,
      lines,
      maxLines: maxLines,
    );
    if (next == null) {
      return;
    }
    _replaceState(next);
  }

  void appendTerminalLine(String line, {int maxLines = 1000}) {
    final next = _mirrorSessionStateMutationService.appendTerminalLine(
      state,
      line,
      maxLines: maxLines,
    );
    if (next == null) {
      return;
    }
    _replaceState(next);
  }

  void setCompileValidationArtifacts({
    required String compileFingerprint,
    String? serverVersionToken,
  }) {
    final next = _mirrorSessionStateMutationService.setCompileValidationArtifacts(
      state,
      compileFingerprint: compileFingerprint,
      serverVersionToken: serverVersionToken,
    );
    if (next == null) {
      return;
    }
    _replaceState(next);
    _scheduleDraftPersist();
  }

  Future<void> persistOnRunStart() async {
    await _persistCheckpointNow();
  }

  Future<void> persistOnApply() async {
    await _persistCheckpointNow();
  }

  Future<void> persistOnRouteExit() async {
    await _persistCheckpointNow();
  }

  Future<void> _persistCheckpointNow() async {
    final sessionKey = _activeSessionKey;
    if (sessionKey == null || sessionKey.isEmpty) {
      return;
    }
    _draftPersistTimer?.cancel();
    await _persistDraftNow(sessionKey, generation: _stateGeneration);
  }

  void _scheduleDraftPersist() {
    final sessionKey = _activeSessionKey;
    if (sessionKey == null || sessionKey.isEmpty) {
      return;
    }

    final generation = _stateGeneration;
    _draftPersistTimer?.cancel();
    _draftPersistTimer = Timer(_draftPersistDebounce, () {
      unawaited(_persistDraftNow(sessionKey, generation: generation));
    });
  }

  Future<void> _persistDraftNow(
    String sessionKey, {
    required int generation,
    MirrorDraftCacheService? draftCacheServiceOverride,
  }) async {
    if (!_isCurrentPersistTarget(generation, sessionKey)) {
      return;
    }

    if (_persistInFlight) {
      return;
    }

    _persistInFlight = true;

    final snapshot = _mirrorSessionPersistenceService.buildPersistSnapshot(
      sessionKey: sessionKey,
      files: state.files,
      selectedFile: state.selectedFile,
      mode: _lastMode,
      offlineWarningKey: _lastOfflineWarningKey,
      contextFingerprint: state.contextFingerprint,
      contextVersion: state.contextVersion,
    );
    if (snapshot == null) {
      _persistInFlight = false;
      return;
    }

    try {
      final MirrorDraftCacheService draftCacheService =
          draftCacheServiceOverride ?? ref.read(mirrorDraftCacheServiceProvider);
      await draftCacheService.writeDraft(
        sessionKey: snapshot.sessionKey,
        files: snapshot.files,
        selectedFile: snapshot.selectedFile,
        mode: snapshot.mode,
        offlineWarningKey: snapshot.offlineWarningKey,
        contextFingerprint: snapshot.contextFingerprint,
        contextVersion: snapshot.contextVersion,
      );
    } catch (_) {
      // Keep editing responsive when draft persistence is unavailable.
    } finally {
      _persistInFlight = false;

      final latestSessionKey = _activeSessionKey;
      final shouldReplayPersist =
          _mirrorSessionPersistenceService.shouldReplayPersist(
        latestSessionKey: latestSessionKey,
        sessionKey: sessionKey,
        generation: generation,
        currentGeneration: _stateGeneration,
      );
      if (shouldReplayPersist) {
        unawaited(
          _persistDraftNow(
            latestSessionKey!,
            generation: _stateGeneration,
            draftCacheServiceOverride: draftCacheServiceOverride,
          ),
        );
      }
    }
  }

  bool _isCurrentBootstrap(int generation, String sessionKey) {
    return generation == _bootstrapGeneration && _activeSessionKey == sessionKey;
  }

  bool _isCurrentPersistTarget(int generation, String sessionKey) {
    return generation == _stateGeneration && _activeSessionKey == sessionKey;
  }

  void _replaceState(MirrorSessionState next) {
    state = next;
    _stateGeneration += 1;
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
      contextVersion: snapshot.contextVersion ?? mirrorDraftContextVersion,
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
      reasonCode: MirrorSessionBootstrapReasonCodes.repositoryError,
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
