# Koppel dashboard items aan `projectsProvider`

Bronbestand: `lib/core/providers/dashboard_providers.dart`

Beschrijving:
Sommige dashboarditems moeten project-data tonen; koppel dit zodra `projectsProvider` stabiel is.

Wat toe te voegen:
- Consumers die `projectsProvider` gebruiken om project-namen/ids te resolven.
- Fallbacks wanneer `projectsProvider` loading/errors heeft.

Prioriteit: Laag

Labels: `area:dashboard`, `integration`
