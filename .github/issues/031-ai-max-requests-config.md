# Maak max requests per window configureerbaar

Bronbestand: `lib/core/providers/ai_chat_provider.dart`

Beschrijving:
Exposeer instelling voor maximum requests per time window (vb. 10/min standaard).

Wat toe te voegen:
- Config entry en provider/setting.
- Gebruik deze waarde in de rate-limiter initialisatie.
- Tests voor respecteren van verschilende configuraties.

Prioriteit: Middel

Labels: `area:ai`, `config`
