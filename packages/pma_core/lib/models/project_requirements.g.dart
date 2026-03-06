// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_requirements.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectRequirements _$ProjectRequirementsFromJson(Map<String, dynamic> json) =>
    _ProjectRequirements(
      software: (json['software'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      hardware: (json['hardware'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$ProjectRequirementsToJson(
        _ProjectRequirements instance) =>
    <String, dynamic>{
      'software': instance.software,
      'hardware': instance.hardware,
    };
