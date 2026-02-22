import 'package:uuid/uuid.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/app_logger.dart';
import '../services/ai_planning_helpers.dart';
import '../config/ai_config.dart' as ai_config;
import '../providers/ai/ai_usage_provider.dart';
import '../../models/chat_message_model.dart';
import '../../models/project_plan.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_usage_record.dart';

/// Custom exception for rate limit exceeded
class RateLimitExceededException implements Exception {
  final Duration backoffDuration;

  RateLimitExceededException(this.backoffDuration);

  @override
  String toString() => 'Rate limit exceeded. Try again in ${backoffDuration.inSeconds} seconds.';
}

/// State class for AI chat with rate limiting
/// 
/// This state holds the current chat messages and rate limiting status.
/// Rate limits are configurable via AiRateLimitsConfig and prevent abuse.
/// See .github/issues/030-ai-configurable-rate-limits.md for configuration details.
/// See .github/issues/034-ai-per-operation-rate-limits.md for per-operation limits.
class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final DateTime? lastRequestTime;
  final Map<String, int> requestCountInWindow; // Changed to Map for per-operation tracking
  final AiRateLimitsConfig rateLimits;

  const AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.lastRequestTime,
    this.requestCountInWindow = const {}, // Default empty map
    required this.rateLimits,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    DateTime? lastRequestTime,
    Map<String, int>? requestCountInWindow,
    AiRateLimitsConfig? rateLimits,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastRequestTime: lastRequestTime ?? this.lastRequestTime,
      requestCountInWindow: requestCountInWindow ?? this.requestCountInWindow,
      rateLimits: rateLimits ?? this.rateLimits,
    );
  }

  /// Check if rate limit is exceeded based on configurable limits
  ///
  /// Implements sliding window rate limiting with configurable max requests per window.
  /// Falls back to default of 10 requests if maxRequestsPerWindow <= 0.
  /// See .github/issues/031-ai-max-requests-config.md for configuration details.
  ///
  /// Uses the rateLimits configuration to determine if the user has exceeded
  /// the allowed number of requests within the configured time window.
  /// Returns true if rate limited, false otherwise.
  bool get isRateLimited {
    if (lastRequestTime == null) return false;
    final now = DateTime.now();
    final timeSinceLastRequest = now.difference(lastRequestTime!);

    if (timeSinceLastRequest > rateLimits.timeWindowDuration) {
      return false; // Window expired, reset counter
    }

    // Safe fallback: use default 10 if maxRequestsPerWindow is invalid
    final maxRequests = rateLimits.maxRequestsPerWindow <= 0 ? 10 : rateLimits.maxRequestsPerWindow;
    return requestCountInWindow.values.fold(0, (sum, count) => sum + count) >= maxRequests;
  }

  /// Check if specific operation is rate limited
  ///
  /// Uses per-operation limits from perOperationLimits map, falling back to global limit.
  /// See .github/issues/034-ai-per-operation-rate-limits.md for per-operation limits.
  bool isOperationRateLimited(String operation) {
    if (lastRequestTime == null) return false;
    final now = DateTime.now();
    final timeSinceLastRequest = now.difference(lastRequestTime!);

    if (timeSinceLastRequest > rateLimits.timeWindowDuration) {
      return false; // Window expired, reset counter
    }

    final limit = _getLimitForOperation(operation);
    final operationCount = requestCountInWindow[operation] ?? 0;
    return operationCount >= limit;
  }

  /// Get remaining time until rate limit resets
  /// 
  /// Calculates how much time is left before the current rate limit window expires
  /// and the request counter resets. Returns Duration.zero if not rate limited.
  Duration get timeUntilReset {
    if (lastRequestTime == null) return Duration.zero;
    final resetTime = lastRequestTime!.add(rateLimits.timeWindowDuration);
    final remaining = resetTime.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Get the rate limit for a specific operation
  ///
  /// Returns the per-operation limit if configured, otherwise falls back to global limit.
  /// This centralizes limit access and ensures consistent fallback behavior.
  /// See .github/issues/034-ai-per-operation-rate-limits.md for per-operation limits.
  int _getLimitForOperation(String operation) {
    return rateLimits.perOperationLimits[operation] ?? rateLimits.maxRequestsPerWindow;
  }
}

/// Notifier for managing AI chat state with rate limiting and request queuing
///
/// This notifier provides configurable AI rate limiting based on user settings.
/// Rate limits are loaded from settings on initialization with safe fallbacks.
/// See .github/issues/030-ai-configurable-rate-limits.md for rate limiting details.
/// See .github/issues/034-ai-per-operation-rate-limits.md for per-operation limits.
///
/// Implements request queuing to handle AI API bursts without immediate errors.
/// Background worker processes queued requests when rate limits allow.
/// See .github/issues/033-ai-request-queue.md for queue implementation details.
///
/// Features:
/// - Sliding window rate limiting with configurable limits per operation
/// - Exponential backoff retry for throttling errors per operation
/// - In-memory request queue with optional Hive persistence
/// - Queue metrics tracking (processed, dropped, queue length)
/// - Automatic queue size management (max 50 requests)
/// - Priority-based processing (higher priority first, then FIFO)
class AiChatNotifier extends AsyncNotifier<AiChatState> {
  @override
  Future<AiChatState> build() async {
    AiChatState state;
    try {
      final settings = await ref.watch(settingsRepositoryProvider.future);
      final rateLimits = settings.getAiRateLimitsConfig();
      AppLogger.event('ai_max_requests_config_loaded', params: {'value': rateLimits.maxRequestsPerWindow});
      state = AiChatState(rateLimits: rateLimits);
    } catch (e) {
      // Fallback to defaults if settings fail to load
      AppLogger.event('Failed to load AI rate limits from settings, using defaults', params: {'error': e.toString()});
      state = AiChatState(rateLimits: const AiRateLimitsConfig.defaults());
    }

    // Load persisted queue from previous app sessions
    await _loadPersistedQueue();

    return state;
  }

  // Queue worker for processing queued AI requests
  Timer? _workerTimer;
  final Map<String, Completer<dynamic>> _pendingRequests = {};
  final List<AiRequest> _requestQueue = [];

  // Queue metrics for monitoring and analytics
  int _processedToday = 0;
  int _droppedCount = 0;
  final Map<String, int> _operationProcessedToday = {};
  final Map<String, int> _operationDroppedCount = {};
  DateTime? _lastMetricsReset;

  /// Get current queue metrics for monitoring
  ///
  /// Returns metrics about queue performance and health.
  /// See .github/issues/033-ai-request-queue.md for queue implementation.
  QueueMetrics get queueMetrics {
    _resetMetricsIfNeeded();
    return QueueMetrics(
      queueLength: _requestQueue.length,
      processedCount: _processedToday,
      failedCount: _droppedCount,
    );
  }

  /// Reset daily metrics if it's a new day
  void _resetMetricsIfNeeded() {
    final now = DateTime.now();
    if (_lastMetricsReset == null ||
        now.day != _lastMetricsReset!.day ||
        now.month != _lastMetricsReset!.month ||
        now.year != _lastMetricsReset!.year) {
      _processedToday = 0;
      _droppedCount = 0;
      _operationProcessedToday.clear();
      _operationDroppedCount.clear();
      _lastMetricsReset = now;
    }
  }

  /// Persist queue to Hive for offline recovery (public for app lifecycle)
  ///
  /// Saves pending requests to local storage when app goes to background.
  /// Follows offline pattern from .github/issues/028-offline-mode.md.
  /// See .github/issues/033-ai-request-queue.md for queue persistence.
  Future<void> persistQueue() async {
    try {
      final box = await Hive.openBox<List>('ai_request_queue');
      final serializedRequests = _requestQueue.map((r) => r.toJson()).toList();
      await box.put('pending_requests', serializedRequests);
      AppLogger.event('ai_queue_persisted', params: {'count': _requestQueue.length});
    } catch (e) {
      AppLogger.instance.e('Failed to persist AI request queue', error: e);
    }
  }

  /// Load persisted queue from Hive on startup
  ///
  /// Restores pending requests from local storage after app restart.
  /// Only loads requests that are less than 24 hours old to prevent stale data.
  /// See .github/issues/033-ai-request-queue.md for queue persistence.
  Future<void> _loadPersistedQueue() async {
    try {
      final box = await Hive.openBox<List>('ai_request_queue');
      final serializedRequests = box.get('pending_requests', defaultValue: []);
      if (serializedRequests != null) {
        final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
        for (final json in serializedRequests) {
          try {
            final request = AiRequest.fromJson(json as Map<String, dynamic>);
            // Only restore recent requests
            if (request.timestamp.isAfter(cutoffTime)) {
              _enqueueRequest(request);
              // Create completer for the restored request
              _pendingRequests[request.id] = Completer<dynamic>();
            }
          } catch (e) {
            AppLogger.instance.e('Failed to deserialize AI request', error: e);
          }
        }
        AppLogger.event('ai_queue_restored', params: {'count': _requestQueue.length});
      }
    } catch (e) {
      AppLogger.instance.e('Failed to load persisted AI request queue', error: e);
    }
  }

  /// Calculate estimated cost based on token usage
  /// TODO: Use actual pricing from AI provider
  double _calculateEstimatedCost(int inputTokens, int outputTokens) {
    const double costPerToken = 0.0000015; // Example: $1.50 per 1M tokens
    return (inputTokens + outputTokens) * costPerToken;
  }
  Future<(ChatMessage, int)> _executeChatRequest(Map<String, dynamic> payload) async {
    final userMessage = payload['userMessage'] as String;
    // TODO: Use promptOverride and projectId in future AI call enhancements

    final anonymizedMessage = _anonymizeMessage(userMessage);
    final result = await _callAiWithRetry(anonymizedMessage);

    ref.read(aiUsageUpdateProvider(result.tokensUsed));

    final chatMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: result.content,
      isUser: false,
      timestamp: DateTime.now(),
    );

    return (chatMessage, result.tokensUsed);
  }

  /// Execute queued generate questions request
  Future<(List<String>, int)> _executeGenerateQuestionsRequest(Map<String, dynamic> payload) async {
    final projectData = payload['projectData'] as Map<String, dynamic>;
    final helpLevel = payload['helpLevel'] as ai_config.HelpLevel;

    final result = await _retryAiCall(() => AiPlanningHelpers.generatePlanningQuestions(
      projectData,
      helpLevel,
    ));

    ref.read(aiUsageUpdateProvider(result.tokensUsed));
    return (result.content, result.tokensUsed);
  }

  /// Execute queued generate proposals request
  Future<(List<String>, int)> _executeGenerateProposalsRequest(Map<String, dynamic> payload) async {
    final projectData = payload['projectData'] as Map<String, dynamic>;
    final helpLevel = payload['helpLevel'] as ai_config.HelpLevel;
    final answers = payload['answers'] as List<String>?;

    final result = await _retryAiCall(() => AiPlanningHelpers.generateProposals(
      projectData,
      helpLevel,
      answers: answers,
    ));

    ref.read(aiUsageUpdateProvider(result.tokensUsed));
    return (result.content, result.tokensUsed);
  }

  /// Execute queued generate plan request
  Future<(ProjectPlan, int)> _executeGeneratePlanRequest(Map<String, dynamic> payload) async {
    final projectData = payload['projectData'] as Map<String, dynamic>;

    final result = await _retryAiCall(() => AiPlanningHelpers.generateFinalPlan(projectData));

    ref.read(aiUsageUpdateProvider(result.tokensUsed));
    return (result.content, result.tokensUsed);
  }

  /// Send a message and get AI response with queuing
  ///
  /// Enqueues the message for processing instead of direct API call.
  /// Updates UI state immediately, processes asynchronously via queue worker.
  /// Preserves existing error handling and rate limiting behavior.
  /// See .github/issues/033-ai-request-queue.md for queue implementation.
  ///
  /// Parameters:
  /// - userMessage: The message text to send
  /// - promptOverride: Optional custom prompt to override defaults
  /// - projectId: Optional project context for the conversation
  Future<void> sendMessage(
    String userMessage, {
    String? promptOverride,
    String? projectId,
  }) async {
    if (userMessage.trim().isEmpty) return;

    final currentState = state.value!;

    // Check rate limit - if exceeded, enqueue anyway (queue will wait)
    final isCurrentlyLimited = currentState.isOperationRateLimited('chat');
    if (isCurrentlyLimited) {
      final remainingTime = currentState.timeUntilReset;
      final limit = _getLimitForOperation('chat');
      final chatCount = currentState.requestCountInWindow['chat'] ?? 0;
      AppLogger.event('ai_rate_limit_exceeded_queued', params: {
        'remainingTime': remainingTime.inSeconds,
        'requestCount': chatCount,
        'maxRequestsPerWindow': limit,
        'timeWindowDuration': currentState.rateLimits.timeWindowDuration.inSeconds,
        'operation': 'chat',
      });
    }

    // Add user message immediately
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Update UI state with loading
    final now = DateTime.now();
    final newRequestCounts = _calculateNewRequestCounts(now, currentState, 'chat');

    state = AsyncValue.data(currentState.copyWith(
      messages: [...currentState.messages, userMsg],
      isLoading: true,
      error: null,
      lastRequestTime: now,
      requestCountInWindow: newRequestCounts,
    ));

    // Create and enqueue the request
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final completer = Completer<ChatMessage>();
    final request = AiRequest(
      id: requestId,
      action: 'chat',
      payload: {
        'userMessage': userMessage,
        'promptOverride': promptOverride,
        'projectId': projectId,
      },
      timestamp: DateTime.now(),
      priority: 1,
      completer: completer,
    );

    _pendingRequests[requestId] = completer;
    _enqueueRequest(request);

    // Start worker if not running
    _startWorker();

    try {
      // Wait for queue processing to complete
      final aiMsg = await completer.future;

      // Update UI with AI response
      final updatedState = state.value!;
      state = AsyncValue.data(updatedState.copyWith(
        messages: [...updatedState.messages, aiMsg],
        isLoading: false,
      ));
    } catch (e) {
      final errorMsg = e.toString();
      AppLogger.instance.e('AI Queue Error', error: errorMsg);

      final updatedState = state.value!;
      state = AsyncValue.data(updatedState.copyWith(
        isLoading: false,
        error: 'Failed to get AI response: $errorMsg',
      ));
    }
  }

  /// UI Example: Queue Status Indicators for AI Chat Screen
  ///
  /// Add these components to your chat screen to show queue status to users.
  /// See .github/issues/033-ai-request-queue.md for UI integration examples.
  ///
  /// Example usage in chat screen:
  ///
  /// ```dart
  /// class AiChatScreen extends ConsumerWidget {
  ///   @override
  ///   Widget build(BuildContext context, WidgetRef ref) {
  ///     final chatState = ref.watch(aiChatProvider);
  ///     final chatNotifier = ref.read(aiChatProvider.notifier);
  ///     final l10n = AppLocalizations.of(context)!;
  ///
  ///     return Scaffold(
  ///       appBar: AppBar(
  ///         title: Text('AI Chat'),
  ///         actions: [
  ///           // Queue status badge
  ///           if (chatNotifier.queueMetrics.queueLength > 0)
  ///             Container(
  ///               padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  ///               decoration: BoxDecoration(
  ///                 color: Colors.orange,
  ///                 borderRadius: BorderRadius.circular(12),
  ///               ),
  ///               child: Text(
  ///                 l10n.queue_length(chatNotifier.queueMetrics.queueLength),
  ///                 style: TextStyle(color: Colors.white, fontSize: 12),
  ///               ),
  ///             ),
  ///         ],
  ///       ),
  ///       body: Column(
  ///         children: [
  ///           // Chat messages list
  ///           Expanded(
  ///             child: ListView.builder(
  ///               itemCount: chatState.value?.messages.length ?? 0,
  ///               itemBuilder: (context, index) {
  ///                 final message = chatState.value!.messages[index];
  ///                 return ListTile(
  ///                   title: Text(message.content),
  ///                   subtitle: message.isUser ? null : Text(l10n.ai_request_queued),
  ///                 );
  ///               },
  ///             ),
  ///           ),
  ///
  ///           // Queue processing indicator
  ///           if (chatNotifier.queueMetrics.queueLength > 0)
  ///             Container(
  ///               padding: EdgeInsets.all(8),
  ///               color: Colors.blue.withOpacity(0.1),
  ///               child: Row(
  ///                 children: [
  ///                   CircularProgressIndicator(),
  ///                   SizedBox(width: 8),
  ///                   Text(l10n.ai_queue_processing(chatNotifier.queueMetrics.queueLength)),
  ///                 ],
  ///               ),
  ///             ),
  ///
  ///           // Burst handling success message
  ///           if (chatNotifier.queueMetrics.processedCount > 0)
  ///             Container(
  ///               padding: EdgeInsets.all(8),
  ///               color: Colors.green.withOpacity(0.1),
  ///               child: Text(l10n.ai_burst_handled(chatNotifier.queueMetrics.processedCount)),
  ///             ),
  ///
  ///           // Input field
  ///           Padding(
  ///             padding: EdgeInsets.all(8),
  ///             child: Row(
  ///               children: [
  ///                 Expanded(
  ///                   child: TextField(
  ///                     controller: _messageController,
  ///                     decoration: InputDecoration(
  ///                       hintText: 'Type your message...',
  ///                       border: OutlineInputBorder(),
  ///                     ),
  ///                   ),
  ///                 ),
  ///                 IconButton(
  ///                   icon: Icon(Icons.send),
  ///                   onPressed: chatState.value?.isLoading == true ? null : () {
  ///                     chatNotifier.sendMessage(_messageController.text);
  ///                     _messageController.clear();
  ///                   },
  ///                 ),
  ///               ],
  ///             ),
  ///           ),
  ///         ],
  ///       ),
  ///     );
  ///   }
  /// }
  /// ```

  /// Calculate new request counts based on current window for specific operation
  Map<String, int> _calculateNewRequestCounts(DateTime now, AiChatState currentState, String operation) {
    if (currentState.lastRequestTime == null) {
      return {operation: 1};
    }

    final timeSinceLastRequest = now.difference(currentState.lastRequestTime!);
    if (timeSinceLastRequest > currentState.rateLimits.timeWindowDuration) {
      // Window expired, reset all counters
      return {operation: 1};
    }

    // Increment the specific operation's counter
    final newCounts = Map<String, int>.from(currentState.requestCountInWindow);
    newCounts[operation] = (newCounts[operation] ?? 0) + 1;
    return newCounts;
  }

  /// Get the rate limit for a specific AI operation
  ///
  /// Returns the configured limit for the operation from perOperationLimits,
  /// falling back to the global maxRequestsPerWindow for unknown operations.
  /// Ensures graceful fallback for operations not explicitly configured.
  /// See .github/issues/034-ai-per-operation-rate-limits.md
  int _getLimitForOperation(String operation) {
    final currentState = state.value!;
    return currentState.rateLimits.perOperationLimits[operation] ?? currentState.rateLimits.maxRequestsPerWindow;
  }

  Future<AiApiResult<String>> _callAiWithAnonymizedPrompt(String prompt) async {
    // Use the new general chat method from AiPlanningHelpers
    return await AiPlanningHelpers.sendChatMessage(prompt);
  }

  /// Check if an error is a throttling/rate limit error that should be retried
  bool _isThrottlingError(Object error) {
    if (error is RateLimitExceededException) return true;
    final errorString = error.toString().toLowerCase();
    return errorString.contains('rate limit') ||
           errorString.contains('throttle') ||
           errorString.contains('too many requests');
  }

  /// Call AI with retry logic for throttling errors
  ///
  /// Wraps the AI call with exponential backoff retry for throttling errors.
  /// Retries up to maxRetryAttempts with backoff on RateLimitExceededException or API throttling errors.
  /// See .github/issues/032-ai-exponential-backoff.md
  Future<AiApiResult<String>> _callAiWithRetry(String prompt) async {
    final currentState = state.value!;
    final maxAttempts = currentState.rateLimits.maxRetryAttempts;
    for (int attempt = 0; attempt <= maxAttempts; attempt++) {
      try {
        return await _callAiWithAnonymizedPrompt(prompt);
      } catch (e) {
        if (attempt < maxAttempts && _isThrottlingError(e)) {
          final baseDelay = currentState.rateLimits.backoffBaseDelay;
          final maxDelay = currentState.rateLimits.backoffMaxDelay;
          final maxDelayMs = maxDelay.inMilliseconds;
          final calculatedDelayMs = (baseDelay.inMilliseconds * pow(2, attempt)).toInt();
          final clampedDelayMs = calculatedDelayMs > maxDelayMs ? maxDelayMs : calculatedDelayMs;
          final delay = Duration(milliseconds: (Random().nextDouble() * clampedDelayMs).round());
          AppLogger.event('ai_retry_attempt', params: {
            'attempt': attempt,
            'delay_ms': delay.inMilliseconds,
            'reason': e.toString(),
          });
          await Future.delayed(delay);
        } else {
          if (attempt == maxAttempts) {
            AppLogger.error('AI call failed after maximum retries', error: e);
          }
          rethrow;
        }
      }
    }
    // This should not be reached, but just in case
    throw Exception('AI call failed after $maxAttempts retries');
  }

  /// Generic retry wrapper for AI API calls with exponential backoff
  ///
  /// Implements configurable retry logic with exponential backoff for AI API calls.
  /// Retries on throttling errors up to maxRetryAttempts, using full jitter backoff.
  /// Logs each retry attempt and final failures. See .github/issues/032-ai-exponential-backoff.md
  Future<T> _retryAiCall<T>(Future<T> Function() aiCall) async {
    final currentState = state.value!;
    final maxAttempts = currentState.rateLimits.maxRetryAttempts;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await aiCall();
      } catch (e) {
        if (attempt < maxAttempts - 1 && _isThrottlingError(e)) {
          final baseDelay = currentState.rateLimits.backoffBaseDelay;
          final maxDelay = currentState.rateLimits.backoffMaxDelay;
          final calculatedDelay = baseDelay * pow(2, attempt);
          final clampedDelay = calculatedDelay > maxDelay ? maxDelay : calculatedDelay;
          final delay = Duration(milliseconds: (Random().nextDouble() * clampedDelay.inMilliseconds).round());
          AppLogger.event('ai_retry_attempt', params: {
            'attempt': attempt,
            'delay_ms': delay.inMilliseconds,
            'reason': e.toString(),
          });
          // UI Example: Show snackbar/toast during backoff period
          // Requires BuildContext from UI layer (e.g., chat screen)
          // final l10n = AppLocalizations.of(context)!;
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text(l10n.ai_retry_attempt(delay.inSeconds)),
          //     duration: delay,
          //   ),
          // );
          await Future.delayed(delay);
        } else {
          if (attempt == maxAttempts - 1) {
            AppLogger.error('AI call failed after maximum retries', error: e);
          }
          rethrow;
        }
      }
    }
    throw Exception('AI call failed after $maxAttempts retries');
  }

  /// Anonymize message for worldwide compliance
  String _anonymizeMessage(String message) {
    // Remove or generalize sensitive information
    // For chat messages, this is typically less sensitive, but apply basic anonymization
    return message.replaceAll(RegExp(r'\b\d{10,}\b'), '[PHONE_NUMBER]')
                  .replaceAll(RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'), '[EMAIL]')
                  .replaceAll(RegExp(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'), '[IP_ADDRESS]');
  }

  /// Generate project plan from idea using modular helpers
  Future<void> generateProjectPlan(String projectIdea) async {
    final prompt = 'Genereer stappenplan voor project: $projectIdea';
    await sendMessage(prompt);
  }

  /// Clear all messages and reset chat state
  /// 
  /// Removes all chat messages and resets the conversation state.
  /// Rate limiting counters are preserved to maintain proper limiting behavior.
  /// Safe to call at any time without affecting rate limit enforcement.
  void clearChat() {
    final currentState = state.value!;
    state = AsyncValue.data(AiChatState(rateLimits: currentState.rateLimits));
  }

  /// Generate planning questions using queued AI processing
  ///
  /// Enqueues request for processing instead of direct API call.
  /// Preserves existing error handling and fallback behavior.
  /// See .github/issues/033-ai-request-queue.md for queue implementation.
  ///
  /// Parameters:
  /// - projectData: Map containing project information
  /// - helpLevel: AI assistance level from configuration
  ///
  /// Returns: List of planning questions as strings
  Future<List<String>> generatePlanningQuestions(
    Map<String, dynamic> projectData,
    ai_config.HelpLevel helpLevel,
  ) async {
    final currentState = state.value!;

    // Log if currently rate limited (queue will handle waiting)
    if (currentState.isOperationRateLimited('generate_questions')) {
      final remainingTime = currentState.timeUntilReset;
      final limit = _getLimitForOperation('generate_questions');
      final questionCount = currentState.requestCountInWindow['generate_questions'] ?? 0;
      AppLogger.event('ai_rate_limit_exceeded_queued', params: {
        'remainingTime': remainingTime.inSeconds,
        'requestCount': questionCount,
        'maxRequestsPerWindow': limit,
        'operation': 'generate_questions',
      });
    }

    // Create and enqueue the request
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final completer = Completer<List<String>>();
    final request = AiRequest(
      id: requestId,
      action: 'generate_questions',
      payload: {
        'projectData': projectData,
        'helpLevel': helpLevel,
      },
      timestamp: DateTime.now(),
      priority: 1,
      completer: completer,
    );

    _pendingRequests[requestId] = completer;
    _enqueueRequest(request);

    // Start worker if not running
    _startWorker();

    try {
      return await completer.future;
    } catch (e) {
      AppLogger.instance.e('Error generating planning questions', error: e);
      // Return fallback questions
      return [
        'What are the main challenges for this project?',
        'How will you measure success?',
        'What resources do you need?',
      ];
    }
  }

  /// Generate project improvement proposals using queued AI processing
  ///
  /// Enqueues request for processing instead of direct API call.
  /// Preserves existing error handling and fallback behavior.
  /// See .github/issues/033-ai-request-queue.md for queue implementation.
  ///
  /// Parameters:
  /// - projectData: Map containing project information
  /// - helpLevel: AI assistance level from configuration
  /// - answers: Optional previous answers for context
  ///
  /// Returns: List of improvement proposals as strings
  Future<List<String>> generateProposals(
    Map<String, dynamic> projectData,
    ai_config.HelpLevel helpLevel, {
    List<String>? answers,
  }) async {
    final currentState = state.value!;

    // Log if currently rate limited (queue will handle waiting)
    if (currentState.isOperationRateLimited('generate_proposals')) {
      final remainingTime = currentState.timeUntilReset;
      final limit = _getLimitForOperation('generate_proposals');
      final proposalCount = currentState.requestCountInWindow['generate_proposals'] ?? 0;
      AppLogger.event('ai_rate_limit_exceeded_queued', params: {
        'remainingTime': remainingTime.inSeconds,
        'requestCount': proposalCount,
        'maxRequestsPerWindow': limit,
        'operation': 'generate_proposals',
      });
    }

    // Create and enqueue the request
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final completer = Completer<List<String>>();
    final request = AiRequest(
      id: requestId,
      action: 'generate_proposals',
      payload: {
        'projectData': projectData,
        'helpLevel': helpLevel,
        'answers': answers,
      },
      timestamp: DateTime.now(),
      priority: 1,
      completer: completer,
    );

    _pendingRequests[requestId] = completer;
    _enqueueRequest(request);

    // Start worker if not running
    _startWorker();

    try {
      return await completer.future;
    } catch (e) {
      AppLogger.instance.e('Error generating proposals', error: e);
      return [
        'Define clear project objectives',
        'Set realistic timeline',
        'Allocate budget properly',
        'Identify potential risks',
        'Plan team communication',
      ];
    }
  }

  /// Generate final project plan using queued AI processing
  ///
  /// Enqueues request for processing instead of direct API call.
  /// Preserves existing error handling and fallback behavior.
  /// See .github/issues/033-ai-request-queue.md for queue implementation.
  ///
  /// Parameters:
  /// - projectData: Map containing project information
  ///
  /// Returns: Complete ProjectPlan with chapters and tasks
  Future<ProjectPlan> generateFinalPlan(Map<String, dynamic> projectData) async {
    final currentState = state.value!;

    // Log if currently rate limited (queue will handle waiting)
    if (currentState.isOperationRateLimited('generate_plan')) {
      final remainingTime = currentState.timeUntilReset;
      final limit = _getLimitForOperation('generate_plan');
      final planCount = currentState.requestCountInWindow['generate_plan'] ?? 0;
      AppLogger.event('ai_rate_limit_exceeded_queued', params: {
        'remainingTime': remainingTime.inSeconds,
        'requestCount': planCount,
        'maxRequestsPerWindow': limit,
        'operation': 'generate_plan',
      });
    }

    // Create and enqueue the request
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final completer = Completer<ProjectPlan>();
    final request = AiRequest(
      id: requestId,
      action: 'generate_plan',
      payload: {
        'projectData': projectData,
      },
      timestamp: DateTime.now(),
      priority: 1,
      completer: completer,
    );

    _pendingRequests[requestId] = completer;
    _enqueueRequest(request);

    // Start worker if not running
    _startWorker();

    try {
      return await completer.future;
    } catch (e) {
      AppLogger.instance.e('Error generating final plan', error: e);
      // Return a default plan
      return ProjectPlan(
        overview: 'Default project plan - please refine with AI',
        chapters: [
          PlanChapter(
            title: 'Planning Phase',
            overview: 'Initial project setup and planning',
            tasks: [
              PlanTask(description: 'Define project scope'),
              PlanTask(description: 'Create timeline'),
              PlanTask(description: 'Allocate budget'),
            ],
          ),
          PlanChapter(
            title: 'Development Phase',
            overview: 'Core development work',
            tasks: [
              PlanTask(description: 'Implement core features'),
              PlanTask(description: 'Add testing'),
            ],
          ),
          PlanChapter(
            title: 'Deployment Phase',
            overview: 'Final deployment and launch',
            tasks: [
              PlanTask(description: 'Deploy to production'),
              PlanTask(description: 'Monitor and maintain'),
            ],
          ),
        ],
      );
    }
  }

  /// Process queued AI requests respecting rate limits and backoff
  ///
  /// Background worker method that processes pending requests from the queue.
  /// Respects rate limiter and uses exponential backoff from issue 032.
  /// See .github/issues/033-ai-request-queue.md for queue integration.
  /// See .github/issues/034-ai-per-operation-rate-limits.md for per-operation limits.
  Future<void> _processQueue() async {
    if (_requestQueue.isEmpty) return;

    final currentState = state.value!;
    
    // Sort by priority (higher first) then timestamp (older first)
    _requestQueue.sort((a, b) {
      if (a.priority != b.priority) return b.priority.compareTo(a.priority);
      return a.timestamp.compareTo(b.timestamp);
    });

    final request = _requestQueue.first; // Peek at the next request
    if (currentState.isOperationRateLimited(request.action)) {
      // Apply per-operation exponential backoff
      final limit = _getLimitForOperation(request.action);
      final operationCount = currentState.requestCountInWindow[request.action] ?? 0;
      
      // Calculate backoff delay using exponential backoff formula
      final baseDelay = currentState.rateLimits.backoffBaseDelay;
      final maxDelay = currentState.rateLimits.backoffMaxDelay;
      final excessRequests = operationCount - limit + 1; // How many over the limit
      final calculatedDelay = baseDelay * pow(2, excessRequests.clamp(0, 10)); // Cap exponent
      final clampedDelay = calculatedDelay > maxDelay ? maxDelay : calculatedDelay;
      final delay = Duration(milliseconds: (Random().nextDouble() * clampedDelay.inMilliseconds).round());
      
      AppLogger.event('ai_per_op_limit_applied', params: {
        'operation': request.action,
        'limit': limit,
        'currentCount': operationCount,
        'backoffDelayMs': delay.inMilliseconds,
      });
      
      // Wait for backoff period before checking again
      await Future.delayed(delay);
      return; // Re-check on next worker cycle
    }

    // Remove from queue now that we're processing it
    _requestQueue.removeAt(0);
    final completer = _pendingRequests[request.id];

    if (completer == null) return; // Request was cancelled

    try {
      (dynamic processedResult, int tokens);
      switch (request.action) {
        case 'chat':
          (processedResult, tokens) = await _executeChatRequest(request.payload);
          break;
        case 'generate_questions':
          (processedResult, tokens) = await _executeGenerateQuestionsRequest(request.payload);
          break;
        case 'generate_proposals':
          (processedResult, tokens) = await _executeGenerateProposalsRequest(request.payload);
          break;
        case 'generate_plan':
          (processedResult, tokens) = await _executeGeneratePlanRequest(request.payload);
          break;
        default:
          throw Exception('Unknown action: ${request.action}');
      }

      // Update rate limiting state after successful processing
      final now = DateTime.now();
      final newRequestCounts = _calculateNewRequestCounts(now, currentState, request.action);
      state = AsyncValue.data(currentState.copyWith(
        lastRequestTime: now,
        requestCountInWindow: newRequestCounts,
      ));

      _resetMetricsIfNeeded();
      _processedToday++;
      _operationProcessedToday[request.action] = (_operationProcessedToday[request.action] ?? 0) + 1;
      completer.complete(processedResult);

      // Log usage record
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final record = AiUsageRecord(
        id: const Uuid().v4(),
        timestamp: now,
        operation: request.action,
        inputTokens: tokens,
        outputTokens: 0,
        estimatedCost: _calculateEstimatedCost(tokens, 0),
        userId: userId,
        projectId: null, // TODO: Extract from payload if available
        success: true,
        errorMessage: null,
      );
      await ref.read(aiUsageHistoryProvider.notifier).logUsage(record);

      AppLogger.event('ai_queue_processed', params: {
        'queueLength': _requestQueue.length,
        'success': true,
        'action': request.action,
        'processedToday': _processedToday,
        'operationProcessedToday': _operationProcessedToday[request.action],
      });
    } catch (e) {
      _resetMetricsIfNeeded();
      _droppedCount++;
      _operationDroppedCount[request.action] = (_operationDroppedCount[request.action] ?? 0) + 1;
      completer.completeError(e);

      // Log usage record for failed request
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final record = AiUsageRecord(
        id: const Uuid().v4(),
        timestamp: DateTime.now(),
        operation: request.action,
        inputTokens: 0,
        outputTokens: 0,
        estimatedCost: 0.0,
        userId: userId,
        projectId: null,
        success: false,
        errorMessage: e.toString(),
      );
      await ref.read(aiUsageHistoryProvider.notifier).logUsage(record);

      AppLogger.event('ai_queue_processed', params: {
        'queueLength': _requestQueue.length,
        'success': false,
        'action': request.action,
        'error': e.toString(),
        'droppedCount': _droppedCount,
        'operationDroppedCount': _operationDroppedCount[request.action],
      });
    }
  }

  /// Enqueue a request, dropping oldest if queue is full
  ///
  /// Prevents unlimited queue growth by dropping oldest low-priority requests.
  /// Maximum queue size is 50 requests to prevent memory issues.
  void _enqueueRequest(AiRequest request) {
    const maxQueueSize = 50;

    if (_requestQueue.length >= maxQueueSize) {
      // Remove oldest low-priority request
      final oldRequests = _requestQueue.where((r) => r.priority == 0).toList();
      if (oldRequests.isNotEmpty) {
        oldRequests.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        final toRemove = oldRequests.first;
        _requestQueue.remove(toRemove);
        _pendingRequests.remove(toRemove.id);
        _droppedCount++;
        AppLogger.event('ai_queue_dropped', params: {
          'reason': 'queue_full',
          'action': toRemove.action,
          'droppedCount': _droppedCount
        });
      }
    }

    _requestQueue.add(request);
  }

  /// Start the background queue worker
  ///
  /// Initializes Timer.periodic to process queued requests.
  /// Worker runs every few seconds to check for processable requests.
  void _startWorker() {
    _stopWorker(); // Ensure no duplicate timers
    _workerTimer = Timer.periodic(const Duration(seconds: 5), (_) => _processQueue());
  }

  /// Stop the background queue worker
  ///
  /// Cancels the worker timer and cleans up resources.
  void _stopWorker() {
    _workerTimer?.cancel();
    _workerTimer = null;
  }

  /// Clear all pending requests from the queue
  ///
  /// Removes all queued requests and cancels their pending futures.
  /// Useful for cleanup or when user wants to cancel all pending operations.
  /// See .github/issues/033-ai-request-queue.md for queue management.
  void clearQueue() {
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Request cancelled - queue cleared'));
      }
    }
    _pendingRequests.clear();
    _requestQueue.clear();
    AppLogger.event('ai_queue_cleared', params: {'wasCleared': true});
  }
}

/// Provider for AI chat state
final aiChatProvider = AsyncNotifierProvider<AiChatNotifier, AiChatState>(
  AiChatNotifier.new,
);

/// Notifier for toggling project file usage in AI prompts.
class UseProjectFilesNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setEnabled(bool value) {
    state = value;
  }
}

/// Controls whether project files are included in AI prompts.
final useProjectFilesProvider =
    NotifierProvider<UseProjectFilesNotifier, bool>(
  UseProjectFilesNotifier.new,
);

/// Provider for AI usage repository
final aiUsageRepositoryProvider = Provider<IAiUsageRepository>((ref) {
  return AiUsageRepository();
});
