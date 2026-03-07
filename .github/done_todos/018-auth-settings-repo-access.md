# Gebruik `settingsRepositoryProvider.future` waar nodig

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `packages/pma_core/lib/providers/auth/auth_providers.dart`

Beschrijving:
Sommige codepaths refereren settings synchronously; centraliseer het correcte asynchrone access-pattern.

Wat toe te voegen:
- Scan en vervang plekken met sync access door `await ref.read(settingsRepositoryProvider.future)`.
- Voeg korte code-examples en tests.

Audit-opvolging uitgevoerd:
- Auth settings callsites zijn gestandaardiseerd op `await ref.read(settingsRepositoryProvider.future)` voor imperatieve async paden.
- Engineering note toegevoegd met expliciet `read` vs `watch` gebruiksbeleid.
- Guard-test uitgebreid om regressie naar `ref.watch(settingsRepositoryProvider.future)` in auth providers te blokkeren.

Prioriteit: Middel

Labels: `area:auth`, `refactor`
