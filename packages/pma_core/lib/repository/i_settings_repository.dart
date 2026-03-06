import 'package:flutter/material.dart';
import 'package:pma_core/models/ai_rate_limits_config.dart';
import 'package:pma_core/repository/models/dashboard_models.dart';

/// Interface for settings repository operations
abstract class ISettingsRepository {
  Future<void> initialize();

  ThemeMode? getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);

  bool? getNotificationsEnabled();
  Future<void> setNotificationsEnabled(bool enabled);

  String? getLocaleCode();
  Future<void> setLocaleCode(String? localeCode);

  DateTime? getLastBackupTime();
  Future<void> setLastBackupTime(DateTime timestamp);

  String? getLastBackupPath();
  Future<void> setLastBackupPath(String path);

  bool getAutoLoginEnabled();
  Future<void> setAutoLoginEnabled(bool enabled);

  DateTime? getLastLoginTime();
  Future<void> setLastLoginTime(DateTime time);

  String? getHelpLevel();
  Future<void> setHelpLevel(String level);

  bool getAiConsentEnabled();
  Future<void> setAiConsentEnabled(bool enabled);

  bool getUseBiometricsEnabled();
  Future<void> setUseBiometricsEnabled(bool enabled);

  bool getEnableBiometricLogin();
  Future<void> setEnableBiometricLogin(bool enabled);

  AiRateLimitsConfig getAiRateLimitsConfig();
  Future<void> setAiRateLimitsConfig(AiRateLimitsConfig config);

  String getRecaptchaSiteKey();
  Future<void> setRecaptchaSiteKey(String key);

  int? getColorSchemeSeed();
  Future<void> setColorSchemeSeed(int? seed);

  List<DashboardItem>? getDashboardItems();
  Future<void> setDashboardItems(List<DashboardItem> items);

  List<DashboardTemplate>? getDashboardTemplates();
  Future<void> setDashboardTemplates(List<DashboardTemplate> templates);

  String? getStripePublishableKey();
  Future<void> setStripePublishableKey(String? key);

  String? getStripeSecretKey();
  Future<void> setStripeSecretKey(String? key);

  String? getSubscriptionLevel();
  Future<void> setSubscriptionLevel(String level);

  bool getEnableRealPaymentBackend();
  Future<void> setEnableRealPaymentBackend(bool enabled);

  bool? getEnableOpenAILangchain();
  Future<void> setEnableOpenAILangchain(bool enabled);
}
