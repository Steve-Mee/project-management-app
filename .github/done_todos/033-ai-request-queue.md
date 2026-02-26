# Request queuing voor AI burst handling

Bronbestand: `lib/core/providers/ai_chat_provider.dart`

Beschrijving:
Behandel bursts middels queue en worker zodat rate-limits niet direct errors veroorzaken voor gebruikers.

Wat toe te voegen:
- Queue implementatie (in-memory of persistent) met background worker die requests pusht volgens limiter.
- Metrics en retries.

Prioriteit: Middel

Labels: `area:ai`, `feature`