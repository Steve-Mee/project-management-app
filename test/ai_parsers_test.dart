import 'package:flutter_test/flutter_test.dart';
import 'package:my_project_management_app/core/services/ai_parsers.dart';

void main() {
  group('AiParsers.safeParseXml', () {
    test('should parse valid simple XML to Map', () {
      const xml = '<user><name>John</name><age>30</age></user>';
      final result = AiParsers.safeParseXml(xml);
      expect(result, isA<Map<String, dynamic>>());
      expect((result as Map)['name'], {'#text': 'John'});
      expect((result)['age'], {'#text': '30'});
    });

    test('should parse XML with attributes and nested elements', () {
      const xml = '<project id="123"><name>My Project</name><tasks><task>Task 1</task><task>Task 2</task></tasks></project>';
      final result = AiParsers.safeParseXml(xml);
      expect(result, isA<Map<String, dynamic>>());
      final project = (result as Map);
      expect(project['@id'], '123');
      expect(project['name'], {'#text': 'My Project'});
      expect(project['tasks']['task'], [
        {'#text': 'Task 1'},
        {'#text': 'Task 2'}
      ]);
    });

    test('should extract XML from mixed text using RegExp fallback', () {
      const mixedText = 'Here is some text <item><name>Extracted</name></item> and more text.';
      final result = AiParsers.safeParseXml(mixedText);
      expect(result, isA<Map<String, dynamic>>());
      expect((result as Map)['name'], {'#text': 'Extracted'});
    });

    test('should return raw string for malformed XML', () {
      const malformed = '<user><name>John</name><age>30</user>';
      final result = AiParsers.safeParseXml(malformed);
      expect(result, isA<String>());
      expect(result, malformed);
    });

    test('should throw exception for empty response', () {
      expect(() => AiParsers.safeParseXml(''), throwsException);
      expect(() => AiParsers.safeParseXml('   '), throwsException);
    });

    test('should return raw string on total parsing failure', () {
      const invalid = 'This is not XML at all, no tags here.';
      final result = AiParsers.safeParseXml(invalid);
      expect(result, isA<String>());
      expect(result, invalid.trim());
    });
  });
}