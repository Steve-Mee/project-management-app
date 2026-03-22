# Mirror DB Performance Baseline

## Purpose

This document is the execution guide for the remaining database portion of Task 4.5.4.

Local client and gateway latency baselines are already captured in the Flutter benchmark harness. The remaining open work is staging or production SQL runtime evidence for query timing, index usage, and post-refactor parity.

Use this together with:
- [operations.md](operations.md)
- [production-readiness.md](production-readiness.md)
- [mirror_operational_runbook.md](mirror_operational_runbook.md)
- [../supabase/verification/20260322_mirror_context_fk_post_migration_verification.sql](../supabase/verification/20260322_mirror_context_fk_post_migration_verification.sql)

## Scope

This runbook covers only database-side evidence:
- UUID FK hardening verification
- RLS and policy contract verification
- query runtime timing with `EXPLAIN ANALYZE`
- post-refactor baseline capture from `mirror_usage_logs`

It does not replace:
- Flutter benchmark evidence for client and gateway latency
- release sign-off from SRE or security

## Preconditions

Before running this baseline, confirm all of the following:
- Latest app workspace checks are green (`flutter analyze`, full Flutter tests, Deno gateway tests)
- Target environment has the latest Mirror migrations applied
- You have service-role access or an equivalent approved SQL execution path
- There is enough recent Mirror traffic in `mirror_usage_logs` to compute compile and apply percentiles

## Quick Execution Sequence

Use this exact order in staging or production.

### 1. FK and post-migration verification

Run:

```sql
\i supabase/verification/20260322_mirror_context_fk_post_migration_verification.sql
```

Record:
- schema presence results
- validated FK list
- all null, orphan, and mismatch counts
- `mirror_context_fk_migration_issues` counts

### 2. RLS and storage contract verification

Run:

```sql
\i test/supabase/mirror_rls_contract.sql
\i test/supabase/mirror_storage_rls_contract_test.sql
\i test/supabase/mirror_idempotency_runtime_contract.sql
```

Record:
- any exception output
- confirmation that all scripts completed without contract violations

### 3. Runtime percentile capture

Run:

```sql
SELECT
  action,
  COUNT(*) AS sample_count,
  ROUND(AVG(duration_ms)::numeric, 2) AS avg_ms,
  ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY duration_ms)::numeric, 2) AS p50_ms,
  ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY duration_ms)::numeric, 2) AS p95_ms,
  ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY duration_ms)::numeric, 2) AS p99_ms
FROM public.mirror_usage_logs
WHERE created_at >= NOW() - INTERVAL '7 days'
  AND action IN ('compile', 'apply')
  AND duration_ms IS NOT NULL
GROUP BY action
ORDER BY action;
```

Record:
- compile sample count, p50, p95, p99
- apply sample count, p50, p95, p99
- whether results are representative for the chosen environment

### 4. Query plan capture

Replace placeholder UUIDs before running.

Run:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT s.id, s.project_uuid, s.task_uuid
FROM public.ai_sessions s
JOIN public.tasks t ON t.id = s.task_uuid
JOIN public.projects p ON p.id = s.project_uuid
WHERE s.project_uuid = '<project-uuid>'::uuid
  AND s.task_uuid = '<task-uuid>'::uuid
LIMIT 50;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, action, duration_ms, created_at
FROM public.mirror_usage_logs
WHERE project_uuid = '<project-uuid>'::uuid
  AND task_uuid = '<task-uuid>'::uuid
ORDER BY created_at DESC
LIMIT 100;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, status, action, created_at
FROM public.mirror_usage_logs
WHERE user_id = '<user-uuid>'::uuid
  AND status IN ('success', 'failed', 'rate_limited', 'timeout', 'upstream_error')
ORDER BY created_at DESC
LIMIT 100;

EXPLAIN (ANALYZE, BUFFERS)
SELECT user_id, action, idempotency_key
FROM public.mirror_request_idempotency
WHERE expires_at < NOW()
ORDER BY expires_at ASC
LIMIT 100;
```

Record:
- total execution time per query
- planner choice and index usage
- any sequential scan that looks unexpected

### 5. Final release note entry

Copy this template into the workflow log or release note:

```text
4.5.4 DB baseline run completed in <environment> on <date>.
Contracts: FK verification [pass/fail], RLS [pass/fail], storage [pass/fail], idempotency [pass/fail].
Percentiles: compile p50=<x> p95=<x> p99=<x> (n=<x>); apply p50=<x> p95=<x> p99=<x> (n=<x>).
Query timing: ai_sessions=<x>ms, usage project/task=<x>ms, usage user/status=<x>ms, idempotency expiry=<x>ms.
Comparison to pre-refactor baseline: <within 5% / regressed by x% / improved by x%>.
Result: <GO / NO-GO> for Task 4.5.4.
```

## Required Repo Artifacts

Use these existing SQL assets first:
- Verification script: [../supabase/verification/20260322_mirror_context_fk_post_migration_verification.sql](../supabase/verification/20260322_mirror_context_fk_post_migration_verification.sql)
- RLS contract: [../test/supabase/mirror_rls_contract.sql](../test/supabase/mirror_rls_contract.sql)
- Storage contract: [../test/supabase/mirror_storage_rls_contract_test.sql](../test/supabase/mirror_storage_rls_contract_test.sql)
- Idempotency runtime contract: [../test/supabase/mirror_idempotency_runtime_contract.sql](../test/supabase/mirror_idempotency_runtime_contract.sql)

## Step 1: Post-Migration Verification

Run the full FK verification script first.

Expected result:
- all schema presence checks return `present = true`
- all expected constraints exist and `convalidated = true`
- `ai_sessions` null, orphan, and mismatch counts are `0`
- any nullable UUID rows in metering and audit tables are reviewed and accepted

Execution:

```sql
\i supabase/verification/20260322_mirror_context_fk_post_migration_verification.sql
```

Evidence to retain:
- screenshot or exported result set for sections A through H
- count from `mirror_context_fk_migration_issues`
- explicit GO or NO-GO note

## Step 2: Contract Verification

Run the Mirror SQL contract files against the same environment.

Execution order:
1. [../test/supabase/mirror_rls_contract.sql](../test/supabase/mirror_rls_contract.sql)
2. [../test/supabase/mirror_storage_rls_contract_test.sql](../test/supabase/mirror_storage_rls_contract_test.sql)
3. [../test/supabase/mirror_idempotency_runtime_contract.sql](../test/supabase/mirror_idempotency_runtime_contract.sql)

Expected result:
- no contract violation exceptions
- RLS enabled on critical tables
- mirror storage policies present with owner-folder guard
- idempotency cleanup function and `expires_at` index present

## Step 3: Mirror Usage Percentiles

Capture the current runtime percentile baseline from production-like traffic.

Suggested window:
- last 7 days for production
- last 24 hours for staging, only if traffic volume is representative

Query:

```sql
SELECT
  action,
  COUNT(*) AS sample_count,
  ROUND(AVG(duration_ms)::numeric, 2) AS avg_ms,
  ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY duration_ms)::numeric, 2) AS p50_ms,
  ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY duration_ms)::numeric, 2) AS p95_ms,
  ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY duration_ms)::numeric, 2) AS p99_ms
FROM public.mirror_usage_logs
WHERE created_at >= NOW() - INTERVAL '7 days'
  AND action IN ('compile', 'apply')
  AND duration_ms IS NOT NULL
GROUP BY action
ORDER BY action;
```

Expected review points:
- compile P95 remains at or below the documented 4s target
- apply P95 remains at or below the documented 5s target
- sample size is large enough to be meaningful

## Step 4: Query Plan Evidence

Capture `EXPLAIN ANALYZE` for the primary post-refactor query paths.

### 4.1 AI sessions UUID join path

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT s.id, s.project_uuid, s.task_uuid
FROM public.ai_sessions s
JOIN public.tasks t ON t.id = s.task_uuid
JOIN public.projects p ON p.id = s.project_uuid
WHERE s.project_uuid = '<project-uuid>'::uuid
  AND s.task_uuid = '<task-uuid>'::uuid
LIMIT 50;
```

### 4.2 Usage logs project and task path

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, action, duration_ms, created_at
FROM public.mirror_usage_logs
WHERE project_uuid = '<project-uuid>'::uuid
  AND task_uuid = '<task-uuid>'::uuid
ORDER BY created_at DESC
LIMIT 100;
```

### 4.3 Usage logs user and status path

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, status, action, created_at
FROM public.mirror_usage_logs
WHERE user_id = '<user-uuid>'::uuid
  AND status IN ('success', 'failed', 'rate_limited', 'timeout', 'upstream_error')
ORDER BY created_at DESC
LIMIT 100;
```

### 4.4 Idempotency cleanup candidate path

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT user_id, action, idempotency_key
FROM public.mirror_request_idempotency
WHERE expires_at < NOW()
ORDER BY expires_at ASC
LIMIT 100;
```

Review criteria:
- planner uses the expected indexes for the filtered path
- runtime is stable and does not regress materially from pre-refactor evidence
- there is no unexpected sequential scan on hot paths unless table size is too small for a meaningful plan

## Step 5: Pre-Refactor Comparison

Record the comparison explicitly in the release note or workflow log.

Minimum evidence table:

| Metric | Pre-refactor | Current | Delta | Result |
|---|---:|---:|---:|---|
| Compile P95 | | | | |
| Apply P95 | | | | |
| AI sessions UUID join runtime | | | | |
| Usage logs project/task runtime | | | | |
| Usage logs user/status runtime | | | | |
| Idempotency expiry lookup runtime | | | | |

Acceptance rule:
- no regression greater than 5 percent without an explicit written reason and approval

## Step 6: Workflow Update

Once the SQL evidence is captured, update [MIRROR_IMPLEMENTATION_WORKFLOW.md](MIRROR_IMPLEMENTATION_WORKFLOW.md) with:
- environment used
- sample window used
- exact p50, p95, p99 values
- exact `EXPLAIN ANALYZE` runtimes or summarized results
- comparison outcome against the pre-refactor baseline
- final GO or NO-GO statement for 4.5.4

## Evidence Checklist

- [ ] FK post-migration verification executed
- [ ] RLS contract script executed
- [ ] Storage contract script executed
- [ ] Idempotency runtime contract script executed
- [ ] Compile percentile evidence captured
- [ ] Apply percentile evidence captured
- [ ] Primary `EXPLAIN ANALYZE` query evidence captured
- [ ] Pre-refactor delta recorded
- [ ] 4.5.4 workflow log updated with final result

## Current Status

As of 2026-03-22:
- local Flutter benchmark evidence is complete
- workspace regression status is green
- this database runbook is ready
- the only remaining step is execution in a staging or production SQL environment