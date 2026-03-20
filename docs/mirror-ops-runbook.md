// ARCHITECTURE LOCK: Mirror Gateway = thin proxy only. Compute always on Fly.io or local runner.
# Mirror Ops Runbook

## Scope
This runbook covers production operations for the Mirror compile/apply pipeline:
- Mirror Gateway `mirror-gateway` (thin proxy only) — Supabase Edge Function at `supabase/functions/mirror-gateway/`
- Dart cloud backend: `MirrorGatewayBackend` (`lib/features/mirror/mirror_gateway_backend.dart`)
- Cloud runner (`server/mirror-cloud-runner`)
- Supabase Storage buckets `mirror-signed-inputs` and `mirror-backups`

Flutter editor services (extracted from screen):
- `MirrorEditorRealtimeController` — owns Realtime channel subscription and dedup
- `MirrorEditorRunService` — owns run in-progress lifecycle
- `MirrorEditorOrchestrationService` — compile/apply pipeline

Canonical naming note:
- Use only `mirror-signed-inputs` and `mirror-backups`
- Do not use legacy/ambiguous bucket aliases

## Service Tier And Responsibilities

- Tier: Production-critical developer workflow service
- Primary owner: Mirror Backend team
- Supporting teams: Flutter Client, SRE, Security
- On-call handoff: SRE owns incident command, Mirror Backend owns remediation

Business impact assumptions:
- Compile/apply failures block user editing workflows.
- Prolonged degradation increases support tickets and release risk for users.

## Architecture Contract
Request flow:
1. Client calls `POST /functions/v1/mirror-gateway/compile` or `POST /functions/v1/mirror-gateway/apply`
2. Mirror Gateway validates bearer token via Supabase Auth
3. Mirror Gateway forwards request to mode-specific upstream endpoint (`private` or `cloud`)
4. Mirror Gateway returns upstream body and propagates `x-request-id` + `x-idempotency-key`

Storage contract:
- Object paths for Mirror artifacts must start with authenticated user id:
- `<auth.uid>/<projectId>/<taskId>/<backupId>/(input|backup)/<filePath>`
- RLS policies enforce `storage.foldername(name)[1] = auth.uid()::text`
- Bucket naming must follow `docs/mirror-bucket-contract.md`

Apply audit contract:
- Backend apply events are written to `public.mirror_apply_audit_events`
- Required fields include actor (`actor_user_id`), artifact ids (`artifact_ids`/`backup_id`), and fingerprints (`file_set_fingerprint`, `applied_files_fingerprint`, `diff_fingerprint`)

## Required Environment Variables
Mirror Gateway function:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `PRIVATE_COMPUTE_ENDPOINT`
- Cloud upstream endpoint environment variable (mode=`cloud`)
- `MIRROR_FORWARD_TIMEOUT_MS` (optional, default 20000)

Cloud runner:
- `MIRROR_SERVICE_TOKEN`
- `MIRROR_JWT_SECRET` (legacy/fallback)
- `MIRROR_JWT_KEYS_BY_KID` (JSON map for key rotation)
- `MIRROR_MAX_FILES` (optional, default 500)
- `MIRROR_MAX_WORKSPACE_BYTES` (optional, default 52428800)
- `MIRROR_MAX_EXECUTION_WINDOW_SECONDS` (optional, default 300)

Local runner:
- `MIRROR_SERVICE_TOKEN`
- `MIRROR_JWT_SECRET` (legacy/fallback)
- `MIRROR_JWT_KEYS_BY_KID` (JSON map for key rotation)
- `MIRROR_MAX_FILES` (optional, default 500)
- `MIRROR_MAX_WORKSPACE_BYTES` (optional, default 52428800)
- `MIRROR_MAX_EXECUTION_WINDOW_SECONDS` (optional, default 300)

AB/remote-config contract:
- Experiment key: `mirror_runner_mode` (`local` vs `cloud`)
- Feature-flag keys:
- `mirror_runner_mode`
- `mirror_runner_quota_max_files`
- `mirror_runner_quota_max_workspace_bytes`
- `mirror_runner_quota_max_execution_window_seconds`

## Deployment Runbook

### Preconditions
1. Confirm readiness gates in `docs/mirror-production-readiness-checklist.md` are complete.
2. Confirm SLO baselines and current burn-rate in `docs/mirror-production-slos.md`.
3. Confirm no active Sev1/Sev2 incidents for Mirror dependencies (Supabase, runner infra).
4. Confirm rollback artifacts are available for app, gateway function, and runner.

### Standard Deployment Order
1. Apply DB migrations in staging.
2. Deploy/update cloud runner and verify health endpoints.
3. Deploy `mirror-gateway` edge function.
4. Deploy Flutter/web clients.
5. Run staging smoke: one compile + one apply + verify audit record.
6. Promote to production in canary mode.

### Canary Rollout Procedure
1. Route 5% traffic to new release for 15 minutes.
2. Validate compile/apply success rate and latency within SLO warning thresholds.
3. Increase to 25% for 30 minutes if stable.
4. Increase to 100% only if no stop criteria are met.

Stop criteria:
- Availability drops below 99.5% over any 15-minute window.
- P95 compile latency > 6s for 15 minutes.
- P95 apply latency > 8s for 15 minutes.
- Timeout error code exceeds 1.5% for 10 minutes.

### Post-Deploy Validation (Within 30 Minutes)
1. Verify request/trace-id propagation appears in logs across gateway and runner.
2. Verify no auth-denied surge caused by key/config drift.
3. Verify storage write/read to `mirror-signed-inputs` and `mirror-backups` for owner paths.
4. Verify dashboard tiles for availability, latency, and error mix are healthy.

### Rollback Procedure
1. Declare rollback in incident/deploy channel and assign incident commander.
2. Revert runner to last-known-good image.
3. Revert `mirror-gateway` function version.
4. Revert client release or disable rollout flag.
5. If needed, disable high-risk path via feature flag (`mirror_runner_mode` fallback).
6. Re-run smoke compile/apply and confirm recovery.
7. Document timeline, cause, and mitigation in postmortem.

## Monitoring And Alerting

### Core Signals
- Traffic: requests/minute for `/compile` and `/apply`
- Success: 2xx/overall request ratio
- Latency: P50/P95/P99 for compile and apply
- Reliability: timeout ratio, upstream error ratio, auth denied ratio
- Durability: outbox replay queue depth, replay failure ratio, circuit-breaker open events

### Required Dashboards
1. Gateway health dashboard (availability, latency, timeout).
2. Runner health dashboard (CPU/memory saturation, queueing, execution duration).
3. Security dashboard (auth denied, token validation failures, abnormal idempotency conflicts).
4. Replay resilience dashboard (replay attempts, timeout events, breaker transitions).

### Alert Policy
- Sev1 page:
- Compile/apply availability < 99.0% for 10 minutes.
- Timeout ratio > 3% for 10 minutes.
- Runner unreachable or repeated upstream 5xx spikes (>5% for 10 minutes).
- Sev2 page:
- P95 compile latency > 6s for 20 minutes.
- P95 apply latency > 8s for 20 minutes.
- Circuit-breaker open state sustained > 10 minutes.
- Ticket-only:
- Auth denied 2x baseline for 15 minutes.
- Elevated idempotency conflict rate without user-visible errors.

### Observability Correlation Requirements
- Every request path must include `x-request-id` and `x-trace-id` in logs/events.
- Structured errors must carry correlation identifiers.
- Incident investigation must be able to trace one request across client, gateway, and runner logs.

## Full Deployment Procedure

### Release Inputs
1. Release tag is cut and immutable.
2. DB migration plan and rollback SQL are attached.
3. Gateway env-var diff is reviewed.
4. Runner image digest and runtime config are pinned.
5. Flutter client build hash is pinned.

### Production Deployment Steps
1. Announce deployment start in the release/incident channel.
2. Apply production DB migrations.
3. Deploy cloud runner using pinned image digest.
4. Deploy `mirror-gateway` edge function revision.
5. Roll out client version behind existing feature-flag safety controls.
6. Run post-deploy smoke checks:
  - one `/compile`
  - one `/apply`
  - verify audit event row and storage artifact path
7. Execute canary ramps: 5% -> 25% -> 100% with hold windows.
8. Mark deployment complete and post summary.

### Deployment Abort Criteria
1. Compile/apply availability below 99.5% during any canary hold window.
2. P95 latency breaches stop criteria defined in this runbook for 15+ minutes.
3. Timeout ratio > 3% for 10 minutes.
4. Auth-denied errors > 2x baseline caused by deployment changes.

### Deployment Verification Checklist
1. Correlation IDs observed across client, gateway, and runner logs.
2. Idempotency replay behavior is healthy (no unexpected conflict spike).
3. Runner resource saturation remains below paging thresholds.
4. Circuit breaker is closed and replay queue depth is stable.
5. SLO dashboard remains within target during the first 30 minutes.

## Full Monitoring Procedure

### Monitoring Stack Requirements
1. Metrics dashboard for gateway:
  - request volume
  - success ratio
  - P50/P95/P99 latency
  - timeout ratio
2. Metrics dashboard for runner:
  - CPU/memory
  - execution duration
  - error ratio
3. Resilience dashboard:
  - replay queue depth
  - replay timeout count
  - circuit-breaker state transitions
4. Log search views with request/trace correlation filters.

### Standard Monitoring Cadence
1. During release canary: every 5 minutes.
2. First hour after release: every 15 minutes.
3. Normal operation: hourly dashboard spot-check.
4. Weekly: reliability review against SLO report.

### Alert Handling Rules
1. Every page must include current severity, affected path (`compile`/`apply`), and top suspected layer.
2. Sev1 and Sev2 alerts require explicit owner assignment in channel.
3. Repeated flapping alerts require threshold tuning ticket after incident closure.

## Full Incident Response Procedure

### Incident Roles
1. Incident Commander (IC): owns coordination and timelines.
2. Ops Lead: executes mitigations and rollback actions.
3. Communications Lead: posts updates and stakeholder notes.
4. Subject-Matter Engineer (SME): deep technical diagnosis.

### First 15 Minutes Playbook
1. Acknowledge alert and open incident channel.
2. Assign IC, Ops Lead, and SME.
3. Classify severity and blast radius (`compile`, `apply`, or both).
4. Start an incident timeline with timestamps.
5. Execute immediate triage:
  - verify dependency status
  - inspect error mix
  - identify first failing request ID

### Containment Options
1. Roll back runner revision.
2. Roll back `mirror-gateway` function revision.
3. Shift traffic to healthy mode via `mirror_runner_mode` where safe.
4. Reduce pressure by pausing high-risk feature rollout.

### Recovery Validation
1. Error rate returns below alert threshold for 30 minutes.
2. Latency percentiles return within runbook bounds.
3. Replay queue resumes normal drain behavior.
4. End-to-end smoke compile/apply succeeds.

### Incident Closure Criteria
1. User impact is no longer ongoing.
2. Mitigation is stable and monitored.
3. Timeline, root cause hypothesis, and next actions are documented.
4. Postmortem owner and due date are assigned before closure.

## Incident Response

### Severity Model
- Sev1: User-facing outage or major degradation with broad impact.
- Sev2: Significant partial degradation with a viable workaround.
- Sev3: Limited impact, low urgency, or non-production issue.

### Initial Response (First 10 Minutes)
1. Acknowledge page and assign incident commander.
2. Define blast radius: compile only, apply only, or both.
3. Confirm whether issue is client, gateway, runner, or dependency induced.
4. Decide immediate mitigation: traffic shift, rollback, or feature kill-switch.

### Investigation Workflow
1. Start with correlation ID from a failing request.
2. Check gateway logs for route, upstream target, and error code.
3. Follow same request/trace ID in runner logs for execution and auth state.
4. Validate dependency status (Supabase auth/storage/network).
5. Determine if failure mode matches known playbooks below.

### Communication Cadence
- Sev1: status update every 15 minutes.
- Sev2: status update every 30 minutes.
- Include: current impact, mitigation in progress, ETA confidence, next update time.

### Recovery Criteria
- Success rate and latency return to SLO-compliant range.
- No sustained alert re-firing for 30 minutes.
- Smoke compile/apply verification passes.
- On-call confirms user impact is resolved.

### Post-Incident Requirements
1. Publish incident summary within 24 hours.
2. Publish postmortem with action items within 5 business days.
3. Link action items to owners and due dates.
4. Update this runbook and checklist when gaps are discovered.

## On-Call Triage
1. Confirm whether impact is `compile`, `apply`, or both.
2. Check Mirror Gateway logs for:
- `code=timeout`
- `code=upstream_error`
- `code=unauthorized`
3. Check runner logs for auth denied metrics and compile latency max/avg.
4. Verify Supabase status and network path to upstream endpoints.
5. Validate no recent config drift in endpoint or JWT env vars.

## Incident Playbooks
### A. Unauthorized errors increase
1. Confirm bearer token presence in client request headers.
2. Confirm `SUPABASE_URL` and `SUPABASE_ANON_KEY` correctness in Mirror Gateway env.
3. For runner-side denials, verify `MIRROR_JWT_KEYS_BY_KID` JSON is valid and contains active `kid`.
4. Keep `MIRROR_JWT_SECRET` as fallback during rotation window.

### B. Timeouts or upstream errors
1. Verify private/cloud upstream endpoint reachability for Mirror Gateway.
2. Check upstream health and saturation (CPU, memory, connection limits).
3. Increase capacity or redirect traffic to healthy mode if needed.
4. Temporarily raise `MIRROR_FORWARD_TIMEOUT_MS` only with incident note and rollback plan.
5. Confirm runner execution window (`MIRROR_MAX_EXECUTION_WINDOW_SECONDS`) is not lower than expected workload runtime.

### C. Apply path or patch failures
1. Validate route used is `/apply` (not `/compile`).
2. Validate idempotency key propagation in Mirror Gateway response headers.
3. Confirm backup/signed-input artifacts are written to owner-prefixed paths.
4. Check gateway structured errors for quota rejections:
- `payload_too_large` (workspace/request bytes)
- `bad_request` with file-count limit details

### D. Outbox replay backlog grows
1. Check queue depth and oldest replay item age.
2. Check for repeated timeout failures and circuit-breaker open events.
3. Validate runner reachability and latency; mitigate upstream bottleneck first.
4. If breaker remains open, reduce replay pressure and restore health before reopening.
5. Confirm replay success resumes and backlog drains at expected rate.

## Storage and RLS Verification
Run in SQL editor (service role) when validating policies:
1. Ensure both buckets exist and are private.
2. Ensure policy set exists for insert/select/update/delete on both buckets.
3. Ensure each policy includes owner-folder check using `storage.foldername(name)[1]`.

## Session Retention Verification
Run in SQL editor (service role):
1. Confirm function `public.cleanup_ai_sessions_retention(integer, integer)` exists.
2. Dry-run retention trim in staging and inspect counts:
- `select * from public.cleanup_ai_sessions_retention(30, 50);`
3. Confirm cron job `mirror_ai_sessions_retention_daily` exists when `pg_cron` is enabled.

## Key Rotation Procedure
1. Generate new JWT key and assign a new `kid`.
2. Add key to `MIRROR_JWT_KEYS_BY_KID` while keeping previous active key.
3. Deploy runner.
4. Shift token issuer to new `kid`.
5. Monitor auth denied metric for 30-60 minutes.
6. Remove old key after stable window.

## Idempotency Operations

### Monitoring Stale Claims
A `processing` claim older than 300 seconds that was never finalized indicates a runner crash or network partition. The gateway recovers these automatically via `resetIdempotencyKeyClaim`. If stale-claim takeover rate is elevated:
1. Check runner health and crash reports for the affected time window.
2. Verify the stale threshold (300 s) is appropriate relative to P95 runner execution time.
3. Confirm `MIRROR_FORWARD_TIMEOUT_MS` is lower than 300 000 ms so gateway timeouts surface before stale threshold.

### Finalize Conflict Errors
If `idempotency_update_conflict:no_matching_processing_claim` appears in gateway logs:
1. This means a finalize call found no matching `processing` record with the expected `request_id` and `request_hash`.
2. Check whether the record was already finalized by a previous (possibly duplicate) request.
3. Check whether the record was taken over by stale-claim recovery before finalize ran.
4. The error is non-fatal to the caller (upstream response is still returned); monitor for elevated rates.

### Clearing Stuck Records (break-glass)
If a record is permanently stuck in `processing` and automatic recovery has not fired:
```sql
-- Run as service role. Replace placeholders.
UPDATE mirror_request_idempotency
SET status = 'failed',
    expires_at = now() - interval '1 second'
WHERE user_id = '<uid>'
  AND action = '<compile|apply>'
  AND idempotency_key = '<key>'
  AND status = 'processing';
```

## Safe Rollback
1. Roll back Mirror Gateway and runner to last known good release.
2. Keep schema and RLS migrations intact unless a migration-specific issue is confirmed.
3. Re-run contract tests:
- `flutter test test/features/mirror/mirror_gateway_contract_test.dart`
- SQL contract test script in `test/supabase/mirror_storage_rls_contract_test.sql`

## Operational Checks After Deploy
- `flutter analyze`
- `flutter test test/features/mirror/mirror_gateway_contract_test.dart`
- Execute SQL contract checks in Supabase SQL editor.
- Validate one real compile and one real apply request in staging.

