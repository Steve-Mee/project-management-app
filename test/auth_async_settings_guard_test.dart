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
}
