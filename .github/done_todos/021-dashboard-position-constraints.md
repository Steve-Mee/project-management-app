# Position constraints en boundaries voor dashboard widgets

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/providers/dashboard/dashboard_providers.dart`

Beschrijving:
Zorg dat widgets binnen layout-bounding-boxen blijven en niet off-screen geplaatst worden.

Wat toe te voegen:
- Definieer minimale/maximale X/Y en minimale grootte.
- Pas drag/resize logica aan om constraints af te dwingen.
- Voeg tests voor edge cases.

Audit-opvolging uitgevoerd:
- `_clampPosition` hardening toegevoegd voor extreme invoer: width/height worden nu begrensd op containergrootte.
- Na overflow-correcties worden `x`/`y` opnieuw defensief geclamped naar `>= 0` om negatieve posities te voorkomen.
- Regressietest toegevoegd voor case `width > containerWidth` en `height > containerHeight`.

Prioriteit: Middel

Labels: `area:dashboard`, `ux`
