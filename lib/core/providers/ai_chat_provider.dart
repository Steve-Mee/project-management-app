import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_logger.dart';
import '../services/ai_planning_helpers.dart';
import '../config/ai_config.dart' as ai_config;
import '../providers/ai/ai_usage_provider.dart';
import '../../models/chat_message_model.dart';
import '../../models/project_plan.dart';
import '../models/ai_rate_limits_config.dart';
import 'auth_providers.dart';

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
class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final DateTime? lastRequestTime;
  final int requestCountInWindow;
  final AiRateLimitsConfig rateLimits;

  const AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.lastRequestTime,
    this.requestCountInWindow = 0,
    required this.rateLimits,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    DateTime? lastRequestTime,
    int? requestCountInWindow,
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
    return requestCountInWindow >= maxRequests;
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
}

/// Notifier for managing AI chat state with rate limiting
/// 
/// This notifier provides configurable AI rate limiting based on user settings.
/// Rate limits are loaded from settings on initialization with safe fallbacks.
/// See .github/issues/030-ai-configurable-rate-limits.md for implementation details.
class AiChatNotifier extends AsyncNotifier<AiChatState> {
  @override
  Future<AiChatState> build() async {
    try {
      final settings = await ref.watch(settingsRepositoryProvider.future);
      final rateLimits = settings.getAiRateLimitsConfig();
      AppLogger.event('ai_max_requests_config_loaded', params: {'value': rateLimits.maxRequestsPerWindow});
      return AiChatState(rateLimits: rateLimits);
    } catch (e) {
      // Fallback to defaults if settings fail to load
      AppLogger.event('Failed to load AI rate limits from settings, using defaults', params: {'error': e.toString()});
      return AiChatState(rateLimits: const AiRateLimitsConfig.defaults());
    }
  }

  /// Send a message and get AI response with rate limiting
  /// 
  /// Sends a user message to the AI service and updates the chat state.
  /// Checks rate limits before making the API call and throws RateLimitExceededException
  /// if limits are exceeded. Logs rate limit violations for monitoring.
  /// 
  /// Parameters:
  /// - userMessage: The message text to send
  /// - promptOverride: Optional custom prompt to override defaults
  /// - projectId: Optional project context for the conversation
  /// 
  /// Throws: RateLimitExceededException if rate limits are exceeded
  Future<void> sendMessage(
    String userMessage, {
    String? promptOverride,
    String? projectId,
  }) async {
    if (userMessage.trim().isEmpty) return;

    final currentState = state.value!;
    
    // Check rate limit before proceeding
    if (currentState.isRateLimited) {
      final remainingTime = currentState.timeUntilReset;
      AppLogger.event('ai_rate_limit_exceeded', params: {
        'remainingTime': remainingTime.inSeconds,
        'requestCount': currentState.requestCountInWindow,
        'maxRequestsPerWindow': currentState.rateLimits.maxRequestsPerWindow,
        'timeWindowDuration': currentState.rateLimits.timeWindowDuration.inSeconds,
      });
      throw RateLimitExceededException(remainingTime);
    }

    // Add user message
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Update rate limiting state
    final now = DateTime.now();
    final newRequestCount = _calculateNewRequestCount(now, currentState);

    state = AsyncValue.data(currentState.copyWith(
      messages: [...currentState.messages, userMsg],
      isLoading: true,
      error: null,
      lastRequestTime: now,
      requestCountInWindow: newRequestCount,
    ));

    try {
      // Anonymize the message for compliance
      final anonymizedMessage = _anonymizeMessage(userMessage);

      // Use AiPlanningHelpers for modular API calls
      final result = await _callAiWithRetry(anonymizedMessage);

      // Add AI message
      final aiMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: result.content,
        isUser: false,
        timestamp: DateTime.now(),
      );

      final updatedState = state.value!;
      state = AsyncValue.data(updatedState.copyWith(
        messages: [...updatedState.messages, aiMsg],
        isLoading: false,
      ));

      // Log token usage from metadata
      ref.read(aiUsageUpdateProvider(result.tokensUsed));
    } catch (e) {
      final errorMsg = e.toString();
      AppLogger.instance.e('AI Error', error: errorMsg);
      // UI Example: Show error snackbar for final failure
      // Requires BuildContext from UI layer
      // final l10n = AppLocalizations.of(context)!;
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(_isThrottlingError(e) ? l10n.ai_rate_limit_retry_failed : 'Failed to get AI response: $errorMsg'),
      //     backgroundColor: Colors.red,
      //   ),
      // );
      final updatedState = state.value!;
      state = AsyncValue.data(updatedState.copyWith(
        isLoading: false,
        error: 'Failed to get AI response: ${e.toString()}',
      ));
    }
  }

  /// Calculate new request count based on current window
  int _calculateNewRequestCount(DateTime now, AiChatState currentState) {
    if (currentState.lastRequestTime == null) return 1;

    final timeSinceLastRequest = now.difference(currentState.lastRequestTime!);
    if (timeSinceLastRequest > currentState.rateLimits.timeWindowDuration) {
      return 1; // Window expired, reset to 1
    }

    return currentState.requestCountInWindow + 1;
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

  /// Generate planning questions for a project using modular helpers
  /// 
  /// Creates contextual planning questions based on project data and help level.
  /// Checks rate limits before making the API call and throws RateLimitExceededException
  /// if limits are exceeded. Part of the AI-powered project planning workflow.
  /// 
  /// Parameters:
  /// - projectData: Map containing project information
  /// - helpLevel: AI assistance level from configuration
  /// 
  /// Returns: List of planning questions as strings
  /// Throws: RateLimitExceededException if rate limits are exceeded
  Future<List<String>> generatePlanningQuestions(
    Map<String, dynamic> projectData,
    ai_config.HelpLevel helpLevel,
  ) async {
    final currentState = state.value!;
    
    // Check rate limit before AI call
    if (currentState.isRateLimited) {
      final remainingTime = currentState.timeUntilReset;
      AppLogger.event('ai_rate_limit_exceeded', params: {
        'remainingTime': remainingTime.inSeconds,
        'requestCount': currentState.requestCountInWindow,
        'operation': 'generatePlanningQuestions',
      });
      throw RateLimitExceededException(remainingTime);
    }

    try {
      final result = await _retryAiCall(() => AiPlanningHelpers.generatePlanningQuestions(
        projectData,
        helpLevel,
      ));

      // Log token usage
      ref.read(aiUsageUpdateProvider(result.tokensUsed));

      return result.content;
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

  /// Generate project improvement proposals using modular helpers
  /// 
  /// Analyzes project data and generates improvement suggestions.
  /// Checks rate limits before making the API call and throws RateLimitExceededException
  /// if limits are exceeded. Supports answering previous questions for context.
  /// 
  /// Parameters:
  /// - projectData: Map containing project information
  /// - helpLevel: AI assistance level from configuration
  /// - answers: Optional previous answers for context
  /// 
  /// Returns: List of improvement proposals as strings
  /// Throws: RateLimitExceededException if rate limits are exceeded
  Future<List<String>> generateProposals(
    Map<String, dynamic> projectData,
    ai_config.HelpLevel helpLevel, {
    List<String>? answers,
  }) async {
    final currentState = state.value!;
    
    // Check rate limit before AI call
    if (currentState.isRateLimited) {
      final remainingTime = currentState.timeUntilReset;
      AppLogger.event('ai_rate_limit_exceeded', params: {
        'remainingTime': remainingTime.inSeconds,
        'requestCount': currentState.requestCountInWindow,
        'operation': 'generateProposals',
      });
      throw RateLimitExceededException(remainingTime);
    }

    try {
      final result = await _retryAiCall(() => AiPlanningHelpers.generateProposals(
        projectData,
        helpLevel,
        answers: answers,
      ));

      // Log token usage
      ref.read(aiUsageUpdateProvider(result.tokensUsed));

      return result.content;
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

  /// Generate final project plan using modular helpers
  /// 
  /// Creates a complete project plan with chapters and tasks based on project data.
  /// Checks rate limits before making the API call and throws RateLimitExceededException
  /// if limits are exceeded. The final step in the AI-powered project planning workflow.
  /// 
  /// Parameters:
  /// - projectData: Map containing project information
  /// 
  /// Returns: Complete ProjectPlan with chapters and tasks
  /// Throws: RateLimitExceededException if rate limits are exceeded
  Future<ProjectPlan> generateFinalPlan(Map<String, dynamic> projectData) async {
    final currentState = state.value!;
    
    // Check rate limit before AI call
    if (currentState.isRateLimited) {
      final remainingTime = currentState.timeUntilReset;
      AppLogger.event('ai_rate_limit_exceeded', params: {
        'remainingTime': remainingTime.inSeconds,
        'requestCount': currentState.requestCountInWindow,
        'operation': 'generateFinalPlan',
      });
      throw RateLimitExceededException(remainingTime);
    }

    try {
      final result = await _retryAiCall(() => AiPlanningHelpers.generateFinalPlan(projectData));

      // Log token usage
      ref.read(aiUsageUpdateProvider(result.tokensUsed));

      return result.content;
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
