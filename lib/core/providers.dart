/// Core providers barrel file - exports all Riverpod providers for the app.
///
/// This file provides a centralized export point for all provider definitions,
/// organized into logical modules for better maintainability and separation of concerns:
///
/// - project_providers.dart: Project management, CRUD operations, and project state
/// - task_providers.dart: Task and sub-task state management, repositories
/// - notification_providers.dart: Notification services, toggles, and scheduling
/// - sync_providers.dart: Offline sync, data synchronization, and connectivity
/// - analytics_providers.dart: Usage tracking, AI analytics, and performance metrics
/// - active_viewers_provider.dart: Real-time active user tracking
/// - connectivity_provider.dart: Network connectivity monitoring
///
/// Do NOT add new provider definitions in this file.
/// Instead, create new provider files in this directory and add exports here.
/// See .github/issues/038-split-provider-files.md for organization guidelines.
library;

export 'providers/project_providers.dart';
export 'providers/task_providers.dart';
export 'providers/notification_providers.dart';
export 'providers/sync_providers.dart';
export 'providers/analytics_providers.dart';
export 'providers/active_viewers_provider.dart';
export 'providers/connectivity_provider.dart';
