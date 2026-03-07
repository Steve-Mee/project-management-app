# Efficient `getProjectById` implementatie

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/providers/project/project_providers.dart` en `packages/pma_core/lib/repository/impl/hive_project_repository.dart`

Beschrijving:
Maak `getProjectById` efficiënt zodat UI direct een enkel project kan ophalen zonder `getAllProjects` te scannen.

Wat toe te voegen:
- Voeg efficiënte `Future<ProjectModel> getProjectById(String id)` implementatie in repository toe die direct de Hive key/layout gebruikt.
- Update interface en providers om hiervan gebruik te maken.

Audit-opvolging uitgevoerd:
- Contract geharmoniseerd op throwing behavior: `getProjectById` retourneert `ProjectModel` en gooit exception bij ontbrekend project-id.
- Interface- en implementatie-comments verduidelijkt om nullable/throwing ambiguiteit weg te nemen.
- Provider/UI foutpad getest via widget test die not-found uit `projectByIdProvider` valideert en consistente foutweergave afdwingt.

Prioriteit: Hoog

Labels: `area:repository`, `performance`
