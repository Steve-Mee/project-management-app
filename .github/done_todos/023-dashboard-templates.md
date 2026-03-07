# Dashboard templates en preset layouts

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/providers/dashboard/dashboard_providers.dart`

Beschrijving:
Voorzie preset layouts en mogelijkheid om templates op te slaan en te laden.

Wat toe te voegen:
- Data model voor dashboard template.
- CRUD in repository/provider om templates te bewaren.
- UI om templates te selecteren en te beheren.

Audit-opvolging uitgevoerd:
- `saveAsTemplate` valideert nu template-naam op niet-leeg (`trim().isNotEmpty`).
- Duplicate template-namen worden nu geblokkeerd met case-insensitive vergelijking op genormaliseerde naam.
- Tests gealigneerd: lege naam en duplicate naam leveren nu `ArgumentError` op.

Prioriteit: Laag

Labels: `feature`, `area:dashboard`
