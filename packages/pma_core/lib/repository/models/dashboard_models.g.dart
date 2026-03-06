// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DashboardItem _$DashboardItemFromJson(Map<String, dynamic> json) =>
    _DashboardItem(
      widgetType: _dashboardWidgetTypeFromJson(json['widgetType']),
      position: _dashboardPositionFromJson(json['position']),
    );

Map<String, dynamic> _$DashboardItemToJson(_DashboardItem instance) =>
    <String, dynamic>{
      'widgetType': _dashboardWidgetTypeToJson(instance.widgetType),
      'position': _dashboardPositionToJson(instance.position),
    };

_DashboardTemplate _$DashboardTemplateFromJson(Map<String, dynamic> json) =>
    _DashboardTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => DashboardItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      isPreset: json['isPreset'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$DashboardTemplateToJson(_DashboardTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'isPreset': instance.isPreset,
      'createdAt': instance.createdAt.toIso8601String(),
    };
