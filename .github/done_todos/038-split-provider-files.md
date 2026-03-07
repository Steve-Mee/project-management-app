# Splits `providers.dart` en maak extra provider-bestanden

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/providers.dart`

Beschrijving:
`providers.dart` bevat een barrel en TODO suggereert extra providerbestanden zoals `task_providers.dart`, `notification_providers.dart`, `sync_providers.dart`, `analytics_providers.dart`.

Wat toe te voegen:
- Maak de genoemde provider-bestanden aan (indien relevant) en verplaats gerelateerde providers.
- Update `providers.dart` exports en documenteer de structuur.

Audit-opvolging uitgevoerd:
- Canonieke barrel staat op `packages/pma_core/lib/providers.dart` en exporteert `providers/index.dart`.
- Gevraagde providerbestanden bestaan als compat-barrels: `task_providers.dart`, `notification_providers.dart`, `sync_providers.dart`, `analytics_providers.dart`.
- De modulebestanden bestaan onder `packages/pma_core/lib/providers/task/`, `packages/pma_core/lib/providers/notification/`, `packages/pma_core/lib/providers/sync/`, `packages/pma_core/lib/providers/analytics/`.
- Structuur is gedocumenteerd via inline barrel comments en issue-referenties (`055-barrel-files-providers.md`).

Resterende cleanup (geen blocker voor TODO 038):
- Compat-barrels gefaseerd reduceren zodra alle interne imports op canonieke modulepaden staan.

Prioriteit: Laag

Labels: `refactor`, `area:providers`
