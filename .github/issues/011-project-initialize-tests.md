# Verwijderen/aanpassen van `ProjectsNotifier.initialize()` test-compatibiliteit

Bronbestand: `lib/core/providers/project_providers.dart`

Beschrijving:
`ProjectsNotifier.initialize()` is momenteel aanwezig vanwege oude tests; wanneer tests worden bijgewerkt kan deze methode verwijderd of gemarkeerd worden als legacy.

Wat toe te voegen/aanpassen:
- Scan tests die `initialize()` aanroepen en update die tests om `projectRepositoryProvider` te mocken of `ref.read(...).initialize()` te gebruiken.
- Markeer `initialize()` met `@visibleForTesting` of plan verwijdering en noteer breaking change.

Prioriteit: Laag

Labels: `testing`, `tech-debt`
