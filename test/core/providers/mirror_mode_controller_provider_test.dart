import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/services/mirror_access_policy.dart';
import 'package:project_management_app/core/providers/mirror_mode_controller_provider.dart';

class _TestMirrorModeController extends MirrorModeController {
  @override
  MirrorState build() => const MirrorState(
        mode: 'private',
        isPremium: false,
        teamModeVariant: 'solo',
        offlineWarning: null,
      );
}

void main() {
  group('Mirror provider policy', () {
    test('blocks cloud mode without premium and sets warning', () {
      const policy = MirrorAccessPolicy();
      final decision = policy.resolveRequestedMode(
        requestedMode: 'cloud',
        isPremium: false,
        runnerModeVariant: 'cloud',
      );

      expect(decision.effectiveMode, 'private');
      expect(
        decision.warning,
        contains('Cloud mode requires'),
      );
    });

    test('allows cloud mode with premium', () {
      const policy = MirrorAccessPolicy();
      final decision = policy.resolveRequestedMode(
        requestedMode: 'cloud',
        isPremium: true,
        runnerModeVariant: 'cloud',
      );

      expect(decision.effectiveMode, 'cloud');
      expect(decision.warning, isNull);
    });

    test('cloud mode falls back to private when premium is lost', () {
      const policy = MirrorAccessPolicy();
      final decision = policy.resolveRequestedMode(
        requestedMode: 'cloud',
        isPremium: false,
        runnerModeVariant: 'cloud',
      );

      expect(decision.effectiveMode, 'private');
      expect(
        decision.warning,
        contains('Cloud mode requires'),
      );
    });

    test('private-only policy downgrades cloud request', () {
      const policy = MirrorAccessPolicy();
      final decision = policy.resolveRequestedMode(
        requestedMode: 'cloud',
        isPremium: true,
        allowCloudMode: false,
        allowPrivateMode: true,
      );

      expect(decision.effectiveMode, 'private');
      expect(decision.usedAdminBypass, isFalse);
      expect(decision.warning, contains('disabled by policy'));
    });

    test('cloud-only policy upgrades private request when allowed', () {
      const policy = MirrorAccessPolicy();
      final decision = policy.resolveRequestedMode(
        requestedMode: 'private',
        isPremium: true,
        allowPrivateMode: false,
        allowCloudMode: true,
      );

      expect(decision.effectiveMode, 'cloud');
      expect(decision.warning, contains('restricted'));
    });

    test('admin bypass allows cloud without premium', () {
      const policy = MirrorAccessPolicy();
      final decision = policy.resolveRequestedMode(
        requestedMode: 'cloud',
        isPremium: false,
        allowCloudMode: false,
        allowAdminBypass: true,
      );

      expect(decision.effectiveMode, 'cloud');
      expect(decision.requiresPremium, isFalse);
      expect(decision.usedAdminBypass, isTrue);
    });

    test('warning clear behavior', () {
      final container = ProviderContainer(
        overrides: <Override>[
          mirrorModeControllerProvider.overrideWith(
            _TestMirrorModeController.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(mirrorModeControllerProvider).teamModeVariant, 'solo');
      expect(container.read(mirrorModeControllerProvider).isTeamMode, isFalse);

      container.read(mirrorModeControllerProvider.notifier).state = container
          .read(mirrorModeControllerProvider)
          .copyWith(offlineWarning: 'offline fallback');
      expect(container.read(mirrorModeControllerProvider).offlineWarning, 'offline fallback');

      container.read(mirrorModeControllerProvider.notifier).clearOfflineWarning();
      expect(container.read(mirrorModeControllerProvider).offlineWarning, isNull);
    });
  });
}
