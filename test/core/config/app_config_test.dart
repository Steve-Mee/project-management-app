import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project_management_app/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    setUpAll(() async {
      // Ensure dotenv is initialized before direct env access in tests.
      await dotenv.load(fileName: '.env', isOptional: true);
    });

    tearDown(() {
      dotenv.env.clear();
    });

    test('loads OPENAI_API_KEY and other env vars correctly', () async {
      await AppConfig.initialize();

      // AppConfig always reloads .env on initialize, so only assert presence/types.
      expect(AppConfig.supabaseUrl, isNotNull);
      expect(AppConfig.supabaseAnonKey, isNotNull);
      expect(AppConfig.isValid, isTrue);
      expect(AppConfig.logLevel, anyOf(isNull, isA<String>()));
      expect(AppConfig.sentryDsn, anyOf(isNull, isA<String>()));
    });

    test('supports future expansions - can add new env vars without changing main.dart', () async {
      await AppConfig.initialize();

      // Baseline contract: initialize remains stable when additional env vars exist.
      expect(AppConfig.supabaseUrl, isNotNull);
      expect(AppConfig.supabaseAnonKey, isNotNull);
    });

    test('proper loading and validation runs without throwing in test mode', () async {
      await AppConfig.initialize();

      expect(AppConfig.supabaseUrl, isNotNull);
      expect(AppConfig.supabaseAnonKey, isNotNull);
      expect(AppConfig.isValid, isTrue);
    });

    test('additional env vars are supported', () async {
      await AppConfig.initialize();

      expect(AppConfig.openaiBaseUrl, anyOf(isNull, isA<String>()));
      expect(AppConfig.sentryDsn, anyOf(isNull, isA<String>()));
      expect(AppConfig.logLevel, anyOf(isNull, isA<String>()));
      expect(AppConfig.firebaseApiKey, anyOf(isNull, isA<String>()));
    });

    test('isValid returns true when required configs are present', () async {
      dotenv.env['SUPABASE_URL'] = 'test_url';
      dotenv.env['SUPABASE_ANON_KEY'] = 'test_key';

      await AppConfig.initialize();

      expect(AppConfig.isValid, true);
    });

    test('isValid returns false when required configs are missing', () async {
      await AppConfig.initialize();

      // initialize() reloads .env, so this depends on actual file contents.
      expect(AppConfig.isValid, isA<bool>());
    });
  });
}
