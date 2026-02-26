# 070-modularization-core-package

**Priority:** High

**Description:** Modularize the application by extracting core functionality into a separate package.

**Acceptance Criteria:**
- [ ] Create packages/pma_core with all core providers, services, models, utils
- [ ] Features remain in main app but import pma_core
- [ ] Update go_router with deferred loading where possible