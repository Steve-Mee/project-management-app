import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/models/ai_rate_limits_config.dart';

void main() {
  group('AiRateLimitsConfig validation', () {
    test('clamps invalid window and retry values', () {
      const raw = AiRateLimitsConfig(
        maxRequestsPerWindow: 0,
        maxRetryAttempts: 99,
      );

      final validated = AiRateLimitsConfig.validateAiRateLimits(raw);

      expect(validated.maxRequestsPerWindow, 1);
      expect(validated.maxRetryAttempts, 10);
    });

    test('clamps invalid backoff durations into allowed range', () {
      const raw = AiRateLimitsConfig(
        backoffBaseDelay: Duration(milliseconds: 10),
        backoffMaxDelay: Duration(seconds: 1),
      );

      final validated = AiRateLimitsConfig.validateAiRateLimits(raw);

      expect(validated.backoffBaseDelay, const Duration(milliseconds: 100));
      expect(validated.backoffMaxDelay, const Duration(seconds: 5));
    });

    test('clamps invalid per-operation limits', () {
      const raw = AiRateLimitsConfig(
        perOperationLimits: {
          'chat': 0,
          'summarize': 5001,
        },
      );

      final validated = AiRateLimitsConfig.validateAiRateLimits(raw);

      expect(validated.perOperationLimits['chat'], 1);
      expect(validated.perOperationLimits['summarize'], 1000);
    });

    test('keeps different valid window configurations distinct', () {
      const conservative = AiRateLimitsConfig(
        maxRequestsPerWindow: 3,
        timeWindowDuration: Duration(seconds: 30),
      );
      const relaxed = AiRateLimitsConfig(
        maxRequestsPerWindow: 15,
        timeWindowDuration: Duration(seconds: 30),
      );

      final conservativeValidated =
          AiRateLimitsConfig.validateAiRateLimits(conservative);
      final relaxedValidated = AiRateLimitsConfig.validateAiRateLimits(relaxed);

      expect(conservativeValidated.maxRequestsPerWindow, 3);
      expect(relaxedValidated.maxRequestsPerWindow, 15);
      expect(
        relaxedValidated.maxRequestsPerWindow,
        greaterThan(conservativeValidated.maxRequestsPerWindow),
      );
    });

    test('preserves window values in json roundtrip', () {
      const config = AiRateLimitsConfig(
        maxRequestsPerWindow: 7,
        timeWindowDuration: Duration(seconds: 45),
      );

      final encoded = config.toJson();
      final decoded = AiRateLimitsConfig.fromJson(encoded);

      expect(decoded.maxRequestsPerWindow, 7);
      expect(decoded.timeWindowDuration, const Duration(seconds: 45));
    });
  });
}
