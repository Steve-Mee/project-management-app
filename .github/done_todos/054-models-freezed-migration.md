# 054-models-freezed-migration

**Priority:** High

**Description:** Migrate all models to freezed + json_serializable for better type safety and code generation.

**Acceptance Criteria:**
- [ ] Add deps: freezed: ^2.5.0, freezed_annotation: ^2.4.0, json_annotation: ^4.9.0, build_runner: ^2.4.0
- [ ] Replace all manual fromJson/toJson + Equatable with @freezed classes
- [ ] Update Hive adapters (or migrate to freezed + Hive generator)
- [ ] Update all repositories, providers and tests
- [ ] Remove old model files after validation