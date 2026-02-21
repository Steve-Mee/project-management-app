/// Abstract interface for dashboard repository
/// Allows easy swapping of implementations (Hive, Supabase, mock for tests, etc.)
library;
import 'package:my_project_management_app/models/project_requirements.dart';

/// Dashboard item configuration
class DashboardItem {
  final String widgetType;
  final Map<String, dynamic> position;

  const DashboardItem({
    required this.widgetType,
    required this.position,
  });

  Map<String, dynamic> toJson() => {
        'widgetType': widgetType,
        'position': position,
      };

  factory DashboardItem.fromJson(Map<String, dynamic> json) => DashboardItem(
        widgetType: json['widgetType'],
        position: json['position'],
      );
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
}