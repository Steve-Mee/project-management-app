# pma_core

Shared core package for the Project Management App.

## Purpose

This package will host reusable, non-feature-specific code extracted from the app:

- providers
- services
- repositories
- models
- utils
- shared widgets
- auth and config primitives

## Current Status

Package is actively used in production and contains:

- models and adapters
- Riverpod providers
- repositories (interfaces + Hive implementations)
- services
- shared widgets and utilities

## Import Guidelines

Preferred public imports:

- `package:pma_core/pma_core.dart` for broad app-level usage
- `package:pma_core/providers.dart` for provider-only usage
- `package:pma_core/repository/repository.dart` for stable repository abstractions
- `package:pma_core/repository/repository_interfaces.dart` for explicit abstractions
- `package:pma_core/repository/repository_impl.dart` for concrete implementations

Compatibility exports are still present for migration safety, but new code should
use the canonical imports listed above.

See `docs/import_deprecation_matrix.md` for compatibility paths and planned
removal policy.

## Quality Gates

- `dart analyze packages/pma_core`
- `flutter test packages/pma_core/test`

## Notes

Example snippets that are not runtime-critical should live in docs or
`packages/pma_core/example`, not in production source files under `lib/`.
