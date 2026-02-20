# Verplaats `IProjectRepository` naar aparte file

Bronbestand: `lib/core/providers/project_providers.dart`

Beschrijving:
De interface `IProjectRepository` staat momenteel in `project_providers.dart`. Dit maakt repository-implementaties minder duidelijk en polluteert de provider barrel.

Wat toe te voegen:
- Maak een nieuwe interface-file `lib/core/repository/i_project_repository.dart` met de `IProjectRepository` definitie.
- Update `ProjectRepository` en alle gebruikspunten om die interface te importeren van de nieuwe locatie.
- Update `lib/core/providers/project_providers.dart` om `projectRepositoryProvider` te blijven leveren maar te importeren vanaf de nieuwe interface/implementatie.

Prioriteit: Hoog

Labels (suggestie): `area:repository`, `refactor`, `tech-debt`
