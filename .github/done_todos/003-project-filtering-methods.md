# Voeg filtering-methoden toe aan project repository

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/providers/project/project_providers.dart` (+ repository)

Beschrijving:
Momenteel is er alleen een `filteredProjectsProvider` die in-memory filtert. Voor schaalbaarheid moeten filter-eerst in de repository ondersteund worden.

Wat toe te voegen:
- Methoden in `IProjectRepository` zoals `Future<List<ProjectModel>> getProjectsByStatus(String status)` of een generic `getProjects({String? status, String? search, int? limit, int? offset})`.
- Implementeer die methoden in `HiveProjectRepository`.
- Pas providers aan om repository-filtering te gebruiken wanneer mogelijk.

Audit-opvolging uitgevoerd:
- Gedeelde filter-engine toegevoegd in repository zodat `getProjectsPaginated` en `getFilteredProjects` dezelfde filtersemantiek gebruiken.
- Repositoryfiltering geharmoniseerd voor status/search/priority/tags/startDate/endDate.
- Comment/documentatie in repository gealigneerd met feitelijk gedrag.
- Extra tests toegevoegd voor gecombineerde filtervelden en tag-zoekgedrag.

Prioriteit: Middel

Labels: `area:repository`, `feature`, `performance`
