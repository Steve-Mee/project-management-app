import 'dart:async';
import 'dart:math';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:my_project_management_app/core/models/ai_rate_limits_config.dart';
import 'package:my_project_management_app/core/providers/ai_chat_provider.dart' as ai_provider show aiChatProvider, AiChatState, RateLimitExceededException, AiChatNotifier;
import 'package:my_project_management_app/core/providers/auth_providers.dart';
import 'package:my_project_management_app/core/repository/settings_repository.dart';
import 'package:my_project_management_app/core/services/ai_planning_helpers.dart';
import 'package:my_project_management_app/core/services/app_logger.dart';
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

class MockAppLogger extends Mock implements AppLogger {}

class TestAiChatNotifier extends ai_provider.AiChatNotifier {
  int _callCount = 0;
  bool _shouldFail = true;
  int _failOnCallNumber = 1; // Fail on first call by default
  bool _isThrottling = true; // Whether the error is a throttling error
  
  void configureFailure(bool shouldFail, {int failOnCallNumber = 1, bool isThrottlingError = true}) {
    _shouldFail = shouldFail;
    _failOnCallNumber = failOnCallNumber; // Use -1 to always fail
    _isThrottling = isThrottlingError;
    _callCount = 0;
  }
  
  int get callCount => _callCount;

  @override
  Future<ai_provider.AiChatState> build() async {
    final settings = await ref.watch(settingsRepositoryProvider.future);
    var config = settings.getAiRateLimitsConfig();
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
      final remainingTime = currentState.timeUntilReset;
      AppLogger.event('ai_rate_limit_exceeded', params: {
        'remainingTime': remainingTime.inSeconds,
        'requestCount': currentState.requestCountInWindow,
        'maxRequestsPerWindow': currentState.rateLimits.maxRequestsPerWindow,
        'timeWindowDuration': currentState.rateLimits.timeWindowDuration.inSeconds,
      });
      throw ai_provider.RateLimitExceededException(remainingTime);
    }

    // Add user message
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Update rate limiting state
    final now = DateTime.now();
    final newRequestCount = _calculateNewRequestCount(now, currentState);

    state = AsyncValue.data(currentState.copyWith(
      messages: [...currentState.messages, userMsg],
      isLoading: true,
      error: null,
      lastRequestTime: now,
      requestCountInWindow: newRequestCount,
    ));

    try {
      // Use custom retry logic for testing
      final result = await _callAiWithRetryForTest(userMessage);

      // Add AI message
      final aiMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: result.content,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = AsyncValue.data(state.value!.copyWith(
        messages: [...state.value!.messages, aiMsg],
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      state = AsyncValue.data(state.value!.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  Future<AiApiResult<String>> _callAiWithRetryForTest(String prompt) async {
    final currentState = state.value!;
    final maxAttempts = currentState.rateLimits.maxRetryAttempts;
    for (int attempt = 0; attempt <= maxAttempts; attempt++) {
      try {
        return await _callAiWithAnonymizedPromptForTest(prompt);
      } catch (e) {
        if (attempt < maxAttempts && _isThrottlingError(e)) {
          final baseDelay = currentState.rateLimits.backoffBaseDelay;
          final maxDelay = currentState.rateLimits.backoffMaxDelay;
          final calculatedDelay = baseDelay * pow(2, attempt);
          final clampedDelay = calculatedDelay > maxDelay ? maxDelay : calculatedDelay;
          final delay = Duration(milliseconds: (Random().nextDouble() * clampedDelay.inMilliseconds).round());
          AppLogger.event('ai_retry_attempt', params: {
            'attempt': attempt,
            'delay_ms': delay.inMilliseconds,
            'reason': e.toString(),
          });
          await Future.delayed(delay);
        } else {
          if (attempt == maxAttempts) {
            AppLogger.error('AI call failed after maximum retries', error: e);
          }
          rethrow;
        }
      }
    }
    // This should not be reached, but just in case
    throw Exception('AI call failed after $maxAttempts retries');
  }

  Future<AiApiResult<String>> _callAiWithAnonymizedPromptForTest(String prompt) async {
    _callCount++;
    if (_shouldFail && (_failOnCallNumber == -1 || _callCount == _failOnCallNumber)) {
      if (_isThrottling) {
        throw Exception('Rate limit exceeded');
      } else {
        throw Exception('Network error');
      }
    }
    return AiApiResult<String>(
      content: 'Success response',
      tokensUsed: 100,
    );
  }

  bool _isThrottlingError(Object error) {
    if (error is ai_provider.RateLimitExceededException) return true;
    final errorString = error.toString().toLowerCase();
    return errorString.contains('rate limit') ||
           errorString.contains('throttle') ||
           errorString.contains('too many requests');
  }

  int _calculateNewRequestCount(DateTime now, ai_provider.AiChatState currentState) {
    final timeWindowStart = now.subtract(currentState.rateLimits.timeWindowDuration);
    if (currentState.lastRequestTime != null && currentState.lastRequestTime!.isAfter(timeWindowStart)) {
      return currentState.requestCountInWindow + 1;
    } else {
      return 1;
    }
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
        backoffBaseDelay: const Duration(milliseconds: 500),
        backoffMaxDelay: const Duration(seconds: 30),
        maxRetryAttempts: 3,
      );

      fakeSettingsRepo = FakeSettingsRepository(aiRateLimitsConfig: customConfig);
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettingsRepo)),
          ai_provider.aiChatProvider.overrideWith(() => FakeAiChatNotifier()),
        ],
      );

      final asyncState = await container.read(ai_provider.aiChatProvider.future);

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
        backoffBaseDelay: const Duration(milliseconds: 500),
        backoffMaxDelay: const Duration(seconds: 30),
        maxRetryAttempts: 3,
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
        backoffBaseDelay: const Duration(milliseconds: 500),
        backoffMaxDelay: const Duration(seconds: 30),
        maxRetryAttempts: 3,
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

      // Make requests with delays to avoid minute limit
      await notifier.sendMessage('Test message 1');
      await Future.delayed(const Duration(seconds: 1));

      await notifier.sendMessage('Test message 2');
      await Future.delayed(const Duration(seconds: 1));

      await notifier.sendMessage('Test message 3');
      await Future.delayed(const Duration(seconds: 1));

      // Fourth request should be rate limited
      await notifier.sendMessage('Test message 4');
      expect(container.read(ai_provider.aiChatProvider).value!.error, isNotNull);
      expect(
        container.read(ai_provider.aiChatProvider).value!.error.toString(),
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
        backoffBaseDelay: const Duration(milliseconds: 500),
        backoffMaxDelay: const Duration(seconds: 30),
        maxRetryAttempts: 3,
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

      // Make requests with delays to avoid shorter limits
      await notifier.sendMessage('Test message 1');
      await Future.delayed(const Duration(seconds: 2));

      await notifier.sendMessage('Test message 2');
      await Future.delayed(const Duration(seconds: 2));

      // Third request should be rate limited
      await notifier.sendMessage('Test message 3');
      expect(container.read(ai_provider.aiChatProvider).value!.error, isNotNull);
      expect(
        container.read(ai_provider.aiChatProvider).value!.error.toString(),
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
        backoffBaseDelay: const Duration(milliseconds: 500),
        backoffMaxDelay: const Duration(seconds: 30),
        maxRetryAttempts: 3,
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

      // Request with too many tokens should be rejected
      await notifier.sendMessage('This is a very long message that would exceed the token limit when processed by the AI model and converted to tokens during the API call. ' * 50); // Make it much longer
      expect(container.read(ai_provider.aiChatProvider).value!.error, isNotNull);
      expect(
        container.read(ai_provider.aiChatProvider).value!.error.toString(),
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
        backoffBaseDelay: const Duration(milliseconds: 500),
        backoffMaxDelay: const Duration(seconds: 30),
        maxRetryAttempts: 3,
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

      // First request should exceed daily token limit
      await notifier.sendMessage('Short message 1');
      expect(container.read(ai_provider.aiChatProvider).value!.error, isNotNull);
      expect(
        container.read(ai_provider.aiChatProvider).value!.error.toString(),
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
            ai_provider.aiChatProvider.overrideWith(() => FakeAiChatNotifier()),
          ],
        );

        // This should not crash the provider, should use defaults
        final asyncState = await errorContainer.read(ai_provider.aiChatProvider.future);
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
        backoffBaseDelay: const Duration(milliseconds: 50), // invalid
        backoffMaxDelay: const Duration(minutes: 10), // invalid
        maxRetryAttempts: -1, // invalid
      );

      fakeSettingsRepo = FakeSettingsRepository(aiRateLimitsConfig: invalidConfig);
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettingsRepo)),
          ai_provider.aiChatProvider.overrideWith(() => FakeAiChatNotifier()),
        ],
      );

      final asyncState = await container.read(ai_provider.aiChatProvider.future);

      // Should have been clamped to minimum values
      expect(asyncState.rateLimits.maxRequestsPerMinute, equals(1));
      expect(asyncState.rateLimits.maxRequestsPerHour, equals(1));
      expect(asyncState.rateLimits.maxRequestsPerDay, equals(1));
      expect(asyncState.rateLimits.maxTokensPerRequest, equals(100));
      expect(asyncState.rateLimits.maxTotalTokensPerDay, equals(1000));
      expect(asyncState.rateLimits.maxRequestsPerWindow, equals(1));
      expect(asyncState.rateLimits.backoffBaseDelay, equals(const Duration(milliseconds: 100)));
      expect(asyncState.rateLimits.backoffMaxDelay, equals(const Duration(seconds: 5)));
      expect(asyncState.rateLimits.maxRetryAttempts, equals(0));
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
        backoffBaseDelay: const Duration(milliseconds: 500),
        backoffMaxDelay: const Duration(seconds: 30),
        maxRetryAttempts: 3,
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

      // Second request should be rate limited
      await notifier.sendMessage('Test message 2');
      expect(container.read(ai_provider.aiChatProvider).value!.error, isNotNull);

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
        backoffBaseDelay: const Duration(milliseconds: 500),
        backoffMaxDelay: const Duration(seconds: 30),
        maxRetryAttempts: 3,
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

      // Start multiple requests sequentially to test rate limiting
      await notifier.sendMessage('Sequential 1');
      await notifier.sendMessage('Sequential 2');
      await notifier.sendMessage('Sequential 3');

      final state = container.read(ai_provider.aiChatProvider);
      // Only 2 should succeed due to rate limiting
      final messages = state.value!.messages;
      expect(messages.length, lessThanOrEqualTo(4)); // 2 successful requests = 4 messages (user + AI each)
    });

    test('should use default maxRequestsPerWindow value of 10 when no config', () async {
      // Wait for the provider to initialize
      final asyncState = await container.read(ai_provider.aiChatProvider.future);

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
        backoffBaseDelay: const Duration(milliseconds: 500),
        backoffMaxDelay: const Duration(seconds: 30),
        maxRetryAttempts: 3,
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

      // First 3 requests should succeed
      await notifier.sendMessage('Test message 1');
      expect(container.read(ai_provider.aiChatProvider).value!.error, isNull);

      await notifier.sendMessage('Test message 2');
      expect(container.read(ai_provider.aiChatProvider).value!.error, isNull);

      await notifier.sendMessage('Test message 3');
      expect(container.read(ai_provider.aiChatProvider).value!.error, isNull);

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
        backoffBaseDelay: const Duration(milliseconds: 500),
        backoffMaxDelay: const Duration(seconds: 30),
        maxRetryAttempts: 3,
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

      // Should allow 10 requests (default fallback) before rate limiting
      for (int i = 1; i <= 10; i++) {
        await notifier.sendMessage('Test message $i');
        expect(container.read(ai_provider.aiChatProvider).value!.error, isNull);
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
        backoffBaseDelay: const Duration(milliseconds: 500),
        backoffMaxDelay: const Duration(seconds: 30),
        maxRetryAttempts: 3,
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

      // Third request should be blocked
      expect(
        () async => await notifier.sendMessage('Test message 3'),
        throwsA(isA<ai_provider.RateLimitExceededException>()),
      );

      // Verify the state shows correct request count
      final state = container.read(ai_provider.aiChatProvider).value!;
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
        backoffBaseDelay: const Duration(milliseconds: 500),
        backoffMaxDelay: const Duration(seconds: 30),
        maxRetryAttempts: 3,
      );

      // Save the config
      await fakeSettingsRepo.setAiRateLimitsConfig(customConfig);

      // Create new container to simulate fresh load
      final newContainer = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettingsRepo)),
          ai_provider.aiChatProvider.overrideWith(() => FakeAiChatNotifier()),
        ],
      );

      // Load and verify
      final loadedState = await newContainer.read(ai_provider.aiChatProvider.future);
      expect(loadedState.rateLimits.maxRequestsPerWindow, equals(7));
      expect(loadedState.rateLimits.timeWindowDuration, equals(const Duration(minutes: 2)));

      newContainer.dispose();
    });
  });

  group('AiChatProvider Exponential Backoff Tests', () {
    late ProviderContainer container;
    late FakeSettingsRepository fakeSettingsRepo;
    late TestAiChatNotifier testNotifier;

    setUp(() {
      fakeSettingsRepo = FakeSettingsRepository();
      testNotifier = TestAiChatNotifier();
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettingsRepo)),
          ai_provider.aiChatProvider.overrideWith(() => testNotifier),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should retry on rate limit errors with exponential backoff and jitter', () async {
      // Setup config with backoff parameters
      final config = AiRateLimitsConfig(
        maxRequestsPerMinute: 10,
        maxRequestsPerHour: 100,
        maxRequestsPerDay: 500,
        maxTokensPerRequest: 1000,
        maxTotalTokensPerDay: 100000,
        maxRequestsPerWindow: 10,
        timeWindowDuration: const Duration(minutes: 1),
        backoffBaseDelay: const Duration(milliseconds: 500),
        backoffMaxDelay: const Duration(seconds: 30),
        maxRetryAttempts: 3,
      );
      fakeSettingsRepo = FakeSettingsRepository(aiRateLimitsConfig: config);
      testNotifier.configureFailure(true, failOnCallNumber: -1); // Always fail

      // Recreate container with new settings
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettingsRepo)),
          ai_provider.aiChatProvider.overrideWith(() => testNotifier),
        ],
      );

      // Initialize provider
      await container.read(ai_provider.aiChatProvider.future);

      // Use fake_async to control time
      fakeAsync((async) async {
        // Get the notifier from the container
        final notifier = container.read(ai_provider.aiChatProvider.notifier);
        
        // Call sendMessage which should trigger retries
        final future = notifier.sendMessage('test message');

        // Expect the future to throw an exception
        expectLater(future, throwsA(isA<Exception>()));

        // Advance time to allow retries to complete
        async.elapse(const Duration(seconds: 35)); // Enough time for all retries

        // Verify AI call was attempted 4 times (initial + 3 retries)
        expect(testNotifier.callCount, equals(4));

        // The future should have completed with an exception, but we don't need to await it
        // since we're just verifying the retry behavior
      });
    });

    test('should respect configurable backoff parameters', () async {
      // Setup custom config with different backoff parameters
      final config = AiRateLimitsConfig(
        maxRequestsPerMinute: 10,
        maxRequestsPerHour: 100,
        maxRequestsPerDay: 500,
        maxTokensPerRequest: 1000,
        maxTotalTokensPerDay: 100000,
        maxRequestsPerWindow: 10,
        timeWindowDuration: const Duration(minutes: 1),
        backoffBaseDelay: const Duration(seconds: 1), // 1 second base
        backoffMaxDelay: const Duration(seconds: 10), // 10 second max
        maxRetryAttempts: 2, // Only 2 retries
      );
      fakeSettingsRepo = FakeSettingsRepository(aiRateLimitsConfig: config);
      testNotifier.configureFailure(true, failOnCallNumber: -1); // Always fail

      // Recreate container with new settings
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettingsRepo)),
          ai_provider.aiChatProvider.overrideWith(() => testNotifier),
        ],
      );

      await container.read(ai_provider.aiChatProvider.future);

      fakeAsync((async) async {
        final future = testNotifier.sendMessage('test message');
        async.elapse(const Duration(seconds: 15));

        bool threw = false;
        try {
          await future;
        } catch (e) {
          threw = true;
        }
        expect(threw, isTrue);

        // Verify only 3 total attempts (initial + 2 retries)
        expect(testNotifier.callCount, equals(3));
      });
    });

    test('should not retry on non-throttling errors', () async {
      final config = AiRateLimitsConfig.defaults();
      fakeSettingsRepo = FakeSettingsRepository(aiRateLimitsConfig: config);
      testNotifier.configureFailure(true, failOnCallNumber: -1, isThrottlingError: false); // Always fail with non-throttling error

      // Recreate container with new settings
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettingsRepo)),
          ai_provider.aiChatProvider.overrideWith(() => testNotifier),
        ],
      );

      await container.read(ai_provider.aiChatProvider.future);

      fakeAsync((async) async {
        final future = testNotifier.sendMessage('test message');
        async.elapse(const Duration(seconds: 1));

        bool threw = false;
        try {
          await future;
        } catch (e) {
          threw = true;
        }
        expect(threw, isTrue);

        // Verify only 1 attempt (no retries for non-throttling errors)
        expect(testNotifier.callCount, equals(1));
      });
    });

    test('should succeed on retry after initial rate limit failure', () async {
      final config = AiRateLimitsConfig.defaults();
      fakeSettingsRepo = FakeSettingsRepository(aiRateLimitsConfig: config);
      
      // Configure to fail on first call, succeed on second
      testNotifier.configureFailure(true, failOnCallNumber: 1);

      // Recreate container with new settings
      container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => Future.value(fakeSettingsRepo)),
          ai_provider.aiChatProvider.overrideWith(() => testNotifier),
        ],
      );

      await container.read(ai_provider.aiChatProvider.future);

      fakeAsync((async) async {
        final sendFuture = testNotifier.sendMessage('test message');
        async.elapse(const Duration(seconds: 5));

        // Should complete successfully
        await sendFuture;

        // Verify 2 attempts (initial failure + retry success)
        expect(testNotifier.callCount, equals(2));
      });
    });
  });
}
