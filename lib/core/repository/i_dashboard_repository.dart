/// Abstract interface for dashboard repository
/// Allows easy swapping of implementations (Hive, Supabase, mock for tests, etc.)
library;
import 'package:project_management_app/models/project_requirements.dart';
import 'package:project_management_app/core/models/dashboard_types.dart';
import 'package:project_management_app/core/models/requirements.dart';
import 'models/dashboard_models.dart';

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
