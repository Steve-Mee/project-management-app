# Error handling en logging toevoegen voor dashboard providers

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `lib/core/providers/dashboard_providers.dart`

Beschrijving:
Robuuste try/catch en telemetrie ontbreken op meerdere plekken.

Wat toe te voegen:
- Voeg `try/catch` rondom IO/DB bewerkingen en log errors met `AppLogger.error`.
- Voeg `AppLogger.event` voor belangrijke acties (create/update/delete).
- Voeg tests voor foutafhandeling.

Audit-opvolging uitgevoerd:
- Repositorylaag gehard in `packages/pma_core/lib/repository/impl/hive_dashboard_repository.dart`:
	- stille catches vervangen door `AppLogger.error` met context op fallback-paden,
	- `AppLogger.event` toegevoegd voor belangrijke mutaties (config/templates/requirements/shared dashboard),
	- bestaande fallback-semantiek (zoals `return []` of `return null`) behouden waar dat contractueel verwacht is.
- Bestaande provider failure-path tests blijven dekkend; repository regressie geverifieerd met `test/hive_dashboard_repository_test.dart`.

Prioriteit: Middel

Labels: `area:dashboard`, `reliability`
