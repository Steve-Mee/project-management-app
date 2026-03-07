# 049-repository-refactoring

**Priority:** Low

**Description:** Refactor repository implementations for better testing and maintainability.

**Acceptance Criteria:**
- [x] DONE: Move repository implementations to separate files when they grow
- [x] DONE: Consider using abstract interfaces for easy testing/swapping
- [x] DONE: Improve repository structure and organization
- [x] DONE: Update repository files for better separation of concerns

**Verification Notes:**
- Split auth repository internals into dedicated modules:
	- `packages/pma_core/lib/repository/impl/auth/auth_data_mapper.dart`
	- `packages/pma_core/lib/repository/impl/auth/auth_operations.dart`
	- `packages/pma_core/lib/repository/impl/auth/auth_remote_service.dart`
- `HiveAuthRepository` now delegates mapping/auth workflows to those modules.
- Legacy password upgrade now persists via canonical `users` key path.