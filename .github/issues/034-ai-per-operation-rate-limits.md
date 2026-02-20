# Per-operation rate limits voor AI

Bronbestand: `lib/core/providers/ai_chat_provider.dart`

Beschrijving:
Verschillende AI-operaties (chat, embeddings, file ops) hebben verschillende kosten en limieten.

Wat toe te voegen:
- Support voor het configureren van limieten per operatie.
- Pas de rate-limiter en queue aan om operation-based throttling toe te passen.

Prioriteit: Middel

Labels: `area:ai`, `design`
