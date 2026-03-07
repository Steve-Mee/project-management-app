# 041-ai-usage-analytics-improvement

Status: Voltooid

Afgewerkt na audit-opvolging: 2026-03-07

**Priority:** Medium

**Description:** Improve AI usage analytics with history tracking, filtering, and export capabilities.

**Acceptance Criteria:**
- [x] DONE: Implement usage history tracking in ai_usage_provider.dart
- [x] DONE: Add filtering capabilities to analytics_providers.dart
- [x] DONE: Implement CSV export functionality for usage data
- [x] DONE: Update both AI usage providers with new features
- [x] DONE: Add usage metrics expansion areas in ai_usage_screen.dart
- [x] DONE: Use actual pricing from AI provider in ai_chat_provider.dart
- [x] DONE: Extract projectId from payload in usage logging
- [x] DONE: Use promptOverride and projectId in future AI call enhancements

Audit-opvolging uitgevoerd:
- Filtering endpoint uitgebreid met `aiUsageFilteredHistoryProvider` op basis van typed filter (`from`, `to`, `userId`, `projectId`) in `packages/pma_core/lib/providers/ai/ai_usage_providers.dart`.
- `AiUsageNotifier` exposeert nu expliciet `getHistory(...)` voor repository-backed history queries met filters.
- Testdekking uitgebreid in `test/ai_usage_provider_test.dart` voor notifier history filtering en filtered family provider gedrag.
- Bestaande CSV/JSON export en per-user/per-project aggregaties blijven intact en gevalideerd.

Resterende hardening (geen blocker voor TODO 041):
- Pricing source-of-truth verder expliciteren zodat `estimatedCost` uniform herleidbaar is naar provider/model configuratie.
- UI-uitbreiding van `AIUsageScreen` naar rijkere analytics-weergave kan apart opgepakt worden.