import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';
import '../services/ai_parsers.dart';
import '../../models/project_plan.dart';

/// Service for AI-powered project planning functions
/// This service provides modular functions for generating questions, proposals,
/// and final project plans using the Grok API via HTTP calls.
/// Each function is independent for easy future AI model swaps.
class AiPlanningService {
  /// Private constructor to prevent instantiation
  AiPlanningService._();

  /// Generates a list of clarifying questions based on project data
  /// Uses the specified help level to adjust question complexity
  static Future<List<String>> generateQuestions(
    Map<String, dynamic> projectData,
    HelpLevel level,
  ) async {
    final apiKey = AiConfig.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GROK_API_KEY not configured');
    }

    // Anonymize project data for compliance
    final anonymizedData = _anonymizeProjectData(projectData);

    final prompt =
        '''
Based on the following project information, generate 5-7 clarifying questions that would help create a better project plan.
Focus on aspects that are unclear or need more detail for effective planning.

Project Data: ${jsonEncode(anonymizedData)}

Help Level: ${level.name}

Output format: JSON array of strings, e.g., ["Question 1?", "Question 2?"]

Ensure all suggestions comply with local laws and regulations in the user's region.
''';

    final response = await _callGrokApi(prompt);
    final parsed = AiParsers.safeParseJson(response);

    if (parsed is List) {
      return parsed.map((q) => q.toString()).toList();
    }

    // Fallback: try to extract questions from text response
    return _extractQuestionsFromText(response);
  }

  /// Generates a list of project proposals based on project data
  /// Uses the specified help level to adjust proposal detail level
  static Future<List<String>> generateProposals(
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

    final answersText = answers != null && answers.isNotEmpty
        ? '\n\nAdditional context from user answers:\n${answers.map((a) => '- $a').join('\n')}'
        : '';

    final prompt =
        '''
Based on the following project information$answersText.isNotEmpty ? ' and user answers' : '', generate 3-5 different project implementation proposals.
Each proposal should outline a different approach or strategy for executing the project.

Project Data: ${jsonEncode(anonymizedData)}$answersText

Help Level: ${level.name}

Output format: JSON array of strings, where each string is a complete proposal description.

Ensure all suggestions comply with local laws and regulations in the user's region.
''';

    final response = await _callGrokApi(prompt);
    final parsed = AiParsers.safeParseJson(response);

    if (parsed is List) {
      return parsed.map((p) => p.toString()).toList();
    }

    // Fallback: try to extract proposals from text response
    return _extractProposalsFromText(response);
  }

  /// Generates a complete project plan based on project data
  /// Returns a structured ProjectPlan object
  static Future<ProjectPlan> generateFinalPlan(
    Map<String, dynamic> projectData,
  ) async {
    final apiKey = AiConfig.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GROK_API_KEY not configured');
    }

    // Anonymize project data for compliance
    final anonymizedData = _anonymizeProjectData(projectData);

    final prompt =
        '''
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

    final response = await _callGrokApi(prompt);
    final parsed = AiParsers.safeParseJson(response);

    if (parsed is Map<String, dynamic>) {
      try {
        return ProjectPlan.fromJson(parsed);
      } catch (e) {
        throw Exception('Failed to parse project plan: $e');
      }
    }

    throw Exception('Invalid response format from AI service');
  }

  /// Makes an HTTP call to the Grok API
  /// Internal utility method for all AI interactions
  static Future<String> _callGrokApi(String prompt) async {
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
      if (content != null) {
        return content as String;
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

    // Generalize location data
    if (anonymized.containsKey('region')) {
      anonymized['region'] = 'user_region'; // Generic placeholder
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
}
