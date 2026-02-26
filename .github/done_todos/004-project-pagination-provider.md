# Paginated provider voor projecten

Bronbestand: `lib/core/providers/project_providers.dart`

Beschrijving:
UI-componenten moeten makkelijk paginatie kunnen opvragen zonder zelf repository-logic te dupliceren.

Wat toe te voegen:
- Voeg `paginatedProjectsProvider` (family) toe: `FutureProvider.family<List<ProjectModel>, PageRequest>`.
- Zorg dat provider valideert parameters en errors correct proxyt.
- Update documentatie/README met voorbeeldgebruik.

Prioriteit: Middel

Labels: `area:providers`, `feature`
