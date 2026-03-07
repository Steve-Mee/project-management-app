import 'package:pma_core/core/feature_flags/feature_flag_resolver.dart';

/// Typed representation of a feature flag row from Supabase.
class FeatureFlag {
  const FeatureFlag({
    required this.key,
    required this.enabled,
    this.id,
    this.value,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  final String key;
  final bool enabled;
  final String? id;
  final Object? value;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static FeatureFlag? tryParse(Map<dynamic, dynamic> raw) {
    final dynamicKey = raw['key'];
    if (dynamicKey is! String || dynamicKey.isEmpty) {
      return null;
    }

    return FeatureFlag(
      key: dynamicKey,
      enabled: FeatureFlagResolver.resolveEnabled(raw),
      id: raw['id'] as String?,
      value: raw['value'],
      description: raw['description'] as String?,
      createdAt: _tryParseDateTime(raw['created_at']),
      updatedAt: _tryParseDateTime(raw['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'key': key,
      'enabled': enabled,
      'value': value,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  static DateTime? _tryParseDateTime(Object? raw) {
    if (raw is DateTime) {
      return raw;
    }
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }
}
