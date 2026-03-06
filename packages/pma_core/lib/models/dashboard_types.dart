// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pma_core/repository/models/dashboard_models.dart';

part 'dashboard_types.freezed.dart';
part 'dashboard_types.g.dart';

enum DashboardWidgetType {
  metricCard,
  taskList,
  progressChart,
  kanbanBoard,
  calendar,
  notificationFeed,
  projectOverview,
  timeline;

  String get name => toString().split('.').last;

  static DashboardWidgetType fromString(String value) {
    final normalized = value.contains('.') ? value.split('.').last : value;
    return DashboardWidgetType.values.firstWhere(
      (e) => e.name == normalized,
      orElse: () => DashboardWidgetType.metricCard,
    );
  }
}

/// Dashboard position constraints constants
const double kDashboardMinX = 0;
const double kDashboardMinY = 0;
const double kDashboardMinWidth = 180;
const double kDashboardMinHeight = 120;
const double kDashboardContainerWidth = 1200;
const double kDashboardContainerHeight = 800;

class InvalidWidgetTypeException implements Exception {
  final String message;
  InvalidWidgetTypeException(this.message);

  @override
  String toString() => 'InvalidWidgetTypeException: $message';
}

enum DashboardPermission { view, edit }

@freezed
abstract class SharedDashboard with _$SharedDashboard {
  @JsonSerializable(explicitToJson: true)
  const factory SharedDashboard({
    required String id,
    required String ownerId,
    required String title,
    required List<DashboardItem> items,
    @JsonKey(fromJson: _sharedDashboardPermissionsFromJson, toJson: _sharedDashboardPermissionsToJson)
    required Map<String, String> permissions,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _SharedDashboard;

  factory SharedDashboard.fromJson(Map<String, dynamic> json) =>
      _$SharedDashboardFromJson(json);
}

Map<String, String> _sharedDashboardPermissionsFromJson(Object? value) {
  if (value is Map) {
    return Map<String, String>.from(value);
  }
  return const <String, String>{};
}

Map<String, String> _sharedDashboardPermissionsToJson(
  Map<String, String> value,
) =>
    value;
