# pma_core Public API Policy

## Goal

Keep `pma_core` stable for app consumers while allowing internal refactors.

## API Levels

- Stable API: intended for app imports and long-term compatibility.
- Internal API: implementation details that may change without notice.

## Stable Entry Points

- `package:pma_core/pma_core.dart`
- `package:pma_core/providers.dart`
- `package:pma_core/repository/repository_interfaces.dart`
- `package:pma_core/repository/repository_impl.dart`

## Internal Paths

Imports directly from deep paths under `lib/providers/**`, `lib/repository/impl/**`,
and similar internals should be avoided in feature code unless strictly needed.

## Deprecation Rules

1. Add replacement path in docs and comments.
2. Keep compatibility exports for at least one release cycle.
3. Remove only after migration is complete.

## Quality Rules

- No references to app package imports inside `pma_core` runtime source.
- Keep examples out of production files under `lib/`.
- Add tests for new provider/repository behavior.

## Migration Reference

- See `docs/import_deprecation_matrix.md` for canonical imports,
  compatibility paths, and removal timing.
