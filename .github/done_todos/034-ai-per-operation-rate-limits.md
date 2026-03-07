# Per-operation rate limits voor AI

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `lib/core/providers/ai_chat_provider.dart`

Beschrijving:
Verschillende AI-operaties (chat, embeddings, file ops) hebben verschillende kosten en limieten.

Wat toe te voegen:
- Support voor het configureren van limieten per operatie.
- Pas de rate-limiter en queue aan om operation-based throttling toe te passen.

Audit-opvolging uitgevoerd:
- Actieve provider (`packages/pma_core/lib/providers/ai/ai_chat_providers.dart`) handhaaft nu operation-based throttling in queueverwerking via action-specifieke counters (`_operationRequestTimestamps`).
- Queue worker plant operation-specifieke backoff wanneer de voorste request-action zijn limiet bereikt (`ai_operation_rate_limited_backoff_scheduled`).
- Fallback naar globale windowlimiet (`maxRequestsPerWindow`) blijft actief voor onbekende operaties.
- Testdekking toegevoegd in `test/ai_operation_rate_limit_test.dart` voor:
	- operation-specifieke limieten,
	- fallback naar globale limiet,
	- onafhankelijke counters per operatie.

Prioriteit: Middel

Labels: `area:ai`, `design`
