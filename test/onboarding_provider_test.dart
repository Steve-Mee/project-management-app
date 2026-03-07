import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pma_core/providers/auth/auth_providers.dart';
import 'package:pma_core/providers/onboarding_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        // Keep onboarding tests isolated from Hive/settings initialization.
        settingsRepositoryProvider.overrideWith((ref) async {
          throw StateError('settings init not required for onboarding tests');
        }),
      ],
    );
  }

  group('OnboardingProvider persistence', () {
    test('isFirstLaunch is true when onboarding is not completed', () async {
      SharedPreferences.setMockInitialValues({});
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(onboardingProvider.notifier);
      final isFirstLaunch = await notifier.isFirstLaunch();

      expect(isFirstLaunch, isTrue);
      expect(container.read(onboardingProvider), isFalse);
    });

    test('markOnboardingCompleted persists completion flag', () async {
      SharedPreferences.setMockInitialValues({});
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(onboardingProvider.notifier);

      expect(await notifier.isFirstLaunch(), isTrue);

      await notifier.markOnboardingCompleted();

      expect(container.read(onboardingProvider), isTrue);
      expect(await notifier.isFirstLaunch(), isFalse);
    });

    test('completion persists across container recreation', () async {
      SharedPreferences.setMockInitialValues({
        'onboardingCompleted': true,
      });

      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(onboardingProvider.notifier);

      expect(await notifier.isFirstLaunch(), isFalse);
      expect(container.read(onboardingProvider), isTrue);
    });
  });
}
