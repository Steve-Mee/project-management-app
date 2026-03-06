// ignore_for_file: invalid_annotation_target

import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_request_queue.freezed.dart';
part 'ai_request_queue.g.dart';

/// AI Request Queue Model for handling burst requests
///
/// Implements request queuing to handle AI API bursts without immediate rate limit errors.
/// Background worker processes queued requests when rate limits allow.
/// See .github/issues/033-ai-request-queue.md for implementation details.
///
/// This model provides in-memory queuing with optional Hive persistence support.
/// Requests are processed in priority order (higher priority first) then FIFO.
@Freezed(fromJson: false, toJson: false)
abstract class AiRequest with _$AiRequest {
  const AiRequest._();

  const factory AiRequest({
    required String id,
    required String action,
    required Map<String, dynamic> payload,
    required DateTime timestamp,
    @Default(1) int priority,
    required Completer<dynamic> completer,
  }) = _AiRequest;

  /// Serialize to JSON for persistence (excludes completer)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
      'priority': priority,
    };
  }

  /// Deserialize from JSON (creates new completer)
  factory AiRequest.fromJson(Map<String, dynamic> json) {
    return AiRequest(
      id: json['id'] as String,
      action: json['action'] as String,
      payload: json['payload'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      priority: json['priority'] as int? ?? 1,
      completer: Completer<dynamic>(),
    );
  }
}

/// AI Request Queue for managing pending requests
///
/// Provides in-memory queue with stream-based processing.
/// Integrates with rate limiter to process requests when allowed.
/// See .github/issues/033-ai-request-queue.md for background worker integration.
class AiRequestQueue {
  final List<AiRequest> _queue = [];
  final StreamController<AiRequest> _streamController = StreamController<AiRequest>.broadcast();
  int _processedCount = 0;
  int _failedCount = 0;
  final List<Duration> _processingTimes = [];

  /// Add request to queue
  Future<void> enqueue(AiRequest request) async {
    _queue.add(request);
    // Sort by priority (high first) then timestamp (old first)
    _queue.sort((a, b) {
      if (a.priority != b.priority) {
        return b.priority.compareTo(a.priority); // Higher priority first
      }
      return a.timestamp.compareTo(b.timestamp); // Older first
    });
    _streamController.add(request);
  }

  /// Stream of pending requests for processing
  Stream<AiRequest> get pendingStream => _streamController.stream;

  /// Remove all pending requests
  Future<void> clear() async {
    _queue.clear();
  }

  /// Get current queue metrics
  QueueMetrics get metrics {
    final avgTime = _processingTimes.isNotEmpty
        ? _processingTimes.reduce((a, b) => a + b) ~/ _processingTimes.length
        : Duration.zero;

    return QueueMetrics(
      queueLength: _queue.length,
      processedCount: _processedCount,
      failedCount: _failedCount,
      averageProcessingTime: avgTime,
    );
  }

  /// Mark request as processed (for metrics)
  void markProcessed(Duration processingTime) {
    _processedCount++;
    _processingTimes.add(processingTime);
    // Keep only last 100 processing times for average
    if (_processingTimes.length > 100) {
      _processingTimes.removeAt(0);
    }
  }

  /// Mark request as failed (for metrics)
  void markFailed() {
    _failedCount++;
  }

  /// Get next pending request without removing it
  AiRequest? peek() => _queue.isNotEmpty ? _queue.first : null;

  /// Remove and return next pending request
  AiRequest? dequeue() => _queue.isNotEmpty ? _queue.removeAt(0) : null;

  /// Check if queue has pending requests
  bool get hasPending => _queue.isNotEmpty;

  /// Get all pending requests for serialization
  List<AiRequest> getPendingRequests() => List.unmodifiable(_queue);
}

/// Metrics for queue monitoring
@freezed
abstract class QueueMetrics with _$QueueMetrics {
  const factory QueueMetrics({
    required int queueLength,
    required int processedCount,
    @Default(0) int failedCount,
    @Default(Duration.zero) Duration averageProcessingTime,
  }) = _QueueMetrics;

  factory QueueMetrics.fromJson(Map<String, dynamic> json) =>
      _$QueueMetricsFromJson(json);
}
