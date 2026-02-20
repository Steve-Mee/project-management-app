# Maak AI rate limits configureerbaar

Bronbestand: `lib/core/providers/ai_chat_provider.dart`

Beschrijving:
Harde limieten zijn niet flexibel; maak ze configureerbaar via settings of env.

Wat toe te voegen:
- Verplaats magic-nummers naar config (`ai_config` of `settingsRepository`).
- Voorzie fallback-waarden en validatie.

Prioriteit: Middel

Labels: `area:ai`, `config`
