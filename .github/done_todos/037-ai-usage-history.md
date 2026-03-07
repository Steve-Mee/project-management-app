# Implement usage history tracking voor AI (tokens/requests)

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/providers/ai/ai_usage_providers.dart`

Beschrijving:
Bewaar per gebruiker/project de tokens en requests history voor billing/monitoring/analytics.

Wat toe te voegen:
- Persistentie model (Hive or Supabase) voor usage records.
- Provider endpoints om history op te vragen en totalen te berekenen.
- Expose per-project en per-user metrics.

Audit-opvolging uitgevoerd:
- Persistent model `AiUsageRecord` + repository contract `IAiUsageRepository` zijn actief in `packages/pma_core/lib/models/ai_usage_record.dart` en `packages/pma_core/lib/repository/i_ai_usage_repository.dart`.
- Hive persistence, filtering en totals (inclusief advanced metrics + caching) staan in `packages/pma_core/lib/repository/impl/hive_ai_usage_repository.dart`.
- Provider-endpoints voor history/totals/per-user/per-project staan in `packages/pma_core/lib/providers/ai/ai_usage_providers.dart` (`aiUsageHistoryProvider`, `aiUsageUserProvider`, `aiUsageProjectProvider`).
- End-to-end testdekking uitgebreid in `test/ai_usage_provider_test.dart` met flowvalidatie voor loggen -> history filter -> user/project totals en CSV/JSON export via notifier.

Resterende hardening (geen blocker voor TODO 037):
- Architectuur is hybride (Supabase aggregate + lokale Hive history); documenteer op termijn expliciet welke metrics authoritative zijn per use-case.

Prioriteit: Middel

Labels: `area:ai`, `analytics`