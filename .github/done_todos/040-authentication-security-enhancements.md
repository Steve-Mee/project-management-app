# 040-authentication-security-enhancements

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

**Priority:** High

**Description:** Enhance authentication security with captcha, rate limiting, and biometric support.

**Acceptance Criteria:**
- [x] Integrate reCAPTCHA or similar captcha to login screen after 3 failed attempts
- [x] Implement sliding-window rate limiting (5 attempts per minute) for login
- [x] Add biometric authentication support using device biometrics
- [x] Implement proper async checking with settings repository
- [x] Access settings repository properly for auth configurations
- [x] Replace placeholder auth in auth_repository.dart with real backend integration

Audit-opvolging uitgevoerd:
- Loginflow gebruikt sliding-window limiter + captcha threshold via `LoginRateLimiter` en `RecaptchaService` in `packages/pma_core/lib/providers/auth/auth_providers.dart`.
- Biometrische authenticatie gebruikt platform/feature-flag checks en secure refresh-token opslag (geen plaintext wachtwoord) in `auth_providers.dart`.
- Auth settings worden asynchroon via `settingsRepositoryProvider.future` gelezen in imperative paden.
- Cloud sync auth-calls gebruiken nu canonieke methoden (`authSignIn`, `authSignOut`) i.p.v. placeholder methoden, met compat wrappers in `packages/pma_core/lib/services/cloud_sync_service.dart`.
- Regressietest toegevoegd voor canonical method usage in `test/auth_async_settings_guard_test.dart`.

Resterende hardening (geen blocker voor TODO 040):
- Integratietests voor volledige security keten (failed attempts -> captcha -> lockout/backoff -> recovery) verder uitbreiden.
- Security policy/documentatie rond biometrische token lifecycle en fallback scenario's formaliseren.