# 046-rate-limits-ui-per-operation

**Priority:** Medium

**Description:** Add UI for configuring per-operation rate limits and advanced rate limiting features.

**Acceptance Criteria:**
- [ ] Implement settings UI for per-operation rate limits in settings_screen.dart
- [ ] Make rate limits configurable (max requests per window)
- [ ] Add different rate limits for different AI operations
- [ ] Implement exponential backoff for rate limits
- [ ] Add request queuing for burst handling
- [ ] Update ai_rate_limits_config.dart with new configurations