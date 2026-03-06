import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:pma_core/services/app_logger.dart';

/// Centralized application configuration loaded from environment variables.
/// Provides typed access to API keys and configuration values.
/// Designed to be easily extensible for future environment variables.
///
/// See .github/issues/048-application-configuration-expansions.md for expansion details.
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
  /// Should be called early in app startup.
  static Future<void> initialize() async {
    try {
      // Load Supabase keys with secure storage fallback for production
      if (!kReleaseMode) {
        // Debug mode: load from .env file
        await dotenv.load();
        _supabaseUrl = dotenv.env['SUPABASE_URL'];
        _supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
      } else {
        // Release mode: Use secure storage for production security
        const storage = FlutterSecureStorage();
        _supabaseUrl = await storage.read(key: 'SUPABASE_URL');
        _supabaseAnonKey = await storage.read(key: 'SUPABASE_ANON_KEY');
        if (_supabaseUrl == null || _supabaseUrl!.isEmpty || _supabaseAnonKey == null || _supabaseAnonKey!.isEmpty) {
          // Fallback to .env if secure storage is empty
          await dotenv.load();
          _supabaseUrl = dotenv.env['SUPABASE_URL'];
          _supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
        }
      }

      // Load other configuration values from dotenv (available in both modes)
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

    // Validation
    _validateConfiguration();
  }

  /// Validate required configuration values and log warnings for missing optional ones.
  static void _validateConfiguration() {
    // Required configurations
    if (_supabaseUrl == null || _supabaseUrl!.isEmpty) {
      AppLogger.instance.e('AppConfig: SUPABASE_URL is required but not found');
    }
    if (_supabaseAnonKey == null || _supabaseAnonKey!.isEmpty) {
      AppLogger.instance.e('AppConfig: SUPABASE_ANON_KEY is required but not found');
    }

    // Optional configurations with warnings
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

    // Throw in production for missing critical keys
    if (kReleaseMode) {
      if (_supabaseUrl == null || _supabaseUrl!.isEmpty) {
        throw Exception('SUPABASE_URL is required in production but not configured. Please set the SUPABASE_URL environment variable.');
      }
      if (_supabaseAnonKey == null || _supabaseAnonKey!.isEmpty) {
        throw Exception('SUPABASE_ANON_KEY is required in production but not configured. Please set the SUPABASE_ANON_KEY environment variable.');
      }
    }
  }

  // Getters for configuration values

  /// OpenAI API key for AI integration.
  static String? get openaiApiKey => _openaiApiKey;

  /// Stripe publishable key for client-side payment processing.
  static String? get stripePublishableKey => _stripePublishableKey;

  /// Stripe secret key for server-side payment processing.
  static String? get stripeSecretKey => _stripeSecretKey;

  /// Supabase project URL.
  static String? get supabaseUrl => _supabaseUrl;

  /// Supabase anonymous key for client authentication.
  static String? get supabaseAnonKey => _supabaseAnonKey;

  /// OpenAI base URL for API requests.
  static String? get openaiBaseUrl => _openaiBaseUrl;

  /// Sentry DSN for error reporting.
  static String? get sentryDsn => _sentryDsn;

  /// Application log level.
  static String? get logLevel => _logLevel;

  /// Firebase API key for Firebase services.
  static String? get firebaseApiKey => _firebaseApiKey;

  /// Check if all required configurations are present.
  static bool get isValid =>
      _supabaseUrl != null && _supabaseUrl!.isNotEmpty &&
      _supabaseAnonKey != null && _supabaseAnonKey!.isNotEmpty;
}
