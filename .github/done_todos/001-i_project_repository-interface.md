# 001 - IProjectRepository interface extracted

Status: Voltooid

Datum: 2026-02-20

Beschrijving:
- De abstracte interface `IProjectRepository` is verplaatst naar een eigen bestand:
  [lib/core/repository/i_project_repository.dart](lib/core/repository/i_project_repository.dart)
- Methoden en signaturen zijn afgestemd op bestaande implementaties (met name
  `ProjectRepository`) zodat er geen breaking changes optreden. Belangrijke aanpassingen:
  - `metadata` parameter gebruikt `Map<String, Object?>?` consistent met implementatie.
  - Toegevoegd: `updateDirectoryPath`, `updatePlanJson`, `close`, en sharing helpers
    (`addSharedUser`, `removeSharedUser`, `addSharedGroup`, `removeSharedGroup`) omdat
    `ProjectRepository` deze already implementatie heeft en ze door providers en UI worden aangeroepen.
- De oude inline-definitie is verwijderd uit `lib/core/providers/project_providers.dart` en
  dat bestand importeert nu de nieuwe interface.

Waarom:
- Maakt repository-implementaties swapbaar (Hive, Supabase, mocks voor tests) en
  vermindert file bloat in provider-bestand.

Bestanden gewijzigd:
- [lib/core/repository/i_project_repository.dart](lib/core/repository/i_project_repository.dart)
- [lib/core/providers/project_providers.dart](lib/core/providers/project_providers.dart)

Commit suggestie:
`feat: Extract IProjectRepository to separate interface file (resolves TODO in project_providers.dart)`

Volgende stappen (optioneel):
- Open PR met deze wijzigingen en voer `flutter analyze` & unit tests uit in CI.
- Voeg extra interface-methoden toe voor paginatie of filter-API indien gewenst.
