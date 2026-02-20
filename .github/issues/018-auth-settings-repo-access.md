# Gebruik `settingsRepositoryProvider.future` waar nodig

Bronbestand: `lib/core/providers/auth_providers.dart`

Beschrijving:
Sommige codepaths refereren settings synchronously; centraliseer het correcte asynchrone access-pattern.

Wat toe te voegen:
- Scan en vervang plekken met sync access door `await ref.read(settingsRepositoryProvider.future)`.
- Voeg korte code-examples en tests.

Prioriteit: Middel

Labels: `area:auth`, `refactor`
