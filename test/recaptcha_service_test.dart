import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_management_app/core/services/recaptcha_service.dart';
import 'package:project_management_app/core/repository/settings_repository.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late SettingsRepository settings;
  late RecaptchaService recaptchaService;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('recaptcha_service_test_');
    Hive.init(tempDir.path);
    await Hive.openBox('settings');
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() {
    settings = SettingsRepository();
    recaptchaService = RecaptchaService(settings);
  });

  group('RecaptchaService', () {
    test('returns null when site key is empty (dev mode)', () async {
      await settings.setRecaptchaSiteKey('');

      final result = await recaptchaService.getRecaptchaToken();

      expect(result, isNull);
    });

    test('returns null when site key is configured in non-production mode', () async {
      await settings.setRecaptchaSiteKey('test-site-key');

      final result = await recaptchaService.getRecaptchaToken();

      expect(result, isNull);
    });
  });
}
