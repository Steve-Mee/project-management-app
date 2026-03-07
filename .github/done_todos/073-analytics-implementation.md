# 073-analytics-implementation

**Priority:** Low

**Description:** Add analytics tracking for important user events using Supabase or Firebase.

**Acceptance Criteria:**
- [x] DONE: Track important events: project_created, task_completed, ai_used, invite_sent
- [x] DONE: Make AnalyticsService abstract

**Validation Notes (2026-03-07):**
- Confirmed canonical `project_created` tracking uses `AnalyticsService.logEvent(...)` in `packages/pma_core/lib/repository/impl/hive_project_repository.dart`.
- Existing analytics mapping in `docs/analytics.md` already points to repository-level callsites for the required core events.