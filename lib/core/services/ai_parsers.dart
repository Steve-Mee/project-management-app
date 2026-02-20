import 'dart:convert';

/// Utility class for parsing AI responses safely
/// Handles inconsistencies from AI APIs like Grok, with robust JSON extraction
/// and fallback mechanisms. Designed for modular extensions (e.g., XML parsing).
///
/// IMPORTANT COMPLIANCE NOTE: When parsing AI responses that may contain
/// user-generated or sensitive data, ensure compliance with local data privacy
/// laws (GDPR, CCPA, etc.). This parser handles data that might contain
/// sensitive information - always validate and sanitize parsed content
/// according to applicable regulations in the user's jurisdiction.
class AiParsers {
  /// Private constructor to prevent instantiation
  AiParsers._();

  /// Safely parses JSON from AI response string
  /// Attempts direct JSON decoding first, then uses RegExp fallback
  /// to extract JSON from mixed text responses.
  ///
  /// Throws exception with clear message on parsing failure.
  ///
  /// Example usage:
  /// ```dart
  /// try {
  ///   final data = AiParsers.safeParseJson(response);
  ///   // Use parsed data
  /// } catch (e) {
  ///   print('Failed to parse AI response: $e');
  /// }
  /// ```
  static dynamic safeParseJson(String response) {
    if (response.trim().isEmpty) {
      throw Exception('Empty response cannot be parsed');
    }

    // First attempt: direct JSON parsing
    try {
      return jsonDecode(response.trim());
    } catch (e) {
      // Ignore and try fallback
    }

    // Second attempt: extract JSON using RegExp
    try {
      final extractedJson = _extractJsonWithRegExp(response);
      if (extractedJson != null) {
        return jsonDecode(extractedJson);
      }
    } catch (e) {
      // Ignore and continue to final failure
    }

    // Final failure: throw descriptive exception
    throw Exception(
      'Failed to parse JSON from AI response. '
      'Response may not contain valid JSON or may be malformed. '
      'Original response length: ${response.length} characters. '
      'Ensure AI prompt requests proper JSON formatting.',
    );
  }

  /// Extracts JSON string from mixed text using RegExp
  /// Looks for the outermost JSON object or array in the response
  static String? _extractJsonWithRegExp(String response) {
    // Pattern to match JSON objects (starting with { and ending with })
    final objectPattern = RegExp(r'\{(?:[^{}]|{(?:[^{}]|{[^{}]*})*})*\}');
    final arrayPattern = RegExp(
      r'\[(?:[^\[\]]|\[(?:[^\[\]]|\[[^\[\]]*\])*])*]',
    );

    // Try to find JSON object first
    final objectMatch = objectPattern.firstMatch(response);
    if (objectMatch != null) {
      return objectMatch.group(0);
    }

    // Try to find JSON array
    final arrayMatch = arrayPattern.firstMatch(response);
    if (arrayMatch != null) {
      return arrayMatch.group(0);
    }

    return null;
  }

  // Future extension points for additional parsing formats
  // static dynamic safeParseXml(String response) {
  //   // TODO: Implement XML parsing for future AI models
  //   throw UnimplementedError('XML parsing not yet implemented');
  // }

  // static dynamic safeParseYaml(String response) {
  //   // TODO: Implement YAML parsing for future AI models
  //   throw UnimplementedError('YAML parsing not yet implemented');
  // }
}
