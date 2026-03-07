# Project Repository Interface Decision

Date: 2026-03-07
Scope: TODO 001 follow-up

## Decision

`IProjectRepository` remains in `packages/pma_core/lib/repository/i_project_repository.dart`.

## Why

- The interface is used by multiple feature providers and test fakes.
- Keeping the contract in `pma_core` avoids app-layer import cycles.
- Backend implementations can be swapped (Hive, Supabase, test doubles) without changing provider call sites.
- This location is stable after modularization (TODO 070), so older `lib/core/...` references are now historical only.

## Guardrails

- New app code should depend on `IProjectRepository`, not concrete repository classes.
- Contract-level behavior changes should be accompanied by repository tests in `test/project_repository_test.dart` and provider tests that use `projectRepositoryProvider` overrides.
