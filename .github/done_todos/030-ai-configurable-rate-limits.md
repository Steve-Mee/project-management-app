# Maak AI rate limits configureerbaar

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `lib/core/providers/ai_chat_provider.dart`

Beschrijving:
Harde limieten zijn niet flexibel; maak ze configureerbaar via settings of env.

Wat toe te voegen:
- Verplaats magic-nummers naar config (`ai_config` of `settingsRepository`).
- Voorzie fallback-waarden en validatie.

Audit-opvolging uitgevoerd:
- Runtimeconfig is leidend in actieve provider `packages/pma_core/lib/providers/ai/ai_chat_providers.dart`:
	- window-throttle gebruikt `maxRequestsPerWindow` + `timeWindowDuration`,
	- retry-limiet gebruikt `maxRetryAttempts`,
	- exponential backoff gebruikt `backoffBaseDelay`/`backoffMaxDelay`.
- Settings-integratie en clamping blijven centraal in `packages/pma_core/lib/repository/impl/hive_settings_repository.dart` + `packages/pma_core/lib/models/ai_rate_limits_config.dart`.
- Validatietests toegevoegd in `test/ai_rate_limits_config_test.dart` voor clamping van window/retry/backoff/per-operation limieten.

Prioriteit: Middel

Labels: `area:ai`, `config`
