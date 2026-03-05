// ignore_for_file: prefer_const_constructors
import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/app_logger.dart';
import '../../config/ai_config.dart' as ai_config;
import './ai_usage_provider.dart';
import './ai_providers.dart';
import '../../../models/chat_message_model.dart';
import '../../../models/project_plan.dart';
import '../../services/ai/ai_service.dart';

import '../../models/ai_rate_limits_config.dart';
import '../../models/ai_request_queue.dart';
import '../auth_providers.dart';

/// State class for AI chat
/// 
/// Contains the current state of AI chat including messages, loading status,
/// rate limiting information, and queue metrics for UI display.
/// See .github/issues/033-ai-request-queue.md for queue metrics implementation.
class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final bool isRateLimited;
  final DateTime? rateLimitResetTime;
  final AiRateLimitsConfig rateLimitsConfig;
  // Queue metrics exposed to UI (see .github/issues/033-ai-request-queue.md)
  final int queueLength;
  final int processedToday;
  final int droppedCount;

  const AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.isRateLimited = false,
    this.rateLimitResetTime,
    this.rateLimitsConfig = const AiRateLimitsConfig(),
    this.queueLength = 0,
    this.processedToday = 0,
    this.droppedCount = 0,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    bool? isRateLimited,
    DateTime? rateLimitResetTime,
    AiRateLimitsConfig? rateLimitsConfig,
    int? queueLength,
    int? processedToday,
    int? droppedCount,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isRateLimited: isRateLimited ?? this.isRateLimited,
      rateLimitResetTime: rateLimitResetTime ?? this.rateLimitResetTime,
      rateLimitsConfig: rateLimitsConfig ?? this.rateLimitsConfig,
      queueLength: queueLength ?? this.queueLength,
      processedToday: processedToday ?? this.processedToday,
      droppedCount: droppedCount ?? this.droppedCount,
    );
  }
}

/// Notifier for managing AI chat state with configurable rate limiting
/// 
/// Manages AI chat conversations with background queue processing to handle
/// request bursts without immediate rate limit errors. Includes queue metrics
/// tracking for UI feedback.
/// See .github/issues/033-ai-request-queue.md for queue implementation details.
class AiChatNotifier extends AsyncNotifier<AiChatState> {
  AiChatNotifier([AiService? aiService]) : _aiService = aiService;

  AiService? _aiService;
  AiRateLimitsConfig? _rateLimitsConfig;
  final List<DateTime> _requestTimestamps = [];
  final List<DateTime> _hourlyRequestTimestamps = [];
  final List<DateTime> _dailyRequestTimestamps = [];
  int _totalTokensUsedToday = 0;
  DateTime? _lastTokenResetDate;
  final AiRequestQueue _requestQueue = AiRequestQueue();
  Timer? _workerTimer;
  // Queue metrics tracking (see .github/issues/033-ai-request-queue.md)
  int _processedToday = 0;
  int _droppedCount = 0;
  // Maximum queue size to prevent unbounded growth
  static const int _maxQueueSize = 100;

  /// Get rate limits based on subscription level
  AiRateLimitsConfig _getSubscriptionBasedRateLimits(AiRateLimitsConfig baseConfig, String? subscriptionLevel) {
    final level = subscriptionLevel ?? 'free';
    
    // Apply subscription multipliers
    final multiplier = switch (level) {
      'premium' => 2.0,      // 2x limits for Premium
      'premium_plus' => 5.0, // 5x limits for Premium Plus
      _ => 1.0,              // 1x limits for free/basic
    };

    final scaledConfig = AiRateLimitsConfig(
      maxRequestsPerMinute: (baseConfig.maxRequestsPerMinute * multiplier).round(),
      maxRequestsPerHour: (baseConfig.maxRequestsPerHour * multiplier).round(),
      maxRequestsPerDay: (baseConfig.maxRequestsPerDay * multiplier).round(),
      maxTokensPerRequest: (baseConfig.maxTokensPerRequest * multiplier).round(),
      maxTotalTokensPerDay: (baseConfig.maxTotalTokensPerDay * multiplier).round(),
      maxRequestsPerWindow: (baseConfig.maxRequestsPerWindow * multiplier).round(),
      timeWindowDuration: baseConfig.timeWindowDuration,
      backoffBaseDelay: baseConfig.backoffBaseDelay,
      backoffMaxDelay: baseConfig.backoffMaxDelay,
      maxRetryAttempts: baseConfig.maxRetryAttempts,
      perOperationLimits: baseConfig.perOperationLimits.map(
        (operation, limit) => MapEntry(operation, (limit * multiplier).round()),
      ),
    );

    // Validate the scaled config
    return AiRateLimitsConfig.validateAiRateLimits(scaledConfig);
  }

  @override
  Future<AiChatState> build() async {
    _aiService ??= ref.read(aiServiceProvider);

    try {
      final settings = await ref.watch(settingsRepositoryProvider.future);
      final baseConfig = settings.getAiRateLimitsConfig();
      final subscriptionLevel = settings.getSubscriptionLevel();
      
      // Apply subscription-based rate limits
      _rateLimitsConfig = _getSubscriptionBasedRateLimits(baseConfig, subscriptionLevel);
      
      // Restore persisted queue from previous app sessions
      await restoreQueue();
      
      // Start background worker for queue processing
      _startWorker();
      
      // Cleanup worker when notifier is disposed
      ref.onDispose(() {
        _stopWorker();
        final service = _aiService;
        if (service != null) {
          unawaited(service.dispose());
        }
      });
      
      return AiChatState(
        rateLimitsConfig: _rateLimitsConfig!,
        queueLength: _requestQueue.metrics.queueLength,
        processedToday: _processedToday,
        droppedCount: _droppedCount,
      );
    } catch (e) {
      AppLogger.instance.e('Failed to load AI rate limits config: $e');
      // Fallback to defaults if settings fail
      _rateLimitsConfig = const AiRateLimitsConfig();
      
      // Restore persisted queue even with defaults
      await restoreQueue();
      
      // Start background worker even with defaults
      _startWorker();
      
      // Cleanup worker when notifier is disposed
      ref.onDispose(() {
        _stopWorker();
        final service = _aiService;
        if (service != null) {
          unawaited(service.dispose());
        }
      });
      
      return AiChatState(
        rateLimitsConfig: _rateLimitsConfig!,
        queueLength: _requestQueue.metrics.queueLength,
        processedToday: _processedToday,
        droppedCount: _droppedCount,
      );
    }
  }

  /// Reset token usage if it's a new day
  void _resetTokenUsageIfNeeded() {
    final now = DateTime.now();
    if (_lastTokenResetDate == null || 
        now.day != _lastTokenResetDate!.day || 
        now.month != _lastTokenResetDate!.month || 
        now.year != _lastTokenResetDate!.year) {
      _totalTokensUsedToday = 0;
      _lastTokenResetDate = now;
      _dailyRequestTimestamps.clear();
      _processedToday = 0; // Reset daily processed count
      _droppedCount = 0; // Reset dropped count for new day
    }
  }

  /// Update queue metrics in state for UI exposure
  /// 
  /// Keeps the UI synchronized with current queue status including length,
  /// daily processed count, and dropped request count.
  /// See .github/issues/033-ai-request-queue.md for metrics requirements.
  void _updateQueueMetrics() {
    final currentState = state.value;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(
        queueLength: _requestQueue.metrics.queueLength,
        processedToday: _processedToday,
        droppedCount: _droppedCount,
      ));
    }
  }

  /// Get current queue metrics for testing/UI access
  /// 
  /// Returns current queue status including pending requests,
  /// daily processed count, and dropped request count.
  /// See .github/issues/033-ai-request-queue.md for metrics tracking.
  QueueMetrics get queueMetrics {
    return QueueMetrics(
      queueLength: _requestQueue.metrics.queueLength,
      processedCount: _processedToday,
      failedCount: _droppedCount,
      averageProcessingTime: _requestQueue.metrics.averageProcessingTime,
    );
  }

  /// Check if rate limit is exceeded for the given window
  bool _isRateLimited(List<DateTime> timestamps, int maxRequests, Duration window) {
    final now = DateTime.now();
    // Remove timestamps outside the window
    timestamps.removeWhere((timestamp) => 
      now.difference(timestamp) > window);
    
    return timestamps.length >= maxRequests;
  }

  /// Check if any rate limit is exceeded
  bool _isAnyRateLimited(AiRateLimitsConfig? config) {
    if (config == null) return false;

    _resetTokenUsageIfNeeded();

    return _isRateLimited(_requestTimestamps, config.maxRequestsPerMinute, const Duration(minutes: 1)) ||
           _isRateLimited(_hourlyRequestTimestamps, config.maxRequestsPerHour, const Duration(hours: 1)) ||
           _isRateLimited(_dailyRequestTimestamps, config.maxRequestsPerDay, const Duration(days: 1)) ||
           _totalTokensUsedToday >= config.maxTotalTokensPerDay;
  }

  /// Estimate token count for a message (rough approximation)
  int _estimateTokenCount(String message) {
    // Rough approximation: ~4 characters per token for English text
    return (message.length / 4).ceil();
  }

  /// Send a message and get AI response using background queue
  Future<void> sendMessage(
    String userMessage, {
    String? promptOverride,
    String? projectId,
  }) async {
    if (userMessage.trim().isEmpty) return;

    // Ensure we have the latest state
    final currentState = state.value ?? const AiChatState();

    // Check token limit first (before queuing)
    final estimatedTokens = _estimateTokenCount(userMessage);
    final rateLimitsConfig = currentState.rateLimitsConfig;
    if (_totalTokensUsedToday + estimatedTokens > rateLimitsConfig.maxTotalTokensPerDay) {
      state = AsyncValue.data(currentState.copyWith(
        error: 'Daily token limit exceeded. Please try again tomorrow.',
        isRateLimited: true,
        rateLimitResetTime: null,
      ));
      return;
    }

    // Check per-request token limit
    if (estimatedTokens > rateLimitsConfig.maxTokensPerRequest) {
      state = AsyncValue.data(currentState.copyWith(
        error: 'Message too long. Please shorten your request.',
        isRateLimited: true,
        rateLimitResetTime: null,
      ));
      return;
    }

    // Add user message to UI immediately for better UX
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = AsyncValue.data(currentState.copyWith(
      messages: [...currentState.messages, userMsg],
      isLoading: true,
      error: null,
      isRateLimited: false,
      rateLimitResetTime: null,
    ));

    // Create and enqueue the request
    final completer = Completer<void>();
    final request = AiRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      action: 'chat',
      payload: {
        'userMessage': userMessage,
        'promptOverride': promptOverride,
        'projectId': projectId,
        'estimatedTokens': estimatedTokens,
      },
      timestamp: DateTime.now(),
      completer: completer,
    );

    await _enqueueRequest(request);
    return completer.future;
  }

  /// Enqueue an AI request for background processing
  /// 
  /// Adds requests to the queue for processing when rate limits allow.
  /// Includes overflow protection to prevent unbounded queue growth.
  /// See .github/issues/033-ai-request-queue.md for queue metrics tracking.
  Future<void> _enqueueRequest(AiRequest request) async {
    // Check for queue overflow
    if (_requestQueue.metrics.queueLength >= _maxQueueSize) {
      _droppedCount++; // Track dropped requests
      _updateQueueMetrics(); // Update UI with dropped count
      AppLogger.event('ai_queue_overflow', params: {
        'droppedCount': _droppedCount,
        'action': request.action,
      });
      // Complete the request with an error
      request.completer.completeError(Exception('Queue overflow: too many pending requests'));
      return;
    }

    // For chat messages, we already updated UI, so just enqueue
    // For other requests, enqueue directly
    await _requestQueue.enqueue(request);
    _updateQueueMetrics(); // Update UI with new queue length
  }

  /// Modular method for AI API calls via AiService abstraction.
  Future<String> _callAiWithAnonymizedPrompt(String prompt, {String? projectId}) async {
    final service = _aiService;
    if (service == null) {
      throw StateError('AiService not initialized');
    }
    return service.generate(prompt, projectId: projectId);
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

  /// Clear all messages
  void clearChat() {
    state = const AsyncValue.data(AiChatState());
  }

  /// Generate planning questions for a project using background queue
  Future<List<String>> generatePlanningQuestions(
    Map<String, dynamic> projectData,
    ai_config.HelpLevel helpLevel,
  ) async {
    final completer = Completer<List<String>>();
    final request = AiRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      action: 'generate_questions',
      payload: {
        'projectData': projectData,
        'helpLevel': helpLevel,
      },
      timestamp: DateTime.now(),
      completer: completer,
    );

    await _enqueueRequest(request);
    return completer.future;
  }

  /// Generate project improvement proposals using background queue
  Future<List<String>> generateProposals(
    Map<String, dynamic> projectData,
    ai_config.HelpLevel helpLevel, {
    List<String>? answers,
  }) async {
    final completer = Completer<List<String>>();
    final request = AiRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      action: 'generate_proposals',
      payload: {
        'projectData': projectData,
        'helpLevel': helpLevel,
        'answers': answers,
      },
      timestamp: DateTime.now(),
      completer: completer,
    );

    await _enqueueRequest(request);
    return completer.future;
  }

  /// Generate final project plan using background queue
  Future<ProjectPlan> generateFinalPlan(Map<String, dynamic> projectData) async {
    final completer = Completer<ProjectPlan>();
    final request = AiRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      action: 'generate_final_plan',
      payload: {
        'projectData': projectData,
      },
      timestamp: DateTime.now(),
      completer: completer,
    );

    await _enqueueRequest(request);
    return completer.future;
  }

  /// Persist queue to Hive for offline recovery (public for app lifecycle)
  ///
  /// Saves pending requests to local storage when app goes to background.
  /// Follows offline pattern from .github/issues/028-offline-mode.md.
  /// See .github/issues/033-ai-request-queue.md for queue persistence.
  Future<void> persistQueue() async {
    try {
      final box = await Hive.openBox<List>('ai_request_queue');
      final serializedRequests = _requestQueue.getPendingRequests().map((r) => r.toJson()).toList();
      await box.put('pending_requests', serializedRequests);
      AppLogger.event('ai_queue_persisted', params: {'count': _requestQueue.metrics.queueLength});
    } catch (e) {
      AppLogger.instance.e('Failed to persist AI request queue', error: e);
    }
  }

  /// Restore queue from Hive for offline recovery (public for app lifecycle)
  ///
  /// Loads pending requests from local storage when app starts.
  /// Follows offline pattern from .github/issues/028-offline-mode.md.
  /// See .github/issues/033-ai-request-queue.md for queue persistence.
  Future<void> restoreQueue() async {
    try {
      final box = await Hive.openBox<List>('ai_request_queue');
      final serializedRequests = box.get('pending_requests');
      if (serializedRequests != null) {
        final requests = serializedRequests
            .map((json) => AiRequest.fromJson(json))
            .toList();
        // Add restored requests back to queue
        for (final request in requests) {
          await _requestQueue.enqueue(request);
        }
        _updateQueueMetrics(); // Update UI with restored queue length
        AppLogger.event('ai_queue_restored', params: {'count': _requestQueue.metrics.queueLength});
      }
    } catch (e) {
      AppLogger.instance.e('Failed to restore AI request queue', error: e);
    }
  }

  /// Start background worker to process queued requests
  void _startWorker() {
    _stopWorker(); // Ensure no duplicate timers
    _workerTimer = Timer.periodic(const Duration(seconds: 2), (_) => _processQueue());
  }

  /// Stop background worker
  void _stopWorker() {
    _workerTimer?.cancel();
    _workerTimer = null;
  }

  /// Process queued requests respecting rate limits and exponential backoff
  Future<void> _processQueue() async {
    if (!_requestQueue.hasPending || _isAnyRateLimited(_rateLimitsConfig!)) {
      return; // Nothing to process or rate limited
    }

    final request = _requestQueue.dequeue();
    if (request == null) return;

    final startTime = DateTime.now();

    try {
      await _executeQueuedRequest(request);
      final processingTime = DateTime.now().difference(startTime);
      _requestQueue.markProcessed(processingTime);
      _processedToday++; // Track daily processed count
      _updateQueueMetrics(); // Update UI with new metrics
      AppLogger.event('ai_queue_processed', params: {
        'queueLength': _requestQueue.metrics.queueLength,
        'success': true,
        'action': request.action,
        'processingTimeMs': processingTime.inMilliseconds,
      });
    } catch (e) {
      _requestQueue.markFailed();
      // Implement exponential backoff with jitter for retries
      final retryCount = request.payload['retryCount'] as int? ?? 0;
      if (retryCount < 3) {
        // Re-queue with incremented retry count after backoff delay
        final retryDelay = _calculateBackoffDelay(retryCount);
        await Future.delayed(retryDelay);
        
        final retryRequest = request.copyWith(
          payload: {...request.payload, 'retryCount': retryCount + 1}
        );
        await _requestQueue.enqueue(retryRequest); // Re-enqueue for retry
      }
      AppLogger.event('ai_queue_processed', params: {
        'queueLength': _requestQueue.metrics.queueLength,
        'success': false,
        'action': request.action,
        'error': e.toString(),
        'retryCount': retryCount,
      });
    }
  }

  /// Execute a queued request based on its action
  Future<void> _executeQueuedRequest(AiRequest request) async {
    try {
      switch (request.action) {
        case 'chat':
          await _executeChatRequest(request);
          break;
        case 'generate_questions':
          final result = await _executeGenerateQuestionsRequest(request);
          request.completer.complete(result);
          break;
        case 'generate_proposals':
          final result = await _executeGenerateProposalsRequest(request);
          request.completer.complete(result);
          break;
        case 'generate_final_plan':
          final result = await _executeGenerateFinalPlanRequest(request);
          request.completer.complete(result);
          break;
        default:
          throw Exception('Unknown action: ${request.action}');
      }
      request.completer.complete(); // For void methods like chat
    } catch (e) {
      request.completer.completeError(e);
      rethrow;
    }
  }

  /// Execute a chat request with UI updates
  Future<void> _executeChatRequest(AiRequest request) async {
    final userMessage = request.payload['userMessage'] as String;
    
    // Record this request in rate limiting windows (now that we're actually processing)
    final now = DateTime.now();
    _requestTimestamps.add(now);
    _hourlyRequestTimestamps.add(now);
    _dailyRequestTimestamps.add(now);

    try {
      // Anonymize the message for compliance
      final anonymizedMessage = _anonymizeMessage(userMessage);

      // Use AiPlanningHelpers for modular API calls
      final result = await _callAiWithAnonymizedPrompt(
        anonymizedMessage,
        projectId: request.payload['projectId'] as String?,
      );

      // Add AI message to UI
      final aiMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: result,
        isUser: false,
        timestamp: DateTime.now(),
      );

      // Update UI state
      final currentState = state.value;
      if (currentState != null) {
        state = AsyncValue.data(currentState.copyWith(
          messages: [...currentState.messages, aiMsg],
          isLoading: false,
          isRateLimited: false,
          rateLimitResetTime: null,
        ));
      }

      // Log token usage from metadata
      final estimatedInput = request.payload['estimatedTokens'] as int? ?? _estimateTokenCount(userMessage);
      final estimatedOutput = _estimateTokenCount(result);
      final estimatedTotalTokens = estimatedInput + estimatedOutput;
      ref.read(aiUsageUpdateProvider(estimatedTotalTokens));

      // Update total tokens used with actual tokens
      _totalTokensUsedToday += estimatedTotalTokens;

    } catch (e) {
      final errorMsg = e.toString();
      AppLogger.instance.e('AI Error', error: errorMsg);
      
      // Update UI with error
      final currentState = state.value;
      if (currentState != null) {
        state = AsyncValue.data(currentState.copyWith(
          isLoading: false,
          error: 'Failed to get AI response: ${e.toString()}',
        ));
      }
      rethrow; // Re-throw for completer
    }
  }

  /// Execute a generate questions request
  Future<List<String>> _executeGenerateQuestionsRequest(AiRequest request) async {
    final projectData = request.payload['projectData'] as Map<String, dynamic>;
    final helpLevel = request.payload['helpLevel'] as ai_config.HelpLevel;
    final service = _aiService;
    if (service == null) throw StateError('AiService not initialized');

    final questions = await service.generatePlanningQuestions(
      projectData,
      helpLevel,
      projectId: request.payload['projectId'] as String?,
    );

    // Preserve usage tracking with conservative estimate.
    final estimatedTokens = _estimateTokenCount(projectData.toString()) +
        questions.fold<int>(0, (sum, q) => sum + _estimateTokenCount(q));
    ref.read(aiUsageUpdateProvider(estimatedTokens));

    return questions;
  }

  /// Execute a generate proposals request
  Future<List<String>> _executeGenerateProposalsRequest(AiRequest request) async {
    final projectData = request.payload['projectData'] as Map<String, dynamic>;
    final helpLevel = request.payload['helpLevel'] as ai_config.HelpLevel;
    final answers = request.payload['answers'] as List<String>?;
    final service = _aiService;
    if (service == null) throw StateError('AiService not initialized');

    final proposals = await service.generateProposals(
      projectData,
      helpLevel,
      answers: answers,
      projectId: request.payload['projectId'] as String?,
    );

    // Preserve usage tracking with conservative estimate.
    final estimatedTokens = _estimateTokenCount(projectData.toString()) +
        (answers?.fold<int>(0, (sum, a) => sum + _estimateTokenCount(a)) ?? 0) +
        proposals.fold<int>(0, (sum, p) => sum + _estimateTokenCount(p));
    ref.read(aiUsageUpdateProvider(estimatedTokens));

    return proposals;
  }

  /// Execute a generate final plan request
  Future<ProjectPlan> _executeGenerateFinalPlanRequest(AiRequest request) async {
    final projectData = request.payload['projectData'] as Map<String, dynamic>;
    final service = _aiService;
    if (service == null) throw StateError('AiService not initialized');

    final plan = await service.generateFinalPlan(
      projectData,
      projectId: request.payload['projectId'] as String?,
    );

    // Preserve usage tracking with conservative estimate.
    final estimatedTokens = _estimateTokenCount(projectData.toString()) +
        _estimateTokenCount(plan.overview) +
        plan.chapters.fold<int>(
          0,
          (sum, chapter) =>
              sum + _estimateTokenCount(chapter.title) +
              _estimateTokenCount(chapter.overview) +
              chapter.tasks.fold<int>(
                0,
                (taskSum, task) => taskSum + _estimateTokenCount(task.description),
              ),
        );
    ref.read(aiUsageUpdateProvider(estimatedTokens));

    return plan;
  }

  /// Calculate exponential backoff delay with jitter
  Duration _calculateBackoffDelay(int retryCount) {
    // Simple exponential backoff: base delay * 2^attempts with jitter
    const baseDelay = const Duration(seconds: 1);
    final exponentialDelay = baseDelay * pow(2, retryCount).toInt();
    final jitter = Duration(milliseconds: Random().nextInt(1000)); // 0-1 second jitter
    return exponentialDelay + jitter;
  }

  /// Clear all pending requests from the queue
  ///
  /// Removes all queued requests and cancels their pending futures.
  /// Useful for cleanup or when user wants to cancel all pending operations.
  /// See .github/issues/033-ai-request-queue.md for queue management.
  void clearQueue() {
    _requestQueue.clear();
    _updateQueueMetrics(); // Update UI with cleared queue
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

/// Temporary helper controlling the AI help level used in various UI forms.
/// Stored in-memory rather than in settings, so multiple screens can override
/// independently.
final aiHelpLevelProvider = StateProvider<ai_config.HelpLevel>(
  (ref) => ai_config.HelpLevel.basis,
);
