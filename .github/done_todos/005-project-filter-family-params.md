# Voeg filter-/sort-parameters toe aan providers (family)

Bronbestand: `lib/core/providers/project_providers.dart`

Beschrijving:
`filteredProjectsProvider` is nu minimal; maak een uitbreidbare family die filters en sortering accepteert.

Wat toe te voegen:
- Breid `ProjectFilter` uit met extra velden (createdAt-range, owner, tags, sortBy).
- Maak `filteredProjectsProvider` een family die deze `ProjectFilter` accepteert.
- Zorg dat filtering in repository wordt uitgevoerd wanneer mogelijk.

Prioriteit: Middel

Labels: `area:providers`, `feature`
