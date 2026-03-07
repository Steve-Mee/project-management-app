# 001 - IProjectRepository interface extracted

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Datum: 2026-02-20

Beschrijving:
- De abstracte interface `IProjectRepository` is verplaatst naar een eigen bestand:
  [packages/pma_core/lib/repository/i_project_repository.dart](packages/pma_core/lib/repository/i_project_repository.dart)
- Methoden en signaturen zijn afgestemd op bestaande implementaties (met name
  `HiveProjectRepository`) zodat er geen breaking changes optreden. Belangrijke aanpassingen:
  - `metadata` parameter gebruikt `Map<String, Object?>?` consistent met implementatie.
  - Toegevoegd: `updateDirectoryPath`, `updatePlanJson`, `close`, en sharing helpers
    (`addSharedUser`, `removeSharedUser`, `addSharedGroup`, `removeSharedGroup`) omdat
    `ProjectRepository` deze already implementatie heeft en ze door providers en UI worden aangeroepen.
- De oude inline-definitie is verwijderd uit de providerlaag; de app gebruikt nu de interface
  via `projectRepositoryProvider` in
  [packages/pma_core/lib/providers/project/project_providers.dart](packages/pma_core/lib/providers/project/project_providers.dart).

Audit-opvolging uitgevoerd:
- Dubbele comments in interfacebestand verwijderd.
- Verouderde "future methods to consider" comments verwijderd omdat die methodes intussen bestaan.
- Contract-invariant tests toegevoegd voor status-filter consistentie en paginatie-gedrag.
- Korte architectuurnota toegevoegd waarom `IProjectRepository` in `pma_core` hoort.

Waarom:
- Maakt repository-implementaties swapbaar (Hive, Supabase, mocks voor tests) en
  vermindert file bloat in provider-bestand.

Bestanden gewijzigd:
- [packages/pma_core/lib/repository/i_project_repository.dart](packages/pma_core/lib/repository/i_project_repository.dart)
- [packages/pma_core/lib/providers/project/project_providers.dart](packages/pma_core/lib/providers/project/project_providers.dart)
- [test/project_repository_test.dart](test/project_repository_test.dart)
- [packages/pma_core/docs/project_repository_interface_decision.md](packages/pma_core/docs/project_repository_interface_decision.md)

Commit suggestie:
`feat: Extract IProjectRepository to separate interface file (resolves TODO in project_providers.dart)`

Volgende stappen (optioneel):
- Open PR met deze wijzigingen en voer `flutter analyze` & unit tests uit in CI.
- Voeg extra interface-methoden toe voor paginatie of filter-API indien gewenst.
