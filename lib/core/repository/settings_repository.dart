import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Repository for app settings persisted with Hive.
class SettingsRepository {
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

  Future<void> initialize() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  Box get _box => Hive.box(_boxName);

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

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _box.put(_themeModeKey, value);
  }

  bool? getNotificationsEnabled() {
    final value = _box.get(_notificationsEnabledKey);
    if (value is bool) {
      return value;
    }
    return null;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _box.put(_notificationsEnabledKey, enabled);
  }

  String? getLocaleCode() {
    final value = _box.get(_localeKey);
    return value is String ? value : null;
  }

  Future<void> setLocaleCode(String? localeCode) async {
    if (localeCode == null || localeCode.isEmpty) {
      await _box.delete(_localeKey);
      return;
    }
    await _box.put(_localeKey, localeCode);
  }

  DateTime? getLastBackupTime() {
    final value = _box.get(lastBackupKey);
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Future<void> setLastBackupTime(DateTime timestamp) async {
    await _box.put(lastBackupKey, timestamp.toIso8601String());
  }

  String? getLastBackupPath() {
    final value = _box.get(lastBackupPathKey);
    return value is String && value.isNotEmpty ? value : null;
  }

  Future<void> setLastBackupPath(String path) async {
    await _box.put(lastBackupPathKey, path);
  }

  bool getAutoLoginEnabled() {
    return _box.get(_autoLoginEnabledKey, defaultValue: false);
  }

  Future<void> setAutoLoginEnabled(bool enabled) async {
    await _box.put(_autoLoginEnabledKey, enabled);
  }

  DateTime? getLastLoginTime() {
    final value = _box.get(_lastLoginTimeKey) as String?;
    if (value != null) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Future<void> setLastLoginTime(DateTime time) async {
    await _box.put(_lastLoginTimeKey, time.toIso8601String());
  }

  String? getHelpLevel() {
    final value = _box.get(_helpLevelKey);
    return value is String ? value : null;
  }

  Future<void> setHelpLevel(String level) async {
    await _box.put(_helpLevelKey, level);
  }

  bool getAiConsentEnabled() {
    return _box.get(_aiConsentEnabledKey, defaultValue: false);
  }

  Future<void> setAiConsentEnabled(bool enabled) async {
    await _box.put(_aiConsentEnabledKey, enabled);
  }

  bool getUseBiometricsEnabled() {
    return _box.get(_useBiometricsKey, defaultValue: false);
  }

  Future<void> setUseBiometricsEnabled(bool enabled) async {
    await _box.put(_useBiometricsKey, enabled);
  }
}
