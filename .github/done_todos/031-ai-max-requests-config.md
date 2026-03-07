# Maak max requests per window configureerbaar

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `lib/core/providers/ai_chat_provider.dart`

Beschrijving:
Exposeer instelling voor maximum requests per time window (vb. 10/min standaard).

Wat toe te voegen:
- Config entry en provider/setting.
- Gebruik deze waarde in de rate-limiter initialisatie.
- Tests voor respecteren van verschilende configuraties.

Audit-opvolging uitgevoerd:
- Config-entry + settingspad aanwezig via `AiRateLimitsConfig.maxRequestsPerWindow` en `HiveSettingsRepository.getAiRateLimitsConfig/setAiRateLimitsConfig`.
- Actieve runtime gebruikt nu deze config in limiterpad (`_windowRequestTimestamps` + `maxRequestsPerWindow` + `timeWindowDuration`) in `packages/pma_core/lib/providers/ai/ai_chat_providers.dart`.
- Tests aangevuld in `test/ai_rate_limits_config_test.dart` voor:
	- onderscheid tussen verschillende geldige window-configuraties,
	- JSON roundtrip-behoud van windowwaarden,
	- clamping van ongeldige windowwaarden.

Prioriteit: Middel

Labels: `area:ai`, `config`
