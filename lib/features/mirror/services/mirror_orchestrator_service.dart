import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/mirror_session_provider.dart';
import '../mirror_compute_backend.dart';

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

class MirrorOutboxEntry {
  const MirrorOutboxEntry({
    required this.operation,
    required this.sessionKey,
    required this.prompt,
    required this.context,
    required this.mode,
    required this.createdAt,
  });

  final String operation;
  final String sessionKey;
  final String prompt;
  final ProjectContext context;
  final String mode;
  final DateTime createdAt;
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
  final List<MirrorOutboxEntry> _outboxQueue = <MirrorOutboxEntry>[];

  List<MirrorOutboxEntry> get queuedOutboxEntries =>
      List<MirrorOutboxEntry>.unmodifiable(_outboxQueue);

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
      _queueOutboxStub(
        operation: 'generate',
        sessionKey: sessionKey,
        prompt: prompt,
        context: context,
        mode: mode,
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
      _queueOutboxStub(
        operation: 'compile',
        sessionKey: sessionKey,
        prompt: prompt,
        context: context,
        mode: mode,
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
  }) async {
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
        );
      },
      isSuccess: (ApplyResult value) => value.success,
      failureMessage: (ApplyResult value) => value.message,
    );

    if (result.success) {
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
      _queueOutboxStub(
        operation: 'apply',
        sessionKey: sessionKey,
        prompt: prompt,
        context: context,
        mode: mode,
      );
      _emitStatus(
        ref,
        sessionKey,
        terminalLine: 'Mirror apply failed: ${result.message ?? 'unknown error'}',
        liveLine: 'Apply failed.',
      );
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

      await Future<void>.delayed(backoff);
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

  void _queueOutboxStub({
    required String operation,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) {
    _outboxQueue.add(
      MirrorOutboxEntry(
        operation: operation,
        sessionKey: sessionKey,
        prompt: prompt,
        context: context,
        mode: mode,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }
}
