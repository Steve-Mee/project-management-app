import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/ai_rate_limits_config.dart';
import '../../services/app_logger.dart';
import '../i_settings_repository.dart';
import '../models/dashboard_models.dart';

/// Repository for app settings persisted with Hive.
/// Refactored per .github/issues/049-repository-refactoring.md
class HiveSettingsRepository implements ISettingsRepository {
  static const String _boxName = 'settings';
  static const String _themeModeKey = 'theme_mode';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _localeKey = 'locale';
  static const String lastBackupKey = 'last_backup_iso';
  static const String lastBackupPathKey = 'last_backup_path';
  static const String _autoLoginEnabledKey = 'auto_login_enabled';
  static const String _lastLoginTimeKey = 'last_login_time_iso';
  static const String _helpLevelKey = 'help_level';
  static const String _aiConsentEnabledKey = 'ai_consent_enabled';
  static const String _useBiometricsKey = 'use_biometrics_enabled';
  static const String _enableBiometricLoginKey = 'enable_biometric_login';
  static const String _aiRateLimitsKey = 'ai_rate_limits';
  static const String _recaptchaSiteKey = 'recaptcha_site_key';
  static const String _colorSchemeSeedKey = 'color_scheme_seed';
  static const String _dashboardItemsKey = 'dashboard_items';
  static const String _dashboardTemplatesKey = 'dashboard_templates';
  static const String _stripePublishableKey = 'stripe_publishable_key';
  static const String _stripeSecretKey = 'stripe_secret_key';
  static const String _subscriptionLevelKey = 'subscription_level';
  static const String _enableRealPaymentBackendKey = 'enable_real_payment_backend';

  @override
  Future<void> initialize() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  Box get _box => Hive.box(_boxName);

  @override
  ThemeMode? getThemeMode() {
    final value = _box.get(_themeModeKey) as String?;
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return null;
    }
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _box.put(_themeModeKey, value);
  }

  @override
  bool? getNotificationsEnabled() {
    final value = _box.get(_notificationsEnabledKey);
    if (value is bool) {
      return value;
    }
    return null;
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _box.put(_notificationsEnabledKey, enabled);
  }

  @override
  String? getLocaleCode() {
    final value = _box.get(_localeKey);
    return value is String ? value : null;
  }

  @override
  Future<void> setLocaleCode(String? localeCode) async {
    if (localeCode == null || localeCode.isEmpty) {
      await _box.delete(_localeKey);
      return;
    }
    await _box.put(_localeKey, localeCode);
  }

  @override
  DateTime? getLastBackupTime() {
    final value = _box.get(lastBackupKey);
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  @override
  Future<void> setLastBackupTime(DateTime timestamp) async {
    await _box.put(lastBackupKey, timestamp.toIso8601String());
  }

  @override
  String? getLastBackupPath() {
    final value = _box.get(lastBackupPathKey);
    return value is String && value.isNotEmpty ? value : null;
  }

  @override
  Future<void> setLastBackupPath(String path) async {
    await _box.put(lastBackupPathKey, path);
  }

  @override
  bool getAutoLoginEnabled() {
    return _box.get(_autoLoginEnabledKey, defaultValue: false);
  }

  @override
  Future<void> setAutoLoginEnabled(bool enabled) async {
    await _box.put(_autoLoginEnabledKey, enabled);
  }

  @override
  DateTime? getLastLoginTime() {
    final value = _box.get(_lastLoginTimeKey) as String?;
    if (value != null) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  @override
  Future<void> setLastLoginTime(DateTime time) async {
    await _box.put(_lastLoginTimeKey, time.toIso8601String());
  }

  @override
  String? getHelpLevel() {
    final value = _box.get(_helpLevelKey);
    return value is String ? value : null;
  }

  @override
  Future<void> setHelpLevel(String level) async {
    await _box.put(_helpLevelKey, level);
  }

  @override
  bool getAiConsentEnabled() {
    return _box.get(_aiConsentEnabledKey, defaultValue: false);
  }

  @override
  Future<void> setAiConsentEnabled(bool enabled) async {
    await _box.put(_aiConsentEnabledKey, enabled);
  }

  @override
  bool getUseBiometricsEnabled() {
    return _box.get(_useBiometricsKey, defaultValue: false);
  }

  @override
  Future<void> setUseBiometricsEnabled(bool enabled) async {
    await _box.put(_useBiometricsKey, enabled);
  }

  @override
  bool getEnableBiometricLogin() {
    return _box.get(_enableBiometricLoginKey, defaultValue: false);
  }

  @override
  Future<void> setEnableBiometricLogin(bool enabled) async {
    await _box.put(_enableBiometricLoginKey, enabled);
  }

  @override
  AiRateLimitsConfig getAiRateLimitsConfig() {
    final value = _box.get(_aiRateLimitsKey);
    if (value is Map<String, dynamic>) {
      try {
        final config = AiRateLimitsConfig.fromJson(value);
        
        // Additional validation for perOperationLimits map
        if (value['perOperationLimits'] != null && value['perOperationLimits'] is! Map<String, dynamic>) {
          AppLogger.warning('Invalid perOperationLimits format in settings, expected Map<String, dynamic>', 
            params: {'type': value['perOperationLimits'].runtimeType.toString()});
        }
        
        // Validate and clamp values using the centralized validation helper
        final validatedConfig = AiRateLimitsConfig.validateAiRateLimits(config);
        if (validatedConfig != config) {
          AppLogger.event('AI rate limits config contained invalid values, clamping to valid ranges');
        }
        return validatedConfig;
      } catch (e) {
        AppLogger.event('Invalid AI rate limits config in settings, using defaults', params: {'error': e.toString()});
        return const AiRateLimitsConfig();
      }
    }
    // Migration: return defaults for existing users (includes perOperationLimits defaults)
    return const AiRateLimitsConfig();
  }

  @override
  Future<void> setAiRateLimitsConfig(AiRateLimitsConfig config) async {
    // Additional validation for perOperationLimits map
    for (final entry in config.perOperationLimits.entries) {
      if (entry.value < 1) {
        AppLogger.warning('Invalid perOperationLimit value for operation ${entry.key}, must be >= 1', 
          params: {'operation': entry.key, 'value': entry.value.toString()});
      }
    }
    
    final validatedConfig = AiRateLimitsConfig.validateAiRateLimits(config);
    if (validatedConfig != config) {
      AppLogger.event('AI rate limits config contained invalid values when saving, clamping to valid ranges');
    }
    await _box.put(_aiRateLimitsKey, validatedConfig.toJson());
  }

  @override
  String getRecaptchaSiteKey() {
    final key = _box.get(_recaptchaSiteKey, defaultValue: '');
    AppLogger.debug('reCAPTCHA site key loaded', params: {'configured': key.isNotEmpty});
    return key;
  }

  @override
  Future<void> setRecaptchaSiteKey(String key) async {
    await _box.put(_recaptchaSiteKey, key);
  }

  @override
  int? getColorSchemeSeed() {
    final value = _box.get(_colorSchemeSeedKey);
    if (value is int) {
      return value;
    }
    return null;
  }

  @override
  Future<void> setColorSchemeSeed(int? seed) async {
    if (seed == null) {
      await _box.delete(_colorSchemeSeedKey);
      return;
    }
    await _box.put(_colorSchemeSeedKey, seed);
  }

  @override
  List<DashboardItem>? getDashboardItems() {
    final value = _box.get(_dashboardItemsKey);
    if (value is List) {
      try {
        return value.map((item) {
          if (item is Map<String, dynamic>) {
            return DashboardItem.fromJson(item);
          }
          return null;
        }).whereType<DashboardItem>().toList();
      } catch (e) {
        AppLogger.instance.w('Failed to parse dashboard items from settings', error: e);
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> setDashboardItems(List<DashboardItem> items) async {
    final jsonItems = items.map((item) => item.toJson()).toList();
    await _box.put(_dashboardItemsKey, jsonItems);
  }

  @override
  List<DashboardTemplate>? getDashboardTemplates() {
    final value = _box.get(_dashboardTemplatesKey);
    if (value is List) {
      try {
        return value.map((template) {
          if (template is Map<String, dynamic>) {
            return DashboardTemplate.fromJson(template);
          }
          return null;
        }).whereType<DashboardTemplate>().toList();
      } catch (e) {
        AppLogger.instance.w('Failed to parse dashboard templates from settings', error: e);
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> setDashboardTemplates(List<DashboardTemplate> templates) async {
    final jsonTemplates = templates.map((template) => template.toJson()).toList();
    await _box.put(_dashboardTemplatesKey, jsonTemplates);
  }

  @override
  String? getStripePublishableKey() {
    final value = _box.get(_stripePublishableKey);
    return value is String ? value : null;
  }

  @override
  Future<void> setStripePublishableKey(String? key) async {
    if (key == null || key.isEmpty) {
      await _box.delete(_stripePublishableKey);
      return;
    }
    await _box.put(_stripePublishableKey, key);
  }

  @override
  String? getStripeSecretKey() {
    final value = _box.get(_stripeSecretKey);
    return value is String ? value : null;
  }

  @override
  Future<void> setStripeSecretKey(String? key) async {
    if (key == null || key.isEmpty) {
      await _box.delete(_stripeSecretKey);
      return;
    }
    await _box.put(_stripeSecretKey, key);
  }

  @override
  String? getSubscriptionLevel() {
    final value = _box.get(_subscriptionLevelKey);
    return value is String ? value : 'free';
  }

  @override
  Future<void> setSubscriptionLevel(String level) async {
    await _box.put(_subscriptionLevelKey, level);
  }

  @override
  bool getEnableRealPaymentBackend() {
    final value = _box.get(_enableRealPaymentBackendKey, defaultValue: false);
    AppLogger.debug('payment_backend_flag_loaded', params: {'enabled': value});
    return value;
  }

  @override
  Future<void> setEnableRealPaymentBackend(bool enabled) async {
    await _box.put(_enableRealPaymentBackendKey, enabled);
  }
}
