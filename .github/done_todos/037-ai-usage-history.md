# Implement usage history tracking voor AI (tokens/requests)

Bronbestand: `lib/core/providers/ai/ai_usage_provider.dart`

Beschrijving:
Bewaar per gebruiker/project de tokens en requests history voor billing/monitoring/analytics.

Wat toe te voegen:
- Persistentie model (Hive or Supabase) voor usage records.
- Provider endpoints om history op te vragen en totalen te berekenen.
- Expose per-project en per-user metrics.

Prioriteit: Middel

Labels: `area:ai`, `analytics`