# Async ophalen van instellingen in auth providers

Bronbestand: `lib/core/providers/auth_providers.dart`

Beschrijving:
Sommige plekken doen sync checks op settings; gebruik de async settings repository waar nodig.

Wat toe te voegen:
- Vervang sync checks met `await ref.read(settingsRepositoryProvider.future)` of geschikte pattern.
- Zorg voor juiste loading/error states in providers.

Prioriteit: Middel

Labels: `area:auth`, `bug`
