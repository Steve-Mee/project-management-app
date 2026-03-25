/// Canonical analytics event names.
///
/// Keep these constants as single source of truth to avoid typos and drift
/// across services, providers, and dashboards.
abstract final class AnalyticsEventName {
  static const String projectCreated = 'project_created';
  static const String taskCompleted = 'task_completed';
  static const String aiUsed = 'ai_used';
  static const String inviteSent = 'invite_sent';

  static const String featureFlagChanged = 'feature_flag_changed';
  static const String mirrorLaunchResolved = 'mirror_launch_resolved';

  static const String projectUpdated = 'project_updated';
  static const String projectDeleted = 'project_deleted';
  static const String projectBulkDeleted = 'project_bulk_deleted';
  static const String syncAll = 'sync_all';
  static const String authSignIn = 'auth_sign_in';
  static const String authSignOut = 'auth_sign_out';
}
