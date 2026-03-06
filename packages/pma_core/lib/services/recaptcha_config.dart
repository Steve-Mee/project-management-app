import 'package:flutter_gcaptcha_v3/recaptca_config.dart';
import 'package:pma_core/repository/i_settings_repository.dart';

/// reCAPTCHA configuration for issue 040-authentication-security-enhancements
/// Centralizes reCAPTCHA site key management and initialization
class RecaptchaConfig {
  static ISettingsRepository? _settings;

  /// Initialize with settings repository (call during app startup)
  static void initializeWithRepository(ISettingsRepository settings) {
    _settings = settings;
  }

  /// Get the reCAPTCHA site key from settings or fallback to empty string
  static String get siteKey => _settings?.getRecaptchaSiteKey() ?? '';

  /// Check if running in production mode (site key configured)
  static bool get isProduction => siteKey.isNotEmpty;

  /// Initialize reCAPTCHA handler if in production mode
  static void initialize() {
    if (isProduction) {
      RecaptchaHandler.instance.setupSiteKey(dataSiteKey: siteKey);
    }
  }
}
