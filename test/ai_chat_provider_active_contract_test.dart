import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/models/ai_rate_limits_config.dart';
import 'package:pma_core/providers/ai/ai_chat_providers.dart' as active_ai;

void main() {
  group('Active AiChatState contract', () {
    test('exposes default active state fields', () {
      const state = active_ai.AiChatState();

      expect(state.messages, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isRateLimited, isFalse);
      expect(state.rateLimitResetTime, isNull);
      expect(state.rateLimitsConfig, const AiRateLimitsConfig());
      expect(state.queueLength, 0);
      expect(state.processedToday, 0);
      expect(state.droppedCount, 0);
    });

    test('copyWith updates active state fields', () {
      const base = active_ai.AiChatState();
      final updated = base.copyWith(
        isLoading: true,
        error: 'rate_limited',
        isRateLimited: true,
        queueLength: 3,
        processedToday: 10,
        droppedCount: 1,
        rateLimitsConfig: const AiRateLimitsConfig(maxRequestsPerWindow: 42),
      );

      expect(updated.isLoading, isTrue);
      expect(updated.error, 'rate_limited');
      expect(updated.isRateLimited, isTrue);
      expect(updated.queueLength, 3);
      expect(updated.processedToday, 10);
      expect(updated.droppedCount, 1);
      expect(updated.rateLimitsConfig.maxRequestsPerWindow, 42);
    });
  });
}
