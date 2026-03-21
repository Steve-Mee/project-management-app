# Feature Flags

## Purpose

Feature flags control runtime availability and behavior variants without requiring a full client release.

## Data Source

Canonical source:

- Supabase table: `feature_flags`

Local resilience:

- Hive cache box: `feature_flags`
- `last_fetch` timestamp for staleness-aware refresh

## Runtime Architecture

- Service: `FeatureFlagService`
- Provider: `featureFlagProvider` (`AsyncNotifierProvider<FeatureFlagNotifier, Map<String, dynamic>>`)
- Model/resolver: typed flag parsing with safe defaults
- Admin interface: feature flag management widget and route

Legacy note:

- `ABTestingService` remains compatibility-only and should not be used for new work.

## Refresh Behavior

- Cache-first hydration on startup
- Background refresh when cache is stale
- Scheduled refresh cadence: 30 minutes
- Refresh on app resume

## Core Flags

Primary examples in current app:

- `mirror_enabled`: global Mirror availability gate
- `premium`: premium entitlement behavior gate
- A/B variant keys: runtime variant selection (for example model/backend and UX experiments)
- Additional UX gates used by app modules such as AI, Gantt, and onboarding

## Read/Write Security

- Authenticated users can read active flags as allowed by RLS policy.
- Write operations require admin role claims (`auth.jwt() -> app_metadata ->> role = 'admin'`).
- Missing admin claim results in safe denial without mutation.

## Operational Rules

- Always define safe default behavior when flag data is unavailable.
- Use deterministic fallback values for critical gates.
- Log evaluation path for observability and post-incident diagnosis.
- Record writes in analytics/audit stream with previous and new values.

## Testing Requirements

Minimum coverage:

- Resolver/model parsing
- Provider refresh lifecycle
- Cache fallback behavior
- UI gating for disabled and loading states
- Admin write permission enforcement

## Change Management

- Add new flags with explicit owner, default, and rollback plan.
- Remove obsolete flags only after code paths are deleted.
- Keep naming consistent and avoid alias drift.
