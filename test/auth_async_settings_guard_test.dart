import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recaptcha provider uses async settings repository without sync fallback', () async {
    final file = File('packages/pma_core/lib/providers/auth/auth_providers.dart');
    expect(file.existsSync(), isTrue);

    final content = await file.readAsString();
    expect(content.contains('final recaptchaServiceProvider = FutureProvider<RecaptchaService>'), isTrue);
    expect(content.contains('await ref.read(settingsRepositoryProvider.future)'), isTrue);
    expect(content.contains('HiveSettingsRepository.new'), isFalse);
  });

  test('login flow awaits recaptcha provider future', () async {
    final file = File('packages/pma_core/lib/providers/auth/auth_providers.dart');
    final content = await file.readAsString();

    expect(content.contains('await ref.read(recaptchaServiceProvider.future)'), isTrue);
  });

  test('auth settings access uses read(future) and avoids watch(future) in imperative paths', () async {
    final file = File('packages/pma_core/lib/providers/auth/auth_providers.dart');
    final content = await file.readAsString();

    expect(content.contains('await ref.read(settingsRepositoryProvider.future)'), isTrue);
    expect(content.contains('ref.watch(settingsRepositoryProvider.future)'), isFalse);
  });

  test('auth providers use canonical cloud sync auth method names', () async {
    final file = File('packages/pma_core/lib/providers/auth/auth_providers.dart');
    final content = await file.readAsString();

    expect(content.contains('authSignInPlaceholder('), isFalse);
    expect(content.contains('authSignOutPlaceholder('), isFalse);
    expect(content.contains('authSignIn('), isTrue);
    expect(content.contains('authSignOut('), isTrue);
  });
}
