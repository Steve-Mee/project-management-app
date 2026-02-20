# Position constraints en boundaries voor dashboard widgets

Bronbestand: `lib/core/providers/dashboard_providers.dart`

Beschrijving:
Zorg dat widgets binnen layout-bounding-boxen blijven en niet off-screen geplaatst worden.

Wat toe te voegen:
- Definieer minimale/maximale X/Y en minimale grootte.
- Pas drag/resize logica aan om constraints af te dwingen.
- Voeg tests voor edge cases.

Prioriteit: Middel

Labels: `area:dashboard`, `ux`
