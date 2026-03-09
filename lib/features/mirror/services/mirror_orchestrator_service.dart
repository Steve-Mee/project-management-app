import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pma_core/providers/task/task_providers.dart';
import 'package:pma_core/repository/encrypted_hive_box.dart';
import 'package:pma_core/services/app_logger.dart';

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
    this.idempotencyKey = '',
    this.retryCount = 0,
    this.lastAttemptAt,
    this.nextRetryAt,
    this.lastError,
    this.updatedAt,
  });

  final String operation;
  final String sessionKey;
  final String prompt;
  final ProjectContext context;
  final String mode;
  final DateTime createdAt;
  final String idempotencyKey;
  final int retryCount;
  final DateTime? lastAttemptAt;
  final DateTime? nextRetryAt;
  final String? lastError;
  final DateTime? updatedAt;

  MirrorOutboxEntry copyWith({
    String? operation,
    String? sessionKey,
    String? prompt,
    ProjectContext? context,
    String? mode,
    DateTime? createdAt,
    String? idempotencyKey,
    int? retryCount,
    DateTime? lastAttemptAt,
    DateTime? nextRetryAt,
    String? lastError,
    DateTime? updatedAt,
  }) {
    return MirrorOutboxEntry(
      operation: operation ?? this.operation,
      sessionKey: sessionKey ?? this.sessionKey,
      prompt: prompt ?? this.prompt,
      context: context ?? this.context,
      mode: mode ?? this.mode,
      createdAt: createdAt ?? this.createdAt,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      lastError: lastError ?? this.lastError,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'operation': operation,
      'sessionKey': sessionKey,
      'prompt': prompt,
      'context': <String, dynamic>{
        'projectId': context.projectId,
        'taskId': context.taskId,
        'files': context.files,
        'metadata': _jsonSafe(context.metadata),
      },
      'mode': mode,
      'createdAt': createdAt.toIso8601String(),
      'idempotencyKey': idempotencyKey,
      'retryCount': retryCount,
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      'nextRetryAt': nextRetryAt?.toIso8601String(),
      'lastError': lastError,
      'updatedAt': (updatedAt ?? createdAt).toIso8601String(),
    };
  }

  static MirrorOutboxEntry? fromRaw(dynamic raw) {
    if (raw is! Map) {
      return null;
    }

    try {
      final map = Map<String, dynamic>.from(raw);
      final contextRaw = map['context'];
      if (contextRaw is! Map) {
        return null;
      }

      final contextMap = Map<String, dynamic>.from(contextRaw);
      final files = _stringMap(contextMap['files']);
      final metadataRaw = contextMap['metadata'];
      final metadata = metadataRaw is Map
          ? Map<String, dynamic>.from(metadataRaw)
          : const <String, dynamic>{};

      final operation = map['operation']?.toString();
      final sessionKey = map['sessionKey']?.toString();
      final prompt = map['prompt']?.toString();
      final mode = map['mode']?.toString();
      final createdAtRaw = map['createdAt']?.toString();
      final projectId = contextMap['projectId']?.toString();
      final taskId = contextMap['taskId']?.toString();
      if (operation == null ||
          sessionKey == null ||
          prompt == null ||
          mode == null ||
          createdAtRaw == null ||
          projectId == null ||
          taskId == null) {
        return null;
      }

      final createdAt = DateTime.tryParse(createdAtRaw)?.toUtc();
      if (createdAt == null) {
        return null;
      }

      return MirrorOutboxEntry(
        operation: operation,
        sessionKey: sessionKey,
        prompt: prompt,
        context: ProjectContext(
          projectId: projectId,
          taskId: taskId,
          files: files,
          metadata: metadata,
        ),
        mode: mode,
        createdAt: createdAt,
        idempotencyKey: map['idempotencyKey']?.toString() ?? '',
        retryCount: _parseInt(map['retryCount']),
        lastAttemptAt: _parseDateTime(map['lastAttemptAt']),
        nextRetryAt: _parseDateTime(map['nextRetryAt']),
        lastError: map['lastError']?.toString(),
        updatedAt: _parseDateTime(map['updatedAt']),
      );
    } catch (_) {
      return null;
    }
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString())?.toUtc();
  }

  static Map<String, String> _stringMap(dynamic value) {
    if (value is! Map) {
      return const <String, String>{};
    }
    final result = <String, String>{};
    for (final entry in value.entries) {
      result[entry.key.toString()] = entry.value?.toString() ?? '';
    }
    return result;
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
      return value.toUtc().toIso8601String();
    }
    return value;
  }
}

class MirrorOrchestratorService {
  MirrorOrchestratorService({
    required MirrorComputeBackend backend,
    this.maxRetries = 2,
    this.initialBackoff = const Duration(milliseconds: 250),
  }) : _backend = backend {
    unawaited(_ensureOutboxReady());
  }

  final MirrorComputeBackend _backend;
  final int maxRetries;
  final Duration initialBackoff;
  static const String _outboxBoxName = 'mirror_outbox';
  static const String _outboxEncryptionKey =
      'hive_encryption_key_mirror_outbox';
  final LinkedHashMap<String, MirrorOutboxEntry> _outboxQueue =
      LinkedHashMap<String, MirrorOutboxEntry>();
  final Random _jitterRandom = Random();
  Future<void>? _outboxReadyFuture;
  Box<Map<dynamic, dynamic>>? _outboxBox;

  List<MirrorOutboxEntry> get queuedOutboxEntries =>
      List<MirrorOutboxEntry>.unmodifiable(_outboxQueue.values.toList());

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
      await _queueOutboxStub(
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
      await _queueOutboxStub(
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
      await _queueOutboxStub(
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

  Future<void> _queueOutboxStub({
    required String operation,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) async {
    await _ensureOutboxReady();

    final now = DateTime.now().toUtc();
    final idempotencyKey = _buildIdempotencyKey(
      operation: operation,
      sessionKey: sessionKey,
      prompt: prompt,
      context: context,
      mode: mode,
    );

    final retryDelay = _applyBackoffJitter(
      initialBackoff * max(1, maxRetries + 1),
    );

    final nextEntry = MirrorOutboxEntry(
      operation: operation,
      sessionKey: sessionKey,
      prompt: prompt,
      context: context,
      mode: mode,
      createdAt: now,
      idempotencyKey: idempotencyKey,
      retryCount: maxRetries + 1,
      lastAttemptAt: now,
      nextRetryAt: now.add(retryDelay),
      updatedAt: now,
    );

    final existing = _outboxQueue[idempotencyKey];
    final existingUpdatedAt = existing?.updatedAt ?? existing?.createdAt;
    final nextUpdatedAt = nextEntry.updatedAt ?? nextEntry.createdAt;
    if (existing != null &&
        existingUpdatedAt != null &&
        existingUpdatedAt.isAfter(nextUpdatedAt)) {
      return;
    }

    _outboxQueue[idempotencyKey] = nextEntry;
    await _persistOutboxEntry(nextEntry);
  }

  String _buildIdempotencyKey({
    required String operation,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) {
    final contextPayload = jsonEncode(<String, dynamic>{
      'projectId': context.projectId,
      'taskId': context.taskId,
      'files': context.files,
      'metadata': MirrorOutboxEntry._jsonSafe(context.metadata),
    });
    final payload = <String>[
      operation,
      sessionKey,
      mode,
      prompt,
      contextPayload,
    ].join('|');

    return sha256.convert(utf8.encode(payload)).toString();
  }

  Duration _applyBackoffJitter(Duration base) {
    final baseMs = max(1, base.inMilliseconds);
    final jitterFraction = (_jitterRandom.nextDouble() - 0.5) * 0.4;
    final jittered = (baseMs * (1 + jitterFraction)).round();
    return Duration(milliseconds: max(1, jittered));
  }

  Future<void> _ensureOutboxReady() {
    final existing = _outboxReadyFuture;
    if (existing != null) {
      return existing;
    }

    final ready = _hydrateOutbox();
    _outboxReadyFuture = ready;
    return ready;
  }

  Future<void> _hydrateOutbox() async {
    final box = await _openOutboxBox();
    _outboxBox = box;

    _outboxQueue.clear();
    for (final key in box.keys) {
      final raw = box.get(key);
      final entry = MirrorOutboxEntry.fromRaw(raw);
      if (entry == null) {
        continue;
      }
      final storedKey = key.toString();
      final effectiveKey = entry.idempotencyKey.isNotEmpty
          ? entry.idempotencyKey
          : storedKey;
      _outboxQueue[effectiveKey] = entry;
    }
  }

  Future<void> _persistOutboxEntry(MirrorOutboxEntry entry) async {
    final box = _outboxBox ?? await _openOutboxBox();
    _outboxBox = box;
    await box.put(entry.idempotencyKey, entry.toMap());
  }

  Future<Box<Map<dynamic, dynamic>>> _openOutboxBox() async {
    if (Hive.isBoxOpen(_outboxBoxName)) {
      return Hive.box<Map<dynamic, dynamic>>(_outboxBoxName);
    }

    try {
      final encrypted = EncryptedHiveBox<Map<dynamic, dynamic>>(
        boxName: _outboxBoxName,
        encryptionKey: _outboxEncryptionKey,
      );
      return encrypted.open();
    } catch (error) {
      AppLogger.instance.e(
        'Failed to open encrypted mirror outbox; falling back to unencrypted Hive box.',
        error: error,
      );
      return Hive.openBox<Map<dynamic, dynamic>>(_outboxBoxName);
    }
  }
}
