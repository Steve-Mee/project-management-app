# Error handling en logging toevoegen voor dashboard providers

Bronbestand: `lib/core/providers/dashboard_providers.dart`

Beschrijving:
Robuuste try/catch en telemetrie ontbreken op meerdere plekken.

Wat toe te voegen:
- Voeg `try/catch` rondom IO/DB bewerkingen en log errors met `AppLogger.error`.
- Voeg `AppLogger.event` voor belangrijke acties (create/update/delete).
- Voeg tests voor foutafhandeling.

Prioriteit: Middel

Labels: `area:dashboard`, `reliability`
