import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  late Directory hiveDir;

  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp('mirror_provider_test_');
    Hive.init(hiveDir.path);
  });

  tearDown(() async {
    if (Hive.isBoxOpen('mirror_offline_cache')) {
      await Hive.box<dynamic>('mirror_offline_cache').clear();
      await Hive.box<dynamic>('mirror_offline_cache').close();
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  });

  group('Mirror provider', () {
    test('blocks cloud mode without premium and sets warning', () async {
      final container = ProviderContainer(
        overrides: <Override>[
          mirrorPremiumProvider.overrideWith((ref) async => false),
          mirrorTeamModeVariantProvider.overrideWith((ref) async => 'solo'),
          mirrorProvider.overrideWith(_TestMirrorNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      await container.read(mirrorProvider.notifier).setMode('cloud');
      final state = container.read(mirrorProvider);

      expect(state.mode, 'private');
      expect(state.isPremium, isFalse);
      expect(state.offlineWarning, contains('Cloud mode requires'));
    });

    test('allows cloud mode with premium', () async {
      final container = ProviderContainer(
        overrides: <Override>[
          mirrorPremiumProvider.overrideWith((ref) async => true),
          mirrorTeamModeVariantProvider.overrideWith((ref) async => 'solo'),
          mirrorProvider.overrideWith(_TestMirrorNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      await container.read(mirrorProvider.notifier).setMode('cloud');
      final state = container.read(mirrorProvider);

      expect(state.mode, 'cloud');
      expect(state.offlineWarning, isNull);
    });

    test('refreshPremiumFromMetadata falls back to private when premium is lost', () async {
      final premiumState = StateProvider<bool>((ref) => true);

      final container = ProviderContainer(
        overrides: <Override>[
          mirrorPremiumProvider.overrideWith(
            (ref) async => ref.watch(premiumState),
          ),
          mirrorTeamModeVariantProvider.overrideWith((ref) async => 'solo'),
          mirrorProvider.overrideWith(_TestMirrorNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      await container.read(mirrorProvider.notifier).setMode('cloud');
      expect(container.read(mirrorProvider).mode, 'cloud');

      container.read(premiumState.notifier).state = false;
      await container.read(mirrorProvider.notifier).refreshPremiumFromMetadata();

      final state = container.read(mirrorProvider);
      expect(state.mode, 'private');
      expect(state.isPremium, isFalse);
      expect(state.offlineWarning, contains('Cloud mode requires'));
    });

    test('team mode fallback and warning clear behavior', () {
      final container = ProviderContainer(
        overrides: <Override>[
          mirrorPremiumProvider.overrideWith((ref) async => true),
          mirrorTeamModeVariantProvider.overrideWith((ref) async => 'solo'),
          mirrorProvider.overrideWith(_TestMirrorNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(mirrorTeamModeEnabledProvider), isFalse);

      container.read(mirrorProvider.notifier).state =
          container.read(mirrorProvider).copyWith(offlineWarning: 'offline fallback');
      expect(container.read(mirrorProvider).offlineWarning, 'offline fallback');

      container.read(mirrorProvider.notifier).clearOfflineWarning();
      expect(container.read(mirrorProvider).offlineWarning, isNull);
    });
  });
}
