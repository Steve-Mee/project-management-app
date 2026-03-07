# Login Rate Limit Policy

Source of truth: `packages/pma_core/lib/services/login_rate_limiter.dart`

Policy constants:
- `maxAttempts = 5`
- `windowSeconds = 60`
- `captchaThreshold = 3`
- Progressive lockout backoff durations: `30s`, `2m`, `10m` (capped)

Runtime contract:
- `getAttemptCount(email)` returns the current failed-attempt count in the sliding window.
- `shouldRequireCaptcha(email)` returns `true` when attempts are `>= captchaThreshold`.
- `getBackoffDuration(email)` returns a remaining lockout duration when blocked.
- `recordAttempt(email)` records failed logins and emits telemetry on policy exceed.
- `resetOnSuccess(email)` clears counters after successful authentication.

Auth integration:
- `AuthNotifier.login` should rely on limiter contract methods instead of hardcoded thresholds.
- Captcha checks should use `shouldRequireCaptcha(...)`.
- Block decisions should use `getBackoffDuration(...)`.
