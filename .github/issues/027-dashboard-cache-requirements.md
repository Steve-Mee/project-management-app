# Cache `requirements` data met TTL

Bronbestand: `lib/core/providers/dashboard_providers.dart`

Beschrijving:
Requirements kunnen relatief statisch zijn; cache ze met TTL voor performance.

Wat toe te voegen:
- Implementatie in provider met `_CacheEntry<T>` soort patroon.
- Invalideer cache bij update of na TTL.

Prioriteit: Laag-Middel

Labels: `performance`, `area:dashboard`