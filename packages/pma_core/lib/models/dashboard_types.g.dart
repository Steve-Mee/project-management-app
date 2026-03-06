// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_types.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SharedDashboard _$SharedDashboardFromJson(Map<String, dynamic> json) =>
    _SharedDashboard(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      title: json['title'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => DashboardItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      permissions: _sharedDashboardPermissionsFromJson(json['permissions']),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$SharedDashboardToJson(_SharedDashboard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ownerId': instance.ownerId,
      'title': instance.title,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'permissions': _sharedDashboardPermissionsToJson(instance.permissions),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
