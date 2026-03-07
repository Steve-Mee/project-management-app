# 070-modularization-core-package

**Priority:** High

**Description:** Modularize the application by extracting core functionality into a separate package.

**Acceptance Criteria:**
- [x] DONE: Create packages/pma_core with all core providers, services, models, utils
- [x] DONE: Features remain in main app but import pma_core
- [x] DONE: Update go_router with deferred loading where possible

**Validation Notes (2026-03-07):**
- Added a phased consolidation/removal plan for remaining compatibility surfaces in `docs/modularization.md`.
- Documented explicit exit criteria for removing legacy duplicate paths without changing runtime behavior.