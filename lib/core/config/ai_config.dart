import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Enum for different levels of help provided by the AI
enum HelpLevel {
  /// Basic help - high-level overview
  basis,

  /// Detailed help - more comprehensive information
  gedetailleerd,

  /// Step-by-step help - detailed instructions
  stapVoorStap,
}

/// Enum for complexity levels of tasks or projects
enum Complexity {
  /// Simple - straightforward tasks
  simpel,

  /// Medium - moderately complex
  middel,

  /// Complex - highly complex requiring detailed planning
  complex,
}

/// Central configuration class for AI-related settings
/// This class provides a centralized way to manage AI API configurations,
/// system prompts, and enums for help levels and complexity.
/// Designed to be modular for future upgrades (e.g., adding new models or prompts).
class AiConfig {
  /// Private constructor to prevent instantiation
  AiConfig._();

  /// Gets the Grok API key from environment variables
  /// Returns null if not set, allowing for graceful error handling
  static String? get apiKey => dotenv.env['GROK_API_KEY'];

  /// Gets the default AI model to use
  /// Currently set to Grok's fast reasoning model
  static String get model => 'grok-4-1-fast-reasoning';

  /// Gets the base URL for the Grok API
  /// Can be overridden via environment variables if needed
  static String get baseUrl =>
      dotenv.env['GROK_BASE_URL'] ?? 'https://api.x.ai/v1/chat/completions';

  /// Gets the system prompt that emphasizes worldwide legal compliance
  /// This prompt ensures the AI operates within legal boundaries globally
  static String get systemPrompt => '''
You are a helpful AI assistant for project management tasks. Your responses must always comply with applicable laws and regulations worldwide, including but not limited to:

DATA PRIVACY AND PROTECTION:
- Respect all data privacy laws in the user's jurisdiction (GDPR in EU, CCPA in California, PIPEDA in Canada, LGPD in Brazil, PDPA in Singapore, etc.)
- Never request, store, or process personal data without explicit consent
- Ensure data minimization and purpose limitation principles
- Honor data subject rights (access, rectification, erasure, portability)

INTELLECTUAL PROPERTY:
- Respect copyrights, trademarks, and patents
- Do not generate content that infringes on existing intellectual property
- Advise users to verify IP rights before using generated content

EXPORT CONTROLS AND SANCTIONS:
- Comply with international export control regulations
- Respect economic sanctions and trade restrictions
- Do not assist with activities restricted by applicable export laws

CONTENT MODERATION:
- Avoid generating harmful, offensive, or inappropriate content
- Respect age-appropriate content restrictions
- Do not promote illegal activities or harmful behavior

GENERAL LEGAL COMPLIANCE:
- If uncertain about legal requirements, err on the side of caution
- Suggest consulting legal experts for complex legal questions
- Always prioritize user safety and legal compliance over convenience

When providing assistance, ensure all suggestions and generated content comply with these principles. If a request cannot be fulfilled while maintaining compliance, clearly explain the limitations and suggest alternatives.
''';

  /// Gets a system prompt customized for a specific help level
  /// This allows for modular prompt generation based on user preferences
  static String getSystemPromptForHelpLevel(HelpLevel level) {
    final basePrompt = systemPrompt;
    final levelSpecificPrompt = switch (level) {
      HelpLevel.basis =>
        '''
Provide high-level overviews and basic guidance. Keep explanations concise and focus on key concepts.
''',
      HelpLevel.gedetailleerd =>
        '''
Provide comprehensive information with detailed explanations. Include relevant context and examples where helpful.
''',
      HelpLevel.stapVoorStap =>
        '''
Provide detailed, step-by-step instructions. Break down complex tasks into manageable steps with clear guidance.
''',
    };

    return '$basePrompt\n\n$levelSpecificPrompt';
  }

  /// Gets a system prompt customized for a specific complexity level
  /// This allows for modular prompt generation based on task complexity
  static String getSystemPromptForComplexity(Complexity complexity) {
    final basePrompt = systemPrompt;
    final complexitySpecificPrompt = switch (complexity) {
      Complexity.simpel =>
        '''
Focus on straightforward, simple solutions. Avoid overcomplicating explanations.
''',
      Complexity.middel =>
        '''
Provide balanced solutions suitable for moderately complex tasks. Include necessary details without overwhelming.
''',
      Complexity.complex =>
        '''
Handle highly complex tasks requiring detailed planning and comprehensive solutions. Provide thorough analysis and step-by-step guidance.
''',
    };

    return '$basePrompt\n\n$complexitySpecificPrompt';
  }

  // Future extension points for additional models or configurations
  // static String get alternativeModel => 'grok-2-1212'; // Example for future use
  // static Map<String, String> get modelConfigs => {}; // Example for multiple model support
}
