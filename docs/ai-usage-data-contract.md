# AI Usage Data Contract

Dit document legt de source-of-truth afspraken vast voor AI usage data.

## Scope

Betrokken lagen:

- `packages/pma_core/lib/providers/ai/ai_usage_providers.dart`
- `packages/pma_core/lib/repository/i_ai_usage_repository.dart`
- `packages/pma_core/lib/repository/impl/hive_ai_usage_repository.dart`

## Source-of-Truth Model

1. Supabase aggregate (`ai_usage`)
- Doel: account-level quota en high-level token usage per user.
- Gebruik: `aiUsageProvider`, `aiUsageUpdateProvider`.
- Semantiek: operationele limieten en snel overzicht per account.

2. Lokale history (Hive `AiUsageRecord`)
- Doel: gedetailleerde request history (operation, success/failure, input/output tokens, kosteninschatting).
- Gebruik: history/analytics providers zoals `aiUsageHistoryProvider`, filters, export en grafiekberekeningen.
- Semantiek: detailanalyse, debugging, rapportering, CSV/JSON export.

## Contractregels

- Gebruik Supabase aggregate als autoritatieve bron voor quota/billing-achtige totalen op accountniveau.
- Gebruik lokale Hive-history als autoritatieve bron voor detailtijdlijnen en operationele breakdowns.
- Vermijd impliciete mix van beide bronnen binnen 1 metric zonder expliciete documentatie.
- Bij afwijkingen:
  - UI toont detail op basis van Hive-history.
  - Quota/limietindicatoren blijven Supabase-gedreven.

## Implementatierichtlijnen

- Nieuwe AI usage metric toevoegen?
  1. Kies eerst aggregate (Supabase) of detail (Hive) als primaire bron.
  2. Documenteer de keuze in dit bestand.
  3. Voeg gerichte tests toe op het gekozen providerpad.

- Exportfunctionaliteit:
  - Gebaseerd op Hive-history records.

- Subscription/limietlogica:
  - Gebaseerd op Supabase aggregate + settings/subscription context.

## Non-goals

- Dit contract definieert geen live prijsbron per model.
- Dit contract vervangt geen privacy/compliance beleid; het beschrijft alleen databron-eigenaarschap.
