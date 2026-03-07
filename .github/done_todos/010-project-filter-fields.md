# Voeg extra filter-velden (date range, priority) toe

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/providers/project/project_providers.dart`

Beschrijving:
Ondersteuning voor extra filter-velden verbetert querymogelijkheden.

Wat toe te voegen:
- Breid `ProjectFilter` uit met date-range en priority.
- Pas UI voorbeelden/documentatie aan.

Audit-opvolging uitgevoerd:
- Date-range filtering semantiek geharmoniseerd met expliciete inclusieve grenzen op provider- en repositorypad.
- Gerichte tests toegevoegd voor boundary-instants en timezone-offset scenario's op due-date filtering.
- Scope-documentatie uitgebreid met expliciete `dueDateStart`/`dueDateEnd` evaluatieregel.

Prioriteit: Laag

Labels: `enhancement`
