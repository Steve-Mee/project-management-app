// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppUser _$AppUserFromJson(Map<String, dynamic> json) => _AppUser(
      username: json['username'] as String,
      password: json['password'] as String,
      roleId: json['roleId'] as String? ?? 'role_member',
    );

Map<String, dynamic> _$AppUserToJson(_AppUser instance) => <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
      'roleId': instance.roleId,
    };
