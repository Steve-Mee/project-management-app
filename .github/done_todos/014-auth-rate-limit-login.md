# Rate limiting voor login-pogingen

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/providers/auth/auth_providers.dart` en `packages/pma_core/lib/repository/impl/hive_auth_repository.dart`

Beschrijving:
Bescherm accounts tegen brute-force door rate limiting op login.

Wat toe te voegen:
- Implementeer server/client-side rate limiting (in-memory of persistent store).
- Definieer limiet (bijv. 5 pogingen per minuut) en blocking/backoff-regels.
- Voeg tests en telemetry (AppLogger.event) bij exceeded attempts.

Audit-opvolging uitgevoerd:
- Dubbele in-memory attempt-tracking verwijderd uit `HiveAuthRepository` en `_AuthOperations`.
- Repository rate-limit routes delegeren nu naar `LoginRateLimiter` als single source of truth (met veilige fail-open handling bij storage-initialisatieproblemen).
- Guard-test toegevoegd die afdwingt dat in-memory `_failedAttempts` maps niet terugkeren in de auth repository-implementatie.

Prioriteit: Hoog

Labels: `security`, `area:auth`
