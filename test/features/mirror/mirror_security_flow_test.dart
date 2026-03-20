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

    test('cloud-only permission upgrades private mode to cloud', () {
      final decision = policy.resolveRequestedMode(
        requestedMode: 'private',
        isPremium: true,
        allowPrivateMode: false,
        allowCloudMode: true,
      );

      expect(decision.effectiveMode, 'cloud');
      expect(decision.requiresPremium, true);
    });

    test('private-only permission downgrades cloud mode to private', () {
      final decision = policy.resolveRequestedMode(
        requestedMode: 'cloud',
        isPremium: true,
        allowPrivateMode: true,
        allowCloudMode: false,
      );

      expect(decision.effectiveMode, 'private');
      expect(decision.usedAdminBypass, isFalse);
      expect(decision.warning, contains('disabled by policy'));
    });

    test('admin bypass keeps cloud mode when policy would block it', () {
      final decision = policy.resolveRequestedMode(
        requestedMode: 'cloud',
        isPremium: false,
        allowPrivateMode: true,
        allowCloudMode: false,
        allowAdminBypass: true,
      );

      expect(decision.effectiveMode, 'cloud');
      expect(decision.requiresPremium, isFalse);
      expect(decision.usedAdminBypass, isTrue);
      expect(decision.warning, contains('admin testing bypass'));
    });
  });
}
