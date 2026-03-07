# 054-models-freezed-migration

**Priority:** High

**Description:** Migrate all models to freezed + json_serializable for better type safety and code generation.

**Acceptance Criteria:**
- [x] DONE: Add deps: freezed: ^2.5.0, freezed_annotation: ^2.4.0, json_annotation: ^4.9.0, build_runner: ^2.4.0
- [x] DONE: Replace all manual fromJson/toJson + Equatable with @freezed classes
- [x] DONE: Update Hive adapters (or migrate to freezed + Hive generator)
- [x] DONE: Update all repositories, providers and tests
- [x] DONE: Remove old model files after validation

**Verification Notes:**
- Added canonical ownership policy in `docs/model-location-policy.md`.
- Policy sets `packages/pma_core/lib/models/**` as source of truth and defines staged de-duplication rules for `lib/models/**`.