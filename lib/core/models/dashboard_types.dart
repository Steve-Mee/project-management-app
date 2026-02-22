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

class InvalidWidgetTypeException implements Exception {
  final String message;
  InvalidWidgetTypeException(this.message);

  @override
  String toString() => 'InvalidWidgetTypeException: $message';
}