// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pma_core/providers/task/task_providers.dart';
import 'package:pma_core/services/app_logger.dart';

import '../../../core/providers/mirror_session_provider.dart';
import '../mirror_signed_inputs_backend.dart';
import 'mirror_outbox_replay_service.dart';

export 'mirror_outbox_replay_service.dart' show MirrorOutboxEntry;

class MirrorOrchestrationResult {
  const MirrorOrchestrationResult({
    required this.success,
    this.generateResult,
    this.compileResult,
    this.applyResult,
    this.error,
  });

  final bool success;
  final GenerateResult? generateResult;
  final CompileResult? compileResult;
  final ApplyResult? applyResult;
  final Object? error;
}

class MirrorOrchestratorService {
  MirrorOrchestratorService({
    required MirrorComputeBackend backend,
    this.maxRetries = 2,
    this.initialBackoff = const Duration(milliseconds: 250),
  }) : _backend = backend;

  final MirrorComputeBackend _backend;
  final int maxRetries;
  final Duration initialBackoff;
  MirrorOutboxReplayService? _outboxReplayService;
  final Random _jitterRandom = Random();

  List<MirrorOutboxEntry> get queuedOutboxEntries =>
      _outboxReplayService?.queuedEntries ?? const <MirrorOutboxEntry>[];

  Future<MirrorOrchestrationResult> runGenerateCompileApply({
    required WidgetRef ref,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    GenerateResult? generateResult;
    CompileResult? compileResult;
    ApplyResult? applyResult;

    try {
      await _replayQueuedWork(ref, reason: 'pre_orchestration');

      generateResult = await generate(
        ref: ref,
        sessionKey: sessionKey,
        prompt: prompt,
        context: context,
        mode: mode,
      );

      if (!generateResult.success) {
        return MirrorOrchestrationResult(
          success: false,
          generateResult: generateResult,
        );
      }

      compileResult = await compile(
        ref: ref,
        sessionKey: sessionKey,
        prompt: prompt,
        context: context,
        mode: mode,
      );

      if (!compileResult.success) {
        return MirrorOrchestrationResult(
          success: false,
          generateResult: generateResult,
          compileResult: compileResult,
        );
      }

      applyResult = await apply(
        ref: ref,
        sessionKey: sessionKey,
        prompt: prompt,
        context: context,
        mode: mode,
      );

      if (!applyResult.success) {
        return MirrorOrchestrationResult(
          success: false,
          generateResult: generateResult,
          compileResult: compileResult,
          applyResult: applyResult,
        );
      }

      _emitStatus(
        ref,
        sessionKey,
        terminalLine: 'Mirror orchestration completed successfully.',
      );

      return MirrorOrchestrationResult(
        success: true,
        generateResult: generateResult,
        compileResult: compileResult,
        applyResult: applyResult,
      );
    } catch (error) {
      _emitStatus(
        ref,
        sessionKey,
        terminalLine: 'Mirror orchestration failed: $error',
        liveLine: 'Error: $error',
      );
      return MirrorOrchestrationResult(
        success: false,
        generateResult: generateResult,
        compileResult: compileResult,
        applyResult: applyResult,
        error: error,
      );
    }
  }

  Future<GenerateResult> generate({
    required WidgetRef ref,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    await _replayQueuedWork(ref, reason: 'pre_generate');

    _emitStatus(
      ref,
      sessionKey,
      terminalLine: 'Mirror generate started ($mode mode).',
      liveLine: 'Generating...',
    );

    final result = await _withRetries<GenerateResult>(
      operationName: 'generate',
      ref: ref,
      sessionKey: sessionKey,
      operation: () {
        return _backend.generate(
          prompt: prompt,
          context: context,
          mode: mode,
        );
      },
      isSuccess: (GenerateResult value) => value.success,
      failureMessage: (GenerateResult value) =>
          value.message ?? value.diagnostics.join(' | '),
    );

    if (result.success) {
      _emitStatus(
        ref,
        sessionKey,
        terminalLine: 'Mirror generate completed successfully.',
        liveLine: 'Generate done.',
      );
    } else {
      await _replayService(ref).enqueue(
        operation: 'generate',
        sessionKey: sessionKey,
        prompt: prompt,
        context: context,
        mode: mode,
        lastError: result.message ?? result.diagnostics.join(' | '),
      );
      unawaited(
        _replayService(ref).replayDueEntries(
          reason: 'post_generate_failure',
          operationExecutor: _createOutboxExecutor(),
          onReplaySuccess: _onOutboxReplaySuccess(ref),
        ),
      );
      _emitStatus(
        ref,
        sessionKey,
        terminalLine:
            'Mirror generate failed: ${result.message ?? result.diagnostics.join(' | ')}',
        liveLine: 'Generate failed.',
      );
    }

    return result;
  }

  Future<CompileResult> compile({
    required WidgetRef ref,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    await _replayQueuedWork(ref, reason: 'pre_compile');

    _emitStatus(
      ref,
      sessionKey,
      terminalLine: 'Mirror compile started ($mode mode).',
      liveLine: 'Compiling...',
    );

    final result = await _withRetries<CompileResult>(
      operationName: 'compile',
      ref: ref,
      sessionKey: sessionKey,
      operation: () {
        return _backend.compile(
          prompt: prompt,
          context: context,
          mode: mode,
        );
      },
      isSuccess: (CompileResult value) => value.success,
      failureMessage: (CompileResult value) => value.errors.join(' | '),
    );

    if (result.success) {
      _emitStatus(
        ref,
        sessionKey,
        terminalLine: 'Mirror compile completed successfully.',
        liveLine: 'Compile done.',
      );
    } else {
      await _replayService(ref).enqueue(
        operation: 'compile',
        sessionKey: sessionKey,
        prompt: prompt,
        context: context,
        mode: mode,
        lastError: result.errors.join(' | '),
      );
      unawaited(
        _replayService(ref).replayDueEntries(
          reason: 'post_compile_failure',
          operationExecutor: _createOutboxExecutor(),
          onReplaySuccess: _onOutboxReplaySuccess(ref),
        ),
      );
      _emitStatus(
        ref,
        sessionKey,
        terminalLine: 'Mirror compile failed: ${result.errors.join(' | ')}',
        liveLine: 'Compile failed.',
      );
    }

    return result;
  }

  Future<ApplyResult> apply({
    required WidgetRef ref,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
    String? compileFingerprint,
  }) async {
    await _replayQueuedWork(ref, reason: 'pre_apply');

    _emitStatus(
      ref,
      sessionKey,
      terminalLine: 'Mirror apply started ($mode mode).',
      liveLine: 'Applying...',
    );

    final result = await _withRetries<ApplyResult>(
      operationName: 'apply',
      ref: ref,
      sessionKey: sessionKey,
      operation: () {
        return _backend.apply(
          prompt: prompt,
          context: context,
          mode: mode,
          compileFingerprint: compileFingerprint,
        );
      },
      isSuccess: (ApplyResult value) => value.success,
      failureMessage: (ApplyResult value) => value.message,
    );

    if (result.success) {
      await _refreshTaskAndSubTaskCaches(
        ref: ref,
        context: context,
        sessionKey: sessionKey,
      );
      final appliedFilesText = result.appliedFiles.isEmpty
          ? 'No files were reported as applied.'
          : 'Applied files: ${result.appliedFiles.join(', ')}';
      _emitStatus(
        ref,
        sessionKey,
        terminalLine: 'Mirror apply completed successfully. $appliedFilesText',
        liveLine: 'Apply done.',
      );
    } else {
      final queueContext =
          compileFingerprint == null || compileFingerprint.isEmpty
              ? context
              : context.copyWith(
                  metadata: context.metadata.copyWith(
                    compileFingerprint: compileFingerprint,
                  ),
                );
      await _replayService(ref).enqueue(
        operation: 'apply',
        sessionKey: sessionKey,
        prompt: prompt,
        context: queueContext,
        mode: mode,
        lastError: result.message,
      );
      unawaited(
        _replayService(ref).replayDueEntries(
          reason: 'post_apply_failure',
          operationExecutor: _createOutboxExecutor(),
          onReplaySuccess: _onOutboxReplaySuccess(ref),
        ),
      );
      _emitStatus(
        ref,
        sessionKey,
        terminalLine:
            'Mirror apply failed: ${result.message ?? 'unknown error'}',
        liveLine: 'Apply failed.',
      );
    }

    return result;
  }

  Future<void> _refreshTaskAndSubTaskCaches({
    required WidgetRef ref,
    required ProjectContext context,
    required String sessionKey,
  }) async {
    final parts = sessionKey.split('::');
    final projectId = context.projectId.isNotEmpty
        ? context.projectId
        : (parts.isNotEmpty ? parts.first : '');
    final taskId = context.taskId.isNotEmpty
        ? context.taskId
        : (parts.length > 1 ? parts[1] : '');

    if (projectId.isEmpty) {
      return;
    }

    try {
      await ref.read(tasksProvider.notifier).loadTasks(projectId);
      if (taskId.isNotEmpty) {
        ref.invalidate(subTasksByTaskProvider(taskId));
      }
    } catch (error) {
      AppLogger.instance.w(
        'Mirror apply succeeded but task/subtask cache refresh failed',
        error: error,
      );
    }
  }

  Future<T> _withRetries<T>({
    required String operationName,
    required WidgetRef ref,
    required String sessionKey,
    required Future<T> Function() operation,
    required bool Function(T value) isSuccess,
    required String? Function(T value) failureMessage,
  }) async {
    var backoff = initialBackoff;

    for (var attempt = 1; attempt <= maxRetries + 1; attempt += 1) {
      try {
        final value = await operation();
        if (isSuccess(value)) {
          return value;
        }

        final isLastAttempt = attempt > maxRetries;
        if (isLastAttempt) {
          return value;
        }

        _emitStatus(
          ref,
          sessionKey,
          terminalLine:
              'Mirror $operationName attempt $attempt failed: ${failureMessage(value) ?? 'unknown failure'}. Retrying...',
          liveLine: '$operationName retry $attempt/${maxRetries + 1}',
        );
      } catch (error) {
        final isLastAttempt = attempt > maxRetries;
        if (isLastAttempt) {
          rethrow;
        }

        _emitStatus(
          ref,
          sessionKey,
          terminalLine:
              'Mirror $operationName attempt $attempt threw: $error. Retrying...',
          liveLine: '$operationName retry $attempt/${maxRetries + 1}',
        );
      }

      await Future<void>.delayed(_applyBackoffJitter(backoff));
      backoff *= 2;
    }

    throw StateError('Unreachable retry state for $operationName.');
  }

  void _emitStatus(
    WidgetRef ref,
    String sessionKey, {
    String? terminalLine,
    String? liveLine,
  }) {
    final notifier = ref.read(mirrorSessionProvider(sessionKey).notifier);

    if (terminalLine != null && terminalLine.trim().isNotEmpty) {
      notifier.appendTerminalLine(terminalLine);
    }

    if (liveLine != null && liveLine.trim().isNotEmpty) {
      notifier.appendLiveOutput(<String>[liveLine]);
    }
  }

  Future<void> _replayQueuedWork(WidgetRef ref,
      {required String reason}) async {
    await _replayService(ref).replayDueEntries(
      reason: reason,
      operationExecutor: _createOutboxExecutor(),
      onReplaySuccess: _onOutboxReplaySuccess(ref),
    );
  }

  Future<MirrorOutboxOperationResult> Function(MirrorOutboxEntry entry)
      _createOutboxExecutor() {
    return (MirrorOutboxEntry entry) async {
      switch (entry.operation) {
        case 'generate':
          final result = await _backend.generate(
            prompt: entry.prompt,
            context: entry.context,
            mode: entry.mode,
          );
          return MirrorOutboxOperationResult(
            success: result.success,
            message: result.message ?? result.diagnostics.join(' | '),
          );
        case 'compile':
          final result = await _backend.compile(
            prompt: entry.prompt,
            context: entry.context,
            mode: entry.mode,
          );
          return MirrorOutboxOperationResult(
            success: result.success,
            message: result.errors.join(' | '),
          );
        case 'apply':
          final compileFingerprint = entry.context.metadata.compileFingerprint;
          final result = await _backend.apply(
            prompt: entry.prompt,
            context: entry.context,
            mode: entry.mode,
            compileFingerprint: compileFingerprint,
          );
          return MirrorOutboxOperationResult(
            success: result.success,
            message: result.message,
          );
        default:
          return MirrorOutboxOperationResult(
            success: false,
            message: 'Unknown outbox operation: ${entry.operation}',
          );
      }
    };
  }

  Future<void> Function(MirrorOutboxEntry entry) _onOutboxReplaySuccess(
    WidgetRef ref,
  ) {
    return (MirrorOutboxEntry entry) async {
      if (entry.operation != 'apply') {
        return;
      }
      await _refreshTaskAndSubTaskCaches(
        ref: ref,
        context: entry.context,
        sessionKey: entry.sessionKey,
      );
    };
  }

  MirrorOutboxReplayService _replayService(WidgetRef ref) {
    final existing = _outboxReplayService;
    if (existing != null) {
      return existing;
    }

    final created = ref.read(mirrorOutboxReplayServiceProvider);
    _outboxReplayService = created;
    return created;
  }

  Duration _applyBackoffJitter(Duration base) {
    final baseMs = max(1, base.inMilliseconds);
    final jitterFraction = (_jitterRandom.nextDouble() - 0.5) * 0.4;
    final jittered = (baseMs * (1 + jitterFraction)).round();
    return Duration(milliseconds: max(1, jittered));
  }
}
