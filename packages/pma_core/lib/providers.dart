/// Barrel file for all core providers.
/// See issue 055-barrel-files-providers.md.
library;

// Canonical provider barrel for app imports.
export 'providers/index.dart';

// Backward-compatible export kept during migration.
export 'providers/onboarding_providers.dart';
