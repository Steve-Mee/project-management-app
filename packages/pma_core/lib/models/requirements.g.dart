// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'requirements.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Requirement _$RequirementFromJson(Map<String, dynamic> json) => _Requirement(
      id: json['id'] as String,
      title: json['title'] as String,
      status: json['status'] == null
          ? RequirementStatus.pending
          : _requirementStatusFromJson(json['status'] as String?),
      priority: json['priority'] == null
          ? RequirementPriority.medium
          : _requirementPriorityFromJson(json['priority'] as String?),
    );

Map<String, dynamic> _$RequirementToJson(_Requirement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'status': _requirementStatusToJson(instance.status),
      'priority': _requirementPriorityToJson(instance.priority),
    };
