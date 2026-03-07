# Feature Flags (Supabase)

Issue: `#071-feature-flags-supabase`

## Summary

This project now includes a Supabase-backed feature flag system with Riverpod state access and Hive cache fallback.

Core pieces:

- Service: `packages/pma_core/lib/core/services/feature_flag_service.dart`
- Provider: `packages/pma_core/lib/core/providers/feature_flag_provider.dart`
- Typed model: `packages/pma_core/lib/core/feature_flags/feature_flag.dart`
- Admin widget: `packages/pma_core/lib/core/widgets/feature_flags_admin.dart`
- Legacy compatibility example: `packages/pma_core/lib/services/ab_testing_service.dart`

Migration note:

- `ABTestingService` is now legacy compatibility only.
- New code should use `FeatureFlagService` and `featureFlagProvider` directly.

## Acceptance Criteria Checklist (Exact)

- [x] Create FeatureFlagProvider that reads supabase.from('feature_flags').select() + cache
- [x] Use in AI, Gantt, onboarding etc.

## Notes

- Provider type is `AsyncNotifierProvider<FeatureFlagNotifier, Map<String, dynamic>>`.
- Provider refresh behavior:
  - Auto-refresh every 30 minutes.
  - Refresh on app resume.
- Service caches fetched rows in Hive box `feature_flags` with a `last_fetch` timestamp.
- Provider uses cache-first startup and refreshes stale cache in the background.
- AI, Gantt, and onboarding use graceful degradation when flags are disabled or still loading.
- AI service backend can optionally be selected with `ai_backend` (`grok`, `openai_langchain`, `gemini`, `claude`) with fallback to existing settings toggle when absent/invalid.
- For write operations, Supabase RLS requires JWT `app_metadata.role == 'admin'`.
- Without that claim, the admin UI shows an error and no data mutation occurs (intentional safe behavior).
- Successful flag writes also create an audit event in `analytics_events` (`event = feature_flag_changed`).
- Audit metadata includes `flag_key`, previous/new enabled state, and previous/new value.
- Observability events now include `feature_flag_evaluated`, `feature_flag_fallback_cache`, and `feature_flag_default_used`.

## Implementation Status

All requested integration tasks for issue `#071-feature-flags-supabase` are completed.

Delivered:

- Dedicated service + provider architecture for Supabase-backed flags.
- AI, Gantt, and onboarding runtime gating with graceful fallback behavior.
- Admin route and admin widget for viewing/updating flags.
- Audit trail for successful flag writes (`feature_flag_changed`) with metadata.
- Supabase migration + RLS policies for authenticated reads and admin-only writes.
- AB-only runtime checks phased out; `ABTestingService` kept as deprecated compatibility shim.

## Test Coverage Added

- `test/core/feature_flag_resolver_test.dart`
- `test/core/feature_flag_model_test.dart`
- `test/core/feature_flag_provider_test.dart`
- `test/core/feature_flag_service_test.dart`
- `test/features/feature_flags/feature_flag_gating_test.dart`

These tests cover parser/model behavior, provider lifecycle refresh behavior, service fallback defaults, and UI gating for Gantt/onboarding when flags are disabled.
