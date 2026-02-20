/// Core providers for the application
/// This file has been modularized into separate files for better maintainability
/// Import specific provider files as needed
library;

export 'providers/auth_providers.dart';
export 'providers/project_providers.dart';
export 'providers/theme_providers.dart';
export 'providers/dashboard_providers.dart';

// Keep AI-related exports in a dedicated barrel so they share a single canonical path
export 'providers/ai/index.dart';
export 'providers/task_provider.dart';

// TODO: Consider creating additional provider files for:
// - task_providers.dart
// - notification_providers.dart
// - sync_providers.dart
// - analytics_providers.dart
