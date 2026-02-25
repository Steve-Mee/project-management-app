# 055-barrel-files-providers

**Priority:** Low

**Description:** Create barrel files for providers to simplify imports and improve code organization.

**Acceptance Criteria:**
- [ ] Create lib/core/providers/index.dart with all exports
- [ ] Create per feature lib/features/xxx/providers/index.dart
- [ ] Replace all long imports with import 'package:.../providers.dart';
- [ ] Do the same for models and repositories