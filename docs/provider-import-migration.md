# Provider Import Migration

Dit document beschrijft canonieke importpaden voor providers en compatibiliteitspaden die gefaseerd worden uitgefaseerd.

## AI Providers

Canoniek:

- `package:pma_core/providers/ai/ai_chat_providers.dart`

Legacy/compat (alleen tijdelijk):

- `package:pma_core/providers/ai_legacy_providers.dart`
- `package:pma_core/providers/ai_chat_providers.dart` (historische barrel)

## Richtlijn

- Nieuwe code importeert altijd canonieke modulepaden.
- Compat-barrels blijven tijdelijk voor bestaande callsites.
- Bij refactors: vervang compat-imports eerst, verwijder compat-barrels pas als de codebase volledig gemigreerd is.
