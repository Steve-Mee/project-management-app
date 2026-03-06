import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app_config.dart';

/// Enum for different levels of help provided by the AI.
enum HelpLevel {
  /// Basic help - high-level overview.
  basis,

  /// Detailed help - more comprehensive information.
  gedetailleerd,

  /// Step-by-step help - detailed instructions.
  stapVoorStap,
}

extension HelpLevelApi on HelpLevel {
  String get apiName => switch (this) {
        HelpLevel.basis => 'basic',
        HelpLevel.gedetailleerd => 'detailed',
        HelpLevel.stapVoorStap => 'stepByStep',
      };

  static HelpLevel fromApiName(Object? value) {
    if (value is! String) {
      return HelpLevel.basis;
    }

    switch (value) {
      case 'basis':
      case 'basic':
        return HelpLevel.basis;
      case 'gedetailleerd':
      case 'detailed':
        return HelpLevel.gedetailleerd;
      case 'stapVoorStap':
      case 'stepByStep':
        return HelpLevel.stapVoorStap;
      default:
        return HelpLevel.basis;
    }
  }
}

/// Enum for complexity levels of tasks or projects.
enum Complexity {
  /// Simple - straightforward tasks.
  simpel,

  /// Medium - moderately complex.
  middel,

  /// Complex - highly complex requiring detailed planning.
  complex,
}

extension ComplexityApi on Complexity {
  String get apiName => switch (this) {
        Complexity.simpel => 'simple',
        Complexity.middel => 'medium',
        Complexity.complex => 'complex',
      };

  static Complexity fromApiName(Object? value) {
    if (value is! String) {
      return Complexity.simpel;
    }

    switch (value) {
      case 'simpel':
      case 'simple':
        return Complexity.simpel;
      case 'middel':
      case 'medium':
        return Complexity.middel;
      case 'complex':
        return Complexity.complex;
      default:
        return Complexity.simpel;
    }
  }
}

/// Central configuration class for AI-related settings.
class AiConfig {
  AiConfig._();

  static String? get apiKey => AppConfig.openaiApiKey;

  static String get model => 'grok-4-1-fast-reasoning';

  static String get baseUrl =>
      dotenv.env['GROK_BASE_URL'] ?? 'https://api.x.ai/v1/chat/completions';

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
}
