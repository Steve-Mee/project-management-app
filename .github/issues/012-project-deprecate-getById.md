# Deprecate `ProjectsNotifier.getProjectById` in favor of `projectByIdProvider`

Bronbestand: `lib/core/providers/project_providers.dart`

Beschrijving:
`getProjectById` wordt op meerdere plekken gebruikt, maar `projectByIdProvider` is efficiënter en consistent met Riverpod patterns.

Wat toe te voegen:
- Markeer `getProjectById` als deprecated met duidelijke migratierichtlijnen.
- Zoek en update interne callers naar `projectByIdProvider`.
- Voeg codemod of korte script toe om veelgebruikte gevallen te migreren.

Prioriteit: Middel

Labels: `refactor`, `breaking-change?`
