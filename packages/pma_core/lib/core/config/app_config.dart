import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:pma_core/services/app_logger.dart';

/// Centralized application configuration loaded from environment variables.
class AppConfig {
  static String? _openaiApiKey;
  static String? _stripePublishableKey;
  static String? _stripeSecretKey;
  static String? _supabaseUrl;
  static String? _supabaseAnonKey;
  static String? _openaiBaseUrl;
  static String? _sentryDsn;
  static String? _logLevel;
  static String? _firebaseApiKey;

  /// Initialize configuration by loading environment variables.
  static Future<void> initialize() async {
    try {
      if (!kReleaseMode) {
        await dotenv.load();
        _supabaseUrl = dotenv.env['SUPABASE_URL'];
        _supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
      } else {
        const storage = FlutterSecureStorage();
        _supabaseUrl = await storage.read(key: 'SUPABASE_URL');
        _supabaseAnonKey = await storage.read(key: 'SUPABASE_ANON_KEY');
        if (_supabaseUrl == null || _supabaseUrl!.isEmpty || _supabaseAnonKey == null || _supabaseAnonKey!.isEmpty) {
          await dotenv.load();
          _supabaseUrl = dotenv.env['SUPABASE_URL'];
          _supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
        }
      }

      _openaiApiKey = dotenv.env['OPENAI_API_KEY'];
      _stripePublishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
      _stripeSecretKey = dotenv.env['STRIPE_SECRET_KEY'];
      _openaiBaseUrl = dotenv.env['OPENAI_BASE_URL'];
      _sentryDsn = dotenv.env['SENTRY_DSN'];
      _logLevel = dotenv.env['LOG_LEVEL'];
      _firebaseApiKey = dotenv.env['FIREBASE_API_KEY'];

      AppLogger.instance.i('AppConfig: Configuration loaded successfully');
    } catch (e) {
      AppLogger.instance.e('AppConfig: Failed to load configuration', error: e);
      rethrow;
    }

    _validateConfiguration();
  }

  static void _validateConfiguration() {
    if (_supabaseUrl == null || _supabaseUrl!.isEmpty) {
      AppLogger.instance.e('AppConfig: SUPABASE_URL is required but not found');
    }
    if (_supabaseAnonKey == null || _supabaseAnonKey!.isEmpty) {
      AppLogger.instance.e('AppConfig: SUPABASE_ANON_KEY is required but not found');
    }

    if (_openaiApiKey == null || _openaiApiKey!.isEmpty) {
      AppLogger.instance.w('AppConfig: OPENAI_API_KEY not found - AI features may be limited');
    }
    if (_stripePublishableKey == null || _stripePublishableKey!.isEmpty) {
      AppLogger.instance.w('AppConfig: STRIPE_PUBLISHABLE_KEY not found - Payment features may be disabled');
    }
    if (_stripeSecretKey == null || _stripeSecretKey!.isEmpty) {
      AppLogger.instance.w('AppConfig: STRIPE_SECRET_KEY not found - Server-side payments may fail');
    }

    AppLogger.instance.i('AppConfig: Configuration validation complete');

    if (kReleaseMode) {
      if (_supabaseUrl == null || _supabaseUrl!.isEmpty) {
        throw Exception('SUPABASE_URL is required in production but not configured. Please set the SUPABASE_URL environment variable.');
      }
      if (_supabaseAnonKey == null || _supabaseAnonKey!.isEmpty) {
        throw Exception('SUPABASE_ANON_KEY is required in production but not configured. Please set the SUPABASE_ANON_KEY environment variable.');
      }
    }
  }

  static String? get openaiApiKey => _openaiApiKey;
  static String? get stripePublishableKey => _stripePublishableKey;
  static String? get stripeSecretKey => _stripeSecretKey;
  static String? get supabaseUrl => _supabaseUrl;
  static String? get supabaseAnonKey => _supabaseAnonKey;
  static String? get openaiBaseUrl => _openaiBaseUrl;
  static String? get sentryDsn => _sentryDsn;
  static String? get logLevel => _logLevel;
  static String? get firebaseApiKey => _firebaseApiKey;

  static bool get isValid =>
      _supabaseUrl != null && _supabaseUrl!.isNotEmpty &&
      _supabaseAnonKey != null && _supabaseAnonKey!.isNotEmpty;
}
