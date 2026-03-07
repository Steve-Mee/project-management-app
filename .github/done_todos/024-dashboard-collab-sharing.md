# Collaborative dashboard sharing

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/providers/dashboard/dashboard_providers.dart`

Beschrijving:
Ondersteuning voor delen van dashboards met permissies.

Wat toe te voegen:
- API endpoints/data-models voor gedeelde dashboards.
- Permissiechecks (view/edit) en invite-flow.
- Sync/logging en conflict-resolutie (basis).

Audit-opvolging uitgevoerd:
- Permissiehiërarchie toegevoegd via centrale helper: `edit` impliceert nu `view`.
- `hasPermission` gebruikt deze helper in plaats van exacte string-equality op permissie.
- Sharing-tests aangescherpt met expliciete hiërarchie-asserties (`edit -> view`, `view !-> edit`).

Prioriteit: Laag

Labels: `feature`, `area:dashboard`
