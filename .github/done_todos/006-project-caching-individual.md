# Voeg caching toe voor individuele projecten

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/providers/project/project_providers.dart`

Beschrijving:
`projectByIdProvider` haalt momenteel alle projecten en filtert, wat inefficiënt kan zijn.

Wat toe te voegen:
- Implementeer cache per project (TTL) of repo-methode `getProjectById` die direct toegang geeft.
- Overweeg `StateNotifier` of `AsyncValue` caching en invalidatie bij updates.

Audit-opvolging uitgevoerd:
- Read-through/write-through TTL-cache toegevoegd voor `projectByIdProvider` met configureerbare TTL-provider (`projectByIdCacheTtlProvider`).
- Cache-status expliciet gemaakt via `projectIsCachedProvider`; UI gebruikt nu deze status i.p.v. een los cacheobject.
- Mutatiepaden in `ProjectsNotifier` invalidëren nu gericht `projectByIdProvider` en cache-state voor het betrokken project-id (`updateProject`, `deleteProject`, `updateTasks`, `updateProgress`, plus gerelateerde updates).
- Provider-tests toegevoegd voor cache-hit na provider-invalidate, TTL-expiratie en cache-invalidatie na mutatie.

Prioriteit: Middel

Labels: `area:performance`, `area:providers`
