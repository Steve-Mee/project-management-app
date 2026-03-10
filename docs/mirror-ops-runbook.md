# Mirror Ops Runbook

## Scope
This runbook covers production operations for the Mirror compile/apply pipeline:
- Supabase Edge Function `mirror_compute`
- Cloud runner (`server/mirror-cloud-runner`)
- Supabase Storage buckets `mirror-signed-inputs` and `mirror-backups`

Canonical naming note:
- Use only `mirror-signed-inputs` and `mirror-backups`
- Do not use legacy/ambiguous names such as `mirror_staging`

## Architecture Contract
Request flow:
1. Client calls `POST /functions/v1/mirror_compute/compile` or `POST /functions/v1/mirror_compute/apply`
2. Edge validates bearer token via Supabase Auth
3. Edge forwards request to mode-specific upstream endpoint (`private` or `cloud`)
4. Edge returns upstream body and propagates `x-request-id` + `x-idempotency-key`

Storage contract:
- Object paths for Mirror artifacts must start with authenticated user id:
- `<auth.uid>/<projectId>/<taskId>/<backupId>/(input|backup)/<filePath>`
- RLS policies enforce `storage.foldername(name)[1] = auth.uid()::text`
- Bucket naming must follow `docs/mirror-bucket-contract.md`

Apply audit contract:
- Backend apply events are written to `public.mirror_apply_audit_events`
- Required fields include actor (`actor_user_id`), artifact ids (`artifact_ids`/`backup_id`), and fingerprints (`file_set_fingerprint`, `applied_files_fingerprint`, `diff_fingerprint`)

## Required Environment Variables
Edge Function:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `PRIVATE_COMPUTE_ENDPOINT`
- `FLY_MIRROR_COMPUTE_ENDPOINT`
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

## SLO and Error Budgets
- Compile availability target: 99.9%
- Apply availability target: 99.9%
- Edge timeout budget: < 1% of requests per rolling 30 days
- Auth denied spikes are actionable when > 3x baseline for 15 minutes

## On-Call Triage
1. Confirm whether impact is `compile`, `apply`, or both.
2. Check edge logs for:
- `code=timeout`
- `code=upstream_error`
- `code=unauthorized`
3. Check runner logs for auth denied metrics and compile latency max/avg.
4. Verify Supabase status and network path to upstream endpoints.
5. Validate no recent config drift in endpoint or JWT env vars.

## Incident Playbooks
### A. Unauthorized errors increase
1. Confirm bearer token presence in client request headers.
2. Confirm `SUPABASE_URL` and `SUPABASE_ANON_KEY` correctness in edge env.
3. For runner-side denials, verify `MIRROR_JWT_KEYS_BY_KID` JSON is valid and contains active `kid`.
4. Keep `MIRROR_JWT_SECRET` as fallback during rotation window.

### B. Timeouts or upstream errors
1. Verify `PRIVATE_COMPUTE_ENDPOINT` / `FLY_MIRROR_COMPUTE_ENDPOINT` reachability.
2. Check upstream health and saturation (CPU, memory, connection limits).
3. Increase capacity or redirect traffic to healthy mode if needed.
4. Temporarily raise `MIRROR_FORWARD_TIMEOUT_MS` only with incident note and rollback plan.
5. Confirm runner execution window (`MIRROR_MAX_EXECUTION_WINDOW_SECONDS`) is not lower than expected workload runtime.

### C. Apply path or patch failures
1. Validate route used is `/apply` (not `/compile`).
2. Validate idempotency key propagation in edge response headers.
3. Confirm backup/signed-input artifacts are written to owner-prefixed paths.
4. Check gateway structured errors for quota rejections:
- `payload_too_large` (workspace/request bytes)
- `bad_request` with file-count limit details

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

## Safe Rollback
1. Roll back edge and runner to last known good release.
2. Keep schema and RLS migrations intact unless a migration-specific issue is confirmed.
3. Re-run contract tests:
- `flutter test test/features/mirror/edge_function_contract_test.dart`
- SQL contract test script in `test/supabase/mirror_storage_rls_contract_test.sql`

## Operational Checks After Deploy
- `flutter analyze`
- `flutter test test/features/mirror/edge_function_contract_test.dart`
- Execute SQL contract checks in Supabase SQL editor.
- Validate one real compile and one real apply request in staging.
