# Model Location Policy

This document defines the canonical location of domain models after the Freezed migration.

## Canonical Source

The canonical model source is:

- `packages/pma_core/lib/models/**`

All new model changes should be made in `pma_core` first.

## App-Layer Models (`lib/models`)

`lib/models/**` currently exists for compatibility during modularization.

Rules during migration window:

- Do not introduce new model-only types in `lib/models`.
- Prefer imports from `package:pma_core/models/...` or `package:pma_core/models/models.dart` where available.
- When touching duplicated models, migrate callsites toward `pma_core` instead of extending duplication.

## De-duplication Plan

1. Keep feature behavior stable while moving imports gradually.
2. Remove duplicate app-layer model files only after callsites and tests are migrated.
3. Validate with `flutter analyze` and relevant test suites after each migration batch.

## Scope

This policy complements TODO 054 (Freezed migration) and TODO 070 (modularization).
