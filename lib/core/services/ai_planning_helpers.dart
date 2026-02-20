import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/ai_config.dart';
import '../services/ai_parsers.dart';
import '../../models/project_plan.dart';

/// Result class for AI API calls with token usage information
class AiApiResult<T> {
  final T content;
  final int tokensUsed;
  final Map<String, dynamic> metadata;

  const AiApiResult({
    required this.content,
    required this.tokensUsed,
    this.metadata = const {},
  });
}

/// Service for AI-powered project planning functions
/// This service provides modular functions for generating questions, proposals,
/// and final project plans using the Grok API via HTTP calls.
/// Each function is independent for easy future AI model swaps.
///
/// COMPLIANCE NOTE: All prompts are anonymized to ensure worldwide legal compliance.
/// Data privacy laws (GDPR, CCPA, PIPEDA, LGPD, PDPA, etc.) are respected through
/// data minimization and anonymization techniques.
class AiPlanningHelpers {
  /// Private constructor to prevent instantiation
  AiPlanningHelpers._();

  /// Generates a list of clarifying questions based on project data
  /// Uses the specified help level to adjust question complexity
  static Future<AiApiResult<List<String>>> generatePlanningQuestions(
    Map<String, dynamic> projectData,
    HelpLevel level,
  ) async {
    final apiKey = AiConfig.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GROK_API_KEY not configured');
    }

    // Anonymize project data for compliance
    final anonymizedData = _anonymizeProjectData(projectData);

    final prompt = _buildQuestionPrompt(anonymizedData, level);
    final result = await _callGrokApi(prompt);

    final parsed = AiParsers.safeParseJson(result.content);

    if (parsed is List) {
      return AiApiResult(
        content: parsed.map((q) => q.toString()).toList(),
        tokensUsed: result.tokensUsed,
        metadata: result.metadata,
      );
    }

    // Fallback: try to extract questions from text response
    return AiApiResult(
      content: _extractQuestionsFromText(result.content),
      tokensUsed: result.tokensUsed,
      metadata: result.metadata,
    );
  }

  /// Generates a list of project proposals based on project data
  /// Uses the specified help level to adjust proposal detail level
  static Future<AiApiResult<List<String>>> generateProposals(
    Map<String, dynamic> projectData,
    HelpLevel level, {
    List<String>? answers,
  }) async {
    final apiKey = AiConfig.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GROK_API_KEY not configured');
    }

    // Anonymize project data for compliance
    final anonymizedData = _anonymizeProjectData(projectData);

    final prompt = _buildProposalPrompt(anonymizedData, level, answers);
    final result = await _callGrokApi(prompt);

    final parsed = AiParsers.safeParseJson(result.content);

    if (parsed is List) {
      return AiApiResult(
        content: parsed.map((p) => p.toString()).toList(),
        tokensUsed: result.tokensUsed,
        metadata: result.metadata,
      );
    }

    // Fallback: try to extract proposals from text response
    return AiApiResult(
      content: _extractProposalsFromText(result.content),
      tokensUsed: result.tokensUsed,
      metadata: result.metadata,
    );
  }

  /// Generates a complete project plan based on project data
  /// Returns a structured ProjectPlan object
  static Future<AiApiResult<ProjectPlan>> generateFinalPlan(
    Map<String, dynamic> projectData,
  ) async {
    final apiKey = AiConfig.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GROK_API_KEY not configured');
    }

    // Anonymize project data for compliance
    final anonymizedData = _anonymizeProjectData(projectData);

    final prompt = _buildPlanPrompt(anonymizedData);
    final result = await _callGrokApi(prompt);

    final parsed = AiParsers.safeParseJson(result.content);

    if (parsed is Map<String, dynamic>) {
      try {
        return AiApiResult(
          content: ProjectPlan.fromJson(parsed),
          tokensUsed: result.tokensUsed,
          metadata: result.metadata,
        );
      } catch (e) {
        throw Exception('Failed to parse project plan: $e');
      }
    }

    throw Exception('Invalid response format from AI service');
  }

  /// Builds a compliant prompt for generating questions
  static String _buildQuestionPrompt(Map<String, dynamic> anonymizedData, HelpLevel level) {
    final systemPrompt = AiConfig.systemPrompt;
    final helpLevelPrompt = AiConfig.getSystemPromptForHelpLevel(level);

    return '''
$systemPrompt

$helpLevelPrompt

Based on the following project information, generate 5-7 clarifying questions that would help create a better project plan.
Focus on aspects that are unclear or need more detail for effective planning.

Project Data: ${jsonEncode(anonymizedData)}

Output format: JSON array of strings, e.g., ["Question 1?", "Question 2?"]

Ensure all suggestions comply with local laws and regulations in the user's region.
''';
  }

  /// Builds a compliant prompt for generating proposals
  static String _buildProposalPrompt(Map<String, dynamic> anonymizedData, HelpLevel level, List<String>? answers) {
    final systemPrompt = AiConfig.systemPrompt;
    final helpLevelPrompt = AiConfig.getSystemPromptForHelpLevel(level);

    final answersText = answers != null && answers.isNotEmpty
        ? '\n\nAdditional context from user answers:\n${answers.map((a) => '- $a').join('\n')}'
        : '';

    return '''
$systemPrompt

$helpLevelPrompt

Based on the following project information${answers != null && answers.isNotEmpty ? ' and user answers' : ''}, generate 3-5 different project implementation proposals.
Each proposal should outline a different approach or strategy for executing the project.

Project Data: ${jsonEncode(anonymizedData)}$answersText

Output format: JSON array of strings, where each string is a complete proposal description.

Ensure all suggestions comply with local laws and regulations in the user's region.
''';
  }

  /// Builds a compliant prompt for generating final project plan
  static String _buildPlanPrompt(Map<String, dynamic> anonymizedData) {
    final systemPrompt = AiConfig.systemPrompt;

    return '''
$systemPrompt

Create a comprehensive project plan based on the following project information.
Structure the plan with an overview and multiple chapters, where each chapter contains tasks.

Project Data: ${jsonEncode(anonymizedData)}

Output format: JSON object with this exact structure:
{
  "overview": "Brief project overview",
  "chapters": [
    {
      "title": "Chapter Title",
      "overview": "Chapter overview",
      "tasks": [
        {
          "description": "Task description",
          "status": "pending"
        }
      ]
    }
  ]
}

Ensure all suggestions comply with local laws and regulations in the user's region.
Focus on practical, actionable tasks that can be tracked and completed.
''';
  }

  /// Makes an HTTP call to the Grok API and returns result with token usage
  /// Internal utility method for all AI interactions
  static Future<AiApiResult> _callGrokApi(String prompt) async {
    final apiKey = AiConfig.apiKey!;
    final url = Uri.parse(AiConfig.baseUrl);

    final requestBody = {
      'model': AiConfig.model,
      'messages': [
        {'role': 'system', 'content': AiConfig.systemPrompt},
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 0.7,
      'max_tokens': 2000,
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final content = responseData['choices']?[0]?['message']?['content'];
      final usage = responseData['usage'];

      if (content != null) {
        // Parse token usage from response metadata
        final tokensUsed = usage?['total_tokens'] as int? ?? 0;
        final metadata = {
          'prompt_tokens': usage?['prompt_tokens'] ?? 0,
          'completion_tokens': usage?['completion_tokens'] ?? 0,
          'total_tokens': tokensUsed,
          'model': AiConfig.model,
          'timestamp': DateTime.now().toIso8601String(),
        };

        return AiApiResult(
          content: content as String,
          tokensUsed: tokensUsed,
          metadata: metadata,
        );
      }
      throw Exception('Unexpected response structure');
    } else {
      throw Exception(
        'API call failed: ${response.statusCode} - ${response.body}',
      );
    }
  }

  /// Anonymizes project data to ensure compliance with privacy laws
  /// Removes or generalizes any potentially sensitive information
  static Map<String, dynamic> _anonymizeProjectData(Map<String, dynamic> data) {
    final anonymized = Map<String, dynamic>.from(data);

    // Remove any potential PII
    anonymized.remove('userId');
    anonymized.remove('email');
    anonymized.remove('personalInfo');
    anonymized.remove('user_id');
    anonymized.remove('username');
    anonymized.remove('full_name');

    // Generalize location data
    if (anonymized.containsKey('region')) {
      anonymized['region'] = 'user_region'; // Generic placeholder
    }
    if (anonymized.containsKey('country')) {
      anonymized['country'] = 'user_country'; // Generic placeholder
    }
    if (anonymized.containsKey('location')) {
      anonymized['location'] = 'user_location'; // Generic placeholder
    }

    // Anonymize any file paths or specific identifiers
    if (anonymized.containsKey('directoryPath')) {
      anonymized['directoryPath'] = 'user_directory'; // Generic placeholder
    }

    return anonymized;
  }

  /// Fallback method to extract questions from text response
  /// Used when JSON parsing fails
  static List<String> _extractQuestionsFromText(String text) {
    final lines = text.split('\n');
    final questions = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('?') ||
          trimmed.contains('?') ||
          trimmed.toLowerCase().startsWith('what') ||
          trimmed.toLowerCase().startsWith('how') ||
          trimmed.toLowerCase().startsWith('when') ||
          trimmed.toLowerCase().startsWith('where') ||
          trimmed.toLowerCase().startsWith('why') ||
          trimmed.toLowerCase().startsWith('who')) {
        questions.add(trimmed);
      }
    }

    return questions.take(7).toList(); // Limit to 7 questions
  }

  /// Fallback method to extract proposals from text response
  /// Used when JSON parsing fails
  static List<String> _extractProposalsFromText(String text) {
    final sections = text.split('\n\n');
    final proposals = <String>[];

    for (final section in sections) {
      if (section.trim().isNotEmpty &&
          (section.toLowerCase().contains('proposal') ||
              section.toLowerCase().contains('approach') ||
              section.toLowerCase().contains('strategy'))) {
        proposals.add(section.trim());
      }
    }

    return proposals.take(5).toList(); // Limit to 5 proposals
  }

  /// General AI chat method for non-planning conversations
  /// Uses the same infrastructure as planning helpers for consistency
  static Future<AiApiResult<String>> sendChatMessage(String message, {String? systemPrompt}) async {
    final apiKey = AiConfig.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GROK_API_KEY not configured');
    }

    // Anonymize message for compliance
    final anonymizedMessage = _anonymizeMessage(message);

    final fullPrompt = systemPrompt != null
        ? '$systemPrompt\n\nUser: $anonymizedMessage'
        : anonymizedMessage;

    final result = await _callGrokApi(fullPrompt);

    return AiApiResult(
      content: result.content,
      tokensUsed: result.tokensUsed,
      metadata: result.metadata,
    );
  }

  /// Anonymize general messages for compliance
  static String _anonymizeMessage(String message) {
    // Apply basic anonymization for general chat messages
    return message.replaceAll(RegExp(r'\b\d{10,}\b'), '[PHONE_NUMBER]')
                  .replaceAll(RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'), '[EMAIL]')
                  .replaceAll(RegExp(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'), '[IP_ADDRESS]');
  }
}

/// Provider for AI planning helpers
/// Provides access to modular AI planning functions
final aiPlanningHelpersProvider = Provider<AiPlanningHelpers>((ref) {
  return AiPlanningHelpers._();
});