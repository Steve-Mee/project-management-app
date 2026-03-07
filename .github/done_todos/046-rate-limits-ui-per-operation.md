# 046-rate-limits-ui-per-operation

**Priority:** Medium

**Description:** Add UI for configuring per-operation rate limits and advanced rate limiting features.

**Acceptance Criteria:**
- [x] DONE: Implement settings UI for per-operation rate limits in settings_screen.dart
- [x] DONE: Make rate limits configurable (max requests per window)
- [x] DONE: Add different rate limits for different AI operations
- [x] DONE: Implement exponential backoff for rate limits
- [x] DONE: Add request queuing for burst handling
- [x] DONE: Update ai_rate_limits_config.dart with new configurations

**Verification Notes:**
- `AiChatNotifier` now listens to `aiRateLimitsConfigProvider` and reapplies runtime limits when settings change.
- Added integration proof in `test/ai_rate_limits_runtime_sync_test.dart` to verify settings updates change active `aiChatProvider` limit behavior.