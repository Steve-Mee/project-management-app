# pma_core Import And Deprecation Matrix

## Canonical Imports (Preferred)

- `package:pma_core/pma_core.dart` for broad package usage.
- `package:pma_core/providers.dart` for providers.
- `package:pma_core/repository/repository.dart` for stable repository abstractions.
- `package:pma_core/repository/repository_interfaces.dart` for explicit interfaces.
- `package:pma_core/repository/repository_impl.dart` for concrete implementations.

## Compatibility Imports (Temporary)

These remain for migration safety and should not be used in new code:

- `package:pma_core/providers/providers.dart`
- `package:pma_core/providers/analytics_providers.dart`
- `package:pma_core/providers/analytics/analytics_providers.dart`
- `package:pma_core/repository/auth_repository.dart` (alias)
- `package:pma_core/repository/settings_repository.dart` (alias)

## Planned Removal Policy

1. Keep compatibility paths for at least one release cycle.
2. Migrate feature and test imports to canonical paths.
3. Remove compatibility exports in the next minor/major cleanup once migration is complete.
