import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/core/services/ai_parsers.dart';

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

    test('should throw exception for malformed XML', () {
      const malformed = '<user><name>John</name><age>30</user>';
      expect(() => AiParsers.safeParseXml(malformed), throwsException);
    });

    test('should throw exception for empty response', () {
      expect(() => AiParsers.safeParseXml(''), throwsException);
      expect(() => AiParsers.safeParseXml('   '), throwsException);
    });

    test('should throw exception on total parsing failure', () {
      const invalid = 'This is not XML at all, no tags here.';
      expect(() => AiParsers.safeParseXml(invalid), throwsException);
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

    test('should throw exception for malformed YAML', () {
      const malformed = 'name: John\n- invalid structure';
      expect(() => AiParsers.safeParseYaml(malformed), throwsException);
    });

    test('should throw exception for empty response', () {
      expect(() => AiParsers.safeParseYaml(''), throwsException);
      expect(() => AiParsers.safeParseYaml('   '), throwsException);
    });

    test('should throw exception on total parsing failure', () {
      const invalid = 'This is not YAML at all, no structure here.';
      expect(() => AiParsers.safeParseYaml(invalid), throwsException);
    });
  });

  group('ParserRegistry', () {
    test('should register and retrieve parsers correctly', () {
      // Create a mock parser
      final mockParser = MockAiParser();
      
      // Register the parser
      ParserRegistry.registerParser('test', mockParser);
      
      // Retrieve and verify
      final retrieved = ParserRegistry.getParser('test');
      expect(retrieved, equals(mockParser));
      
      // Check supported formats
      final formats = ParserRegistry.getSupportedFormats();
      expect(formats, contains('test'));
    });

    test('should return null for unregistered format', () {
      final parser = ParserRegistry.getParser('nonexistent');
      expect(parser, isNull);
    });
  });

  group('Extension system integration', () {
    test('XML parsing works via extension system', () {
      const xml = '<user><name>John</name><age>30</age></user>';
      final result = AiParsers.parseAIResponse(xml, 'xml');
      expect(result, isA<Map<String, dynamic>>());
      expect((result as Map)['name'], {'#text': 'John'});
    });

    test('YAML parsing works via extension system', () {
      const yaml = 'name: John\nage: 30';
      final result = AiParsers.parseAIResponse(yaml, 'yaml');
      expect(result, isA<Map<String, dynamic>>());
      expect((result as Map)['name'], 'John');
    });

    test('JSON parsing works via extension system', () {
      const json = '{"name": "John", "age": 30}';
      final result = AiParsers.parseAIResponse(json, 'json');
      expect(result, isA<Map<String, dynamic>>());
      expect((result as Map)['name'], 'John');
    });
  });

  group('Unified parseAIResponse', () {
    test('should auto-detect JSON format', () {
      const json = '{"name": "John", "age": 30}';
      final result = AiParsers.parseAIResponse(json, null);
      expect(result, isA<Map<String, dynamic>>());
      expect((result as Map)['name'], 'John');
    });

    test('should auto-detect XML format', () {
      const xml = '<user><name>John</name></user>';
      final result = AiParsers.parseAIResponse(xml, null);
      expect(result, isA<Map<String, dynamic>>());
      expect((result as Map)['name'], {'#text': 'John'});
    });

    test('should auto-detect YAML format', () {
      const yaml = 'name: John\nage: 30';
      final result = AiParsers.parseAIResponse(yaml, null);
      expect(result, isA<Map<String, dynamic>>());
      expect((result as Map)['name'], 'John');
    });

    test('should detect format hints in response text', () {
      const hintedXml = 'Here is the data in XML format: <user><name>John</name></user>';
      final result = AiParsers.parseAIResponse(hintedXml, null);
      expect(result, isA<Map<String, dynamic>>());
      expect((result as Map)['name'], {'#text': 'John'});
    });

    test('should throw exception for unsupported format', () {
      expect(() => AiParsers.parseAIResponse('data', 'unsupported'), throwsException);
    });
  });

  group('Adding new formats without code changes', () {
    test('should allow registering and using custom parser', () {
      // Create a simple custom parser that returns the input as-is
      final customParser = TestParser();
      ParserRegistry.registerParser('test', customParser);
      
      const testData = 'custom format data';
      final result = AiParsers.parseAIResponse(testData, 'test');
      expect(result, equals('PARSED: $testData'));
    });
  });
}

// Mock classes for testing
class MockAiParser implements AiParser {
  @override
  dynamic parse(String input) => 'mocked';
}

class TestParser implements AiParser {
  @override
  dynamic parse(String input) => 'PARSED: $input';
}
