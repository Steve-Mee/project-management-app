# Mirror Operational Runbook

## Purpose

This runbook is the operator-facing reference for deploying, validating, rolling back, and debugging Mirror in production-like environments.

Use this together with:
- [operations.md](operations.md)
- [production-readiness.md](production-readiness.md)
- [security.md](security.md)
- [troubleshooting.md](troubleshooting.md)

## System Scope

Mirror production runtime is split across four layers:
- Flutter client app
- Supabase edge function `supabase/functions/mirror-gateway`
- Cloud runner `server/mirror-cloud-runner`
- Local runner `server/mirror-local-runner`

Architecture lock:
- `mirror-gateway` is a thin proxy only.
- Compute executes on approved runner services, not inside the edge function.

## Environment Variables And Secrets

### Flutter client

Required in app runtime:
- `SUPABASE_URL`: loaded by [lib/core/config/app_config.dart](../lib/core/config/app_config.dart)
- `SUPABASE_ANON_KEY`: loaded by [lib/core/config/app_config.dart](../lib/core/config/app_config.dart)

Optional app configuration:
- `OPENAI_API_KEY`
- `OPENAI_BASE_URL`
- `STRIPE_PUBLISHABLE_KEY`
- `STRIPE_SECRET_KEY`
- `SENTRY_DSN`
- `LOG_LEVEL`
- `FIREBASE_API_KEY`

Operational note:
- Debug builds read `.env` via `flutter_dotenv`.
- Release builds first try secure storage for `SUPABASE_URL` and `SUPABASE_ANON_KEY`, then fall back to dotenv if storage is empty.

### Gateway edge function

Required in `supabase/functions/mirror-gateway` runtime:
- `SUPABASE_URL`: required by [middleware.ts](../supabase/functions/mirror-gateway/modules/middleware.ts)
- `SUPABASE_ANON_KEY`: required by [middleware.ts](../supabase/functions/mirror-gateway/modules/middleware.ts)
- `PRIVATE_COMPUTE_ENDPOINT`: private-mode upstream endpoint from [routing_identity.ts](../supabase/functions/mirror-gateway/modules/routing_identity.ts)
- `FLY_MIRROR_BACKEND_ENDPOINT`: cloud-mode upstream endpoint from [routing_identity.ts](../supabase/functions/mirror-gateway/modules/routing_identity.ts)

Optional gateway control knobs:
- `MIRROR_IDEMPOTENCY_TTL_SECONDS`
- `MIRROR_FORWARD_TIMEOUT_MS`
- `MIRROR_GATEWAY_CIRCUIT_BREAKER_FAILURE_THRESHOLD`
- `MIRROR_GATEWAY_CIRCUIT_BREAKER_OPEN_SECONDS`
- `MIRROR_GATEWAY_RATE_LIMIT_REQUESTS_PER_MINUTE`
- `MIRROR_GATEWAY_RATE_LIMIT_BURST`
- `MIRROR_GATEWAY_RATE_LIMIT_BURST_WINDOW_SECONDS`
- `MIRROR_GATEWAY_RATE_LIMIT_ACTION_WEIGHT_APPLY`
- `MIRROR_GATEWAY_RATE_LIMIT_ACTION_WEIGHT_COMPILE`
- `MIRROR_GATEWAY_RATE_LIMIT_WEIGHTED_UNITS_PER_MINUTE`
- `MIRROR_GATEWAY_RATE_LIMIT_WEIGHTED_UNITS_BURST`
- `MIRROR_CLOUD_GATEWAY_URL`
- `MIRROR_LOCAL_GATEWAY_URL`

### Cloud runner

Required in `server/mirror-cloud-runner` runtime:
- `SIGNED_URL_SECRET`
- `MIRROR_SERVICE_TOKEN`
- `MIRROR_JWT_SECRET`
- `ARTIFACT_BASE_URL`

Optional cloud runner configuration:
- `PORT`: defaults to `8080`
- `GRPC_PORT`: defaults to `50051`
- `MIRROR_WORKSPACE_ROOT`: defaults to `/tmp/mirror-workspaces`
- `MIRROR_JWT_KEYS_BY_KID`
- `MIRROR_JWT_AUDIENCE`
- `MIRROR_JWT_ISSUER`
- `MIRROR_MAX_FILES`
- `MIRROR_MAX_WORKSPACE_BYTES`
- `MIRROR_MAX_EXECUTION_WINDOW_SECONDS`

Fly.io baseline from [server/mirror-cloud-runner/fly.toml](../server/mirror-cloud-runner/fly.toml):
- `PORT=8080`
- `MIRROR_WORKSPACE_ROOT=/tmp/mirror-workspaces`
- persistent mount at `/tmp/mirror-workspaces`

### Local runner

Required in `server/mirror-local-runner` runtime:
- `SIGNED_URL_SECRET`
- `MIRROR_SERVICE_TOKEN`
- `MIRROR_JWT_SECRET`
- `ARTIFACT_BASE_URL`

Optional local runner configuration:
- `PORT`: defaults to `50051`
- `HTTP_PORT`: defaults to `8080`
- `MIRROR_BIND_ADDRESS`: defaults to `127.0.0.1`
- `MIRROR_WORKSPACE_ROOT`: defaults to `/tmp/mirror-local-workspaces`
- `MIRROR_AUTH_GUARD_ENABLED`: must remain `true`
- `MIRROR_JWT_KEYS_BY_KID`
- `MIRROR_JWT_AUDIENCE`
- `MIRROR_JWT_ISSUER`
- `MIRROR_MAX_FILES`
- `MIRROR_MAX_WORKSPACE_BYTES`
- `MIRROR_MAX_EXECUTION_WINDOW_SECONDS`

Docker Compose baseline from [server/mirror-local-runner/docker-compose.yml](../server/mirror-local-runner/docker-compose.yml):
- gRPC bound on `127.0.0.1:50051`
- HTTP gateway bound on `127.0.0.1:8080`
- workspace volume `mirror_local_workspace`

### Secret management rules

Use this split:
- Local development: `.env` and Docker Compose environment file, never committed
- Supabase edge function: project secrets via Supabase secret management
- Fly.io cloud runner: `fly secrets set ...`
- Client release builds: secure storage bootstrap for client-facing Supabase values, never service tokens

Never place these in client artifacts:
- `MIRROR_SERVICE_TOKEN`
- `SIGNED_URL_SECRET`
- `MIRROR_JWT_SECRET`
- `MIRROR_JWT_KEYS_BY_KID`

## Deployment Sequence

### Pre-deploy checks

1. Confirm `flutter analyze` and targeted Mirror tests are green.
2. Confirm gateway module tests and Supabase SQL contract tests are green.
3. Verify pending migrations and rollback notes.
4. Verify runtime secret inventory for gateway and runners.
5. Confirm canary owner and rollback owner.

### Deploy order

1. Apply database migrations.
2. Verify Mirror schema contracts.
3. Deploy cloud runner revision.
4. Validate runner health and auth.
5. Deploy `mirror-gateway` edge function.
6. Deploy Flutter clients.
7. Execute post-deploy smoke tests.
8. Start canary rollout.

### Suggested commands

Database and function deployment:
```bash
supabase db push
supabase functions deploy mirror-gateway
```

Cloud runner rollout:
```bash
cd server/mirror-cloud-runner
fly deploy
fly status
```

Local runner validation:
```bash
cd server/mirror-local-runner
docker compose up -d
docker compose ps
```

### Post-deploy smoke checks

Run these end-to-end checks:
- open Mirror on a permitted user account
- compile in private mode
- apply a small patch in private mode
- compile in cloud mode with premium-enabled account
- verify `mirror_usage_logs` receives compile/apply entries
- verify `mirror_apply_audit_events` receives apply entries
- verify request correlation IDs appear in client, gateway, and runner logs

### Rollback order

If a release must be reverted:
1. rollback runner revision first
2. rollback edge function second
3. disable or roll back client rollout third
4. if required, apply database rollback only when migration explicitly supports reversal
5. rerun compile/apply smoke tests after rollback

## Incident Response

### Timeout spike

Symptoms:
- `mirror_compile_http_attempt_latency` or `mirror_apply_http_attempt_latency` p95 spikes
- gateway timeout ratio above canary threshold
- runner backlog or saturation

Triage:
1. split by `operation=compile|apply`
2. compare gateway latency to runner latency
3. inspect queue depth and circuit-breaker events
4. inspect runner CPU, memory, and workspace pressure
5. verify `MIRROR_FORWARD_TIMEOUT_MS` was not changed unexpectedly

Mitigation:
- shift traffic off the newest runner revision
- reduce canary percentage or freeze rollout
- rollback runner image if runner saturation is new
- rollback gateway if timeout increase started with edge release

Exit criteria:
- timeout ratio back below 3% for 10 minutes
- p95 latency back inside SLO window
- compile/apply smoke tests green

### Auth denial surge

Symptoms:
- rise in unauthorized or permission-denied responses
- `has_cloud_mirror_access` failures for users who should pass
- runner auth denies from JWT/service token checks

Triage:
1. determine whether denials happen in client, gateway, or runner
2. inspect request IDs and structured error family
3. verify gateway has valid `SUPABASE_URL` and `SUPABASE_ANON_KEY`
4. verify runner secrets: `MIRROR_SERVICE_TOKEN`, `MIRROR_JWT_SECRET`, `MIRROR_JWT_KEYS_BY_KID`
5. verify `MIRROR_JWT_AUDIENCE` and `MIRROR_JWT_ISSUER` if configured
6. verify user entitlement and premium state

Mitigation:
- restore missing or rotated secrets
- rollback auth-related runner or gateway revisions
- if issue is entitlement-only, correct permission or premium data rather than rolling back infra

### Circuit breaker open

Symptoms:
- repeated `mirror_replay_circuit_breaker` events
- request path returns fast failures after upstream instability

Triage:
1. identify whether breaker opened due to cloud or private upstream path
2. confirm upstream endpoint health
3. inspect recent rate-limit and upstream error mix
4. verify `PRIVATE_COMPUTE_ENDPOINT` and `FLY_MIRROR_BACKEND_ENDPOINT`

Mitigation:
- recover or rollback upstream runner
- reduce traffic while upstream stabilizes
- only restart gateway after root cause is understood; do not use restarts as primary mitigation

## Cleanup Schedules

### Idempotency ledger

Code-verified controls:
- gateway TTL defaults through `MIRROR_IDEMPOTENCY_TTL_SECONDS`
- ledger rows store `expires_at`
- SQL contracts require index `idx_mirror_request_idempotency_expires_at`
- SQL contracts require function `cleanup_mirror_request_idempotency_expired`

Operational policy:
- schedule `cleanup_mirror_request_idempotency_expired()` via `pg_cron`
- recommended cadence: every 15 minutes in staging and production
- alert if expired-row count grows between cleanup runs

Manual verification query:
```sql
select count(*) as expired_rows
from public.mirror_request_idempotency
where expires_at < now();
```

Manual cleanup:
```sql
select public.cleanup_mirror_request_idempotency_expired();
```

### Storage artifacts

Code-verified controls:
- storage buckets: `mirror-signed-inputs`, `mirror-backups`
- SQL contracts require function `cleanup_mirror_storage_objects`
- signed artifact URLs created by the client service default to 120 seconds TTL

Operational policy:
- keep signed URL TTL short
- run storage cleanup daily for stale object paths
- retain backup objects only as long as audit and rollback requirements need them

Manual cleanup:
```sql
select public.cleanup_mirror_storage_objects();
```

Note:
- older planning docs mention 7-day artifact retention. Current code verifies short-lived signed URLs and cleanup-function presence, but not a hardcoded 7-day object-retention constant. Treat bucket-retention duration as an environment policy that must be confirmed during deployment review.

## Entitlement Debugging Guide

### Permission check

Primary question:
- does the user have `use_mirror` access in the current environment?

Check in application/admin tooling:
- inspect the effective role/permission assignment for the user
- verify feature-flag state if launch is gated by flag

### Premium and cloud access check

For cloud-mode failures:
1. verify the user is authenticated
2. verify premium entitlement in the billing/admin system
3. verify gateway RPC `has_cloud_mirror_access` succeeds for the user
4. verify route guard and resolved mode are not degraded by policy

### Feature flag check

Validate in Supabase admin dashboard:
- target flag row exists in `feature_flags`
- `enabled` state is correct
- environment-specific overrides are correct
- admin writes were performed by an allowed admin role

### Evidence to collect before escalation

Collect:
- request ID
- trace ID
- user ID
- project ID
- task ID
- failing mode (`private` or `cloud`)
- error family and message
- recent deploy reference

## Operator Checklist

Before closing an incident or change window, confirm:
- smoke tests pass for compile and apply
- logs show end-to-end request correlation
- usage and apply audit tables record fresh entries
- no growing expired idempotency backlog
- no unexpected auth-denial surge remains
- rollback path is documented for the released revision
