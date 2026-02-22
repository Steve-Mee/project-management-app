/// Abstract interface for dashboard repository
/// Allows easy swapping of implementations (Hive, Supabase, mock for tests, etc.)
library;
import 'package:my_project_management_app/models/project_requirements.dart';
import 'package:my_project_management_app/core/models/dashboard_types.dart';
import 'package:my_project_management_app/core/models/requirements.dart';

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
        position: _clampPosition(json['position'] as Map<String, dynamic>),
      );
    } catch (e) {
      throw InvalidWidgetTypeException(
        'Invalid widget type \'$widgetTypeStr\'. Valid types are: ${DashboardWidgetType.values.map((e) => e.name).join(', ')}',
      );
    }
  }

  static Map<String, dynamic> _clampPosition(Map<String, dynamic> position) {
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
}

/// Immutable model for dashboard templates with preset layouts.
/// 
/// Supports both built-in presets and user-created templates.
/// Templates contain a list of DashboardItems with their positions and types.
class DashboardTemplate {
  final String id;
  final String name;
  final List<DashboardItem> items;
  final bool isPreset;
  final DateTime createdAt;

  const DashboardTemplate({
    required this.id,
    required this.name,
    required this.items,
    required this.isPreset,
    required this.createdAt,
  });

  DashboardTemplate copyWith({
    String? id,
    String? name,
    List<DashboardItem>? items,
    bool? isPreset,
    DateTime? createdAt,
  }) {
    return DashboardTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
      isPreset: isPreset ?? this.isPreset,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items.map((item) => item.toJson()).toList(),
        'isPreset': isPreset,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DashboardTemplate.fromJson(Map<String, dynamic> json) {
    return DashboardTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => DashboardItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      isPreset: json['isPreset'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Define abstract class `IDashboardRepository`.
/// Keep method signatures narrow and backend-agnostic to allow swapping.
abstract class IDashboardRepository {
  /// Loads the dashboard configuration from storage.
  Future<List<DashboardItem>> loadConfig();

  /// Saves the dashboard configuration to storage.
  Future<void> saveConfig(List<DashboardItem> items);

  /// Adds a new dashboard item to the configuration.
  Future<void> addItem(DashboardItem item);

  /// Removes a dashboard item by index from the configuration.
  Future<void> removeItem(int index);

  /// Updates the position of a dashboard item by index.
  Future<void> updateItemPosition(int index, Map<String, dynamic> position);

  /// Loads user-created dashboard templates from storage.
  Future<List<DashboardTemplate>> loadTemplates();

  /// Saves user-created dashboard templates to storage.
  Future<void> saveTemplates(List<DashboardTemplate> templates);

  /// Fetches a shared dashboard from remote storage by share ID.
  Future<SharedDashboard?> fetchSharedDashboard(String shareId);

  /// Saves a shared dashboard to remote storage.
  Future<void> saveSharedDashboard(SharedDashboard dashboard);

  /// Updates permissions for a shared dashboard.
  Future<void> updateSharedPermissions(String shareId, Map<String, String> permissions);

  /// Loads a shared dashboard from local storage by share ID.
  Future<SharedDashboard?> loadLocalSharedDashboard(String shareId);

  /// Saves a shared dashboard to local storage.
  Future<void> saveLocalSharedDashboard(SharedDashboard dashboard);

  /// Fetches project requirements for a given category.
  Future<ProjectRequirements> fetchRequirements(String projectCategory);

  /// Parses a requirements string into a ProjectRequirements object.
  ProjectRequirements parseRequirementsString(String requirementsString);

  /// Loads requirements from storage.
  Future<List<Requirement>> loadRequirements();

  /// Saves a requirement to storage.
  Future<void> saveRequirement(Requirement req);

  /// Queues a pending change for sync.
  Future<void> queuePendingChange(Map<String, dynamic> change);

  /// Processes pending sync when online.
  Future<void> processPendingSync();

  /// Preloads cache for performance optimization (optional implementation).
  Future<void> preloadCache();

  /// Clears the in-memory cache (optional implementation).
  Future<void> clearCache();

  /// Closes repository resources (e.g., Hive boxes).
  Future<void> close();
}