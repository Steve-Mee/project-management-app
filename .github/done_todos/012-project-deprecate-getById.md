# Deprecate `ProjectsNotifier.getProjectById` in favor of `projectByIdProvider`

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/providers/project/project_providers.dart`

Beschrijving:
`getProjectById` wordt op meerdere plekken gebruikt, maar `projectByIdProvider` is efficiënter en consistent met Riverpod patterns.

Wat toe te voegen:
- Markeer `getProjectById` als deprecated met duidelijke migratierichtlijnen.
- Zoek en update interne callers naar `projectByIdProvider`.
- Voeg codemod of korte script toe om veelgebruikte gevallen te migreren.

Audit-opvolging uitgevoerd:
- Deprecatieboodschap uitgebreid met expliciete verwijderdoelversie (`Scheduled removal: v2.1.0`).
- Guard-test toegevoegd die borgt dat project-feature runtime code `projectByIdProvider` blijft gebruiken en geen nieuwe `projectsProvider.notifier.getProjectById(...)` calls introduceert.
- Belangrijkste runtimepad (`ProjectDetailScreen`) expliciet gevalideerd op family-provider gebruik.

Prioriteit: Middel

Labels: `refactor`, `breaking-change?`
