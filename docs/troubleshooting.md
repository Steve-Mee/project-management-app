# Troubleshooting

## Fast Triage

1. Identify failing path (`compile`, `apply`, authentication, or UI state).
2. Capture request ID and timestamp.
3. Check feature flags and entitlement state.
4. Check gateway and runner health dashboards.
5. Verify storage and RLS policy access for affected user scope.

## Common Issues

### Mirror Compile Fails Immediately

Likely causes:

- Missing entitlement or permission
- Gateway auth rejection
- Invalid request shape

Actions:

- Confirm user permission and premium state
- Inspect structured error code
- Verify gateway bearer validation logs

### Apply Returns Conflict Or Replay Error

Likely causes:

- Reused idempotency key
- Stale processing claim not yet reclaimed

Actions:

- Retry with fresh operation context
- Check idempotency ledger state
- Validate stale-claim recovery behavior

### Runner Timeout Or Unreachable

Likely causes:

- Runner deployment issue
- Network or upstream saturation

Actions:

- Confirm runner health checks
- Check timeout ratio and queue depth
- Roll back runner revision when thresholds are breached

### Offline Queue Does Not Drain

Likely causes:

- Connectivity instability
- Circuit-breaker open state
- Persistent request validation failures

Actions:

- Inspect replay queue metrics
- Validate breaker reset conditions
- Review first-failure error payload for invalid requests

### Feature Flag Behavior Is Unexpected

Likely causes:

- Stale cache value
- Missing admin role claim for writes
- Incorrect flag key or type

Actions:

- Refresh flag provider state
- Verify `feature_flags` table value and `enabled` state
- Confirm JWT `app_metadata.role` for admin operations

## Evidence Checklist For Bug Reports

- Timestamp and timezone
- Request ID / trace ID
- User ID and project/task scope
- Error code and message
- Recent deploy/release reference
