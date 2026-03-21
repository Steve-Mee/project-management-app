# Production Readiness

## Purpose

This checklist is the release gate for production deployment of app and Mirror changes. All gates must be marked complete before broad rollout.

Status legend:

- [ ] Not complete
- [x] Complete

## Architecture And Ownership

- [x] Mirror Gateway remains a thin proxy.
- [x] Compute runs only in approved runner services.
- [x] Canonical naming is enforced in code and docs.
- [x] Owner assignment exists for app, backend, SRE, and security.

## Database And Migration Safety

- [x] Migrations applied in staging.
- [x] Rollback plan exists for each schema change.
- [x] RLS and index verification completed post-migration.
- [x] Data retention jobs validated.

## Security Gates

- [x] Auth validation at gateway and backend boundaries.
- [x] Entitlement and permission gates verified in integration tests.
- [x] Idempotency claim/finalize ownership checks validated.
- [x] Signed URL TTL and path scoping verified.

## Contract Stability

- [x] `/compile` and `/apply` routes pass contract tests.
- [x] Structured errors include machine-readable codes.
- [x] Correlation headers (`x-request-id`, `x-trace-id`) propagate end to end.

## Reliability And Performance

- [x] SLO thresholds are met in staging baselines.
- [x] Timeout and retry policies are configured and tested.
- [x] Load and soak tests completed for expected traffic envelope.
- [x] Replay queue and breaker behavior validated.

## Client UX Readiness

- [x] Mode gating and premium behavior verified.
- [x] Degraded/offline states produce actionable user messaging.
- [x] Error mapping from backend to UI is deterministic.

## Observability

- [x] Dashboards and alert routes are configured.
- [x] Severity thresholds are documented and page on-call correctly.
- [x] Logs can trace a request across client, gateway, and runner.

## Deployment Readiness

- [x] Canary plan defined with explicit abort criteria.
- [x] Rollback rehearsal completed.
- [x] Post-deploy validation checklist available and assigned.

## Final Gate

Release is approved only when all checklist items above are complete and approvals are recorded for Backend, Flutter, SRE, and Security.
