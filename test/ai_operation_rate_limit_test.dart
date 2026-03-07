import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/models/ai_rate_limits_config.dart';
import 'package:pma_core/providers/ai/ai_chat_providers.dart';

void main() {
  group('AiChatNotifier per-operation rate limits', () {
    test('uses specific limit for configured operation', () {
      final notifier = AiChatNotifier();
      notifier.setRateLimitsConfigForTest(
        const AiRateLimitsConfig(
          maxRequestsPerWindow: 10,
          timeWindowDuration: Duration(minutes: 1),
          perOperationLimits: {
            'chat': 1,
            'generate_questions': 3,
          },
        ),
      );

      expect(notifier.isOperationRateLimitedForTest('chat'), isFalse);
      notifier.recordOperationForTest('chat');
      expect(notifier.isOperationRateLimitedForTest('chat'), isTrue);

      expect(
        notifier.isOperationRateLimitedForTest('generate_questions'),
        isFalse,
      );
    });

    test('falls back to global maxRequestsPerWindow for unknown operation', () {
      final notifier = AiChatNotifier();
      notifier.setRateLimitsConfigForTest(
        const AiRateLimitsConfig(
          maxRequestsPerWindow: 2,
          timeWindowDuration: Duration(minutes: 1),
          perOperationLimits: {'chat': 5},
        ),
      );

      notifier.recordOperationForTest('unknown_op');
      expect(notifier.isOperationRateLimitedForTest('unknown_op'), isFalse);

      notifier.recordOperationForTest('unknown_op');
      expect(notifier.isOperationRateLimitedForTest('unknown_op'), isTrue);
    });

    test('tracks operation limits independently', () {
      final notifier = AiChatNotifier();
      notifier.setRateLimitsConfigForTest(
        const AiRateLimitsConfig(
          maxRequestsPerWindow: 10,
          timeWindowDuration: Duration(minutes: 1),
          perOperationLimits: {
            'chat': 1,
            'generate_questions': 2,
          },
        ),
      );

      notifier.recordOperationForTest('chat');
      notifier.recordOperationForTest('generate_questions');

      expect(notifier.isOperationRateLimitedForTest('chat'), isTrue);
      expect(notifier.isOperationRateLimitedForTest('generate_questions'), isFalse);

      notifier.recordOperationForTest('generate_questions');
      expect(notifier.isOperationRateLimitedForTest('generate_questions'), isTrue);
    });
  });
}
