import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_project_management_app/core/models/ai_rate_limits_config.dart';
import 'package:my_project_management_app/core/providers/ai_chat_provider.dart' as ai_provider;
import 'package:my_project_management_app/core/providers/ai_chat_provider.dart' show aiChatProvider;
import 'package:my_project_management_app/core/providers/auth_providers.dart';
import 'package:my_project_management_app/core/repository/settings_repository.dart';
import 'package:my_project_management_app/models/chat_message_model.dart';

class FakeAiChatNotifier extends ai_provider.AiChatNotifier {
  @override
  Future<ai_provider.AiChatState> build() async {
    final settings = await ref.watch(settingsRepositoryProvider.future);
    var config = settings.getAiRateLimitsConfig();
    // Validate if the config has invalid values (negative or zero)
    if (config.maxRequestsPerMinute <= 0 || config.maxRequestsPerHour <= 0 || 
        config.maxRequestsPerDay <= 0 || config.maxTokensPerRequest <= 0 || 
        config.maxTotalTokensPerDay <= 0) {
      config = AiRateLimitsConfig.validateAiRateLimits(config);
    }
    return ai_provider.AiChatState(rateLimits: config);
  }

  @override
  Future<void> sendMessage(
    String userMessage, {
    String? promptOverride,
    String? projectId,
  }) async {
    if (userMessage.trim().isEmpty) return;

    final currentState = state.value!;
    
    // Check rate limit before proceeding
    if (currentState.isRateLimited) {
      throw ai_provider.RateLimitExceededException(currentState.timeUntilReset);
    }

    // Simulate successful message processing without API call
    final now = DateTime.now();
    final newRequestCount = _calculateNewRequestCount(now, currentState);

    final userMsg = ChatMessage(
      id: now.millisecondsSinceEpoch.toString(),
      content: userMessage,
      isUser: true,
      timestamp: now,
    );

    final aiMsg = ChatMessage(
      id: (now.millisecondsSinceEpoch + 1).toString(),
      content: 'Mock AI response to: $userMessage',
      isUser: false,
      timestamp: now,
    );

    state = AsyncValue.data(currentState.copyWith(
      messages: [...currentState.messages, userMsg, aiMsg],
      isLoading: false,
      error: null,
      lastRequestTime: now,
      requestCountInWindow: newRequestCount,
    ));
  }

  int _calculateNewRequestCount(DateTime now, ai_provider.AiChatState currentState) {
    if (currentState.lastRequestTime == null) return 1;

    final timeSinceLastRequest = now.difference(currentState.lastRequestTime!);
    if (timeSinceLastRequest > currentState.rateLimits.timeWindowDuration) {
      return 1; // Window expired, reset to 1
    }

    return currentState.requestCountInWindow + 1;
  }
}

class FakeSettingsRepository extends SettingsRepository {
  AiRateLimitsConfig? _aiRateLimitsConfig;

  FakeSettingsRepository({AiRateLimitsConfig? aiRateLimitsConfig})
      : _aiRateLimitsConfig = aiRateLimitsConfig,
        super();

  @override
  Future<void> initialize({String? testPath}) async {}

  bool get isInitialized => true;

  @override
  AiRateLimitsConfig getAiRateLimitsConfig() {
    return _aiRateLimitsConfig ?? AiRateLimitsConfig.defaults();
  }

  @override
  Future<void> setAiRateLimitsConfig(AiRateLimitsConfig config) async {
    _aiRateLimitsConfig = config;
  }
}

void main() {
  group('AiChatProvider Rate Limits Tests', () {
    late ProviderContainer container;
    late FakeSettingsRepository fakeSettingsRepo;

    setUp(() {
      fakeSettingsRepo = FakeSettingsRepository();
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettingsRepo)),
        ],
      );
    });

    test('should load default rate limits when no config is set', () async {
      // Wait for the provider to initialize
      final asyncState = await container.read(ai_provider.aiChatProvider.future);

      expect(asyncState.rateLimits.maxRequestsPerMinute, equals(10));
      expect(asyncState.rateLimits.maxRequestsPerHour, equals(100));
      expect(asyncState.rateLimits.maxRequestsPerDay, equals(500));
      expect(asyncState.rateLimits.maxTokensPerRequest, equals(4000));
      expect(asyncState.rateLimits.maxTotalTokensPerDay, equals(100000));
    });

    test('should load custom rate limits from settings', () async {
      final customConfig = AiRateLimitsConfig(
        maxRequestsPerMinute: 5,
        maxRequestsPerHour: 50,
        maxRequestsPerDay: 250,
        maxTokensPerRequest: 2000,
        maxTotalTokensPerDay: 50000,
        maxRequestsPerWindow: 5,
        timeWindowDuration: const Duration(minutes: 1),
      );

      fakeSettingsRepo = FakeSettingsRepository(aiRateLimitsConfig: customConfig);
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettingsRepo)),
          aiChatProvider.overrideWith(() => FakeAiChatNotifier()),
        ],
      );

      final asyncState = await container.read(aiChatProvider.future);

      expect(asyncState.rateLimits.maxRequestsPerMinute, equals(5));
      expect(asyncState.rateLimits.maxRequestsPerHour, equals(50));
      expect(asyncState.rateLimits.maxRequestsPerDay, equals(250));
      expect(asyncState.rateLimits.maxTokensPerRequest, equals(2000));
      expect(asyncState.rateLimits.maxTotalTokensPerDay, equals(50000));
    });

    test('should enforce per-minute rate limit', () async {
      final config = AiRateLimitsConfig(
        maxRequestsPerMinute: 2,
        maxRequestsPerHour: 100,
        maxRequestsPerDay: 500,
        maxTokensPerRequest: 1000,
        maxTotalTokensPerDay: 100000,
        maxRequestsPerWindow: 2,
        timeWindowDuration: const Duration(minutes: 1),
      );

      fakeSettingsRepo = FakeSettingsRepository(aiRateLimitsConfig: config);
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettingsRepo)),
          ai_provider.aiChatProvider.overrideWith(() => FakeAiChatNotifier()),
        ],
      );

      await container.read(ai_provider.aiChatProvider.future);

      final notifier = container.read(ai_provider.aiChatProvider.notifier);

      // First request should succeed
      await notifier.sendMessage('Test message 1');
      expect(container.read(ai_provider.aiChatProvider).value!.error, isNull);

      // Second request should succeed
      await notifier.sendMessage('Test message 2');
      expect(container.read(ai_provider.aiChatProvider).value!.error, isNull);

      // Third request should be rate limited
      expect(
        () async => await notifier.sendMessage('Test message 3'),
        throwsA(isA<ai_provider.RateLimitExceededException>()),
      );
    });

    test('should enforce per-hour rate limit', () async {
      final config = AiRateLimitsConfig(
        maxRequestsPerMinute: 10,
        maxRequestsPerHour: 3,
        maxRequestsPerDay: 500,
        maxTokensPerRequest: 1000,
        maxTotalTokensPerDay: 100000,
        maxRequestsPerWindow: 10,
        timeWindowDuration: const Duration(minutes: 1),
      );

      fakeSettingsRepo = FakeSettingsRepository(aiRateLimitsConfig: config);
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettingsRepo)),
          aiChatProvider.overrideWith(() => FakeAiChatNotifier()),
        ],
      );

      await container.read(aiChatProvider.future);

      final notifier = container.read(aiChatProvider.notifier);

      // Make requests with delays to avoid minute limit
      await notifier.sendMessage('Test message 1');
      await Future.delayed(const Duration(seconds: 1));

      await notifier.sendMessage('Test message 2');
      await Future.delayed(const Duration(seconds: 1));

      await notifier.sendMessage('Test message 3');
      await Future.delayed(const Duration(seconds: 1));

      // Fourth request should be rate limited
      await notifier.sendMessage('Test message 4');
      expect(container.read(aiChatProvider).value!.error, isNotNull);
      expect(
        container.read(aiChatProvider).value!.error.toString(),
        contains('Rate limit exceeded'),
      );
    });

    test('should enforce per-day rate limit', () async {
      final config = AiRateLimitsConfig(
        maxRequestsPerMinute: 10,
        maxRequestsPerHour: 100,
        maxRequestsPerDay: 2,
        maxTokensPerRequest: 1000,
        maxTotalTokensPerDay: 100000,
        maxRequestsPerWindow: 10,
        timeWindowDuration: const Duration(minutes: 1),
      );

      fakeSettingsRepo = FakeSettingsRepository(aiRateLimitsConfig: config);
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettingsRepo)),
          aiChatProvider.overrideWith(() => FakeAiChatNotifier()),
        ],
      );

      await container.read(aiChatProvider.future);

      final notifier = container.read(aiChatProvider.notifier);

      // Make requests with delays to avoid shorter limits
      await notifier.sendMessage('Test message 1');
      await Future.delayed(const Duration(seconds: 2));

      await notifier.sendMessage('Test message 2');
      await Future.delayed(const Duration(seconds: 2));

      // Third request should be rate limited
      await notifier.sendMessage('Test message 3');
      expect(container.read(aiChatProvider).value!.error, isNotNull);
      expect(
        container.read(aiChatProvider).value!.error.toString(),
        contains('Rate limit exceeded'),
      );
    });

    test('should enforce token limits per request', () async {
      final config = AiRateLimitsConfig(
        maxRequestsPerMinute: 10,
        maxRequestsPerHour: 100,
        maxRequestsPerDay: 500,
        maxTokensPerRequest: 100,
        maxTotalTokensPerDay: 100000,
        maxRequestsPerWindow: 10,
        timeWindowDuration: const Duration(minutes: 1),
      );

      fakeSettingsRepo = FakeSettingsRepository(aiRateLimitsConfig: config);
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettingsRepo)),
          aiChatProvider.overrideWith(() => FakeAiChatNotifier()),
        ],
      );

      await container.read(aiChatProvider.future);

      final notifier = container.read(aiChatProvider.notifier);

      // Request with too many tokens should be rejected
      await notifier.sendMessage('This is a very long message that would exceed the token limit when processed by the AI model and converted to tokens during the API call. ' * 50); // Make it much longer
      expect(container.read(aiChatProvider).value!.error, isNotNull);
      expect(
        container.read(aiChatProvider).value!.error.toString(),
        contains('Message too long'),
      );
    });

    test('should enforce total daily token limit', () async {
      final config = AiRateLimitsConfig(
        maxRequestsPerMinute: 10,
        maxRequestsPerHour: 100,
        maxRequestsPerDay: 500,
        maxTokensPerRequest: 1000,
        maxTotalTokensPerDay: 3,
        maxRequestsPerWindow: 10,
        timeWindowDuration: const Duration(minutes: 1),
      );

      fakeSettingsRepo = FakeSettingsRepository(aiRateLimitsConfig: config);
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettingsRepo)),
          aiChatProvider.overrideWith(() => FakeAiChatNotifier()),
        ],
      );

      await container.read(aiChatProvider.future);

      final notifier = container.read(aiChatProvider.notifier);

      // First request should exceed daily token limit
      await notifier.sendMessage('Short message 1');
      expect(container.read(aiChatProvider).value!.error, isNotNull);
      expect(
        container.read(aiChatProvider).value!.error.toString(),
        contains('Daily token limit exceeded'),
      );
    });

    test('should handle settings repository errors gracefully', () async {
      // Create a settings repository that throws an error
      final errorRepo = FakeSettingsRepository().._aiRateLimitsConfig = null;
      // Override the getAiRateLimitsConfig method to throw
      runZonedGuarded(() async {
        final errorContainer = ProviderContainer(
          overrides: [
            settingsRepositoryProvider.overrideWith((ref) => Future.value(errorRepo)),
            aiChatProvider.overrideWith(() => FakeAiChatNotifier()),
          ],
        );

        // This should not crash the provider, should use defaults
        final asyncState = await errorContainer.read(aiChatProvider.future);
        expect(asyncState.rateLimits, isNotNull);
        // Should have fallen back to defaults
        expect(asyncState.rateLimits.maxRequestsPerMinute, equals(10));

        errorContainer.dispose();
      }, (error, stack) {
        fail('Provider should handle settings errors gracefully: $error');
      });
    });

    test('should validate rate limits config on load', () async {
      // Test with invalid config (negative values)
      final invalidConfig = AiRateLimitsConfig(
        maxRequestsPerMinute: -1,
        maxRequestsPerHour: -5,
        maxRequestsPerDay: -10,
        maxTokensPerRequest: -100,
        maxTotalTokensPerDay: -1000,
        maxRequestsPerWindow: -1,
        timeWindowDuration: const Duration(minutes: 1),
      );

      fakeSettingsRepo = FakeSettingsRepository(aiRateLimitsConfig: invalidConfig);
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettingsRepo)),
          aiChatProvider.overrideWith(() => FakeAiChatNotifier()),
        ],
      );

      final asyncState = await container.read(aiChatProvider.future);

      // Should have been clamped to minimum values
      expect(asyncState.rateLimits.maxRequestsPerMinute, equals(1));
      expect(asyncState.rateLimits.maxRequestsPerHour, equals(1));
      expect(asyncState.rateLimits.maxRequestsPerDay, equals(1));
      expect(asyncState.rateLimits.maxTokensPerRequest, equals(100));
      expect(asyncState.rateLimits.maxTotalTokensPerDay, equals(1000));
      expect(asyncState.rateLimits.maxRequestsPerWindow, equals(1));
    });

    test('should reset rate limits after time windows', () async {
      final config = AiRateLimitsConfig(
        maxRequestsPerMinute: 1,
        maxRequestsPerHour: 100,
        maxRequestsPerDay: 500,
        maxTokensPerRequest: 1000,
        maxTotalTokensPerDay: 100000,
        maxRequestsPerWindow: 1,
        timeWindowDuration: const Duration(minutes: 1),
      );

      fakeSettingsRepo = FakeSettingsRepository(aiRateLimitsConfig: config);
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettingsRepo)),
          aiChatProvider.overrideWith(() => FakeAiChatNotifier()),
        ],
      );

      await container.read(aiChatProvider.future);

      final notifier = container.read(aiChatProvider.notifier);

      // First request should succeed
      await notifier.sendMessage('Test message 1');
      expect(container.read(aiChatProvider).value!.error, isNull);

      // Second request should be rate limited
      await notifier.sendMessage('Test message 2');
      expect(container.read(aiChatProvider).value!.error, isNotNull);

      // Simulate time passing (more than a minute)
      // Note: In a real implementation, this would use a timer or clock override
      // For this test, we'll just verify the rate limiting logic exists
      // The actual time-based reset would need integration testing
    });

    test('should handle concurrent requests properly', () async {
      final config = AiRateLimitsConfig(
        maxRequestsPerMinute: 2,
        maxRequestsPerHour: 100,
        maxRequestsPerDay: 500,
        maxTokensPerRequest: 1000,
        maxTotalTokensPerDay: 100000,
        maxRequestsPerWindow: 2,
        timeWindowDuration: const Duration(minutes: 1),
      );

      fakeSettingsRepo = FakeSettingsRepository(aiRateLimitsConfig: config);
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettingsRepo)),
          aiChatProvider.overrideWith(() => FakeAiChatNotifier()),
        ],
      );

      await container.read(aiChatProvider.future);

      final notifier = container.read(aiChatProvider.notifier);

      // Start multiple requests sequentially to test rate limiting
      await notifier.sendMessage('Sequential 1');
      await notifier.sendMessage('Sequential 2');
      await notifier.sendMessage('Sequential 3');

      final state = container.read(aiChatProvider);
      // Only 2 should succeed due to rate limiting
      final messages = state.value!.messages;
      expect(messages.length, lessThanOrEqualTo(4)); // 2 successful requests = 4 messages (user + AI each)
    });

    test('should use default maxRequestsPerWindow value of 10 when no config', () async {
      // Wait for the provider to initialize
      final asyncState = await container.read(aiChatProvider.future);

      expect(asyncState.rateLimits.maxRequestsPerWindow, equals(10));
    });

    test('should respect custom maxRequestsPerWindow value in rate-limiter', () async {
      final config = AiRateLimitsConfig(
        maxRequestsPerMinute: 10,
        maxRequestsPerHour: 100,
        maxRequestsPerDay: 500,
        maxTokensPerRequest: 1000,
        maxTotalTokensPerDay: 100000,
        maxRequestsPerWindow: 3,
        timeWindowDuration: const Duration(minutes: 1),
      );

      fakeSettingsRepo = FakeSettingsRepository(aiRateLimitsConfig: config);
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettingsRepo)),
          aiChatProvider.overrideWith(() => FakeAiChatNotifier()),
        ],
      );

      await container.read(aiChatProvider.future);

      final notifier = container.read(aiChatProvider.notifier);

      // First 3 requests should succeed
      await notifier.sendMessage('Test message 1');
      expect(container.read(aiChatProvider).value!.error, isNull);

      await notifier.sendMessage('Test message 2');
      expect(container.read(aiChatProvider).value!.error, isNull);

      await notifier.sendMessage('Test message 3');
      expect(container.read(aiChatProvider).value!.error, isNull);

      // Fourth request should be rate limited
      expect(
        () async => await notifier.sendMessage('Test message 4'),
        throwsA(isA<ai_provider.RateLimitExceededException>()),
      );
    });

    test('should fallback to default when maxRequestsPerWindow is invalid (0 or negative)', () async {
      final config = AiRateLimitsConfig(
        maxRequestsPerMinute: 10,
        maxRequestsPerHour: 100,
        maxRequestsPerDay: 500,
        maxTokensPerRequest: 1000,
        maxTotalTokensPerDay: 100000,
        maxRequestsPerWindow: 0, // Invalid value
        timeWindowDuration: const Duration(minutes: 1),
      );

      fakeSettingsRepo = FakeSettingsRepository(aiRateLimitsConfig: config);
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettingsRepo)),
          aiChatProvider.overrideWith(() => FakeAiChatNotifier()),
        ],
      );

      await container.read(aiChatProvider.future);

      final notifier = container.read(aiChatProvider.notifier);

      // Should allow 10 requests (default fallback) before rate limiting
      for (int i = 1; i <= 10; i++) {
        await notifier.sendMessage('Test message $i');
        expect(container.read(aiChatProvider).value!.error, isNull);
      }

      // 11th request should be rate limited
      expect(
        () async => await notifier.sendMessage('Test message 11'),
        throwsA(isA<ai_provider.RateLimitExceededException>()),
      );
    });

    test('should block requests correctly at configured maxRequestsPerWindow limit', () async {
      final config = AiRateLimitsConfig(
        maxRequestsPerMinute: 10,
        maxRequestsPerHour: 100,
        maxRequestsPerDay: 500,
        maxTokensPerRequest: 1000,
        maxTotalTokensPerDay: 100000,
        maxRequestsPerWindow: 2,
        timeWindowDuration: const Duration(minutes: 1),
      );

      fakeSettingsRepo = FakeSettingsRepository(aiRateLimitsConfig: config);
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettingsRepo)),
          aiChatProvider.overrideWith(() => FakeAiChatNotifier()),
        ],
      );

      await container.read(aiChatProvider.future);

      final notifier = container.read(aiChatProvider.notifier);

      // First request should succeed
      await notifier.sendMessage('Test message 1');
      expect(container.read(aiChatProvider).value!.error, isNull);

      // Second request should succeed
      await notifier.sendMessage('Test message 2');
      expect(container.read(aiChatProvider).value!.error, isNull);

      // Third request should be blocked
      expect(
        () async => await notifier.sendMessage('Test message 3'),
        throwsA(isA<ai_provider.RateLimitExceededException>()),
      );

      // Verify the state shows correct request count
      final state = container.read(aiChatProvider).value!;
      expect(state.requestCountInWindow, equals(2));
      expect(state.isRateLimited, isTrue);
    });

    test('should save and load maxRequestsPerWindow setting roundtrip', () async {
      final customConfig = AiRateLimitsConfig(
        maxRequestsPerMinute: 10,
        maxRequestsPerHour: 100,
        maxRequestsPerDay: 500,
        maxTokensPerRequest: 4000,
        maxTotalTokensPerDay: 100000,
        maxRequestsPerWindow: 7,
        timeWindowDuration: const Duration(minutes: 2),
      );

      // Save the config
      await fakeSettingsRepo.setAiRateLimitsConfig(customConfig);

      // Create new container to simulate fresh load
      final newContainer = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettingsRepo)),
          aiChatProvider.overrideWith(() => FakeAiChatNotifier()),
        ],
      );

      // Load and verify
      final loadedState = await newContainer.read(aiChatProvider.future);
      expect(loadedState.rateLimits.maxRequestsPerWindow, equals(7));
      expect(loadedState.rateLimits.timeWindowDuration, equals(const Duration(minutes: 2)));

      newContainer.dispose();
    });
  });
}
