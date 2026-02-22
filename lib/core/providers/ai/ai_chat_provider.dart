import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/app_logger.dart';
import '../../services/ai_planning_helpers.dart';
import '../../config/ai_config.dart' as ai_config;
import './ai_usage_provider.dart';
import '../../../models/chat_message_model.dart';
import '../../../models/project_plan.dart';
import '../../models/ai_rate_limits_config.dart';
import '../auth_providers.dart';

/// State class for AI chat
class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final bool isRateLimited;
  final DateTime? rateLimitResetTime;
  final AiRateLimitsConfig rateLimitsConfig;

  const AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.isRateLimited = false,
    this.rateLimitResetTime,
    this.rateLimitsConfig = const AiRateLimitsConfig.defaults(),
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    bool? isRateLimited,
    DateTime? rateLimitResetTime,
    AiRateLimitsConfig? rateLimitsConfig,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isRateLimited: isRateLimited ?? this.isRateLimited,
      rateLimitResetTime: rateLimitResetTime ?? this.rateLimitResetTime,
      rateLimitsConfig: rateLimitsConfig ?? this.rateLimitsConfig,
    );
  }
}

/// Notifier for managing AI chat state with configurable rate limiting
class AiChatNotifier extends AsyncNotifier<AiChatState> {
  AiRateLimitsConfig? _rateLimitsConfig;
  final List<DateTime> _requestTimestamps = [];
  final List<DateTime> _hourlyRequestTimestamps = [];
  final List<DateTime> _dailyRequestTimestamps = [];
  int _totalTokensUsedToday = 0;
  DateTime? _lastTokenResetDate;

  @override
  Future<AiChatState> build() async {
    try {
      final settings = await ref.watch(settingsRepositoryProvider.future);
      _rateLimitsConfig = settings.getAiRateLimitsConfig();
      // Validate the config to ensure safe values
      _rateLimitsConfig = AiRateLimitsConfig.validateAiRateLimits(_rateLimitsConfig!);
      return AiChatState(rateLimitsConfig: _rateLimitsConfig!);
    } catch (e) {
      AppLogger.instance.e('Failed to load AI rate limits config: $e');
      // Fallback to defaults if settings fail
      _rateLimitsConfig = AiRateLimitsConfig.defaults();
      return AiChatState(rateLimitsConfig: _rateLimitsConfig!);
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
    }
  }

  /// Check if rate limit is exceeded for the given window
  bool _isRateLimited(List<DateTime> timestamps, int maxRequests, Duration window) {
    final now = DateTime.now();
    // Remove timestamps outside the window
    timestamps.removeWhere((timestamp) => 
      now.difference(timestamp) > window);
    
    return timestamps.length >= maxRequests;
  }

  /// Get time until rate limit resets for the given window
  DateTime? _getRateLimitResetTimeForWindow(List<DateTime> timestamps, Duration window) {
    if (timestamps.isEmpty) return null;
    final oldestRequest = timestamps.first;
    return oldestRequest.add(window);
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

  /// Get the most restrictive rate limit reset time
  DateTime? _getRateLimitResetTime(AiRateLimitsConfig? config) {
    if (config == null) return null;

    final now = DateTime.now();
    DateTime? resetTime;

    // Check minute limit
    if (_requestTimestamps.length >= config.maxRequestsPerMinute) {
      final minuteReset = _getRateLimitResetTimeForWindow(_requestTimestamps, const Duration(minutes: 1));
      if (minuteReset != null && (resetTime == null || minuteReset.isAfter(resetTime))) { // ignore: unnecessary_null_comparison
        resetTime = minuteReset;
      }
    }

    // Check hour limit
    if (_hourlyRequestTimestamps.length >= config.maxRequestsPerHour) {
      final hourReset = _getRateLimitResetTimeForWindow(_hourlyRequestTimestamps, const Duration(hours: 1));
      if (hourReset != null && (resetTime == null || hourReset.isAfter(resetTime))) {
        resetTime = hourReset;
      }
    }

    // Check day limit
    if (_dailyRequestTimestamps.length >= config.maxRequestsPerDay) {
      final dayReset = _getRateLimitResetTimeForWindow(_dailyRequestTimestamps, const Duration(days: 1));
      if (dayReset != null && (resetTime == null || dayReset.isAfter(resetTime))) {
        resetTime = dayReset;
      }
    }

    // Check token limit (resets at midnight)
    if (_totalTokensUsedToday >= config.maxTotalTokensPerDay) {
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      if (resetTime == null || tomorrow.isAfter(resetTime)) {
        resetTime = tomorrow;
      }
    }

    return resetTime;
  }

  /// Estimate token count for a message (rough approximation)
  int _estimateTokenCount(String message) {
    // Rough approximation: ~4 characters per token for English text
    return (message.length / 4).ceil();
  }

  /// Send a message and get AI response using modular helpers with rate limiting
  Future<void> sendMessage(
    String userMessage, {
    String? promptOverride,
    String? projectId,
  }) async {
    if (userMessage.trim().isEmpty) return;

    // Ensure we have the latest state
    final currentState = state.value ?? const AiChatState();

    // Check token limit first (before API call)
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

    // Check rate limiting
    if (_isAnyRateLimited(rateLimitsConfig)) {
      state = AsyncValue.data(currentState.copyWith(
        error: 'Rate limit exceeded. Please wait before sending another message.',
        isRateLimited: true,
        rateLimitResetTime: _getRateLimitResetTime(rateLimitsConfig),
      ));
      return;
    }

    // Record this request in all time windows
    final now = DateTime.now();
    _requestTimestamps.add(now);
    _hourlyRequestTimestamps.add(now);
    _dailyRequestTimestamps.add(now);

    // Add user message
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

    try {
      // Anonymize the message for compliance
      final anonymizedMessage = _anonymizeMessage(userMessage);

      // Use AiPlanningHelpers for modular API calls
      final result = await _callAiWithAnonymizedPrompt(anonymizedMessage);

      // Add AI message
      final aiMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: result.content,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = AsyncValue.data(state.value!.copyWith(
        messages: [...state.value!.messages, aiMsg],
        isLoading: false,
        isRateLimited: false, // Clear rate limit on success
        rateLimitResetTime: null,
      ));

      // Log token usage from metadata
      ref.read(aiUsageUpdateProvider(result.tokensUsed));

      // Update total tokens used with actual tokens
      _totalTokensUsedToday += result.tokensUsed;
    } catch (e) {
      final errorMsg = e.toString();
      AppLogger.instance.e('AI Error', error: errorMsg);
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: 'Failed to get AI response: ${e.toString()}',
      ));
    }
  }

  /// Modular method for AI API calls using AiPlanningHelpers
  Future<AiApiResult<String>> _callAiWithAnonymizedPrompt(String prompt) async {
    // TEMP: Always return mock response for testing
    return AiApiResult<String>(
      content: 'Mock AI response for testing',
      tokensUsed: 50,
      metadata: {'model': 'test-model', 'mock': true},
    );
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

  /// Generate planning questions for a project using modular helpers
  /// Now uses AiPlanningHelpers with anonymization and token logging
  Future<List<String>> generatePlanningQuestions(
    Map<String, dynamic> projectData,
    ai_config.HelpLevel helpLevel,
  ) async {
    try {
      final result = await AiPlanningHelpers.generatePlanningQuestions(
        projectData,
        helpLevel,
      );

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
  /// Now uses AiPlanningHelpers with anonymization and token logging
  Future<List<String>> generateProposals(
    Map<String, dynamic> projectData,
    ai_config.HelpLevel helpLevel, {
    List<String>? answers,
  }) async {
    try {
      final result = await AiPlanningHelpers.generateProposals(
        projectData,
        helpLevel,
        answers: answers,
      );

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
  /// Now uses AiPlanningHelpers with anonymization and token logging
  Future<ProjectPlan> generateFinalPlan(Map<String, dynamic> projectData) async {
    try {
      final result = await AiPlanningHelpers.generateFinalPlan(projectData);

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

/// Temporary helper controlling the AI help level used in various UI forms.
/// Stored in-memory rather than in settings, so multiple screens can override
/// independently.
final aiHelpLevelProvider = StateProvider<ai_config.HelpLevel>(
  (ref) => ai_config.HelpLevel.basis,
);