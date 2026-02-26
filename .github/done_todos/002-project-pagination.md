# Voeg paginatie API toe voor projecten

Bronbestand: `lib/core/providers/project_providers.dart` (+ repository)

Beschrijving:
Voor grote datasets is het handig om paginatie te ondersteunen zodat UI en netwerkverkeer beheersbaar blijven.

Wat toe te voegen:
- Definieer in `IProjectRepository` een methode `Future<List<ProjectModel>> getProjectsPaginated(int page, int limit)`.
- Implementeer deze methode in `ProjectRepository` (Hive-backed) en zorg voor edge-case handling.
- Voeg een `paginatedProjectsProvider` of family provider toe die pagina/limit accepteert.

Prioriteit: Middel

Labels (suggestie): `feature`, `area:repository`, `performance`
