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