# Modularization (Issue #070)

This document tracks the final status of issue `#070-modularization-core-package`.

## Acceptance Criteria Checklist

- [x] Create `packages/pma_core` with all core providers, services, models, utils
- [x] Features remain in main app but import `pma_core`
- [x] Update `go_router` with deferred loading where possible

## Deferred Routing Notes

Feature routes are configured with deferred imports and lazy `loadLibrary()` wrapping in `lib/core/routes.dart`:

- `/dashboard`
- `/projects`
- `/projects/:id`
- `/projects/:id/members`
- `/ai-chat`
- `/ai-usage`
- `/settings`
- `/admin`

Core providers and shared/core widgets continue to load normally from `pma_core`.

## Remaining Consolidation Plan

The core extraction is functionally complete. The remaining work is a phased cleanup of compatibility surfaces and duplicate legacy paths.

### Phase 1: Inventory And Warnings

- Keep compatibility exports active where needed, but document each remaining app-level duplicate import path.
- Add/refresh references in docs when canonical implementation moved to `packages/pma_core/...`.
- Prefer importing from `package:pma_core/pma_core.dart` in new code.

### Phase 2: Gradual Callsite Migration

- Replace app-level legacy imports with canonical `pma_core` imports in touched files.
- Avoid broad refactors in one pass; migrate with feature work to reduce regression risk.
- Validate each migration step with `flutter analyze` and targeted widget/unit tests.

### Phase 3: Compatibility Surface Reduction

- Remove compatibility shims only after zero remaining callsites are found.
- Update TODO/doc references that still mention old app-level paths.
- Keep one stable canonical source for models/providers/services in `pma_core`.

### Exit Criteria

- No remaining production imports from deprecated app-level duplicate paths.
- Documentation points only to canonical `packages/pma_core/...` locations.
- Analyze and relevant regression tests stay green after each cleanup batch.
