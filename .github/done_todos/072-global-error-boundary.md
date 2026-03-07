# 072-global-error-boundary

**Priority:** Medium

**Description:** Implement global ErrorBoundary widget with Sentry breadcrumbs for better error tracking.

**Acceptance Criteria:**
- [x] DONE: ErrorBoundary wrapper around entire app
- [x] DONE: Log all errors + user actions as breadcrumbs

**Validation Notes (2026-03-07):**
- Added a concrete PR/code-review checklist for `AppLogger.userAction(...)` coverage in `docs/error-boundary.md`.
- Checklist defines where and how to log critical user actions to keep breadcrumb coverage consistent across new features.