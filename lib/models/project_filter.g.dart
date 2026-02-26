// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectFilter _$ProjectFilterFromJson(Map<String, dynamic> json) =>
    _ProjectFilter(
      status: json['status'] as String?,
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      priority: json['priority'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      searchQuery: json['searchQuery'] as String?,
    );

Map<String, dynamic> _$ProjectFilterToJson(_ProjectFilter instance) =>
    <String, dynamic>{
      'status': instance.status,
      'startDate': instance.startDate?.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'priority': instance.priority,
      'tags': instance.tags,
      'searchQuery': instance.searchQuery,
    };
