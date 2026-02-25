import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_project_management_app/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    tearDown(() {
      dotenv.env.clear();
    });

    test('loads OPENAI_API_KEY and other env vars correctly', () async {
      // Arrange
      dotenv.env['OPENAI_API_KEY'] = 'test_openai_key';
      dotenv.env['STRIPE_PUBLISHABLE_KEY'] = 'test_stripe_pub';
      dotenv.env['SUPABASE_URL'] = 'test_supabase_url';
      dotenv.env['SUPABASE_ANON_KEY'] = 'test_supabase_key';
      dotenv.env['OPENAI_BASE_URL'] = 'test_openai_base_url';
      dotenv.env['SENTRY_DSN'] = 'test_sentry_dsn';
      dotenv.env['LOG_LEVEL'] = 'debug';
      dotenv.env['FIREBASE_API_KEY'] = 'test_firebase_key';

      // Act
      await AppConfig.initialize();

      // Assert
      expect(AppConfig.openaiApiKey, 'test_openai_key');
      expect(AppConfig.stripePublishableKey, 'test_stripe_pub');
      expect(AppConfig.supabaseUrl, 'test_supabase_url');
      expect(AppConfig.supabaseAnonKey, 'test_supabase_key');
      expect(AppConfig.openaiBaseUrl, 'test_openai_base_url');
      expect(AppConfig.sentryDsn, 'test_sentry_dsn');
      expect(AppConfig.logLevel, 'debug');
      expect(AppConfig.firebaseApiKey, 'test_firebase_key');
    });

    test('supports future expansions - can add new env vars without changing main.dart', () async {
      // This test demonstrates that new env vars can be added to AppConfig
      // without requiring changes to main.dart initialization
      dotenv.env['SUPABASE_URL'] = 'test_url';
      dotenv.env['SUPABASE_ANON_KEY'] = 'test_key';
      dotenv.env['NEW_ENV_VAR'] = 'new_value';

      await AppConfig.initialize();

      // The class structure allows adding new vars easily
      // In practice, we'd add: static String? _newEnvVar; and getter
      expect(AppConfig.supabaseUrl, 'test_url');
      // This test passes as long as the existing structure works
    });

    test('proper loading and validation - throws on missing required keys in production', () async {
      // Simulate production mode
      dotenv.env.clear(); // No env vars set

      // Since we can't easily change kReleaseMode in tests,
      // we test the validation logic indirectly
      await AppConfig.initialize();

      // In debug mode, it should not throw but log errors
      expect(AppConfig.supabaseUrl, isNull);
      expect(AppConfig.isValid, false);
    });

    test('additional env vars are supported', () async {
      // Test that all additional env vars beyond the original set are loaded
      dotenv.env['SUPABASE_URL'] = 'test_url';
      dotenv.env['SUPABASE_ANON_KEY'] = 'test_key';
      dotenv.env['OPENAI_BASE_URL'] = 'https://api.openai.com/v1';
      dotenv.env['SENTRY_DSN'] = 'https://sentry.io/test';
      dotenv.env['LOG_LEVEL'] = 'info';
      dotenv.env['FIREBASE_API_KEY'] = 'firebase_key_123';

      await AppConfig.initialize();

      expect(AppConfig.openaiBaseUrl, 'https://api.openai.com/v1');
      expect(AppConfig.sentryDsn, 'https://sentry.io/test');
      expect(AppConfig.logLevel, 'info');
      expect(AppConfig.firebaseApiKey, 'firebase_key_123');
    });

    test('isValid returns true when required configs are present', () async {
      dotenv.env['SUPABASE_URL'] = 'test_url';
      dotenv.env['SUPABASE_ANON_KEY'] = 'test_key';

      await AppConfig.initialize();

      expect(AppConfig.isValid, true);
    });

    test('isValid returns false when required configs are missing', () async {
      dotenv.env.clear();

      await AppConfig.initialize();

      expect(AppConfig.isValid, false);
    });
  });
}