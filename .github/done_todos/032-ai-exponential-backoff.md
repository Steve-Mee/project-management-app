# Voeg exponential backoff toe bij rate-limits

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `lib/core/providers/ai_chat_provider.dart`

Beschrijving:
Bij throttling is het verstandig om retry/backoff te implementeren.

Wat toe te voegen:
- Backoff-policy (exponential jitter) in retry-logica.
- Testen van retry-gedrag en observability (logging).

Audit-opvolging uitgevoerd:
- Actieve AI-provider (`packages/pma_core/lib/providers/ai/ai_chat_providers.dart`) plant nu throttling-specifieke exponential backoff wanneer queue verwerking rate-limited is (`ai_rate_limit_backoff_scheduled` event met attempt/delay metadata).
- Retry-flow gebruikt config-gedreven backoff (`backoffBaseDelay`, `backoffMaxDelay`) en `maxRetryAttempts` in plaats van hardcoded limieten.
- Testhooks toegevoegd voor backoff policy validatie en afgedekt in `test/ai_chat_backoff_policy_test.dart`.

Prioriteit: Middel

Labels: `area:ai`, `reliability`