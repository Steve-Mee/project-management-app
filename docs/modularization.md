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
