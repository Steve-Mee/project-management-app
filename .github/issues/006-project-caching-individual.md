# Voeg caching toe voor individuele projecten

Bronbestand: `lib/core/providers/project_providers.dart`

Beschrijving:
`projectByIdProvider` haalt momenteel alle projecten en filtert, wat inefficiënt kan zijn.

Wat toe te voegen:
- Implementeer cache per project (TTL) of repo-methode `getProjectById` die direct toegang geeft.
- Overweeg `StateNotifier` of `AsyncValue` caching en invalidatie bij updates.

Prioriteit: Middel

Labels: `area:performance`, `area:providers`
