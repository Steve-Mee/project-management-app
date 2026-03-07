# Breid filter-conditions in `filteredProjectsProvider` uit

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/providers/project/project_providers.dart`

Beschrijving:
`filteredProjectsProvider` bevat momenteel basale filtering; er zijn extra requirements mogelijk.

Wat toe te voegen:
- Voeg logica toe voor gecombineerde filters (AND/OR), zoekmatching, en null/empty checks.
- Voeg tests voor filter-logica.

Audit-opvolging uitgevoerd:
- `filteredProjectsProvider` gebruikt nu het uitgebreide provider-filtertype (`ProjectFilter`) zodat AND/OR-semantiek direct beschikbaar is.
- Centrale evaluatieflow toegevoegd voor gecombineerde filtering:
	- repository-compatibele velden,
	- `extraConditions`,
	- provider-only velden,
	- consistente sort-resolutie.
- Backward compatibility behouden via deprecated legacy provider voor het model-filtertype.
- Provider-tests toegevoegd voor OR via `tags`, AND via `requiredTags`, en null/empty regressiegedrag.

Prioriteit: Laag-Middel

Labels: `area:providers`, `tests`
