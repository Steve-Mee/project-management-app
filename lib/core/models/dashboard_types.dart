import 'package:my_project_management_app/core/repository/i_dashboard_repository.dart';

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
    return DashboardWidgetType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Invalid widget type: $value'),
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

class SharedDashboard {
  final String id;
  final String ownerId;
  final String title;
  final List<DashboardItem> items;
  final Map<String, String> permissions;
  final DateTime updatedAt;

  const SharedDashboard({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.items,
    required this.permissions,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerId': ownerId,
        'title': title,
        'items': items.map((item) => item.toJson()).toList(),
        'permissions': permissions,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory SharedDashboard.fromJson(Map<String, dynamic> json) => SharedDashboard(
        id: json['id'] as String,
        ownerId: json['ownerId'] as String,
        title: json['title'] as String,
        items: (json['items'] as List<dynamic>)
            .map((item) => DashboardItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        permissions: Map<String, String>.from(json['permissions'] as Map),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}