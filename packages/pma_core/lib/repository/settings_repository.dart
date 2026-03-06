// Settings repository - concrete implementation
import 'impl/hive_settings_repository.dart';
export 'impl/hive_settings_repository.dart';

// Alias for backward compatibility
@Deprecated('Use ISettingsRepository abstractions or HiveSettingsRepository directly.')
typedef SettingsRepository = HiveSettingsRepository;
