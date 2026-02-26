# Biometrische authenticatie ondersteunen

Bronbestand: `lib/core/providers/auth_providers.dart`

Beschrijving:
Voeg optionele biometric login (fingerprint/face) toe met feature-flag en platform checks.

Wat toe te voegen:
- Integratie met packages zoals `local_auth` en feature flag in instellingen.
- Provider/Notifier methoden om biometric enrollment en login te beheren.
- UI flows en permissies (fallback op wachtwoord).

Prioriteit: Laag-Middel

Labels: `feature`, `area:auth`
