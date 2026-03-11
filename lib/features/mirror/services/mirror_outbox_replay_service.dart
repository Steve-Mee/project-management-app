// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pma_core/providers/connectivity/connectivity_providers.dart';
import 'package:pma_core/providers/task/task_providers.dart';
import 'package:pma_core/repository/encrypted_hive_box.dart';
import 'package:pma_core/services/app_logger.dart';

import '../../../core/providers/mirror_provider.dart';
import '../../../core/providers/mirror_session_provider.dart';

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

class MirrorOutboxReplayService {
  MirrorOutboxReplayService({
    required Ref ref,
    this.maxRetries = 2,
    this.initialBackoff = const Duration(milliseconds: 250),
    this.maxReplayAttempts = 8,
    this.replayTickInterval = const Duration(seconds: 8),
    bool? failClosedOnEncryptionError,
    Future<Box<Map<dynamic, dynamic>>> Function()? encryptedBoxOpener,
    Future<Box<Map<dynamic, dynamic>>> Function()? unencryptedBoxOpener,
  })  : _ref = ref,
        _failClosedOnEncryptionError = failClosedOnEncryptionError ??
            const bool.fromEnvironment(
              'MIRROR_OUTBOX_FAIL_CLOSED_ON_ENCRYPTION_ERROR',
              defaultValue: bool.fromEnvironment('dart.vm.product'),
            ),
        _encryptedBoxOpener = encryptedBoxOpener,
        _unencryptedBoxOpener = unencryptedBoxOpener;

  final Ref _ref;
  final int maxRetries;
  final Duration initialBackoff;
  final int maxReplayAttempts;
  final Duration replayTickInterval;
  final bool _failClosedOnEncryptionError;
  final Future<Box<Map<dynamic, dynamic>>> Function()? _encryptedBoxOpener;
  final Future<Box<Map<dynamic, dynamic>>> Function()? _unencryptedBoxOpener;
  static const String _outboxBoxName = 'mirror_outbox';
  static const String _outboxEncryptionKey =
      'hive_encryption_key_mirror_outbox';
  static const String _encryptionFailureLiveStatus =
      'Outbox security error: local encryption unavailable';
  static const String _encryptionFailureTerminalStatus =
      'Mirror outbox paused: secure local storage is unavailable. Please retry after restoring secure storage.';
  final LinkedHashMap<String, MirrorOutboxEntry> _queue =
      LinkedHashMap<String, MirrorOutboxEntry>();
  final Random _jitterRandom = Random();

  Future<void>? _readyFuture;
  Box<Map<dynamic, dynamic>>? _outboxBox;
  bool _isReplaying = false;
  bool _isDisposed = false;
  Timer? _replayTicker;

  List<MirrorOutboxEntry> get queuedEntries =>
      List<MirrorOutboxEntry>.unmodifiable(_queue.values.toList());

  Future<void> bootstrap() async {
    await _ensureReady();
    _startReplayTicker();
    await replayDueEntries(reason: 'app_start');
  }

  Future<void> dispose() async {
    _isDisposed = true;
    _replayTicker?.cancel();
    _replayTicker = null;
  }

  Future<void> onConnectivityChange(ConnectivityResult connectivity) async {
    if (connectivity == ConnectivityResult.none) {
      return;
    }
    await replayDueEntries(reason: 'network_restored');
  }

  Future<void> enqueue({
    required String operation,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
    String? lastError,
  }) async {
    try {
      await _ensureReady();
    } on MirrorOutboxEncryptionException catch (error, stackTrace) {
      _reportOutboxEncryptionFailure(
        sessionKey: sessionKey,
        message: error.userFacingMessage,
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }

    final now = DateTime.now().toUtc();
    final metadataIdempotencyKey = _resolveContextIdempotencyKey(context);
    final idempotencyKey = metadataIdempotencyKey.isNotEmpty
        ? metadataIdempotencyKey
        : _buildIdempotencyKey(
            operation: operation,
            sessionKey: sessionKey,
            prompt: prompt,
            context: context,
            mode: mode,
          );
    final normalizedContext = _contextWithIdempotency(context, idempotencyKey);

    final existing = _queue[idempotencyKey];
    final nextEntry = MirrorOutboxEntry(
      operation: operation,
      sessionKey: sessionKey,
      prompt: prompt,
      context: normalizedContext,
      mode: mode,
      createdAt: existing?.createdAt ?? now,
      idempotencyKey: idempotencyKey,
      retryCount: existing?.retryCount ?? 0,
      lastAttemptAt: existing?.lastAttemptAt,
      nextRetryAt: now,
      lastError: lastError ?? existing?.lastError,
      updatedAt: now,
    );

    if (!_shouldReplaceWithLastWriteWins(
        existing: existing, candidate: nextEntry)) {
      return;
    }

    _queue[idempotencyKey] = nextEntry;
    await _persistOutboxEntry(nextEntry);
    _emitStatus(
      sessionKey,
      terminalLine: 'Mirror outbox queued $operation for replay.',
      liveLine: 'Outbox queued: $operation',
    );
  }

  Future<void> replayDueEntries({
    String reason = 'manual',
    Future<MirrorOutboxOperationResult> Function(MirrorOutboxEntry entry)?
        operationExecutor,
    Future<void> Function(MirrorOutboxEntry entry)? onReplaySuccess,
  }) async {
    if (_isDisposed) {
      return;
    }

    await _ensureReady();
    if (_isReplaying) {
      return;
    }

    _isReplaying = true;
    try {
      final now = DateTime.now().toUtc();
      final dueEntries = _queue.values.where((entry) {
        if (_isTerminal(entry)) {
          return false;
        }
        final nextRetryAt = entry.nextRetryAt;
        return nextRetryAt == null || !nextRetryAt.isAfter(now);
      }).toList()
        ..sort((a, b) {
          final aTime = a.nextRetryAt ?? a.updatedAt ?? a.createdAt;
          final bTime = b.nextRetryAt ?? b.updatedAt ?? b.createdAt;
          return aTime.compareTo(bTime);
        });

      for (final entry in dueEntries) {
        await _replayEntry(
          entry,
          reason: reason,
          operationExecutor: operationExecutor,
          onReplaySuccess: onReplaySuccess,
        );
      }
    } finally {
      _isReplaying = false;
    }
  }

  Future<void> _replayEntry(
    MirrorOutboxEntry entry, {
    required String reason,
    Future<MirrorOutboxOperationResult> Function(MirrorOutboxEntry entry)?
        operationExecutor,
    Future<void> Function(MirrorOutboxEntry entry)? onReplaySuccess,
  }) async {
    _emitStatus(
      entry.sessionKey,
      terminalLine:
          'Mirror outbox replay started for ${entry.operation} (reason: $reason).',
      liveLine: 'Outbox replay: ${entry.operation}',
    );

    final attempt = await _attemptOperation(
      entry,
      operationExecutor: operationExecutor,
    );
    if (attempt.success) {
      _queue.remove(entry.idempotencyKey);
      await _deleteOutboxEntry(entry.idempotencyKey);
      if (onReplaySuccess != null) {
        await onReplaySuccess(entry);
      }
      _emitStatus(
        entry.sessionKey,
        terminalLine: 'Mirror outbox replay succeeded for ${entry.operation}.',
        liveLine: 'Outbox replay done: ${entry.operation}',
      );
      return;
    }

    final now = DateTime.now().toUtc();
    final retryCount = entry.retryCount + 1;
    if (retryCount >= maxReplayAttempts) {
      final terminalEntry = entry.copyWith(
        retryCount: retryCount,
        lastAttemptAt: now,
        nextRetryAt: null,
        lastError: attempt.failureMessage,
        updatedAt: now,
      );
      _queue[entry.idempotencyKey] = terminalEntry;
      await _persistOutboxEntry(terminalEntry);
      _emitStatus(
        entry.sessionKey,
        terminalLine:
            'Mirror outbox replay reached terminal state for ${entry.operation}: ${attempt.failureMessage ?? 'unknown error'}.',
        liveLine: 'Outbox terminal: ${entry.operation}',
      );
      return;
    }

    final nextRetryDelay =
        _applyBackoffJitter(initialBackoff * (1 << min(retryCount, 8)));
    final retryEntry = entry.copyWith(
      retryCount: retryCount,
      lastAttemptAt: now,
      nextRetryAt: now.add(nextRetryDelay),
      lastError: attempt.failureMessage,
      updatedAt: now,
    );
    _queue[entry.idempotencyKey] = retryEntry;
    await _persistOutboxEntry(retryEntry);
    _emitStatus(
      entry.sessionKey,
      terminalLine:
          'Mirror outbox replay failed for ${entry.operation}; retry scheduled at ${retryEntry.nextRetryAt?.toIso8601String()}.',
      liveLine: 'Outbox retry scheduled: ${entry.operation}',
    );
  }

  Future<_ReplayAttempt> _attemptOperation(
    MirrorOutboxEntry entry, {
    Future<MirrorOutboxOperationResult> Function(MirrorOutboxEntry entry)?
        operationExecutor,
  }) async {
    var backoff = initialBackoff;

    for (var attempt = 1; attempt <= maxRetries + 1; attempt += 1) {
      try {
        final operationResult = operationExecutor == null
            ? await _executeOperation(entry)
            : await operationExecutor(entry);
        if (operationResult.success) {
          if (entry.operation == 'apply') {
            await _refreshTaskAndSubTaskCaches(entry.context, entry.sessionKey);
          }
          return const _ReplayAttempt(success: true);
        }

        final isLastAttempt = attempt > maxRetries;
        if (isLastAttempt) {
          return _ReplayAttempt(
            success: false,
            failureMessage: operationResult.message,
          );
        }

        _emitStatus(
          entry.sessionKey,
          terminalLine:
              'Mirror replay ${entry.operation} attempt $attempt failed: ${operationResult.message ?? 'unknown failure'}. Retrying...',
          liveLine:
              '${entry.operation} replay retry $attempt/${maxRetries + 1}',
        );
      } catch (error) {
        final isLastAttempt = attempt > maxRetries;
        if (isLastAttempt) {
          return _ReplayAttempt(
            success: false,
            failureMessage: error.toString(),
          );
        }

        _emitStatus(
          entry.sessionKey,
          terminalLine:
              'Mirror replay ${entry.operation} attempt $attempt threw: $error. Retrying...',
          liveLine:
              '${entry.operation} replay retry $attempt/${maxRetries + 1}',
        );
      }

      await Future<void>.delayed(_applyBackoffJitter(backoff));
      backoff *= 2;
    }

    return const _ReplayAttempt(success: false, failureMessage: 'unreachable');
  }

  Future<MirrorOutboxOperationResult> _executeOperation(
    MirrorOutboxEntry entry,
  ) async {
    final backend = await _ref.read(mirrorBackendProvider.future);
    final context =
        _contextWithIdempotency(entry.context, entry.idempotencyKey);
    switch (entry.operation) {
      case 'generate':
        final result = await backend.generate(
          prompt: entry.prompt,
          context: context,
          mode: entry.mode,
        );
        return MirrorOutboxOperationResult(
          success: result.success,
          message: result.message ?? result.diagnostics.join(' | '),
        );
      case 'compile':
        final result = await backend.compile(
          prompt: entry.prompt,
          context: context,
          mode: entry.mode,
        );
        return MirrorOutboxOperationResult(
          success: result.success,
          message: result.errors.join(' | '),
        );
      case 'apply':
        final compileFingerprint =
            context.metadata['compileFingerprint']?.toString();
        final result = await backend.apply(
          prompt: entry.prompt,
          context: context,
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
  }

  Future<void> _refreshTaskAndSubTaskCaches(
    ProjectContext context,
    String sessionKey,
  ) async {
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
      await _ref.read(tasksProvider.notifier).loadTasks(projectId);
      if (taskId.isNotEmpty) {
        _ref.invalidate(subTasksByTaskProvider(taskId));
      }
    } catch (error, stackTrace) {
      AppLogger.instance.w(
        'Mirror replay apply succeeded but task/subtask cache refresh failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  bool _isTerminal(MirrorOutboxEntry entry) {
    return entry.retryCount >= maxReplayAttempts && entry.nextRetryAt == null;
  }

  bool _shouldReplaceWithLastWriteWins({
    required MirrorOutboxEntry? existing,
    required MirrorOutboxEntry candidate,
  }) {
    if (existing == null) {
      return true;
    }

    final existingUpdatedAt = existing.updatedAt ?? existing.createdAt;
    final candidateUpdatedAt = candidate.updatedAt ?? candidate.createdAt;
    return !existingUpdatedAt.isAfter(candidateUpdatedAt);
  }

  String _buildIdempotencyKey({
    required String operation,
    required String sessionKey,
    required String prompt,
    required ProjectContext context,
    required String mode,
  }) {
    final sanitizedMetadata = _stripIdempotencyMetadata(context.metadata);
    final contextPayload = jsonEncode(<String, dynamic>{
      'projectId': context.projectId,
      'taskId': context.taskId,
      'files': context.files,
      'metadata': MirrorOutboxEntry._jsonSafe(sanitizedMetadata),
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

  String _resolveContextIdempotencyKey(ProjectContext context) {
    final canonical = context.metadata['idempotencyKey']?.toString().trim();
    if (canonical != null && canonical.isNotEmpty) {
      return canonical;
    }

    final headerStyle =
        context.metadata['x-idempotency-key']?.toString().trim();
    if (headerStyle != null && headerStyle.isNotEmpty) {
      return headerStyle;
    }

    return '';
  }

  Map<String, dynamic> _stripIdempotencyMetadata(
      Map<String, dynamic> metadata) {
    if (metadata.isEmpty) {
      return const <String, dynamic>{};
    }

    final sanitized = Map<String, dynamic>.from(metadata);
    sanitized.remove('idempotencyKey');
    sanitized.remove('x-idempotency-key');
    return sanitized;
  }

  ProjectContext _contextWithIdempotency(
    ProjectContext context,
    String idempotencyKey,
  ) {
    if (idempotencyKey.trim().isEmpty) {
      return context;
    }

    final existing = _resolveContextIdempotencyKey(context);
    if (existing == idempotencyKey) {
      return context;
    }

    final metadata = Map<String, dynamic>.from(context.metadata);
    metadata['idempotencyKey'] = idempotencyKey;

    return ProjectContext(
      projectId: context.projectId,
      taskId: context.taskId,
      files: context.files,
      metadata: metadata,
    );
  }

  Duration _applyBackoffJitter(Duration base) {
    final baseMs = max(1, base.inMilliseconds);
    final jitterFraction = (_jitterRandom.nextDouble() - 0.5) * 0.4;
    final jittered = (baseMs * (1 + jitterFraction)).round();
    return Duration(milliseconds: max(1, jittered));
  }

  void _emitStatus(
    String sessionKey, {
    String? terminalLine,
    String? liveLine,
  }) {
    if (_isDisposed) {
      return;
    }

    late final dynamic notifier;
    try {
      notifier = _ref.read(mirrorSessionProvider(sessionKey).notifier);
    } catch (_) {
      return;
    }
    if (terminalLine != null && terminalLine.trim().isNotEmpty) {
      notifier.appendTerminalLine(terminalLine);
    }
    if (liveLine != null && liveLine.trim().isNotEmpty) {
      notifier.appendLiveOutput(<String>[liveLine]);
    }
  }

  Future<void> _ensureReady() {
    final existing = _readyFuture;
    if (existing != null) {
      return existing;
    }

    final ready = _hydrateQueue();
    _readyFuture = ready;
    return ready;
  }

  Future<void> _hydrateQueue() async {
    final box = await _openOutboxBox();
    _outboxBox = box;
    _rebuildQueueCache(box);
  }

  void _startReplayTicker() {
    if (replayTickInterval <= Duration.zero) {
      return;
    }
    _replayTicker?.cancel();
    _replayTicker = Timer.periodic(replayTickInterval, (_) {
      unawaited(replayDueEntries(reason: 'periodic_tick'));
    });
  }

  void _rebuildQueueCache(Box<Map<dynamic, dynamic>> box) {
    _queue.clear();
    for (final key in box.keys) {
      final raw = box.get(key);
      final entry = MirrorOutboxEntry.fromRaw(raw);
      if (entry == null) {
        continue;
      }

      final storedKey = key.toString();
      final effectiveKey =
          entry.idempotencyKey.isNotEmpty ? entry.idempotencyKey : storedKey;
      _queue[effectiveKey] = entry.copyWith(idempotencyKey: effectiveKey);
    }
  }

  Future<void> _persistOutboxEntry(MirrorOutboxEntry entry) async {
    final box = _outboxBox ?? await _openOutboxBox();
    _outboxBox = box;
    await box.put(entry.idempotencyKey, entry.toMap());
  }

  Future<void> _deleteOutboxEntry(String idempotencyKey) async {
    final box = _outboxBox ?? await _openOutboxBox();
    _outboxBox = box;
    await box.delete(idempotencyKey);
  }

  Future<Box<Map<dynamic, dynamic>>> _openOutboxBox() async {
    if (Hive.isBoxOpen(_outboxBoxName)) {
      return Hive.box<Map<dynamic, dynamic>>(_outboxBoxName);
    }

    try {
      final opener = _encryptedBoxOpener;
      if (opener != null) {
        return await opener();
      }

      final encrypted = EncryptedHiveBox<Map<dynamic, dynamic>>(
        boxName: _outboxBoxName,
        encryptionKey: _outboxEncryptionKey,
      );
      return encrypted.open();
    } catch (error, stackTrace) {
      AppLogger.event(
        'mirror_outbox_encryption_open_failed',
        params: <String, Object?>{
          'policy': _failClosedOnEncryptionError ? 'fail_closed' : 'fail_open',
          'box': _outboxBoxName,
        },
      );

      if (_failClosedOnEncryptionError) {
        AppLogger.instance.e(
          'Encrypted mirror outbox unavailable; fail-closed policy blocked fallback to unencrypted storage.',
          error: error,
          stackTrace: stackTrace,
        );
        throw MirrorOutboxEncryptionException(
          userFacingMessage: _encryptionFailureTerminalStatus,
          cause: error,
        );
      }

      AppLogger.instance.w(
        'Failed to open encrypted mirror outbox; fail-open policy enabled fallback to unencrypted Hive box.',
        error: error,
        stackTrace: stackTrace,
      );

      final fallbackOpener = _unencryptedBoxOpener;
      if (fallbackOpener != null) {
        return await fallbackOpener();
      }
      return Hive.openBox<Map<dynamic, dynamic>>(_outboxBoxName);
    }
  }

  void _reportOutboxEncryptionFailure({
    required String sessionKey,
    required String message,
    required Object error,
    required StackTrace stackTrace,
  }) {
    AppLogger.event(
      'mirror_outbox_encryption_policy_blocked',
      params: <String, Object?>{
        'policy': 'fail_closed',
        'sessionKey': sessionKey,
      },
    );
    AppLogger.instance.e(
      'Mirror outbox encryption policy blocked operation.',
      error: error,
      stackTrace: stackTrace,
    );
    _emitStatus(
      sessionKey,
      terminalLine: message,
      liveLine: _encryptionFailureLiveStatus,
    );
  }
}

class MirrorOutboxEncryptionException implements Exception {
  const MirrorOutboxEncryptionException({
    required this.userFacingMessage,
    this.cause,
  });

  final String userFacingMessage;
  final Object? cause;

  @override
  String toString() {
    final causeValue = cause;
    if (causeValue == null) {
      return 'MirrorOutboxEncryptionException($userFacingMessage)';
    }
    return 'MirrorOutboxEncryptionException($userFacingMessage, cause: $causeValue)';
  }
}

class MirrorOutboxOperationResult {
  const MirrorOutboxOperationResult({required this.success, this.message});

  final bool success;
  final String? message;
}

class _ReplayAttempt {
  const _ReplayAttempt({required this.success, this.failureMessage});

  final bool success;
  final String? failureMessage;
}

final mirrorOutboxReplayServiceProvider =
    Provider<MirrorOutboxReplayService>((ref) {
  final premiumService = ref.read(mirrorPremiumServiceProvider);
  final service = MirrorOutboxReplayService(
    ref: ref,
    failClosedOnEncryptionError:
        premiumService.shouldFailClosedOnOutboxEncryptionError(),
  );

  unawaited(service.bootstrap());

  ref.onDispose(() {
    unawaited(service.dispose());
  });

  ref.listen<AsyncValue<ConnectivityResult>>(
    connectivityProvider,
    (previous, next) {
      next.whenData((connectivity) {
        unawaited(service.onConnectivityChange(connectivity));
      });
    },
  );

  return service;
});
