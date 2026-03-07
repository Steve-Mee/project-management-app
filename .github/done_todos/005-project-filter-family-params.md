# Voeg filter-/sort-parameters toe aan providers (family)

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/providers/project/project_providers.dart`

Beschrijving:
`filteredProjectsProvider` is nu minimal; maak een uitbreidbare family die filters en sortering accepteert.

Wat toe te voegen:
- Breid `ProjectFilter` uit met extra velden (createdAt-range, owner, tags, sortBy).
- Maak `filteredProjectsProvider` een family die deze `ProjectFilter` accepteert.
- Zorg dat filtering in repository wordt uitgevoerd wanneer mogelijk.

Audit-opvolging uitgevoerd:
- Type-bridge patroon toegevoegd tussen providerfilter (`ProjectFilter`) en repositoryfilter (`models.ProjectFilter`) via `toRepositoryFilter()`.
- Bridge consequent toegepast in gecombineerde/gefiterde providerpaden om typeverwarring en drift te reduceren.
- Sort fallback in gecombineerde provider deterministisch gemaakt (naam -> id) om paginatie/sort-volgorde stabiel te houden.
- Provider-tests toegevoegd voor bridge-gedrag.

Prioriteit: Middel

Labels: `area:providers`, `feature`
