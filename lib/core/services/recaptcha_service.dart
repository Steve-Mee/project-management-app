import 'package:flutter_gcaptcha_v3/recaptca_config.dart';
import 'package:my_project_management_app/core/services/app_logger.dart';
import 'package:my_project_management_app/core/repository/settings_repository.dart';
import 'package:my_project_management_app/core/services/recaptcha_config.dart';

/// Service for handling reCAPTCHA verification
class RecaptchaService {
  final SettingsRepository _settings;

  RecaptchaService(this._settings);

  /// Get reCAPTCHA token for the specified action
  /// Returns null if reCAPTCHA is not configured (e.g., in dev)
  Future<String?> getRecaptchaToken() async {
    // Skip reCAPTCHA if not in production (dev environment)
    if (!RecaptchaConfig.isProduction) {
      return null;
    }

    final siteKey = _settings.getRecaptchaSiteKey();

    AppLogger.event('recaptcha_token_requested');

    try {
      // Setup the site key
      RecaptchaHandler.instance.setupSiteKey(dataSiteKey: siteKey);

      // Execute reCAPTCHA v3
      await RecaptchaHandler.executeV3(action: 'login');

      final token = RecaptchaHandler.instance.captchaToken;
      AppLogger.event('recaptcha_token_received');
      return token;
    } catch (e) {
      AppLogger.event('recaptcha_token_error', params: {'error': e.toString()});
      return null;
    }
  }
}