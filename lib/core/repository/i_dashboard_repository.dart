/// Abstract interface for dashboard repository
/// Allows easy swapping of implementations (Hive, Supabase, mock for tests, etc.)
library;
import 'package:my_project_management_app/models/project_requirements.dart';
import 'package:my_project_management_app/core/models/dashboard_types.dart';

/// Dashboard item configuration for project management dashboard widgets.
/// 
/// Supported widget types: metricCard, taskList, progressChart, kanbanBoard, calendar, notificationFeed, projectOverview, timeline.
/// 
/// Validation is performed in fromJson() to ensure only supported types are loaded.
/// See .github/issues/020-dashboard-validate-widget-type.md for validation details.
class DashboardItem {
  final DashboardWidgetType widgetType;
  final Map<String, dynamic> position;

  const DashboardItem({
    required this.widgetType,
    required this.position,
  });

  Map<String, dynamic> toJson() => {
        'widgetType': widgetType.name,
        'position': position,
      };

  factory DashboardItem.fromJson(Map<String, dynamic> json) {
    final widgetTypeStr = json['widgetType'] as String;
    try {
      final widgetType = DashboardWidgetType.fromString(widgetTypeStr);
      return DashboardItem(
        widgetType: widgetType,
        position: json['position'],
      );
    } catch (e) {
      throw InvalidWidgetTypeException(
        'Invalid widget type \'$widgetTypeStr\'. Valid types are: ${DashboardWidgetType.values.map((e) => e.name).join(', ')}',
      );
    }
  }
}

/// Define abstract class `IDashboardRepository`.
/// Keep method signatures narrow and backend-agnostic to allow swapping.
abstract class IDashboardRepository {
  /// Dashboard configuration management
  Future<List<DashboardItem>> loadDashboardConfig();
  Future<void> saveDashboardConfig(List<DashboardItem> items);
  Future<void> addDashboardItem(DashboardItem item);
  Future<void> removeDashboardItem(int index);
  Future<void> updateDashboardItemPosition(int index, Map<String, dynamic> newPosition);

  /// Requirements management
  Future<ProjectRequirements> fetchRequirements(String projectCategory);
  ProjectRequirements parseRequirementsString(String requirementsString);

  /// Close repository resources (e.g., Hive boxes)
  Future<void> close();

  /// Sync methods for future Supabase integration
  /// TODO: Implement sync methods when Supabase sync is added
  // Future<void> syncDashboardConfigToSupabase();
  // Future<void> syncDashboardConfigFromSupabase();
  // Future<void> resolveSyncConflicts(List<SyncConflict> conflicts);
}