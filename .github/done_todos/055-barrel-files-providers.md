# 055-barrel-files-providers

**Priority:** Low

**Description:** Create barrel files for providers to simplify imports and improve code organization.

**Acceptance Criteria:**
- [x] DONE: Create lib/core/providers/index.dart with all exports
- [x] DONE: Create per feature lib/features/xxx/providers/index.dart
- [x] DONE: Replace all long imports with import 'package:.../providers.dart';
- [x] DONE: Do the same for models and repositories

**Verification Notes:**
- Added per-feature provider barrels under `lib/features/*/providers/index.dart` for admin, ai_chat, ai_usage, auth, dashboard, project, projects, and settings.
- Migrated key feature screens from deep `package:pma_core/providers/...` imports to feature-local provider barrels.
- Expanded `packages/pma_core/lib/models/models.dart` exports and migrated key screens to the models barrel.