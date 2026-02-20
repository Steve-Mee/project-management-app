# Rate limiting voor login-pogingen

Bronbestand: `lib/core/providers/auth_providers.dart`

Beschrijving:
Bescherm accounts tegen brute-force door rate limiting op login.

Wat toe te voegen:
- Implementeer server/client-side rate limiting (in-memory of persistent store).
- Definieer limiet (bijv. 5 pogingen per minuut) en blocking/backoff-regels.
- Voeg tests en telemetry (AppLogger.event) bij exceeded attempts.

Prioriteit: Hoog

Labels: `security`, `area:auth`
