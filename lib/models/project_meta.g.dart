// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_meta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectMeta _$ProjectMetaFromJson(Map<String, dynamic> json) => _ProjectMeta(
      projectId: json['projectId'] as String,
      urgency: $enumDecode(_$UrgencyLevelEnumMap, json['urgency']),
      trackedSeconds: (json['trackedSeconds'] as num).toInt(),
    );

Map<String, dynamic> _$ProjectMetaToJson(_ProjectMeta instance) =>
    <String, dynamic>{
      'projectId': instance.projectId,
      'urgency': _$UrgencyLevelEnumMap[instance.urgency]!,
      'trackedSeconds': instance.trackedSeconds,
    };

const _$UrgencyLevelEnumMap = {
  UrgencyLevel.low: 'low',
  UrgencyLevel.medium: 'medium',
  UrgencyLevel.high: 'high',
};
