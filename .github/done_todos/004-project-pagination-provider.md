# Paginated provider voor projecten

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/providers/project/project_providers.dart`

Beschrijving:
UI-componenten moeten makkelijk paginatie kunnen opvragen zonder zelf repository-logic te dupliceren.

Wat toe te voegen:
- Voeg `paginatedProjectsProvider` (family) toe: `FutureProvider.family<List<ProjectModel>, PageRequest>`.
- Zorg dat provider valideert parameters en errors correct proxyt.
- Update documentatie/README met voorbeeldgebruik.

Audit-opvolging uitgevoerd:
- Provider-validatie toegevoegd voor ongeldige paginatieparameters (`page >= 1`, `limit > 0`).
- Backward-compatible alias `paginatedProjectsProvider` toegevoegd met deprecatie naar de canonieke `projectsPaginatedProvider`.
- Gerichte provider-tests toegevoegd voor validatie, correcte slicing en alias-compatibiliteit.
- Documentatievoorbeelden uitgebreid met canonieke provider + deprecated alias.

Prioriteit: Middel

Labels: `area:providers`, `feature`
