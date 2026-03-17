import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/services/mirror_access_policy.dart';
import 'package:project_management_app/core/providers/mirror_provider.dart';

class _TestMirrorNotifier extends MirrorNotifier {
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

    test('warning clear behavior', () {
      final container = ProviderContainer(
        overrides: <Override>[
          mirrorProvider.overrideWith(_TestMirrorNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(mirrorProvider).teamModeVariant, 'solo');
      expect(container.read(mirrorProvider).isTeamMode, isFalse);

      container.read(mirrorProvider.notifier).state =
          container.read(mirrorProvider).copyWith(offlineWarning: 'offline fallback');
      expect(container.read(mirrorProvider).offlineWarning, 'offline fallback');

      container.read(mirrorProvider.notifier).clearOfflineWarning();
      expect(container.read(mirrorProvider).offlineWarning, isNull);
    });
  });
}
