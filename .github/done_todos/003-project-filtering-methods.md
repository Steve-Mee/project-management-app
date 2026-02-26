# Voeg filtering-methoden toe aan project repository

Bronbestand: `lib/core/providers/project_providers.dart` (+ repository)

Beschrijving:
Momenteel is er alleen een `filteredProjectsProvider` die in-memory filtert. Voor schaalbaarheid moeten filter-eerst in de repository ondersteund worden.

Wat toe te voegen:
- Methoden in `IProjectRepository` zoals `Future<List<ProjectModel>> getProjectsByStatus(String status)` of een generic `getProjects({String? status, String? search, int? limit, int? offset})`.
- Implementeer die methoden in `ProjectRepository`.
- Pas providers aan om repository-filtering te gebruiken wanneer mogelijk.

Prioriteit: Middel

Labels: `area:repository`, `feature`, `performance`
