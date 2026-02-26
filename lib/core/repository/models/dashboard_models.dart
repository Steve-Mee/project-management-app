// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:project_management_app/core/models/dashboard_types.dart';

part 'dashboard_models.freezed.dart';
part 'dashboard_models.g.dart';

/// Dashboard item configuration for project management dashboard widgets.
///
/// Supported widget types: metricCard, taskList, progressChart, kanbanBoard, calendar, notificationFeed, projectOverview, timeline.
///
/// Validation is performed in fromJson() to ensure only supported types are loaded.
/// See .github/issues/020-dashboard-validate-widget-type.md for validation details.
@freezed
abstract class DashboardItem with _$DashboardItem {
  const factory DashboardItem({
    @JsonKey(fromJson: _dashboardWidgetTypeFromJson, toJson: _dashboardWidgetTypeToJson)
    required DashboardWidgetType widgetType,
    @JsonKey(fromJson: _dashboardPositionFromJson, toJson: _dashboardPositionToJson)
    required Map<String, dynamic> position,
  }) = _DashboardItem;

  factory DashboardItem.fromJson(Map<String, dynamic> json) =>
      _$DashboardItemFromJson(json);
}

/// Immutable model for dashboard templates with preset layouts.
///
/// Supports both built-in presets and user-created templates.
/// Templates contain a list of DashboardItems with their positions and types.
@freezed
abstract class DashboardTemplate with _$DashboardTemplate {
  @JsonSerializable(explicitToJson: true)
  const factory DashboardTemplate({
    required String id,
    required String name,
    required List<DashboardItem> items,
    required bool isPreset,
    required DateTime createdAt,
  }) = _DashboardTemplate;

  factory DashboardTemplate.fromJson(Map<String, dynamic> json) =>
      _$DashboardTemplateFromJson(json);
}

DashboardWidgetType _dashboardWidgetTypeFromJson(Object? value) {
  final widgetTypeStr = value as String?;
  if (widgetTypeStr == null) {
    throw InvalidWidgetTypeException(
      'Invalid widget type \'null\'. Valid types are: ${DashboardWidgetType.values.map((e) => e.name).join(', ')}',
    );
  }

  try {
    return DashboardWidgetType.fromString(widgetTypeStr);
  } catch (_) {
    throw InvalidWidgetTypeException(
      'Invalid widget type \'$widgetTypeStr\'. Valid types are: ${DashboardWidgetType.values.map((e) => e.name).join(', ')}',
    );
  }
}

String _dashboardWidgetTypeToJson(DashboardWidgetType value) => value.name;

Map<String, dynamic> _dashboardPositionFromJson(Object? value) {
  final position = value as Map<String, dynamic>?;
  return _clampDashboardPosition(position ?? const <String, dynamic>{});
}

Map<String, dynamic> _dashboardPositionToJson(Map<String, dynamic> value) =>
    value;

Map<String, dynamic> _clampDashboardPosition(Map<String, dynamic> position) {
  double x = (position['x'] as num?)?.toDouble() ?? 0.0;
  double y = (position['y'] as num?)?.toDouble() ?? 0.0;
  double width = (position['width'] as num?)?.toDouble() ?? kDashboardMinWidth;
  double height = (position['height'] as num?)?.toDouble() ?? kDashboardMinHeight;

  if (x < 0) x = 0;
  if (y < 0) y = 0;
  if (width < kDashboardMinWidth) width = kDashboardMinWidth;
  if (height < kDashboardMinHeight) height = kDashboardMinHeight;
  if (x + width > kDashboardContainerWidth) x = kDashboardContainerWidth - width;
  if (y + height > kDashboardContainerHeight) y = kDashboardContainerHeight - height;

  return {'x': x, 'y': y, 'width': width, 'height': height};
}
