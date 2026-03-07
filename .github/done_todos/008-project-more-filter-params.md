# Breid filter-parameters voor projecten uit

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/providers/project/project_providers.dart`

Beschrijving:
Extra velden zoals datum-range, priority, owner, of tags kunnen nuttig zijn.

Wat toe te voegen:
- Voeg extra velden toe aan `ProjectFilter`.
- Pas repository-provider filtering aan om nieuwe velden te ondersteunen.

Audit-opvolging uitgevoerd:
- Provider-only filtervelden worden nu effectief toegepast in de filterpipeline voor `filteredProjectsPaginatedProvider` en `projectsCombinedProvider`:
	- `ownerId` (via `sharedUsers`),
	- `requiredTags` (AND-semantiek),
	- `dueDateStart` en `dueDateEnd` (inclusieve grenzen).
- In-memory sortering geharmoniseerd met expliciete effective sort-resolutie (`filter.sortBy` met fallback).
- Provider-tests toegevoegd die bevestigen dat elk extra veld de resultaatset effectief beïnvloedt.

Prioriteit: Laag-Middel

Labels: `enhancement`, `area:providers`
