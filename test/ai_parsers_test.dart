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

  group('AiParsers.safeParseYaml', () {
    test('should parse valid simple YAML to Map', () {
      const yaml = 'name: John\nage: 30';
      final result = AiParsers.safeParseYaml(yaml);
      expect(result, isA<Map<String, dynamic>>());
      expect((result as Map)['name'], 'John');
      expect((result)['age'], 30);
    });

    test('should parse YAML with lists and nested objects', () {
      const yaml = '''
users:
  - name: John
    age: 30
    config:
      enabled: true
  - name: Jane
    age: 25
''';
      final result = AiParsers.safeParseYaml(yaml);
      expect(result, isA<Map<String, dynamic>>());
      final data = (result as Map);
      expect(data['users'], isA<List>());
      final users = data['users'] as List;
      expect(users.length, 2);
      expect(users[0]['name'], 'John');
      expect(users[0]['config']['enabled'], true);
      expect(users[1]['name'], 'Jane');
    });

    test('should extract YAML from mixed text using RegExp fallback', () {
      const mixedText = 'Here is some text\n---\nname: Extracted\nage: 25\n---\nand more text.';
      final result = AiParsers.safeParseYaml(mixedText);
      expect(result, isA<Map<String, dynamic>>());
      expect((result as Map)['name'], 'Extracted');
      expect((result)['age'], 25);
    });

    test('should return raw string for malformed YAML', () {
      const malformed = 'name: John\n- invalid structure';
      final result = AiParsers.safeParseYaml(malformed);
      expect(result, isA<String>());
      expect(result, malformed);
    });

    test('should throw exception for empty response', () {
      expect(() => AiParsers.safeParseYaml(''), throwsException);
      expect(() => AiParsers.safeParseYaml('   '), throwsException);
    });

    test('should return raw string on total parsing failure', () {
      const invalid = 'This is not YAML at all, no structure here.';
      final result = AiParsers.safeParseYaml(invalid);
      expect(result, isA<String>());
      expect(result, invalid.trim());
    });
  });
}