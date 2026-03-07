/// Shared parsing helpers for feature flag records.
///
/// Supports these payload shapes:
/// - bool value directly
/// - row map containing `enabled`
/// - row map containing `value` (bool or nested map with `enabled`)
class FeatureFlagResolver {
  const FeatureFlagResolver._();

  static dynamic getRawValue(Map<String, dynamic> flags, String key) {
    return flags[key];
  }

  static bool isEnabled(
    Map<String, dynamic> flags,
    String key, {
    bool defaultValue = false,
  }) {
    return resolveEnabled(flags[key], defaultValue: defaultValue);
  }

  static bool resolveEnabled(dynamic raw, {bool defaultValue = false}) {
    if (raw is bool) {
      return raw;
    }

    if (raw is Map) {
      final enabled = raw['enabled'];
      if (enabled is bool) {
        return enabled;
      }

      final value = raw['value'];
      if (value is bool) {
        return value;
      }
      if (value is Map) {
        final nestedEnabled = value['enabled'];
        if (nestedEnabled is bool) {
          return nestedEnabled;
        }
      }
    }

    return defaultValue;
  }
}
