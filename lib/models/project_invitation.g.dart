// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_invitation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectInvitation _$ProjectInvitationFromJson(Map<String, dynamic> json) =>
    _ProjectInvitation(
      id: json['id'] as String,
      email: json['email'] as String,
      projectId: json['project_id'] as String,
      role: json['role'] as String,
      invitedBy: json['invited_by'] as String,
      status: json['status'] as String,
      token: json['token'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ProjectInvitationToJson(_ProjectInvitation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'project_id': instance.projectId,
      'role': instance.role,
      'invited_by': instance.invitedBy,
      'status': instance.status,
      'token': instance.token,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
