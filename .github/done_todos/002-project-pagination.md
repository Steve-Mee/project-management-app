# Voeg paginatie API toe voor projecten

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/providers/project/project_providers.dart` (+ repository)

Beschrijving:
Voor grote datasets is het handig om paginatie te ondersteunen zodat UI en netwerkverkeer beheersbaar blijven.

Wat toe te voegen:
- Definieer in `IProjectRepository` een methode `Future<List<ProjectModel>> getProjectsPaginated(int page, int limit)`.
- Implementeer deze methode in `HiveProjectRepository` (Hive-backed) en zorg voor edge-case handling.
- Voeg een `paginatedProjectsProvider` of family provider toe die pagina/limit accepteert.

Audit-opvolging uitgevoerd:
- Input-validatie toegevoegd (`page >= 1`, `limit > 0`) in `getProjectsPaginated`.
- Deterministische sortering toegevoegd vóór paginatie (naam case-insensitive, daarna id).
- Extra tests toegevoegd voor edge cases:
	- ongeldige `page/limit`,
	- lege dataset,
	- filter + paginatie combinatie.

Prioriteit: Middel

Labels (suggestie): `feature`, `area:repository`, `performance`
