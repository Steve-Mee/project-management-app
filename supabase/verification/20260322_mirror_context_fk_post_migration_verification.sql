-- Post-migration verification for Mirror context FK hardening
-- Target migration: 20260322_mirror_context_uuid_fk_hardening.sql
--
-- Usage:
-- 1) Run this file after applying the migration.
-- 2) Review each section and confirm GO/NO-GO outcomes.
-- 3) If NO-GO, use the remediation queries at the end.

BEGIN;

-- ---------------------------------------------------------------------------
-- A) Schema presence checks
-- GO: all rows return present = true
-- ---------------------------------------------------------------------------
SELECT
  'ai_sessions.project_uuid exists' AS check_name,
  EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'ai_sessions'
      AND column_name = 'project_uuid'
  ) AS present
UNION ALL
SELECT
  'ai_sessions.task_uuid exists',
  EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'ai_sessions'
      AND column_name = 'task_uuid'
  )
UNION ALL
SELECT
  'mirror_apply_audit_events.project_uuid exists',
  EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'mirror_apply_audit_events'
      AND column_name = 'project_uuid'
  )
UNION ALL
SELECT
  'mirror_apply_audit_events.task_uuid exists',
  EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'mirror_apply_audit_events'
      AND column_name = 'task_uuid'
  )
UNION ALL
SELECT
  'mirror_usage_logs.project_uuid exists',
  EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'mirror_usage_logs'
      AND column_name = 'project_uuid'
  )
UNION ALL
SELECT
  'mirror_usage_logs.task_uuid exists',
  EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'mirror_usage_logs'
      AND column_name = 'task_uuid'
  );

-- ---------------------------------------------------------------------------
-- B) Constraint validation status
-- GO: all expected constraints exist and convalidated = true
-- ---------------------------------------------------------------------------
SELECT
  c.conname,
  c.convalidated,
  cl.relname AS table_name,
  pg_get_constraintdef(c.oid) AS definition
FROM pg_constraint c
JOIN pg_class cl ON cl.oid = c.conrelid
JOIN pg_namespace n ON n.oid = cl.relnamespace
WHERE n.nspname = 'public'
  AND c.conname IN (
    'ai_sessions_project_uuid_fkey',
    'ai_sessions_task_uuid_fkey',
    'mirror_apply_audit_events_project_uuid_fkey',
    'mirror_apply_audit_events_task_uuid_fkey',
    'mirror_usage_logs_project_uuid_fkey',
    'mirror_usage_logs_task_uuid_fkey'
  )
ORDER BY c.conname;

-- ---------------------------------------------------------------------------
-- C) Trigger/function presence checks
-- GO: all rows return present = true
-- ---------------------------------------------------------------------------
SELECT
  'normalize_mirror_context_ids function' AS check_name,
  EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'normalize_mirror_context_ids'
  ) AS present
UNION ALL
SELECT
  'trg_ai_sessions_normalize_context_ids',
  EXISTS (
    SELECT 1 FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'ai_sessions'
      AND t.tgname = 'trg_ai_sessions_normalize_context_ids'
      AND NOT t.tgisinternal
  )
UNION ALL
SELECT
  'trg_mirror_apply_audit_events_normalize_context_ids',
  EXISTS (
    SELECT 1 FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'mirror_apply_audit_events'
      AND t.tgname = 'trg_mirror_apply_audit_events_normalize_context_ids'
      AND NOT t.tgisinternal
  )
UNION ALL
SELECT
  'trg_mirror_usage_logs_normalize_context_ids',
  EXISTS (
    SELECT 1 FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'mirror_usage_logs'
      AND t.tgname = 'trg_mirror_usage_logs_normalize_context_ids'
      AND NOT t.tgisinternal
  );

-- ---------------------------------------------------------------------------
-- D) Data integrity checks (core)
-- GO: all counters = 0 for ai_sessions
-- ---------------------------------------------------------------------------
SELECT
  COUNT(*) FILTER (WHERE project_uuid IS NULL) AS ai_sessions_project_uuid_null,
  COUNT(*) FILTER (WHERE task_uuid IS NULL) AS ai_sessions_task_uuid_null
FROM public.ai_sessions;

SELECT
  COUNT(*) AS ai_sessions_orphan_project
FROM public.ai_sessions s
LEFT JOIN public.projects p ON p.id = s.project_uuid
WHERE p.id IS NULL;

SELECT
  COUNT(*) AS ai_sessions_orphan_task
FROM public.ai_sessions s
LEFT JOIN public.tasks t ON t.id = s.task_uuid
WHERE t.id IS NULL;

SELECT
  COUNT(*) AS ai_sessions_task_project_mismatch
FROM public.ai_sessions s
JOIN public.tasks t ON t.id = s.task_uuid
WHERE t.project_id <> s.project_uuid;

-- ---------------------------------------------------------------------------
-- E) Data integrity checks (audit + metering)
-- GO (strict mode): all counters = 0
-- GO (retention mode): nullable UUID rows are acceptable only if reviewed.
-- ---------------------------------------------------------------------------
SELECT
  COUNT(*) FILTER (WHERE project_uuid IS NULL OR task_uuid IS NULL) AS mirror_apply_uuid_nullable_rows,
  COUNT(*) FILTER (
    WHERE project_uuid IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM public.projects p WHERE p.id = mirror_apply_audit_events.project_uuid)
  ) AS mirror_apply_orphan_project,
  COUNT(*) FILTER (
    WHERE task_uuid IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM public.tasks t WHERE t.id = mirror_apply_audit_events.task_uuid)
  ) AS mirror_apply_orphan_task
FROM public.mirror_apply_audit_events;

SELECT
  COUNT(*) FILTER (WHERE project_uuid IS NULL OR task_uuid IS NULL) AS mirror_usage_uuid_nullable_rows,
  COUNT(*) FILTER (
    WHERE project_uuid IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM public.projects p WHERE p.id = mirror_usage_logs.project_uuid)
  ) AS mirror_usage_orphan_project,
  COUNT(*) FILTER (
    WHERE task_uuid IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM public.tasks t WHERE t.id = mirror_usage_logs.task_uuid)
  ) AS mirror_usage_orphan_task
FROM public.mirror_usage_logs;

-- ---------------------------------------------------------------------------
-- F) Backfill quality visibility table
-- GO: no growth after migration cutover.
-- ---------------------------------------------------------------------------
SELECT
  source_table,
  issue_type,
  COUNT(*) AS issue_count
FROM public.mirror_context_fk_migration_issues
GROUP BY source_table, issue_type
ORDER BY source_table, issue_type;

-- ---------------------------------------------------------------------------
-- G) Query-path parity checks (TEXT vs UUID join parity)
-- GO: parity_delta = 0 for each table where both are expected to match
-- ---------------------------------------------------------------------------
WITH text_join AS (
  SELECT COUNT(*) AS cnt
  FROM public.ai_sessions s
  JOIN public.tasks t ON t.id::text = s.task_id
  JOIN public.projects p ON p.id::text = s.project_id
),
uuid_join AS (
  SELECT COUNT(*) AS cnt
  FROM public.ai_sessions s
  JOIN public.tasks t ON t.id = s.task_uuid
  JOIN public.projects p ON p.id = s.project_uuid
)
SELECT
  text_join.cnt AS text_join_count,
  uuid_join.cnt AS uuid_join_count,
  (text_join.cnt - uuid_join.cnt) AS parity_delta
FROM text_join, uuid_join;

-- ---------------------------------------------------------------------------
-- H) New-write smoke test (transactional, rolled back)
-- GO: trigger normalizes text/uuid consistently.
-- ---------------------------------------------------------------------------
SAVEPOINT mirror_context_smoke_test;

-- This smoke test only runs when at least one task row exists.
DO $$
DECLARE
  any_task RECORD;
  smoke_user_id UUID;
  inserted_id UUID;
  normalized_project_text TEXT;
  normalized_task_text TEXT;
BEGIN
  SELECT t.id, t.project_id INTO any_task
  FROM public.tasks t
  LIMIT 1;

  SELECT s.user_id INTO smoke_user_id
  FROM public.ai_sessions s
  WHERE s.user_id IS NOT NULL
  LIMIT 1;

  IF smoke_user_id IS NULL THEN
    SELECT u.id INTO smoke_user_id
    FROM auth.users u
    LIMIT 1;
  END IF;

  IF any_task.id IS NULL THEN
    RAISE NOTICE 'Smoke test skipped: no tasks available';
    RETURN;
  END IF;

  IF smoke_user_id IS NULL THEN
    RAISE NOTICE 'Smoke test skipped: no suitable user_id available';
    RETURN;
  END IF;

  INSERT INTO public.ai_sessions (
    user_id,
    project_id,
    task_id,
    prompt,
    mode,
    status,
    versions,
    metadata
  )
  VALUES (
    smoke_user_id,
    any_task.project_id::text,
    any_task.id::text,
    'mirror context smoke test',
    'private',
    'pending',
    '[]'::jsonb,
    '{}'::jsonb
  )
  RETURNING id INTO inserted_id;

  SELECT project_id, task_id
  INTO normalized_project_text, normalized_task_text
  FROM public.ai_sessions
  WHERE id = inserted_id;

  IF normalized_project_text <> any_task.project_id::text THEN
    RAISE EXCEPTION 'Smoke test failed: project_id not normalized from task relation';
  END IF;

  IF normalized_task_text <> any_task.id::text THEN
    RAISE EXCEPTION 'Smoke test failed: task_id not normalized';
  END IF;

  RAISE NOTICE 'Smoke test passed for ai_sessions trigger normalization';
END;
$$;

ROLLBACK TO SAVEPOINT mirror_context_smoke_test;

-- ---------------------------------------------------------------------------
-- I) NO-GO summary (single row)
-- GO only if no_go_count = 0
-- ---------------------------------------------------------------------------
WITH checks AS (
  SELECT
    (SELECT COUNT(*) FROM public.ai_sessions WHERE project_uuid IS NULL OR task_uuid IS NULL) AS c1,
    (SELECT COUNT(*) FROM public.ai_sessions s LEFT JOIN public.projects p ON p.id = s.project_uuid WHERE p.id IS NULL) AS c2,
    (SELECT COUNT(*) FROM public.ai_sessions s LEFT JOIN public.tasks t ON t.id = s.task_uuid WHERE t.id IS NULL) AS c3,
    (SELECT COUNT(*) FROM public.ai_sessions s JOIN public.tasks t ON t.id = s.task_uuid WHERE t.project_id <> s.project_uuid) AS c4,
    (SELECT COUNT(*) FROM pg_constraint c JOIN pg_class cl ON cl.oid = c.conrelid JOIN pg_namespace n ON n.oid = cl.relnamespace
      WHERE n.nspname = 'public' AND c.conname = 'ai_sessions_project_uuid_fkey' AND c.convalidated = false) AS c5,
    (SELECT COUNT(*) FROM pg_constraint c JOIN pg_class cl ON cl.oid = c.conrelid JOIN pg_namespace n ON n.oid = cl.relnamespace
      WHERE n.nspname = 'public' AND c.conname = 'ai_sessions_task_uuid_fkey' AND c.convalidated = false) AS c6
)
SELECT
  c1 + c2 + c3 + c4 + c5 + c6 AS no_go_count,
  c1 AS ai_sessions_null_uuid_count,
  c2 AS ai_sessions_orphan_project_count,
  c3 AS ai_sessions_orphan_task_count,
  c4 AS ai_sessions_task_project_mismatch_count,
  c5 AS ai_sessions_project_fk_not_validated,
  c6 AS ai_sessions_task_fk_not_validated
FROM checks;

-- ---------------------------------------------------------------------------
-- J) Remediation helper queries (run only if NO-GO)
-- ---------------------------------------------------------------------------
-- 1) Inspect unresolved rows quickly
-- SELECT * FROM public.mirror_context_fk_migration_issues ORDER BY detected_at DESC LIMIT 200;
--
-- 2) Force project_uuid from tasks where task_uuid is present
-- UPDATE public.ai_sessions s
-- SET project_uuid = t.project_id,
--     project_id = t.project_id::text
-- FROM public.tasks t
-- WHERE s.task_uuid = t.id
--   AND (s.project_uuid IS NULL OR s.project_uuid <> t.project_id);
--
-- 3) Re-validate constraints after remediation
-- ALTER TABLE public.ai_sessions VALIDATE CONSTRAINT ai_sessions_project_uuid_fkey;
-- ALTER TABLE public.ai_sessions VALIDATE CONSTRAINT ai_sessions_task_uuid_fkey;

COMMIT;
