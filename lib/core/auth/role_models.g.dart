// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RoleDefinition _$RoleDefinitionFromJson(Map<String, dynamic> json) =>
    _RoleDefinition(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$RoleDefinitionToJson(_RoleDefinition instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'permissions': instance.permissions,
    };

_GroupDefinition _$GroupDefinitionFromJson(Map<String, dynamic> json) =>
    _GroupDefinition(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      roleId: json['roleId'] as String? ?? '',
      members: (json['members'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$GroupDefinitionToJson(_GroupDefinition instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'roleId': instance.roleId,
      'members': instance.members,
    };
