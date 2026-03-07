# Offline opslag voor requirements (Hive)

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `lib/core/providers/dashboard_providers.dart`

Beschrijving:
Sla requirements lokaal op en sync bij netwerkbeschikbaarheid.

Wat toe te voegen:
- Hive model en repository methods voor requirements.
- Sync-logic bij connectiviteit.
- Tests en migratiepad.

Audit-opvolging uitgevoerd:
- Offline queue-replay geimplementeerd in `packages/pma_core/lib/repository/impl/hive_dashboard_repository.dart`:
	- `processPendingSync()` verwerkt queued requirement changes per item i.p.v. blind queue-leegmaken,
	- mislukte of unsupported changes blijven in de queue voor latere retry,
	- succesvolle verwerking wordt gelogd met processed/remaining metadata.
- Provider gebruikt bestaande connectiviteitstrigger (`wasOffline && !_isOffline`) om sync te starten bij online herstel in `packages/pma_core/lib/providers/dashboard/dashboard_providers.dart`.
- Tests uitgebreid in `test/hive_dashboard_repository_test.dart` voor:
	- replay van `save_requirement` naar lokale requirements-opslag,
	- behoud van unsupported queue-items na sync-run.

Prioriteit: Laag

Labels: `feature`, `area:dashboard`