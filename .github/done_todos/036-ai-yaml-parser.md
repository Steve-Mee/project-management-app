# Implementeer YAML-parsing voor AI-parsers

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `lib/core/services/ai_parsers.dart`

Beschrijving:
YAML is een veelgebruikt formaat; ondersteuning verbetert flexibele input parsing.

Wat toe te voegen:
- Voeg `package:yaml` dependency en converter functies toe.
- Tests en documentatie voor YAML->internal model mapping.

Audit-opvolging uitgevoerd:
- YAML parserondersteuning staat in `packages/pma_core/lib/services/ai_parsers.dart` via `YamlAiParser` en `safeParseYaml(...)`.
- Parser extensiesysteem gebruikt YAML als first-class format via `ParserRegistry` + `parseAIResponse`.
- `package:yaml` dependency is aanwezig in root `pubspec.yaml` en `packages/pma_core/pubspec.yaml`.
- Testdekking in `test/ai_parsers_test.dart` dekt valide YAML, nested/list, fallback, malformed en lege input.

Prioriteit: Laag

Labels: `area:ai`, `feature`