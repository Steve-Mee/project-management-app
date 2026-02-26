import 'dart:async';

/// AI Request Queue Model for handling burst requests
///
/// Implements request queuing to handle AI API bursts without immediate rate limit errors.
/// Background worker processes queued requests when rate limits allow.
/// See .github/issues/033-ai-request-queue.md for implementation details.
///
/// This model provides in-memory queuing with optional Hive persistence support.
/// Requests are processed in priority order (higher priority first) then FIFO.
class AiRequest {
  final String id;
  final String action; // "chat", "summarize", "generate_questions", etc.
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final int priority; // 0=low, 1=normal, 2=high
  final Completer<dynamic> completer; // Completes when worker processes request

  const AiRequest({
    required this.id,
    required this.action,
    required this.payload,
    required this.timestamp,
    this.priority = 1,
    required this.completer,
  });

  /// Create copy with modified fields
  AiRequest copyWith({
    String? id,
    String? action,
    Map<String, dynamic>? payload,
    DateTime? timestamp,
    int? priority,
    Completer<dynamic>? completer,
  }) {
    return AiRequest(
      id: id ?? this.id,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      priority: priority ?? this.priority,
      completer: completer ?? this.completer,
    );
  }

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
      completer: Completer<dynamic>(), // New completer for restored requests
    );
  }

  @override
  String toString() {
    return 'AiRequest(id: $id, action: $action, priority: $priority, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
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
class QueueMetrics {
  final int queueLength;
  final int processedCount;
  final int failedCount;
  final Duration averageProcessingTime;

  const QueueMetrics({
    required this.queueLength,
    required this.processedCount,
    this.failedCount = 0,
    this.averageProcessingTime = Duration.zero,
  });

  @override
  String toString() {
    return 'QueueMetrics(length: $queueLength, processed: $processedCount, failed: $failedCount, avgTime: ${averageProcessingTime.inSeconds}s)';
  }
}
