# 067-onboarding-flow

**Priority:** Medium

**Description:** Implement comprehensive onboarding flow for new users to improve first-time experience.

**Acceptance Criteria:**
- [x] DONE: First launch: wizard (welcome → create first project → AI intro → invite team)
- [x] DONE: Use shared_preferences + Riverpod flag

**Validation Notes (2026-03-07):**
- Added dedicated onboarding persistence tests in `test/onboarding_provider_test.dart`:
	- first launch defaults to true,
	- completion toggles state to false,
	- completion persists across ProviderContainer recreation.