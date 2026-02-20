# Efficient `getProjectById` implementatie

Bronbestand: `lib/core/providers/project_providers.dart` en `lib/core/repository/project_repository.dart`

Beschrijving:
Maak `getProjectById` efficiënt zodat UI direct een enkel project kan ophalen zonder `getAllProjects` te scannen.

Wat toe te voegen:
- Voeg `Future<ProjectModel?> getProjectById(String id)` implementatie in repository die direct de Hive key/layout gebruikt.
- Update interface en providers om hiervan gebruik te maken.

Prioriteit: Hoog

Labels: `area:repository`, `performance`
