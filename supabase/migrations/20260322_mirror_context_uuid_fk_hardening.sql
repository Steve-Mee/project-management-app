-- Mirror context relational hardening
-- Goal: replace loose TEXT-only project/task linkage with UUID-backed relational linkage.
--
-- Strategy:
-- 1) Add UUID mirror context columns (additive, no breakage).
-- 2) Backfill from existing TEXT fields and canonical tasks/project relation.
-- 3) Capture unresolved rows for operational follow-up.
-- 4) Enforce write-time normalization via triggers.
-- 5) Add FK constraints (NOT VALID + VALIDATE) and UUID indexes.
--
-- Note:
-- - ai_sessions gets strict NOT NULL UUID context after backfill (core runtime table).
-- - audit/metering tables keep UUID nullable to preserve retention when legacy rows are unresolved.

BEGIN;

DO $$
BEGIN
  IF to_regclass('public.projects') IS NULL THEN
    RAISE EXCEPTION 'Required table public.projects is missing';
  END IF;

  IF to_regclass('public.tasks') IS NULL THEN
    RAISE EXCEPTION 'Required table public.tasks is missing';
  END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- 1) Add UUID columns
-- ---------------------------------------------------------------------------
ALTER TABLE IF EXISTS public.ai_sessions
  ADD COLUMN IF NOT EXISTS project_uuid UUID,
  ADD COLUMN IF NOT EXISTS task_uuid UUID;

ALTER TABLE IF EXISTS public.mirror_apply_audit_events
  ADD COLUMN IF NOT EXISTS project_uuid UUID,
  ADD COLUMN IF NOT EXISTS task_uuid UUID;

ALTER TABLE IF EXISTS public.mirror_usage_logs
  ADD COLUMN IF NOT EXISTS project_uuid UUID,
  ADD COLUMN IF NOT EXISTS task_uuid UUID;

-- ---------------------------------------------------------------------------
-- 2) Backfill UUID columns from TEXT + canonical task relation
-- ---------------------------------------------------------------------------
-- UUID regex must match canonical 8-4-4-4-12 pattern.
-- Safe cast only when regex matches.

UPDATE public.ai_sessions
SET
  project_uuid = CASE
    WHEN project_uuid IS NOT NULL THEN project_uuid
    WHEN project_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' THEN project_id::uuid
    ELSE NULL
  END,
  task_uuid = CASE
    WHEN task_uuid IS NOT NULL THEN task_uuid
    WHEN task_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' THEN task_id::uuid
    ELSE NULL
  END;

UPDATE public.mirror_apply_audit_events
SET
  project_uuid = CASE
    WHEN project_uuid IS NOT NULL THEN project_uuid
    WHEN project_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' THEN project_id::uuid
    ELSE NULL
  END,
  task_uuid = CASE
    WHEN task_uuid IS NOT NULL THEN task_uuid
    WHEN task_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' THEN task_id::uuid
    ELSE NULL
  END;

UPDATE public.mirror_usage_logs
SET
  project_uuid = CASE
    WHEN project_uuid IS NOT NULL THEN project_uuid
    WHEN project_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' THEN project_id::uuid
    ELSE NULL
  END,
  task_uuid = CASE
    WHEN task_uuid IS NOT NULL THEN task_uuid
    WHEN task_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' THEN task_id::uuid
    ELSE NULL
  END;

-- Canonicalize project_uuid from tasks.project_id when task_uuid is known.
UPDATE public.ai_sessions s
SET project_uuid = t.project_id
FROM public.tasks t
WHERE s.task_uuid = t.id
  AND (s.project_uuid IS NULL OR s.project_uuid <> t.project_id);

UPDATE public.mirror_apply_audit_events e
SET project_uuid = t.project_id
FROM public.tasks t
WHERE e.task_uuid = t.id
  AND (e.project_uuid IS NULL OR e.project_uuid <> t.project_id);

UPDATE public.mirror_usage_logs u
SET project_uuid = t.project_id
FROM public.tasks t
WHERE u.task_uuid = t.id
  AND (u.project_uuid IS NULL OR u.project_uuid <> t.project_id);

-- For retention-sensitive tables we preserve rows and null-out unresolved UUID refs
-- so FK validation can proceed while keeping historical records.
UPDATE public.mirror_apply_audit_events e
SET project_uuid = NULL
WHERE e.project_uuid IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.projects p WHERE p.id = e.project_uuid
  );

UPDATE public.mirror_apply_audit_events e
SET task_uuid = NULL
WHERE e.task_uuid IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.tasks t WHERE t.id = e.task_uuid
  );

UPDATE public.mirror_usage_logs u
SET project_uuid = NULL
WHERE u.project_uuid IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.projects p WHERE p.id = u.project_uuid
  );

UPDATE public.mirror_usage_logs u
SET task_uuid = NULL
WHERE u.task_uuid IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.tasks t WHERE t.id = u.task_uuid
  );

-- ---------------------------------------------------------------------------
-- 3) Record unresolved/mismatched data for operational follow-up
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.mirror_context_fk_migration_issues (
  id BIGSERIAL PRIMARY KEY,
  source_table TEXT NOT NULL,
  source_row_id TEXT NOT NULL,
  issue_type TEXT NOT NULL,
  project_id_raw TEXT,
  task_id_raw TEXT,
  detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mirror_context_fk_migration_issues_detected
  ON public.mirror_context_fk_migration_issues (detected_at DESC);

INSERT INTO public.mirror_context_fk_migration_issues (
  source_table, source_row_id, issue_type, project_id_raw, task_id_raw
)
SELECT
  'ai_sessions',
  s.id::text,
  CASE
    WHEN s.project_uuid IS NULL OR s.task_uuid IS NULL THEN 'invalid_uuid_format_or_missing'
    WHEN p.id IS NULL OR t.id IS NULL THEN 'orphan_reference'
    WHEN t.project_id <> s.project_uuid THEN 'task_project_mismatch'
    ELSE 'unknown'
  END,
  s.project_id,
  s.task_id
FROM public.ai_sessions s
LEFT JOIN public.projects p ON p.id = s.project_uuid
LEFT JOIN public.tasks t ON t.id = s.task_uuid
WHERE s.project_uuid IS NULL
   OR s.task_uuid IS NULL
   OR p.id IS NULL
   OR t.id IS NULL
   OR t.project_id <> s.project_uuid;

INSERT INTO public.mirror_context_fk_migration_issues (
  source_table, source_row_id, issue_type, project_id_raw, task_id_raw
)
SELECT
  'mirror_apply_audit_events',
  e.id::text,
  CASE
    WHEN e.project_uuid IS NULL OR e.task_uuid IS NULL THEN 'invalid_uuid_format_or_missing'
    WHEN p.id IS NULL OR t.id IS NULL THEN 'orphan_reference'
    WHEN t.project_id <> e.project_uuid THEN 'task_project_mismatch'
    ELSE 'unknown'
  END,
  e.project_id,
  e.task_id
FROM public.mirror_apply_audit_events e
LEFT JOIN public.projects p ON p.id = e.project_uuid
LEFT JOIN public.tasks t ON t.id = e.task_uuid
WHERE e.project_uuid IS NULL
   OR e.task_uuid IS NULL
   OR p.id IS NULL
   OR t.id IS NULL
   OR t.project_id <> e.project_uuid;

INSERT INTO public.mirror_context_fk_migration_issues (
  source_table, source_row_id, issue_type, project_id_raw, task_id_raw
)
SELECT
  'mirror_usage_logs',
  u.id::text,
  CASE
    WHEN u.project_uuid IS NULL OR u.task_uuid IS NULL THEN 'invalid_uuid_format_or_missing'
    WHEN p.id IS NULL OR t.id IS NULL THEN 'orphan_reference'
    WHEN t.project_id <> u.project_uuid THEN 'task_project_mismatch'
    ELSE 'unknown'
  END,
  u.project_id,
  u.task_id
FROM public.mirror_usage_logs u
LEFT JOIN public.projects p ON p.id = u.project_uuid
LEFT JOIN public.tasks t ON t.id = u.task_uuid
WHERE u.project_uuid IS NULL
   OR u.task_uuid IS NULL
   OR p.id IS NULL
   OR t.id IS NULL
   OR t.project_id <> u.project_uuid;

-- ---------------------------------------------------------------------------
-- 4) Write-time normalization triggers to keep TEXT+UUID in sync
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.try_parse_uuid(raw_value TEXT)
RETURNS UUID
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  IF raw_value IS NULL THEN
    RETURN NULL;
  END IF;

  IF raw_value ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' THEN
    RETURN raw_value::uuid;
  END IF;

  RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION public.normalize_mirror_context_ids()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.project_uuid IS NULL THEN
    NEW.project_uuid := public.try_parse_uuid(NEW.project_id);
  END IF;

  IF NEW.task_uuid IS NULL THEN
    NEW.task_uuid := public.try_parse_uuid(NEW.task_id);
  END IF;

  IF NEW.task_uuid IS NOT NULL THEN
    SELECT t.project_id
    INTO NEW.project_uuid
    FROM public.tasks t
    WHERE t.id = NEW.task_uuid;
  END IF;

  IF NEW.project_uuid IS NOT NULL THEN
    NEW.project_id := NEW.project_uuid::text;
  END IF;

  IF NEW.task_uuid IS NOT NULL THEN
    NEW.task_id := NEW.task_uuid::text;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_ai_sessions_normalize_context_ids ON public.ai_sessions;
CREATE TRIGGER trg_ai_sessions_normalize_context_ids
BEFORE INSERT OR UPDATE ON public.ai_sessions
FOR EACH ROW
EXECUTE FUNCTION public.normalize_mirror_context_ids();

DROP TRIGGER IF EXISTS trg_mirror_apply_audit_events_normalize_context_ids ON public.mirror_apply_audit_events;
CREATE TRIGGER trg_mirror_apply_audit_events_normalize_context_ids
BEFORE INSERT OR UPDATE ON public.mirror_apply_audit_events
FOR EACH ROW
EXECUTE FUNCTION public.normalize_mirror_context_ids();

DROP TRIGGER IF EXISTS trg_mirror_usage_logs_normalize_context_ids ON public.mirror_usage_logs;
CREATE TRIGGER trg_mirror_usage_logs_normalize_context_ids
BEFORE INSERT OR UPDATE ON public.mirror_usage_logs
FOR EACH ROW
EXECUTE FUNCTION public.normalize_mirror_context_ids();

-- ---------------------------------------------------------------------------
-- 5) Strictness for ai_sessions (runtime-critical table)
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  unresolved_count INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO unresolved_count
  FROM public.ai_sessions s
  LEFT JOIN public.projects p ON p.id = s.project_uuid
  LEFT JOIN public.tasks t ON t.id = s.task_uuid
  WHERE s.project_uuid IS NULL
     OR s.task_uuid IS NULL
     OR p.id IS NULL
     OR t.id IS NULL
     OR t.project_id <> s.project_uuid;

  IF unresolved_count > 0 THEN
    RAISE EXCEPTION
      'ai_sessions contains % unresolved project/task context rows; see mirror_context_fk_migration_issues before enforcing strict constraints',
      unresolved_count;
  END IF;
END;
$$;

ALTER TABLE public.ai_sessions
  ALTER COLUMN project_uuid SET NOT NULL,
  ALTER COLUMN task_uuid SET NOT NULL;

-- ---------------------------------------------------------------------------
-- 6) FK constraints (staged validation)
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'ai_sessions_project_uuid_fkey'
      AND conrelid = 'public.ai_sessions'::regclass
  ) THEN
    ALTER TABLE public.ai_sessions
      ADD CONSTRAINT ai_sessions_project_uuid_fkey
      FOREIGN KEY (project_uuid) REFERENCES public.projects(id) ON DELETE CASCADE NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'ai_sessions_task_uuid_fkey'
      AND conrelid = 'public.ai_sessions'::regclass
  ) THEN
    ALTER TABLE public.ai_sessions
      ADD CONSTRAINT ai_sessions_task_uuid_fkey
      FOREIGN KEY (task_uuid) REFERENCES public.tasks(id) ON DELETE CASCADE NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'mirror_apply_audit_events_project_uuid_fkey'
      AND conrelid = 'public.mirror_apply_audit_events'::regclass
  ) THEN
    ALTER TABLE public.mirror_apply_audit_events
      ADD CONSTRAINT mirror_apply_audit_events_project_uuid_fkey
      FOREIGN KEY (project_uuid) REFERENCES public.projects(id) ON DELETE SET NULL NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'mirror_apply_audit_events_task_uuid_fkey'
      AND conrelid = 'public.mirror_apply_audit_events'::regclass
  ) THEN
    ALTER TABLE public.mirror_apply_audit_events
      ADD CONSTRAINT mirror_apply_audit_events_task_uuid_fkey
      FOREIGN KEY (task_uuid) REFERENCES public.tasks(id) ON DELETE SET NULL NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'mirror_usage_logs_project_uuid_fkey'
      AND conrelid = 'public.mirror_usage_logs'::regclass
  ) THEN
    ALTER TABLE public.mirror_usage_logs
      ADD CONSTRAINT mirror_usage_logs_project_uuid_fkey
      FOREIGN KEY (project_uuid) REFERENCES public.projects(id) ON DELETE SET NULL NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'mirror_usage_logs_task_uuid_fkey'
      AND conrelid = 'public.mirror_usage_logs'::regclass
  ) THEN
    ALTER TABLE public.mirror_usage_logs
      ADD CONSTRAINT mirror_usage_logs_task_uuid_fkey
      FOREIGN KEY (task_uuid) REFERENCES public.tasks(id) ON DELETE SET NULL NOT VALID;
  END IF;
END;
$$;

ALTER TABLE public.ai_sessions VALIDATE CONSTRAINT ai_sessions_project_uuid_fkey;
ALTER TABLE public.ai_sessions VALIDATE CONSTRAINT ai_sessions_task_uuid_fkey;
ALTER TABLE public.mirror_apply_audit_events VALIDATE CONSTRAINT mirror_apply_audit_events_project_uuid_fkey;
ALTER TABLE public.mirror_apply_audit_events VALIDATE CONSTRAINT mirror_apply_audit_events_task_uuid_fkey;
ALTER TABLE public.mirror_usage_logs VALIDATE CONSTRAINT mirror_usage_logs_project_uuid_fkey;
ALTER TABLE public.mirror_usage_logs VALIDATE CONSTRAINT mirror_usage_logs_task_uuid_fkey;

-- ---------------------------------------------------------------------------
-- 7) UUID indexes for reporting and cleanup
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_ai_sessions_user_project_uuid_task_uuid
  ON public.ai_sessions (user_id, project_uuid, task_uuid, updated_at DESC);

CREATE INDEX IF NOT EXISTS idx_mirror_apply_audit_events_project_uuid_task_uuid
  ON public.mirror_apply_audit_events (project_uuid, task_uuid, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_mirror_usage_logs_project_uuid_task_uuid
  ON public.mirror_usage_logs (project_uuid, task_uuid, created_at DESC);

-- ---------------------------------------------------------------------------
-- 8) Realtime compatibility update (use UUID canonical values)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.broadcast_mirror_ai_sessions_changes()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  source_row RECORD;
  topic TEXT;
  topic_project_id TEXT;
  topic_task_id TEXT;
BEGIN
  source_row := CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;

  topic_project_id := COALESCE(source_row.project_uuid::text, source_row.project_id::text);
  topic_task_id := COALESCE(source_row.task_uuid::text, source_row.task_id::text);

  IF source_row.user_id IS NULL
     OR topic_project_id IS NULL
     OR topic_task_id IS NULL THEN
    RETURN source_row;
  END IF;

  topic := format(
    'mirror_ai_sessions:%s:%s:%s',
    source_row.user_id::text,
    topic_project_id,
    topic_task_id
  );

  PERFORM realtime.broadcast_changes(
    topic,
    'ai_session_update',
    TG_OP,
    TG_TABLE_NAME,
    TG_TABLE_SCHEMA,
    NEW,
    OLD
  );

  RETURN source_row;
END;
$$;

COMMIT;
