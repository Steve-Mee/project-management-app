# Cache `requirements` data met TTL

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `lib/core/providers/dashboard_providers.dart`

Beschrijving:
Requirements kunnen relatief statisch zijn; cache ze met TTL voor performance.

Wat toe te voegen:
- Implementatie in provider met `_CacheEntry<T>` soort patroon.
- Invalideer cache bij update of na TTL.

Audit-opvolging uitgevoerd:
- TTL-cache voor requirements toegevoegd in `packages/pma_core/lib/repository/impl/hive_dashboard_repository.dart` via `_CacheEntry<ProjectRequirements>` per categorie.
- Cache-expiry geimplementeerd met configureerbare TTL (`requirementsCacheTTL`) en tijdbron (`nowProvider`) voor testbaarheid.
- Cache-invalidering toegevoegd bij `saveRequirement` en bij `clearCache`.
- Regressietests toegevoegd in `test/hive_dashboard_repository_test.dart` voor:
	- cache hit binnen TTL,
	- refetch na TTL-expiry,
	- invalidering na requirement-update.

Prioriteit: Laag-Middel

Labels: `performance`, `area:dashboard`