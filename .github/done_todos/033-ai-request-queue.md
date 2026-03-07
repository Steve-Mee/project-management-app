# Request queuing voor AI burst handling

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `lib/core/providers/ai_chat_provider.dart`

Beschrijving:
Behandel bursts middels queue en worker zodat rate-limits niet direct errors veroorzaken voor gebruikers.

Wat toe te voegen:
- Queue implementatie (in-memory of persistent) met background worker die requests pusht volgens limiter.
- Metrics en retries.

Audit-opvolging uitgevoerd:
- Queue + worker + persistence blijven actief in `packages/pma_core/lib/providers/ai/ai_chat_providers.dart`.
- Runtimegedrag is nu expliciet config-gedreven via `queueEnabled`:
	- `queueEnabled=true`: request wordt gequeued en door worker verwerkt,
	- `queueEnabled=false`: queue wordt omzeild en request wordt direct uitgevoerd (`mode: immediate`).
- Testhooks toegevoegd voor queuegedrag en afgedekt in `test/ai_queue_behavior_test.dart`.
- Queue metrics/retries blijven intact en observability events zijn uitgebreid met bypass-signalen.

Prioriteit: Middel

Labels: `area:ai`, `feature`