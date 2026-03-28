// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/mirror_session_provider.dart';
import '../mirror_signed_inputs_backend.dart';
import 'mirror_orchestrator_execution_paths.dart';
import 'mirror_outbox_replay_service.dart';
import 'mirror_service_boundaries.dart';

export 'mirror_outbox_replay_service.dart' show MirrorOutboxEntry;

/// Adds retry + outbox replay behavior on top of the active compute backend.
///
/// This service no longer owns interactive apply orchestration; it only wraps
/// generate/compile/apply calls with resiliency and replay semantics.
class MirrorOrchestratorService implements MirrorExecutionOrchestrator {
  MirrorOrchestratorService({
    required MirrorComputeBackend backend,
    this.maxRetries = 2,
    this.initialBackoff = const Duration(milliseconds: 250),
    MirrorInteractiveExecutionPath? interactivePath,
    MirrorReplayExecutionPath? replayPath,
  })  : _interactivePath =
            interactivePath ?? MirrorInteractiveExecutionPath(backend: backend),
        _replayPath = replayPath ?? MirrorReplayExecutionPath(backend: backend);

  final MirrorInteractiveExecutionPath _interactivePath;
  final MirrorReplayExecutionPath _replayPath;
  final int maxRetries;
  final Duration initialBackoff;
  MirrorOutboxReplayService? _outboxReplayService;
  final Random _jitterRandom = Random();

  List<MirrorOutboxEntry> get queuedOutboxEntries =>
      _outboxReplayService?.queuedEntries ?? const <MirrorOutboxEntry>[];

  @override
  Future<GenerateResult> generate({
    required WidgetRef ref,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) {
    return _runWithOutbox<GenerateResult>(
      operationName: 'generate',
      ref: ref,
      sessionKey: sessionKey,
      prompt: prompt,
      context: context,
      mode: mode,
      startTerminalLine: 'Mirror generate started ($mode mode).',
      startLiveLine: 'Generating...',
      doneTerminalLine: 'Mirror generate completed successfully.',
      doneLiveLine: 'Generate done.',
      work: () => _interactivePath.generate(
        prompt: prompt,
        context: context,
        mode: mode,
      ),
      isSuccess: (GenerateResult v) => v.success,
      failureMessage: (GenerateResult v) =>
          v.message ?? v.diagnostics.join(' | '),
    );
  }

  @override
  Future<CompileResult> compile({
    required WidgetRef ref,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) {
    return _runWithOutbox<CompileResult>(
      operationName: 'compile',
      ref: ref,
      sessionKey: sessionKey,
      prompt: prompt,
      context: context,
      mode: mode,
      startTerminalLine: 'Mirror compile started ($mode mode).',
      startLiveLine: 'Compiling...',
      doneTerminalLine: 'Mirror compile completed successfully.',
      doneLiveLine: 'Compile done.',
      work: () => _interactivePath.compile(
        prompt: prompt,
        context: context,
        mode: mode,
      ),
      isSuccess: (CompileResult v) => v.success,
      failureMessage: (CompileResult v) => v.errors.join(' | '),
    );
  }

  @override
  Future<ApplyResult> apply({
    required WidgetRef ref,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
    String? compileFingerprint,
  }) {
    // MirrorApplyFlowCoordinator embeds compileFingerprint in context.metadata
    // before calling apply(), so no special injection is needed here.
    return _runWithOutbox<ApplyResult>(
      operationName: 'apply',
      ref: ref,
      sessionKey: sessionKey,
      prompt: prompt,
      context: context,
      mode: mode,
      startTerminalLine: 'Mirror apply started ($mode mode).',
      startLiveLine: 'Applying...',
      doneTerminalLine: 'Mirror apply completed successfully.',
      doneLiveLine: 'Apply done.',
      work: () => _interactivePath.apply(
        prompt: prompt,
        context: context,
        mode: mode,
        compileFingerprint: compileFingerprint,
      ),
      isSuccess: (ApplyResult v) => v.success,
      failureMessage: (ApplyResult v) => v.message,
    );
  }

  // ── Shared outbox pattern ────────────────────────────────────────────────
  //
  // Drains the outbox before executing, then retries the operation. On failure
  // the operation is enqueued for later replay while a background drain fires.
  // Replay-side cache refresh is owned by MirrorOutboxReplayService.

  Future<T> _runWithOutbox<T>({
    required String operationName,
    required WidgetRef ref,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
    required String startTerminalLine,
    required String startLiveLine,
    required String doneTerminalLine,
    required String doneLiveLine,
    required Future<T> Function() work,
    required bool Function(T) isSuccess,
    required String? Function(T) failureMessage,
  }) async {
    // Reused for both the pre-op drain and the post-failure background replay.
    Future<MirrorOutboxOperationResult> replayExecutor(
      MirrorOutboxEntry entry,
    ) async {
      return _replayPath.execute(entry);
    }

    await _replayService(ref).replayDueEntries(
      reason: 'pre_$operationName',
      operationExecutor: replayExecutor,
    );
    // Emit the foreground status only after older queued work had a chance to
    // drain, so terminal output reflects the current attempt in order.
    _emitStatus(ref, sessionKey,
        terminalLine: startTerminalLine, liveLine: startLiveLine);

    final result = await _withRetries<T>(
      operationName: operationName,
      ref: ref,
      sessionKey: sessionKey,
      operation: work,
      isSuccess: isSuccess,
      failureMessage: failureMessage,
    );

    if (isSuccess(result)) {
      _emitStatus(ref, sessionKey,
          terminalLine: doneTerminalLine, liveLine: doneLiveLine);
    } else {
      // Foreground failures are persisted for later replay instead of being
      // silently dropped when the backend or network is unstable.
      await _replayService(ref).enqueue(
        operation: operationName,
        sessionKey: sessionKey,
        prompt: prompt,
        context: context,
        mode: mode,
        lastError: failureMessage(result) ?? 'unknown',
      );
      unawaited(_replayService(ref).replayDueEntries(
        reason: 'post_${operationName}_failure',
        operationExecutor: replayExecutor,
      ));
      _emitStatus(ref, sessionKey,
          terminalLine:
              'Mirror $operationName failed: ${failureMessage(result) ?? 'unknown error'}',
          liveLine: '$operationName failed.');
    }

    return result;
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

        // Backend calls can return a structured failure result without
        // throwing. Those still participate in the retry loop.
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
        // Transport/runtime exceptions use the same retry budget as explicit
        // backend failures so callers get one consistent resiliency policy.
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
    MirrorSessionNotifier notifier;
    try {
      notifier = ref.read(mirrorSessionProvider(sessionKey).notifier);
    } catch (_) {
      // The provider container can already be disposed in tests or app tear-down.
      return;
    }

    if (terminalLine != null && terminalLine.trim().isNotEmpty) {
      notifier.appendTerminalLine(terminalLine);
    }

    if (liveLine != null && liveLine.trim().isNotEmpty) {
      notifier.appendLiveOutput(<String>[liveLine]);
    }
  }

  MirrorOutboxReplayService _replayService(WidgetRef ref) {
    final existing = _outboxReplayService;
    if (existing != null) {
      return existing;
    }

    // Lazily initialize to avoid constructing replay infrastructure in flows
    // that never need it, such as simple tests.
    final created = ref.read(mirrorOutboxReplayServiceProvider);
    _outboxReplayService = created;
    return created;
  }

  Duration _applyBackoffJitter(Duration base) {
    final baseMs = max(1, base.inMilliseconds);
    // Small jitter spreads retries across clients and avoids synchronized
    // retry bursts after a transient upstream failure.
    final jitterFraction = (_jitterRandom.nextDouble() - 0.5) * 0.4;
    final jittered = (baseMs * (1 + jitterFraction)).round();
    return Duration(milliseconds: max(1, jittered));
  }
}
