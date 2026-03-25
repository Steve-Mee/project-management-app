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

import '../../../core/providers/mirror_entitlement_provider.dart';
import '../../../core/providers/mirror_premium_provider.dart';
import '../../../core/providers/mirror_session_provider.dart';
import '../mirror_signed_inputs_backend.dart';
import 'mirror_context_budget_service.dart';
import 'mirror_observability_service.dart';

enum MirrorOutboxCorruptionRecoveryAction {
  migrateLegacy,
  quarantine,
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
        'metadata': _jsonSafe(context.metadata.toJson()),
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

  static MirrorOutboxEntry? fromRaw(
    dynamic raw, {
    void Function(String reason)? onFailure,
  }) {
    if (raw is! Map) {
      onFailure?.call('raw_not_map');
      return null;
    }

    try {
      final map = Map<String, dynamic>.from(raw);
      final contextRaw = map['context'];
      if (contextRaw is! Map) {
        onFailure?.call('context_not_map');
        return null;
      }

      final contextMap = Map<String, dynamic>.from(contextRaw);
      final parsedContext = ProjectContext.fromJson(contextMap);
      final operation = map['operation']?.toString();
      final sessionKey = map['sessionKey']?.toString();
      final prompt = map['prompt']?.toString();
      final mode = map['mode']?.toString();
      final createdAtRaw = map['createdAt']?.toString();
      if (operation == null ||
          sessionKey == null ||
          prompt == null ||
          mode == null ||
          createdAtRaw == null ||
          parsedContext.projectId.isEmpty ||
          parsedContext.taskId.isEmpty) {
        onFailure?.call('missing_required_fields');
        return null;
      }

      final createdAt = DateTime.tryParse(createdAtRaw)?.toUtc();
      if (createdAt == null) {
        onFailure?.call('invalid_created_at');
        return null;
      }

      return MirrorOutboxEntry(
        operation: operation,
        sessionKey: sessionKey,
        prompt: prompt,
        context: parsedContext,
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
      onFailure?.call('parse_exception');
      return null;
    }
  }

  static MirrorOutboxCorruptionRecoveryAction recoveryActionForReason(
    String reason,
  ) {
    switch (reason) {
      case 'missing_required_fields':
      case 'context_not_map':
        return MirrorOutboxCorruptionRecoveryAction.migrateLegacy;
      default:
        return MirrorOutboxCorruptionRecoveryAction.quarantine;
    }
  }

  static MirrorOutboxEntry? tryRecoverLegacyFromRaw(
    dynamic raw, {
    required String reason,
  }) {
    if (recoveryActionForReason(reason) !=
        MirrorOutboxCorruptionRecoveryAction.migrateLegacy) {
      return null;
    }
    if (raw is! Map) {
      return null;
    }

    final map = Map<String, dynamic>.from(raw);
    final operation = _firstNonBlank(<String?>[
      map['operation']?.toString(),
      map['op']?.toString(),
    ]);
    final prompt = _firstNonBlank(<String?>[
      map['prompt']?.toString(),
      map['input']?.toString(),
    ]);
    final mode = _firstNonBlank(<String?>[
          map['mode']?.toString(),
          map['requestedMode']?.toString(),
          map['requested_mode']?.toString(),
        ]) ??
        'private';
    final createdAtRaw = _firstNonBlank(<String?>[
      map['createdAt']?.toString(),
      map['created_at']?.toString(),
    ]);

    if (operation == null || prompt == null || createdAtRaw == null) {
      return null;
    }

    final createdAt = DateTime.tryParse(createdAtRaw)?.toUtc();
    if (createdAt == null) {
      return null;
    }

    final contextRaw = map['context'];
    final contextMap = contextRaw is Map
        ? Map<String, dynamic>.from(contextRaw)
        : <String, dynamic>{};
    final projectId = _firstNonBlank(<String?>[
      contextMap['projectId']?.toString(),
      contextMap['project_id']?.toString(),
      map['projectId']?.toString(),
      map['project_id']?.toString(),
    ]);
    final taskId = _firstNonBlank(<String?>[
      contextMap['taskId']?.toString(),
      contextMap['task_id']?.toString(),
      map['taskId']?.toString(),
      map['task_id']?.toString(),
    ]);

    if (projectId == null || taskId == null) {
      return null;
    }

    final filesRaw = contextMap.containsKey('files')
        ? contextMap['files']
        : map['files'];
    final metadataRaw = contextMap.containsKey('metadata')
        ? contextMap['metadata']
        : map['metadata'];

    final files = <String, String>{};
    if (filesRaw is Map) {
      for (final entry in filesRaw.entries) {
        files[entry.key.toString()] = entry.value?.toString() ?? '';
      }
    }

    final metadata = metadataRaw is Map
        ? Map<String, dynamic>.from(metadataRaw)
        : <String, dynamic>{};

    final parsedContext = ProjectContext.fromJson(<String, dynamic>{
      'projectId': projectId,
      'taskId': taskId,
      'files': files,
      'metadata': metadata,
    });

    final sessionKey = _firstNonBlank(<String?>[
          map['sessionKey']?.toString(),
          map['session_key']?.toString(),
        ]) ??
        '$projectId::$taskId';

    return MirrorOutboxEntry(
      operation: operation,
      sessionKey: sessionKey,
      prompt: prompt,
      context: parsedContext,
      mode: mode,
      createdAt: createdAt,
      idempotencyKey: map['idempotencyKey']?.toString() ??
          map['idempotency_key']?.toString() ??
          '',
      retryCount: _parseInt(
        map.containsKey('retryCount') ? map['retryCount'] : map['retry_count'],
      ),
      lastAttemptAt: _parseDateTime(
        map.containsKey('lastAttemptAt')
            ? map['lastAttemptAt']
            : map['last_attempt_at'],
      ),
      nextRetryAt: _parseDateTime(
        map.containsKey('nextRetryAt')
            ? map['nextRetryAt']
            : map['next_retry_at'],
      ),
      lastError: map['lastError']?.toString() ?? map['last_error']?.toString(),
      updatedAt: _parseDateTime(
        map.containsKey('updatedAt') ? map['updatedAt'] : map['updated_at'],
      ),
    );
  }

  static String? _firstNonBlank(Iterable<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
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
  /// Mirror outbox resilience policy.
  ///
  /// Retry model uses two layers:
  ///
  /// 1. In-attempt retries ([maxRetries])
  ///    A single replay attempt retries transient failures up to
  ///    `maxRetries + 1` total tries with exponential backoff and jitter:
  ///    `initialBackoff * 2^n`, then jittered by ±20%.
  ///
  /// 2. Deferred replay retries ([maxReplayAttempts])
  ///    If the in-attempt loop still fails, the entry is re-scheduled for the
  ///    next replay pass with exponential backoff (also jittered), until
  ///    [maxReplayAttempts] is reached, after which the entry becomes terminal.
  ///
  /// Circuit breaker:
  ///
  /// - Opens after [circuitBreakerFailureThreshold] consecutive replay
  ///   operation failures.
  /// - Stays open for [circuitBreakerOpenDuration], skipping replay dispatch.
  /// - Transitions to half-open after cooldown and allows one probe replay.
  /// - Probe success closes the breaker and resets counters.
  /// - Probe failure re-opens breaker for another cooldown window.
  ///
  /// Per-operation timeout:
  ///
  /// - Every backend replay call is bounded by [operationTimeout].
  /// - Timeout is treated as a retryable replay failure and contributes to
  ///   circuit-breaker failure counts.
  MirrorOutboxReplayService({
    required Ref ref,
    this.maxRetries = 2,
    this.initialBackoff = const Duration(milliseconds: 250),
    this.maxReplayAttempts = 8,
    this.replayTickInterval = const Duration(seconds: 8),
    this.operationTimeout = const Duration(seconds: 25),
    this.circuitBreakerFailureThreshold = 4,
    this.circuitBreakerOpenDuration = const Duration(seconds: 45),
    bool? failClosedOnEncryptionError,
    MirrorContextBudgetService? budgetService,
    Future<Box<Map<dynamic, dynamic>>> Function()? encryptedBoxOpener,
    Future<Box<Map<dynamic, dynamic>>> Function()? unencryptedBoxOpener,
    MirrorObservabilityService? observabilityService,
  })  : _ref = ref,
        _failClosedOnEncryptionError = failClosedOnEncryptionError ??
            const bool.fromEnvironment(
              'MIRROR_OUTBOX_FAIL_CLOSED_ON_ENCRYPTION_ERROR',
              defaultValue: bool.fromEnvironment('dart.vm.product'),
            ),
        _budgetService = budgetService,
        _encryptedBoxOpener = encryptedBoxOpener,
        _unencryptedBoxOpener = unencryptedBoxOpener,
        _observabilityService = observabilityService;

  final Ref _ref;
  final int maxRetries;
  final Duration initialBackoff;
  final int maxReplayAttempts;
  final Duration replayTickInterval;
  final Duration operationTimeout;
  final int circuitBreakerFailureThreshold;
  final Duration circuitBreakerOpenDuration;
  final bool _failClosedOnEncryptionError;
  final MirrorContextBudgetService? _budgetService;
  final MirrorObservabilityService? _observabilityService;
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
  bool _isCircuitHalfOpen = false;
  bool _isDisposed = false;
  DateTime? _circuitOpenUntil;
  int _consecutiveReplayFailures = 0;
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

    // Enforce payload budget before persisting to the outbox.
    final budgetResult = _budgetService?.enforce(normalizedContext);
    final budgetedContext = budgetResult?.context ?? normalizedContext;
    if (budgetResult?.report.wasEnforced == true) {
      AppLogger.event(
        'mirror_outbox_budget_enforced',
        params: <String, Object?>{
          'operation': operation,
          'originalFiles': budgetResult!.report.originalFileCount,
          'enforcedFiles': budgetResult.report.enforcedFileCount,
          'droppedFiles': budgetResult.report.droppedFiles.length,
          'truncatedFiles': budgetResult.report.truncatedFiles.length,
        },
      );
    }

    final existing = _queue[idempotencyKey];
    final nextEntry = MirrorOutboxEntry(
      operation: operation,
      sessionKey: sessionKey,
      prompt: prompt,
      context: budgetedContext,
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
      if (_isCircuitOpen(now)) {
        _observabilityService?.recordCircuitBreakerEvent(
          state: 'open',
          reason: 'replay_skipped',
          consecutiveFailures: _consecutiveReplayFailures,
          openUntil: _circuitOpenUntil,
        );
        return;
      }

      if (_circuitOpenUntil != null && !_isCircuitHalfOpen) {
        _isCircuitHalfOpen = true;
        _observabilityService?.recordCircuitBreakerEvent(
          state: 'half_open',
          reason: 'cooldown_elapsed',
          consecutiveFailures: _consecutiveReplayFailures,
        );
      }

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

      _observabilityService?.recordReplayVolume(
        dueEntryCount: dueEntries.length,
        queueDepth: _queue.length,
        reason: reason,
      );
      for (final entry in dueEntries) {
        await _replayEntry(
          entry,
          reason: reason,
          operationExecutor: operationExecutor,
          onReplaySuccess: onReplaySuccess,
        );
        if (_isCircuitHalfOpen || _isCircuitOpen(DateTime.now().toUtc())) {
          // Half-open allows only one probe; open state pauses remaining work.
          break;
        }
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
      _recordReplaySuccess();
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
    _recordReplayFailure(
      reason: attempt.failureReason,
      now: now,
      operation: entry.operation,
      mode: entry.mode,
      sessionKey: entry.sessionKey,
    );
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
            ? await _executeOperation(entry).timeout(operationTimeout)
            : await operationExecutor(entry).timeout(operationTimeout);
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
            failureReason: 'operation_failed',
          );
        }

        _emitStatus(
          entry.sessionKey,
          terminalLine:
              'Mirror replay ${entry.operation} attempt $attempt failed: ${operationResult.message ?? 'unknown failure'}. Retrying...',
          liveLine:
              '${entry.operation} replay retry $attempt/${maxRetries + 1}',
        );
        _observabilityService?.recordRetry(
          operation: entry.operation,
          reason: 'replay_failure',
          attempt: attempt,
          mode: entry.mode,
        );
      } catch (error) {
        final failureReason = error is TimeoutException
            ? 'operation_timeout'
            : 'replay_exception';
        if (error is TimeoutException) {
          _observabilityService?.recordReplayTimeout(
            operation: entry.operation,
            mode: entry.mode,
            timeoutMs: operationTimeout.inMilliseconds,
            attempt: attempt,
          );
        }
        final isLastAttempt = attempt > maxRetries;
        if (isLastAttempt) {
          return _ReplayAttempt(
            success: false,
            failureMessage: error.toString(),
            failureReason: failureReason,
          );
        }

        _emitStatus(
          entry.sessionKey,
          terminalLine:
              'Mirror replay ${entry.operation} attempt $attempt threw: $error. Retrying...',
          liveLine:
              '${entry.operation} replay retry $attempt/${maxRetries + 1}',
        );
        _observabilityService?.recordRetry(
          operation: entry.operation,
          reason: failureReason,
          attempt: attempt,
          mode: entry.mode,
        );
      }

      await Future<void>.delayed(_applyBackoffJitter(backoff));
      backoff *= 2;
    }

    return const _ReplayAttempt(success: false, failureMessage: 'unreachable');
  }

  bool _isCircuitOpen(DateTime now) {
    final openUntil = _circuitOpenUntil;
    if (openUntil == null) {
      return false;
    }
    if (!now.isBefore(openUntil)) {
      return false;
    }
    return true;
  }

  void _recordReplaySuccess() {
    if (_consecutiveReplayFailures == 0 && _circuitOpenUntil == null) {
      return;
    }

    _consecutiveReplayFailures = 0;
    if (_circuitOpenUntil != null || _isCircuitHalfOpen) {
      _observabilityService?.recordCircuitBreakerEvent(
        state: 'closed',
        reason: 'probe_success',
        consecutiveFailures: _consecutiveReplayFailures,
      );
    }
    _circuitOpenUntil = null;
    _isCircuitHalfOpen = false;
  }

  void _recordReplayFailure({
    required String reason,
    required DateTime now,
    required String operation,
    required String mode,
    required String sessionKey,
  }) {
    _consecutiveReplayFailures += 1;

    if (_consecutiveReplayFailures < circuitBreakerFailureThreshold) {
      return;
    }

    final openUntil = now.add(circuitBreakerOpenDuration);
    _circuitOpenUntil = openUntil;
    _isCircuitHalfOpen = false;
    _observabilityService?.recordCircuitBreakerEvent(
      state: 'open',
      reason: reason,
      consecutiveFailures: _consecutiveReplayFailures,
      openUntil: openUntil,
    );
    _emitStatus(
      sessionKey,
      terminalLine:
          'Mirror replay circuit breaker opened after repeated $operation failures; pausing replay until ${openUntil.toIso8601String()}.',
      liveLine: 'Outbox circuit breaker open',
    );
    _observabilityService?.recordRetry(
      operation: operation,
      reason: 'circuit_breaker_open',
      attempt: _consecutiveReplayFailures,
      mode: mode,
    );
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
        final compileFingerprint = context.metadata.compileFingerprint;
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
      'metadata': MirrorOutboxEntry._jsonSafe(sanitizedMetadata.toJson()),
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
    return context.metadata.idempotencyKey ?? '';
  }

  ProjectContextMetadata _stripIdempotencyMetadata(
    ProjectContextMetadata metadata,
  ) {
    return metadata.copyWith(idempotencyKey: '');
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

    return context.copyWith(
      metadata: context.metadata.copyWith(idempotencyKey: idempotencyKey),
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
    await _rebuildQueueCache(box);
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

  Future<void> _rebuildQueueCache(Box<Map<dynamic, dynamic>> box) async {
    _queue.clear();
    for (final key in box.keys.toList(growable: false)) {
      final raw = box.get(key);
      final storageKey = key.toString();
      String? parseFailureReason;
      final entry = MirrorOutboxEntry.fromRaw(
        raw,
        onFailure: (String reason) {
          parseFailureReason = reason;
        },
      );
      if (entry == null) {
        final reason = parseFailureReason ?? 'parse_unknown';
        final recoveryAction =
            MirrorOutboxEntry.recoveryActionForReason(reason);
        final recovered = MirrorOutboxEntry.tryRecoverLegacyFromRaw(
          raw,
          reason: reason,
        );
        _observabilityService?.recordOutboxCorruption(
          reason: reason,
          storageKey: storageKey,
          recoveryAction: recoveryAction.name,
          recovered: recovered != null,
        );
        if (recovered == null) {
          continue;
        }

        final recoveredKey = recovered.idempotencyKey.isNotEmpty
            ? recovered.idempotencyKey
            : storageKey;
        final normalizedRecovered = recovered.copyWith(
          idempotencyKey: recoveredKey,
        );
        _queue[recoveredKey] = normalizedRecovered;
        await box.put(recoveredKey, normalizedRecovered.toMap());
        if (recoveredKey != storageKey) {
          await box.delete(storageKey);
        }
        continue;
      }

      final effectiveKey =
          entry.idempotencyKey.isNotEmpty ? entry.idempotencyKey : storageKey;
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
  const _ReplayAttempt({
    required this.success,
    this.failureMessage,
    this.failureReason = 'unknown_failure',
  });

  final bool success;
  final String? failureMessage;
  final String failureReason;
}

final mirrorOutboxReplayServiceProvider =
    Provider<MirrorOutboxReplayService>((ref) {
  final premiumService = ref.read(mirrorPremiumServiceProvider);
  final budgetService = ref.read(mirrorContextBudgetServiceProvider);
  final service = MirrorOutboxReplayService(
    ref: ref,
    budgetService: budgetService,
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
