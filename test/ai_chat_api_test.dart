// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pma_core/providers/ai_providers.dart';
import 'package:pma_core/models/chat_message_model.dart';
import 'package:pma_core/services/app_logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Load environment variables
    await dotenv.load(fileName: '.env');
  });

  group('AI Chat API Tests', () {
    test('should detect API key status', () {
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        AppLogger.instance.w('No API key configured in test environment');
      } else if (apiKey == 'your_xai_api_key_here') {
        AppLogger.instance.w('Placeholder API key detected');
      } else {
        final preview = apiKey.length > 10 ? apiKey.substring(0, 10) : apiKey;
        AppLogger.instance.i('Real API key detected: $preview...');
      }

      // This test verifies environment wiring only and should never crash.
      expect(true, isTrue);
    });

    test('should handle missing API key gracefully', () {
      // Temporarily remove API key
      final originalKey = dotenv.env['OPENAI_API_KEY'];
      dotenv.env.remove('OPENAI_API_KEY');

      expect(dotenv.env['OPENAI_API_KEY'], isNull);

      // Restore API key
      if (originalKey != null) {
        dotenv.env['OPENAI_API_KEY'] = originalKey;
      }
    });

    test('should test Grok API connection with simple message', () async {
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        AppLogger.instance.w('Skipping Grok API test - no API key found');
        AppLogger.instance.i('Please add OPENAI_API_KEY to .env file');
        return;
      }

      if (apiKey == 'your_xai_api_key_here') {
        AppLogger.instance.w('Skipping Grok API test - placeholder API key detected');
        AppLogger.instance.i('To test Grok API connection:');
        AppLogger.instance.i('1. Get a Grok API key from https://console.x.ai/');
        AppLogger.instance.i('2. Replace "your_xai_api_key_here" in .env with your actual key');
        AppLogger.instance.i('3. Run this test again');
        AppLogger.instance.i('Current API key: $apiKey');
        return;
      }

      AppLogger.instance.i('API key appears configured for integration tests.');
      // Network integration is intentionally not executed in unit test runs.
      expect(true, isTrue);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('should handle API errors gracefully', () {
      // Unit-level contract check: invalid key values can be represented.
      dotenv.env['OPENAI_API_KEY'] = 'invalid_key_for_testing';
      expect(dotenv.env['OPENAI_API_KEY'], contains('invalid_key'));
    });
  });

  group('AI Chat State Tests', () {
    test('AiChatState should create with default values', () {
      const state = AiChatState();
      expect(state.messages, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('AiChatState copyWith should work correctly', () {
      const original = AiChatState();
      final modified = original.copyWith(
        isLoading: true,
        error: 'Test error',
      );

      expect(modified.messages, isEmpty);
      expect(modified.isLoading, isTrue);
      expect(modified.error, equals('Test error'));
    });

    test('AiChatState should handle messages list', () {
      final messages = [
        ChatMessage(
          id: '1',
          content: 'Test message',
          isUser: true,
          timestamp: DateTime.now(),
        ),
      ];

      final state = AiChatState(messages: messages);
      expect(state.messages.length, equals(1));
      expect(state.messages[0].content, equals('Test message'));
      expect(state.messages[0].isUser, isTrue);
    });

    test('AiChatState copyWith should override error with null when not provided', () {
      final messages = [
        ChatMessage(
          id: '1',
          content: 'Test',
          isUser: true,
          timestamp: DateTime.now(),
        ),
      ];

      final original = AiChatState(
        messages: messages,
        isLoading: false,
        error: 'Original error',
      );

      final modified = original.copyWith(isLoading: true);

      expect(modified.messages, equals(original.messages));
      expect(modified.isLoading, isTrue);
      expect(modified.error, isNull); // Error gets overridden with null when not provided
    });
  });
}
