# Verwijderen/aanpassen van `ProjectsNotifier.initialize()` test-compatibiliteit

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/providers/project/project_providers.dart`

Beschrijving:
`ProjectsNotifier.initialize()` bestaat niet meer in de huidige architectuur. Projectproviders gebruiken de Riverpod `build()` lifecycle en testinjectie via provider-overrides.

Wat toe te voegen/aanpassen:
- Vervang verouderde verwijzingen naar `initialize()` door een migratienota op basis van provider-overrides.
- Documenteer teststrategie: fake repository via `projectRepositoryProvider.overrideWithValue(...)` en async state afwachten via `await container.read(projectsProvider.future)`.

Audit-opvolging uitgevoerd:
- TODO-tekst gemigreerd naar de actuele provider-lifecycle (`build()` + overrides) in plaats van een niet-bestaande `initialize()` methode.
- Verouderde maintainance-aanwijzingen rond `initialize()` verwijderd om toekomstige verwarring te voorkomen.

Prioriteit: Laag

Labels: `testing`, `tech-debt`
