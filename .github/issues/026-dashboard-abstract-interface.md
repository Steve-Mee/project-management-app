# Maak abstract interface voor dashboard data (testbaarheid)

Bronbestand: `lib/core/providers/dashboard_providers.dart`

Beschrijving:
Splits implementatie en interface zodat we mock repositories in tests kunnen gebruiken.

Wat toe te voegen:
- `lib/core/repository/i_dashboard_repository.dart` met CRUD-methoden.
- Hernoem concrete implementatie en update providers om interface te leveren.

Prioriteit: Middel

Labels: `refactor`, `area:dashboard`
