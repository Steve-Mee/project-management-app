import 'dart:async';

typedef MirrorRetryAttemptTelemetry = void Function({
  required int durationMs,
  required bool success,
  required int attempt,
});

typedef MirrorRetryCallback = void Function({
  required String reason,
  required int attempt,
});

class MirrorRetryPolicy {
  const MirrorRetryPolicy({
    required this.timeout,
    required this.maxRetries,
    required this.initialBackoff,
  });

  final Duration timeout;
  final int maxRetries;
  final Duration initialBackoff;

  Future<TResult> execute<TResult, TAttempt>({
    required Future<TAttempt> Function() attemptOperation,
    required bool Function(TAttempt result) isSuccess,
    required bool Function(TAttempt result) isRetriable,
    required String Function(TAttempt result) retryReasonForResult,
    required TResult Function(TAttempt result) onSuccess,
    required TResult Function(TAttempt result) onFailure,
    required TResult Function() onTimeoutFailure,
    required TResult Function(Object error) onErrorFailure,
    MirrorRetryAttemptTelemetry? onAttemptComplete,
    MirrorRetryCallback? onRetry,
  }) async {
    var attempt = 0;
    var backoff = initialBackoff;

    while (true) {
      attempt += 1;
      final stopwatch = Stopwatch()..start();

      try {
        final result = await attemptOperation().timeout(timeout);
        stopwatch.stop();

        if (isSuccess(result)) {
          onAttemptComplete?.call(
            durationMs: stopwatch.elapsedMilliseconds,
            success: true,
            attempt: attempt,
          );
          return onSuccess(result);
        }

        final retriable = isRetriable(result);
        if (retriable && attempt <= maxRetries) {
          onRetry?.call(
            reason: retryReasonForResult(result),
            attempt: attempt,
          );
          await Future<void>.delayed(backoff);
          backoff *= 2;
          continue;
        }

        onAttemptComplete?.call(
          durationMs: stopwatch.elapsedMilliseconds,
          success: false,
          attempt: attempt,
        );
        return onFailure(result);
      } on TimeoutException {
        stopwatch.stop();
        if (attempt <= maxRetries) {
          onRetry?.call(reason: 'timeout', attempt: attempt);
          await Future<void>.delayed(backoff);
          backoff *= 2;
          continue;
        }

        onAttemptComplete?.call(
          durationMs: stopwatch.elapsedMilliseconds,
          success: false,
          attempt: attempt,
        );
        return onTimeoutFailure();
      } catch (error) {
        stopwatch.stop();
        if (attempt <= maxRetries) {
          onRetry?.call(reason: 'network', attempt: attempt);
          await Future<void>.delayed(backoff);
          backoff *= 2;
          continue;
        }

        onAttemptComplete?.call(
          durationMs: stopwatch.elapsedMilliseconds,
          success: false,
          attempt: attempt,
        );
        return onErrorFailure(error);
      }
    }
  }
}