import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_logger.dart';
import '../services/ai_planning_helpers.dart';
import '../config/ai_config.dart' as ai_config;
import '../providers/ai/ai_usage_provider.dart';
import '../../models/chat_message_model.dart';
import '../../models/project_plan.dart';

/// State class for AI chat with rate limiting
class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final DateTime? lastRequestTime;
  final int requestCountInWindow;
  final Duration rateLimitWindow;

  const AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.lastRequestTime,
    this.requestCountInWindow = 0,
    this.rateLimitWindow = const Duration(minutes: 1),
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    DateTime? lastRequestTime,
    int? requestCountInWindow,
    Duration? rateLimitWindow,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastRequestTime: lastRequestTime ?? this.lastRequestTime,
      requestCountInWindow: requestCountInWindow ?? this.requestCountInWindow,
      rateLimitWindow: rateLimitWindow ?? this.rateLimitWindow,
    );
  }

  /// Check if rate limit is exceeded
  /// TODO: Make rate limits configurable
  bool get isRateLimited {
    if (lastRequestTime == null) return false;
    final now = DateTime.now();
    final timeSinceLastRequest = now.difference(lastRequestTime!);

    if (timeSinceLastRequest > rateLimitWindow) {
      return false; // Window expired, reset counter
    }

    // TODO: Make max requests per window configurable (currently 10 per minute)
    return requestCountInWindow >= 10;
  }

  /// Get remaining time until rate limit resets
  Duration get timeUntilReset {
    if (lastRequestTime == null) return Duration.zero;
    final resetTime = lastRequestTime!.add(rateLimitWindow);
    final remaining = resetTime.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

/// Notifier for managing AI chat state with rate limiting
/// TODO: Add exponential backoff for rate limits
/// TODO: Add request queuing for burst handling
/// TODO: Add different rate limits for different AI operations
class AiChatNotifier extends Notifier<AiChatState> {
  @override
  AiChatState build() {
    return const AiChatState();
  }

  /// Send a message and get AI response with rate limiting
  Future<void> sendMessage(
    String userMessage, {
    String? promptOverride,
    String? projectId,
  }) async {
    if (userMessage.trim().isEmpty) return;

    // Check rate limit
    if (state.isRateLimited) {
      final remainingTime = state.timeUntilReset;
      state = state.copyWith(
        error: 'Rate limit exceeded. Please wait ${remainingTime.inSeconds} seconds.',
      );
      AppLogger.event('ai_rate_limit_exceeded', details: {
        'remainingTime': remainingTime.inSeconds,
        'requestCount': state.requestCountInWindow,
      });
      return;
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
    final newRequestCount = _calculateNewRequestCount(now);

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
      lastRequestTime: now,
      requestCountInWindow: newRequestCount,
    );

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

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isLoading: false,
      );

      // Log token usage from metadata
      ref.read(aiUsageUpdateProvider(result.tokensUsed));
    } catch (e) {
      final errorMsg = e.toString();
      AppLogger.instance.e('AI Error', error: errorMsg);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get AI response: ${e.toString()}',
      );
    }
  }

  /// Calculate new request count based on current window
  int _calculateNewRequestCount(DateTime now) {
    if (state.lastRequestTime == null) return 1;

    final timeSinceLastRequest = now.difference(state.lastRequestTime!);
    if (timeSinceLastRequest > state.rateLimitWindow) {
      return 1; // Window expired, reset to 1
    }

    return state.requestCountInWindow + 1;
  }

  /// Modular method for AI API calls using AiPlanningHelpers
  Future<AiApiResult<String>> _callAiWithAnonymizedPrompt(String prompt) async {
    // Use the new general chat method from AiPlanningHelpers
    return await AiPlanningHelpers.sendChatMessage(prompt);
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
    state = const AiChatState();
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
final aiChatProvider = NotifierProvider<AiChatNotifier, AiChatState>(
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
