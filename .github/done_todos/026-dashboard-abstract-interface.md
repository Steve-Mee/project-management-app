# Maak abstract interface voor dashboard data (testbaarheid)

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `lib/core/providers/dashboard_providers.dart`

Beschrijving:
Splits implementatie en interface zodat we mock repositories in tests kunnen gebruiken.

Wat toe te voegen:
- `lib/core/repository/i_dashboard_repository.dart` met CRUD-methoden.
- Hernoem concrete implementatie en update providers om interface te leveren.

Audit-opvolging uitgevoerd:
- Interfacecontract bevestigd in `packages/pma_core/lib/repository/i_dashboard_repository.dart` en concrete implementatie in `packages/pma_core/lib/repository/impl/hive_dashboard_repository.dart`.
- Providerinjectie blijft interface-typed (`dashboardRepositoryProvider` levert `IDashboardRepository`) in `packages/pma_core/lib/providers/dashboard/dashboard_providers.dart`.
- Testbaarheid verdiept met contractgedrag-tests in `test/hive_dashboard_repository_test.dart`:
	- `saveTemplates`/`loadTemplates` roundtrip,
	- `saveLocalSharedDashboard`/`loadLocalSharedDashboard` roundtrip.

Prioriteit: Middel

Labels: `refactor`, `area:dashboard`
