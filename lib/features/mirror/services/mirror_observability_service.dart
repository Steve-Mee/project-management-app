import 'package:pma_core/services/app_logger.dart';

/// Observability service for the Mirror compute pipeline.
///
/// Records structured telemetry events for:
/// - Compile and apply HTTP request latency (per attempt).
/// - Gateway retry occurrences within a single request.
/// - Backend fallback events (e.g. endpoint unavailable → offline queue).
/// - Outbox replay volume and queue depth at each replay pass.
///
/// All events are emitted via [AppLogger.event] for downstream
/// analytics and error-monitoring integration (e.g. Sentry breadcrumbs).
class MirrorObservabilityService {
  const MirrorObservabilityService();

  /// Records template cache outcomes for the templates provider.
  ///
  /// [result] is one of `'hit'`, `'miss'`, or `'fallback'`.
  /// [source] describes cache origin (`'memory'`, `'persistent'`, `'none'`).
  /// [reason] provides optional context such as stale/version mismatch/network.
  void recordTemplateCacheEvent({
    required String result,
    required String source,
    String? reason,
    int? templateCount,
  }) {
    AppLogger.event(
      'mirror_template_cache',
      params: <String, Object?>{
        'result': result,
        'source': source,
        if (reason != null) 'reason': reason,
        if (templateCount != null) 'templateCount': templateCount,
      },
    );
  }

  /// Records the wall-clock time for a single compile or apply HTTP attempt.
  ///
  /// [durationMs]  Elapsed milliseconds for the HTTP round-trip.
  /// [mode]        Mirror mode, e.g. `'cloud'` or `'private'`.
  /// [operation]   `'compile'` or `'apply'`.
  /// [success]     Whether the HTTP call returned a 2xx response.
  /// [attempt]     1-based attempt number within the retry loop.
  void recordCompileLatency({
    required int durationMs,
    required String mode,
    required String operation,
    required bool success,
    int attempt = 1,
    String? requestId,
    String? traceId,
    String? idempotencyKey,
  }) {
    AppLogger.event(
      'mirror_compile_latency',
      params: <String, Object?>{
        'durationMs': durationMs,
        'mode': mode,
        'operation': operation,
        'success': success,
        'attempt': attempt,
        if (requestId != null) 'requestId': requestId,
        if (traceId != null) 'traceId': traceId,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      },
    );
  }

  /// Records a mid-loop retry within a single gateway request.
  ///
  /// [operation]  `'compile'` or `'apply'`.
  /// [reason]     Short token: `'timeout'` | `'server_error'` |
  ///              `'rate_limited'` | `'network'` | `'replay_failure'` |
  ///              `'replay_exception'`.
  /// [attempt]    The attempt number that just failed (1-based).
  /// [mode]       Mirror mode.
  void recordRetry({
    required String operation,
    required String reason,
    required int attempt,
    required String mode,
    String? requestId,
    String? traceId,
    String? idempotencyKey,
  }) {
    AppLogger.event(
      'mirror_gateway_retry',
      params: <String, Object?>{
        'operation': operation,
        'reason': reason,
        'attempt': attempt,
        'mode': mode,
        if (requestId != null) 'requestId': requestId,
        if (traceId != null) 'traceId': traceId,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      },
    );
  }

  /// Records correlation identifiers attached to a gateway-bound request.
  void recordRequestLinkEvent({
    required String operation,
    required String mode,
    required String requestId,
    required String traceId,
    String? idempotencyKey,
    String? endpoint,
    String? linkedRequestId,
    String? linkedTraceId,
    String stage = 'client_gateway_dispatch',
  }) {
    AppLogger.event(
      'mirror_request_link',
      params: <String, Object?>{
        'operation': operation,
        'mode': mode,
        'requestId': requestId,
        'traceId': traceId,
        'stage': stage,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
        if (endpoint != null) 'endpoint': endpoint,
        if (linkedRequestId != null) 'linkedRequestId': linkedRequestId,
        if (linkedTraceId != null) 'linkedTraceId': linkedTraceId,
      },
    );
  }

  /// Records a backend fallback or forced-error routing decision.
  ///
  /// Use when the gateway cannot reach the compute endpoint and routes
  /// the caller toward an offline or degraded path.
  ///
  /// [reason]       Short token describing the fallback trigger, e.g.
  ///                `'config_error'`, `'endpoint_missing'`.
  /// [mode]         Mirror mode at the time of fallback.
  /// [fromBackend]  Source backend identifier, e.g. `'mirror_gateway'`.
  /// [toBackend]    Destination path identifier, e.g. `'offline_queue'`.
  void recordFallbackEvent({
    required String reason,
    required String mode,
    String? fromBackend,
    String? toBackend,
  }) {
    AppLogger.event(
      'mirror_fallback_event',
      params: <String, Object?>{
        'reason': reason,
        'mode': mode,
        if (fromBackend != null) 'fromBackend': fromBackend,
        if (toBackend != null) 'toBackend': toBackend,
      },
    );
  }

  /// Records replay-queue statistics at the start of each replay pass.
  ///
  /// [dueEntryCount]  Number of entries due for replay in this pass.
  /// [queueDepth]     Total entries in the queue including deferred retries.
  /// [reason]         Replay trigger: `'app_start'` | `'network_restored'` |
  ///                  `'periodic_tick'` | `'manual'`.
  void recordReplayVolume({
    required int dueEntryCount,
    required int queueDepth,
    required String reason,
  }) {
    AppLogger.event(
      'mirror_replay_volume',
      params: <String, Object?>{
        'dueEntryCount': dueEntryCount,
        'queueDepth': queueDepth,
        'reason': reason,
      },
    );
  }

  /// Records outbox replay operation timeouts.
  void recordReplayTimeout({
    required String operation,
    required String mode,
    required int timeoutMs,
    required int attempt,
  }) {
    AppLogger.event(
      'mirror_replay_timeout',
      params: <String, Object?>{
        'operation': operation,
        'mode': mode,
        'timeoutMs': timeoutMs,
        'attempt': attempt,
      },
    );
  }

  /// Records circuit breaker transitions and enforced-open skips.
  void recordCircuitBreakerEvent({
    required String state,
    required String reason,
    required int consecutiveFailures,
    DateTime? openUntil,
  }) {
    AppLogger.event(
      'mirror_replay_circuit_breaker',
      params: <String, Object?>{
        'state': state,
        'reason': reason,
        'consecutiveFailures': consecutiveFailures,
        if (openUntil != null) 'openUntil': openUntil.toUtc().toIso8601String(),
      },
    );
  }
}
