import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/services/mirror_access_policy.dart';

void main() {
  group('Mirror security flow', () {
    const policy = MirrorAccessPolicy();

    test('non-premium cloud request is downgraded to private', () {
      final decision = policy.resolveRequestedMode(
        requestedMode: 'cloud',
        isPremium: false,
      );

      expect(decision.effectiveMode, 'private');
      expect(decision.requiresPremium, true);
      expect(decision.warning, isNotNull);
    });

    test('premium cloud request stays cloud', () {
      final decision = policy.resolveRequestedMode(
        requestedMode: 'cloud',
        isPremium: true,
      );

      expect(decision.effectiveMode, 'cloud');
      expect(decision.requiresPremium, true);
      expect(decision.warning, isNull);
    });

    test('invalid mode always resolves to private', () {
      final decision = policy.resolveRequestedMode(
        requestedMode: 'unknown',
        isPremium: true,
      );

      expect(decision.effectiveMode, 'private');
      expect(decision.requiresPremium, false);
    });

    test('runner local variant downgrades cloud request to private', () {
      final decision = policy.resolveRequestedMode(
        requestedMode: 'cloud',
        isPremium: true,
        runnerModeVariant: 'local',
      );

      expect(decision.effectiveMode, 'private');
      expect(decision.requiresPremium, false);
      expect(decision.warning, isNotNull);
    });
  });
}
