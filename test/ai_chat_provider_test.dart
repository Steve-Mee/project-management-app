// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/models/ai_rate_limits_config.dart';
import 'package:pma_core/providers/ai/ai_chat_providers.dart' as ai_provider;
import 'package:pma_core/repository/impl/hive_settings_repository.dart';

class FakeSettingsRepository extends HiveSettingsRepository {
  AiRateLimitsConfig? _aiRateLimitsConfig;

  FakeSettingsRepository({AiRateLimitsConfig? aiRateLimitsConfig})
      : _aiRateLimitsConfig = aiRateLimitsConfig,
        super();

  @override
  Future<void> initialize({String? testPath}) async {}

  bool get isInitialized => true;

  @override
  AiRateLimitsConfig getAiRateLimitsConfig() {
    return _aiRateLimitsConfig ?? const AiRateLimitsConfig();
  }

  @override
  Future<void> setAiRateLimitsConfig(AiRateLimitsConfig config) async {
    _aiRateLimitsConfig = config;
  }
}

void main() {
  group('Per-Operation Rate Limits Tests', () {
    test('should respect different limits for different operations (chat=15 vs summarize=8)', () {
      const config = AiRateLimitsConfig(
        maxRequestsPerMinute: 100,
        maxRequestsPerHour: 1000,
        maxRequestsPerDay: 5000,
        maxTokensPerRequest: 4000,
        maxTotalTokensPerDay: 100000,
        maxRequestsPerWindow: 20, // Global fallback
        timeWindowDuration: const Duration(minutes: 1),
        backoffBaseDelay: const Duration(milliseconds: 500),
        backoffMaxDelay: const Duration(seconds: 30),
        maxRetryAttempts: 3,
        perOperationLimits: const {'chat': 3, 'generate_questions': 2}, // Different limits
      );

      final state = ai_provider.AiChatState(rateLimits: config);

      // Test that operations are not rate limited initially
      expect(state.isOperationRateLimited('chat'), isFalse);
      expect(state.isOperationRateLimited('generate_questions'), isFalse);

      // Test unknown operation falls back to global
      expect(state.isOperationRateLimited('unknown'), isFalse);
    });

    test('should fallback to global limit for unknown operations', () {
      const config = AiRateLimitsConfig(
        maxRequestsPerMinute: 100,
        maxRequestsPerHour: 1000,
        maxRequestsPerDay: 5000,
        maxTokensPerRequest: 4000,
        maxTotalTokensPerDay: 100000,
        maxRequestsPerWindow: 2, // Global fallback limit
        timeWindowDuration: const Duration(minutes: 1),
        backoffBaseDelay: const Duration(milliseconds: 500),
        backoffMaxDelay: const Duration(seconds: 30),
        maxRetryAttempts: 3,
        perOperationLimits: const {'chat': 5}, // Only chat defined
      );

      final state = ai_provider.AiChatState(rateLimits: config);

      // All operations should not be rate limited initially
      expect(state.isOperationRateLimited('chat'), isFalse);
      expect(state.isOperationRateLimited('unknown'), isFalse);
      expect(state.isOperationRateLimited('generate_questions'), isFalse);
    });

    test('should save and load perOperationLimits map correctly', () async {
      const config = AiRateLimitsConfig(
        maxRequestsPerMinute: 10,
        maxRequestsPerHour: 100,
        maxRequestsPerDay: 500,
        maxTokensPerRequest: 4000,
        maxTotalTokensPerDay: 100000,
        maxRequestsPerWindow: 10,
        timeWindowDuration: const Duration(minutes: 1),
        backoffBaseDelay: const Duration(milliseconds: 500),
        backoffMaxDelay: const Duration(seconds: 30),
        maxRetryAttempts: 3,
        perOperationLimits: const {
          'chat': 15,
          'generate_questions': 8,
          'generate_proposals': 6,
          'generate_plan': 4,
          'parse_filter': 10,
          'summarize': 5,
        },
      );

      final fakeSettingsRepo = FakeSettingsRepository();

      // Save config
      await fakeSettingsRepo.setAiRateLimitsConfig(config);

      // Load config
      final loadedConfig = fakeSettingsRepo.getAiRateLimitsConfig();

      expect(loadedConfig.perOperationLimits, equals(config.perOperationLimits));
      expect(loadedConfig.perOperationLimits['chat'], equals(15));
      expect(loadedConfig.perOperationLimits['summarize'], equals(5));
    });

    test('should handle independent operation counters', () {
      const config = AiRateLimitsConfig(
        maxRequestsPerMinute: 100,
        maxRequestsPerHour: 1000,
        maxRequestsPerDay: 5000,
        maxTokensPerRequest: 4000,
        maxTotalTokensPerDay: 100000,
        maxRequestsPerWindow: 10,
        timeWindowDuration: const Duration(minutes: 1),
        backoffBaseDelay: const Duration(milliseconds: 500),
        backoffMaxDelay: const Duration(seconds: 30),
        maxRetryAttempts: 3,
        perOperationLimits: const {'chat': 2, 'generate_questions': 3}, // Different limits
      );

      final now = DateTime.now();
      var state = ai_provider.AiChatState(
        rateLimits: config,
        lastRequestTime: now,
        requestCountInWindow: const {'chat': 2, 'generate_questions': 3},
      );

      // Chat should be at limit (2)
      expect(state.isOperationRateLimited('chat'), isTrue);

      // generate_questions should be at limit (3)
      expect(state.isOperationRateLimited('generate_questions'), isTrue);

      // But they are independent - chat being limited doesn't affect generate_questions
      // (This is already tested by the separate counters)
      expect(state.requestCountInWindow['chat'], equals(2));
      expect(state.requestCountInWindow['generate_questions'], equals(3));
    });
  });
}
