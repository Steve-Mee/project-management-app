# Biometrische authenticatie ondersteunen

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/providers/auth/auth_providers.dart`

Beschrijving:
Voeg optionele biometric login (fingerprint/face) toe met feature-flag en platform checks.

Wat toe te voegen:
- Integratie met packages zoals `local_auth` en feature flag in instellingen.
- Provider/Notifier methoden om biometric enrollment en login te beheren.
- UI flows en permissies (fallback op wachtwoord).

Audit-opvolging uitgevoerd:
- Biometrische flow gebruikt nu een centrale feature-flag gate (`auth_biometric`) met fail-open default om lockout regressies te voorkomen.
- Plaintext opslag van `biometric_password` verwijderd; enrollment bewaart nu gebruikers-id + Supabase refresh token in secure storage.
- Dubbele toggles geconsolideerd: `useBiometricsProvider` is gedepricieerd en verwijst naar `biometricLoginProvider` als single source of truth.
- Guard-test toegevoegd om security en provider-consolidatie te bewaken.

Prioriteit: Laag-Middel

Labels: `feature`, `area:auth`
