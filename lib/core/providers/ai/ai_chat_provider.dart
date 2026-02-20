import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/app_logger.dart';
import '../../services/ai_planning_helpers.dart';
import '../../config/ai_config.dart' as ai_config;
import './ai_usage_provider.dart';
import '../../../models/chat_message_model.dart';
import '../../../models/project_plan.dart';

/// State class for AI chat
class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final bool isRateLimited;
  final DateTime? rateLimitResetTime;

  const AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.isRateLimited = false,
    this.rateLimitResetTime,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    bool? isRateLimited,
    DateTime? rateLimitResetTime,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isRateLimited: isRateLimited ?? this.isRateLimited,
      rateLimitResetTime: rateLimitResetTime ?? this.rateLimitResetTime,
    );
  }
}

/// Notifier for managing AI chat state with modular rate limiting
class AiChatNotifier extends Notifier<AiChatState> {
  // Rate limiting configuration
  static const int _maxRequestsPerMinute = 10; // Configurable limit
  static const Duration _rateLimitWindow = Duration(minutes: 1);
  
  final List<DateTime> _requestTimestamps = [];
  
  @override
  AiChatState build() {
    return const AiChatState();
  }

  /// Check if rate limit is exceeded
  bool _isRateLimited() {
    final now = DateTime.now();
    // Remove timestamps outside the window
    _requestTimestamps.removeWhere((timestamp) => 
      now.difference(timestamp) > _rateLimitWindow);
    
    return _requestTimestamps.length >= _maxRequestsPerMinute;
  }

  /// Get time until rate limit resets
  DateTime? _getRateLimitResetTime() {
    if (_requestTimestamps.isEmpty) return null;
    final oldestRequest = _requestTimestamps.first;
    return oldestRequest.add(_rateLimitWindow);
  }

  /// Send a message and get AI response using modular helpers with rate limiting
  Future<void> sendMessage(
    String userMessage, {
    String? promptOverride,
    String? projectId,
  }) async {
    if (userMessage.trim().isEmpty) return;

    // Check rate limiting
    if (_isRateLimited()) {
      state = state.copyWith(
        error: 'Rate limit exceeded. Please wait before sending another message.',
        isRateLimited: true,
        rateLimitResetTime: _getRateLimitResetTime(),
      );
      return;
    }

    // Record this request
    _requestTimestamps.add(DateTime.now());

    // Add user message
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
      error: null,
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
        isRateLimited: false, // Clear rate limit on success
        rateLimitResetTime: null,
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

/// Temporary helper controlling the AI help level used in various UI forms.
/// Stored in-memory rather than in settings, so multiple screens can override
/// independently.
final aiHelpLevelProvider = StateProvider<ai_config.HelpLevel>(
  (ref) => ai_config.HelpLevel.basis,
);