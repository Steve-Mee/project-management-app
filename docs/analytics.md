# Analytics (Issue #073)

This document tracks the analytics implementation for issue `#073-analytics-implementation`.

## Acceptance Criteria Checklist

- [x] Track important events: `project_created`, `task_completed`, `ai_used`, `invite_sent`
- [x] Make `AnalyticsService` abstract

## Implemented Event Mapping

- `project_created`
  - Source: `packages/pma_core/lib/repository/impl/hive_project_repository.dart`
  - Trigger: new project persisted in repository
- `task_completed`
  - Source: `packages/pma_core/lib/providers/task/task_providers.dart`
  - Trigger: task status changes to `TaskStatus.done`
- `ai_used`
  - Source: `packages/pma_core/lib/providers/ai/ai_chat_providers.dart`
  - Trigger: AI request successfully completes
- `invite_sent`
  - Source: `packages/pma_core/lib/services/project_invitation_service.dart`
  - Source: `packages/pma_core/lib/services/project_members_service.dart`
  - Trigger: invitation row successfully inserted

## Service Architecture

- Abstraction: `packages/pma_core/lib/core/services/analytics_service.dart`
  - `abstract class AnalyticsService`
  - `Future<void> logEvent(String name, {Map<String, dynamic>? parameters})`
- Default implementation: `SupabaseAnalyticsService`
- Riverpod provider: `analyticsServiceProvider` in `packages/pma_core/lib/core/providers.dart`

## How To Add New Events

1. Pick a stable, snake_case event name.
2. Log through `AnalyticsService` (not direct table writes in feature code):
   - Riverpod context:
     - `ref.read(analyticsServiceProvider).logEvent('new_event', parameters: {...})`
   - Non-provider services:
     - inject `AnalyticsService` via constructor, or use `AnalyticsService.create(...)`.
3. Keep payload small and JSON-safe:
   - IDs, status values, counts, and coarse metadata only.
   - Avoid secrets and unnecessary personal data.
4. Add/update tests for the trigger behavior.
5. Update this document with the new event and trigger location.

## Suggested Supabase Schema (`analytics_events`)

```sql
CREATE TABLE IF NOT EXISTS analytics_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event TEXT NOT NULL,
  user_id UUID,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  parameters JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_analytics_events_event
  ON analytics_events(event);

CREATE INDEX IF NOT EXISTS idx_analytics_events_user_id
  ON analytics_events(user_id);

CREATE INDEX IF NOT EXISTS idx_analytics_events_timestamp
  ON analytics_events(timestamp DESC);
```

RLS suggestion:

```sql
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY analytics_events_insert_policy
ON analytics_events
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY analytics_events_select_policy
ON analytics_events
FOR SELECT
USING (auth.uid() = user_id);
```

## Backward Compatibility

`AppLogger.event(...)` remains available for breadcrumb/debug logging.
For product analytics, prefer `AnalyticsService.logEvent(...)` so event routing can be switched from Supabase to Firebase without changing call sites.
