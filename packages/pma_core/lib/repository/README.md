# Repository Layer (pma_core)

## Overview

This folder contains persistence abstractions and concrete data implementations
used by `pma_core`.

## Import Strategy

Use one of these entry points:

- `package:pma_core/repository/repository.dart`
  Stable barrel with repository interfaces + shared repository models.
- `package:pma_core/repository/repository_interfaces.dart`
  Explicit interface-only imports.
- `package:pma_core/repository/repository_impl.dart`
  Concrete implementations (Hive and legacy concrete classes).

## Stable Interfaces

- `i_project_repository.dart`
- `i_dashboard_repository.dart`
- `i_auth_repository.dart`
- `i_settings_repository.dart`
- `i_ai_usage_repository.dart`

## Concrete Implementations

- `impl/hive_project_repository.dart`
- `impl/hive_dashboard_repository.dart`
- `impl/hive_auth_repository.dart`
- `impl/hive_settings_repository.dart`
- `impl/hive_ai_usage_repository.dart`
- `impl/hive_task_repository.dart`
- `impl/project_meta_repository.dart` (legacy concrete class)
- `impl/sub_task_repository.dart` (legacy concrete class)

## Compatibility Notes

Compatibility aliases are still available for migration safety (for example
`settings_repository.dart` and `auth_repository.dart` aliases).

New code should prefer interface imports in feature and provider layers.
