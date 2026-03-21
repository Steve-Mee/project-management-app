# Operations

## Scope

This runbook covers deployment, monitoring, incident response, and rollback for the app and Mirror runtime.

## Deployment Sequence

1. Apply and verify database migrations.
2. Deploy cloud runner and validate health checks.
3. Deploy `mirror-gateway` edge function.
4. Deploy clients.
5. Execute compile/apply smoke test.
6. Roll out with canary gates.

## Canary Gates

- Initial scope: 5% traffic, then 25%, then 100%
- Hold windows between each ramp
- Abort on availability or latency breach

Recommended stop conditions:

- Availability below 99.5% during canary hold
- Timeout ratio above 3% for 10 minutes
- Sustained P95 regression beyond SLO thresholds

## Monitoring

Required dashboards:

- Gateway health: traffic, success, latency, timeout ratio
- Runner health: CPU, memory, execution duration, failure ratio
- Resilience: replay queue depth, circuit-breaker transitions
- Security: auth denials, idempotency conflict rates

### Mirror Observability Taxonomy

Use distinct Mirror client telemetry events for latency triage:

- `mirror_compile_http_attempt_latency`: compile-only HTTP attempt latency.
- `mirror_apply_http_attempt_latency`: apply-only HTTP attempt latency.
- `mirror_http_attempt_latency`: aggregate HTTP attempt latency across compile/apply.

Required event fields:

- `schemaVersion` (current: `2`)
- `layer` (`client_gateway`)
- `stage` (`http_attempt`)
- `operation` (`compile` or `apply`)
- `outcome` (`success` or `failure`)
- `durationMs`, `attempt`, `mode`
- `requestId`, `traceId`, `idempotencyKey` (when available)

Operational query examples:

- Debug compile spikes quickly: filter on `mirror_compile_http_attempt_latency`.
- Debug apply spikes quickly: filter on `mirror_apply_http_attempt_latency`.
- Build total latency percentiles: use `mirror_http_attempt_latency`, then group by `operation`.

Gateway-side usage metering in `mirror_usage_logs` remains action-scoped via
`action` (`compile` or `apply`) and `duration_ms`.

## SLO Targets

Reference targets:

- Compile availability: 99.95% rolling 30 days
- Apply availability: 99.95% rolling 30 days
- Compile P95: <= 4s
- Apply P95: <= 5s

See [production-readiness.md](production-readiness.md) for release gate criteria.

## Incident Response

Roles:

- Incident Commander: coordination and timeline ownership
- Ops Lead: mitigation and rollback execution
- SME: technical diagnosis

First-response sequence:

1. Open incident channel and assign roles.
2. Identify affected path (`compile`, `apply`, or both).
3. Capture failing request IDs and error mix.
4. Contain by rollback or traffic shift.
5. Validate recovery with smoke tests and metrics stability.

## Rollback

Rollback order:

1. Runner image rollback
2. Edge function rollback
3. Client rollback or feature kill-switch
4. Post-rollback smoke and telemetry verification
