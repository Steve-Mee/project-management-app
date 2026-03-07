# Koppel dashboard items aan `projectsProvider`

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `lib/core/providers/dashboard_providers.dart`

Beschrijving:
Sommige dashboarditems moeten project-data tonen; koppel dit zodra `projectsProvider` stabiel is.

Wat toe te voegen:
- Consumers die `projectsProvider` gebruiken om project-namen/ids te resolven.
- Fallbacks wanneer `projectsProvider` loading/errors heeft.

Audit-opvolging uitgevoerd:
- `projectRequirementsProvider` gebruikt `projectsProvider.future` om projectcontext op te halen en requirements category-based te resolven met veilige fallback bij loading/error.
- Expliciete item-level resolver toegevoegd: `projectDisplayNameProvider` in `packages/pma_core/lib/providers/dashboard/dashboard_providers.dart`.
- Fallbackgedrag is afgedekt voor loading/error/missing project met consistente labelwaarde (`Unknown Project`).
- Tests toegevoegd in `test/dashboard_providers_test.dart` voor item-level resolvergedrag op data/loading/error/missing situaties.

Prioriteit: Laag

Labels: `area:dashboard`, `integration`
