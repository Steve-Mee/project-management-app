import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/models/ai_rate_limits_config.dart';
import 'package:pma_core/models/ai_request_queue.dart';
import 'package:pma_core/providers/ai/ai_chat_providers.dart';

void main() {
  group('AiChatNotifier queue behavior', () {
    test('enqueues request when queueEnabled is true', () async {
      final notifier = AiChatNotifier();
      notifier.setRateLimitsConfigForTest(
        const AiRateLimitsConfig(queueEnabled: true),
      );

      final completer = Completer<dynamic>();
      final request = AiRequest(
        id: 'q-enabled',
        action: 'unknown_action',
        payload: const {},
        timestamp: DateTime.now(),
        completer: completer,
      );

      await notifier.enqueueRequestForTest(request);

      expect(notifier.queueLengthForTest, 1);
      expect(completer.isCompleted, isFalse);
    });

    test('bypasses queue when queueEnabled is false', () async {
      final notifier = AiChatNotifier();
      notifier.setRateLimitsConfigForTest(
        const AiRateLimitsConfig(queueEnabled: false),
      );

      final completer = Completer<dynamic>();
      completer.future.catchError((_) => null);
      final request = AiRequest(
        id: 'q-disabled',
        action: 'unknown_action',
        payload: const {},
        timestamp: DateTime.now(),
        completer: completer,
      );

      await expectLater(
        notifier.enqueueRequestForTest(request),
        throwsA(isA<Exception>()),
      );

      expect(notifier.queueLengthForTest, 0);
      expect(completer.isCompleted, isTrue);
    });
  });
}
