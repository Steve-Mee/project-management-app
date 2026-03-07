import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/models/ai_rate_limits_config.dart';
import 'package:pma_core/providers/ai/ai_chat_providers.dart';

void main() {
  group('AiChatNotifier backoff policy', () {
    test('respects configured max backoff cap', () {
      final notifier = AiChatNotifier(null, Random(1));
      notifier.setRateLimitsConfigForTest(
        const AiRateLimitsConfig(
          backoffBaseDelay: Duration(milliseconds: 200),
          backoffMaxDelay: Duration(seconds: 2),
        ),
      );

      final delay = notifier.calculateBackoffDelayForAttempt(10);
      expect(delay, lessThanOrEqualTo(const Duration(seconds: 2)));
    });

    test('uses configured base delay for early attempts', () {
      final notifier = AiChatNotifier(null, Random(2));
      notifier.setRateLimitsConfigForTest(
        const AiRateLimitsConfig(
          backoffBaseDelay: Duration(milliseconds: 300),
          backoffMaxDelay: Duration(seconds: 5),
        ),
      );

      final delay = notifier.calculateBackoffDelayForAttempt(0);
      expect(delay, greaterThanOrEqualTo(const Duration(milliseconds: 300)));
      expect(delay, lessThanOrEqualTo(const Duration(seconds: 5)));
    });
  });
}
