import 'dart:convert';
import 'package:xml/xml.dart';
import 'package:yaml/yaml.dart';

import '../services/app_logger.dart';

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

  // NOTE: converted to issue 047

  /// Safely parses XML from AI response string
  /// Attempts direct XML parsing first, then uses RegExp fallback
  /// to extract XML from mixed text responses.
  ///
  /// Returns parsed Map/List on success, or raw String on complete failure.
  /// Handles malformed XML gracefully by falling back to raw response.
  ///
  /// IMPORTANT COMPLIANCE NOTE: When parsing AI responses that may contain
  /// user-generated or sensitive data, ensure compliance with local data privacy
  /// laws (GDPR, CCPA, etc.). This parser handles data that might contain
  /// sensitive information - always validate and sanitize parsed content
  /// according to applicable regulations in the user's jurisdiction.
  ///
  /// Example usage:
  /// ```dart
  /// final data = AiParsers.safeParseXml(response);
  /// if (data is Map<String, dynamic>) {
  ///   // Use parsed data
  /// } else if (data is String) {
  ///   // Handle raw response
  /// }
  /// ```
  static dynamic safeParseXml(String response) {
    if (response.trim().isEmpty) {
      throw Exception('Empty response cannot be parsed');
    }

    // First attempt: direct XML parsing
    try {
      final document = XmlDocument.parse(response.trim());
      return _xmlToMap(document.rootElement);
    } catch (e) {
      // Ignore and try fallback
    }

    // Second attempt: extract XML using RegExp
    try {
      final extractedXml = _extractXmlWithRegExp(response);
      if (extractedXml != null) {
        final document = XmlDocument.parse(extractedXml);
        AppLogger.instance.w('XML parsing used RegExp fallback for response extraction');
        return _xmlToMap(document.rootElement);
      }
    } catch (e) {
      // Ignore and continue to final failure
    }

    // Final failure: return raw response as fallback
    AppLogger.instance.w('XML parsing completely failed, returning raw response');
    return response.trim();
  }

  /// Safely parses YAML from AI response string
  /// Attempts direct YAML parsing first, then uses RegExp fallback
  /// to extract YAML from mixed text responses.
  ///
  /// Returns parsed Map/List on success, or raw String on complete failure.
  /// Handles malformed YAML gracefully by falling back to raw response.
  ///
  /// IMPORTANT COMPLIANCE NOTE: When parsing AI responses that may contain
  /// user-generated or sensitive data, ensure compliance with local data privacy
  /// laws (GDPR, CCPA, etc.). This parser handles data that might contain
  /// sensitive information - always validate and sanitize parsed content
  /// according to applicable regulations in the user's jurisdiction.
  ///
  /// Example usage:
  /// ```dart
  /// final data = AiParsers.safeParseYaml(response);
  /// if (data is Map<String, dynamic>) {
  ///   // Use parsed data
  /// } else if (data is List) {
  ///   // Handle list
  /// } else if (data is String) {
  ///   // Handle raw response
  /// }
  /// ```
  static dynamic safeParseYaml(String response) {
    if (response.trim().isEmpty) {
      throw Exception('Empty response cannot be parsed');
    }

    // First attempt: direct YAML parsing
    try {
      final parsed = loadYaml(response.trim());
      if (parsed is Map) {
        return _yamlToMap(parsed);
      } else if (parsed is List) {
        return _yamlToList(parsed);
      } else {
        return parsed; // Scalar
      }
    } catch (e) {
      // Ignore and try fallback
    }

    // Second attempt: extract YAML using RegExp
    try {
      final extractedYaml = _extractYamlWithRegExp(response);
      if (extractedYaml != null) {
        final parsed = loadYaml(extractedYaml);
        AppLogger.instance.w('YAML parsing used RegExp fallback for response extraction');
        if (parsed is Map) {
          return _yamlToMap(parsed);
        } else if (parsed is List) {
          return _yamlToList(parsed);
        } else {
          return parsed; // Scalar
        }
      }
    } catch (e) {
      // Ignore and continue to final failure
    }

    // Final failure: return raw response as fallback
    AppLogger.instance.w('YAML parsing completely failed, returning raw response');
    return response.trim();
  }

  /// Extracts XML string from mixed text using RegExp
  /// Looks for the outermost XML element in the response
  static String? _extractXmlWithRegExp(String response) {
    // Pattern to match XML elements (starting with <tag> and ending with </tag>)
    final xmlPattern = RegExp(r'<[^>]+>.*</[^>]+>', dotAll: true);

    final match = xmlPattern.firstMatch(response);
    if (match != null) {
      return match.group(0);
    }

    return null;
  }

  /// Extracts YAML string from mixed text using RegExp
  /// Looks for YAML content between --- markers in the response
  static String? _extractYamlWithRegExp(String response) {
    // Pattern to match YAML between --- markers
    final yamlPattern = RegExp(r'---\s*\n(.*?)\n---', dotAll: true);

    final match = yamlPattern.firstMatch(response);
    if (match != null) {
      return match.group(1);
    }

    return null;
  }

  /// Converts XmlElement to Map, handling attributes, text nodes, and nested elements.
  /// Part of AI XML parser implementation (.github/issues/035-ai-xml-parser.md)
  /// Example: `<user id="1"><name>John</name></user>` -> `{'@id': '1', 'name': 'John'}`
  static Map<String, dynamic> _xmlToMap(XmlElement element) {
    final map = <String, dynamic>{};

    // Attributes
    for (var attr in element.attributes) {
      map['@${attr.name.local}'] = attr.value;
    }

    // Children
    final childElements = <String, List<XmlElement>>{};
    String? textContent;

    for (var child in element.children) {
      if (child is XmlElement) {
        childElements.putIfAbsent(child.name.local, () => []).add(child);
      } else if (child is XmlText && child.value.trim().isNotEmpty) {
        textContent = (textContent ?? '') + child.value.trim();
      }
    }

    // Process child elements
    for (var entry in childElements.entries) {
      final name = entry.key;
      final elements = entry.value;
      if (elements.length == 1) {
        map[name] = _xmlToMap(elements.first);
      } else {
        map[name] = _xmlToList(elements);
      }
    }

    // Add text
    if (textContent != null) {
      map['#text'] = textContent;
    }

    return map;
  }

  /// Converts list of XmlElement to List, for multiple same-named elements.
  /// Example: [<item>a</item>, <item>b</item>] -> [{'#text': 'a'}, {'#text': 'b'}]
  static List<dynamic> _xmlToList(List<XmlElement> elements) {
    return elements.map(_xmlToMap).toList();
  }

  /// Converts YAML document to Map, handling nested structures.
  /// Part of AI YAML parser implementation (.github/issues/036-ai-yaml-parser.md)
  /// Recursively processes nested Maps and Lists to ensure String keys and proper types.
  /// Example: {'name': 'John', 'config': {'enabled': true}} -> {'name': 'John', 'config': {'enabled': true}}
  static Map<String, dynamic> _yamlToMap(dynamic yamlDocument) {
    if (yamlDocument is! Map) {
      throw ArgumentError('yamlDocument must be a Map');
    }

    final map = <String, dynamic>{};

    for (var entry in yamlDocument.entries) {
      final key = entry.key.toString(); // Ensure key is String
      final value = entry.value;

      if (value is Map) {
        map[key] = _yamlToMap(value);
      } else if (value is List) {
        map[key] = _yamlToList(value);
      } else {
        map[key] = value; // Scalars remain as-is
      }
    }

    return map;
  }

  /// Converts YAML list to List, handling nested structures.
  /// Part of AI YAML parser implementation (.github/issues/036-ai-yaml-parser.md)
  /// Recursively processes nested Maps and Lists.
  /// Example: [{'name': 'John'}, {'name': 'Jane'}] -> [{'name': 'John'}, {'name': 'Jane'}]
  static List<dynamic> _yamlToList(dynamic yamlDocument) {
    if (yamlDocument is! List) {
      throw ArgumentError('yamlDocument must be a List');
    }

    return yamlDocument.map((item) {
      if (item is Map) {
        return _yamlToMap(item);
      } else if (item is List) {
        return _yamlToList(item);
      } else {
        return item; // Scalars remain as-is
      }
    }).toList();
  }

}
