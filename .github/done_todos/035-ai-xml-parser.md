# Implementeer XML-parsing voor AI-parsers

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

Bronbestand: `lib/core/services/ai_parsers.dart`

Beschrijving:
Sommige AI-output of importformaten kunnen XML bevatten; support toevoegen verbreedt compatibiliteit.

Wat toe te voegen:
- Voeg `package:xml` dependency en parser-adapters toe.
- Voeg tests met voorbeeld-XML inputs en expected outputs.

Audit-opvolging uitgevoerd:
- XML parsing staat in `packages/pma_core/lib/services/ai_parsers.dart` met `XmlAiParser`, `safeParseXml(...)`, RegExp-fallback en integratie in `ParserRegistry`/`parseAIResponse`.
- XML dependency is aanwezig in zowel root `pubspec.yaml` als `packages/pma_core/pubspec.yaml`.
- Testdekking in `test/ai_parsers_test.dart` dekt:
	- valide XML,
	- attributes en nesting,
	- mixed-text fallback parsing,
	- malformed/empty/invalid input paden.

Prioriteit: Laag-Middel

Labels: `area:ai`, `feature`