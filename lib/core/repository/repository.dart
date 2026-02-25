// Repository layer exports
// Clean architecture: interfaces, implementations, and models

// Interfaces
export 'i_ai_usage_repository.dart';
export 'i_auth_repository.dart';
export 'i_dashboard_repository.dart';
export 'i_project_repository.dart';
export 'i_settings_repository.dart';

// Implementations
export 'impl/hive_ai_usage_repository.dart';
export 'impl/hive_auth_repository.dart';
export 'impl/hive_dashboard_repository.dart';
export 'impl/hive_project_repository.dart';
export 'impl/hive_settings_repository.dart';
export 'impl/hive_task_repository.dart';

// Concrete classes (for backward compatibility)
export 'settings_repository.dart';

// Models
export 'models/dashboard_models.dart';
export 'models/project_models.dart';

// Other repositories (to be refactored)
export 'impl/sub_task_repository.dart';
export 'impl/project_meta_repository.dart';