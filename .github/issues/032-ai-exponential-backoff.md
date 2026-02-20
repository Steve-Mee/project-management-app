# Voeg exponential backoff toe bij rate-limits

Bronbestand: `lib/core/providers/ai_chat_provider.dart`

Beschrijving:
Bij throttling is het verstandig om retry/backoff te implementeren.

Wat toe te voegen:
- Backoff-policy (exponential jitter) in retry-logica.
- Testen van retry-gedrag en observability (logging).

Prioriteit: Middel

Labels: `area:ai`, `reliability`