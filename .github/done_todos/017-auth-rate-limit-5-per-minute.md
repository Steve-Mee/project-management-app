# Specificeer en implementeer: max 5 login attempts per minuut

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/services/login_rate_limiter.dart` en `packages/pma_core/lib/providers/auth/auth_providers.dart`

Beschrijving:
Concretiseer de rate limit policy voor login.

Wat toe te voegen:
- Implementatie voor 5 attempts/minute met backoff en optionele captcha.
- Tests die de limiet en unblock-logica valideren.

Audit-opvolging uitgevoerd:
- Captcha drempel gecentraliseerd in `LoginRateLimiter.captchaThreshold` (naast `maxAttempts` en `windowSeconds`).
- Auth login-flow gebruikt nu limitercontract (`shouldRequireCaptcha`) in plaats van hardcoded threshold checks.
- Testen gealigneerd op limiter constants om policy drift te voorkomen.
- Extra limiter-test toegevoegd voor captcha-threshold gedrag.

Prioriteit: Hoog

Labels: `security`, `area:auth`
