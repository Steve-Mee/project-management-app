-- Mirror backend audit trail + ai_sessions retention hardening
--
-- Adds:
-- 1) Canonical backend apply audit table with actor/artifact/fingerprint fields
-- 2) RLS so each authenticated user can only read/write own audit events
-- 3) Retention helpers for old ai_sessions rows and oversized versions payloads

BEGIN;

CREATE TABLE IF NOT EXISTS public.mirror_apply_audit_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  project_id TEXT NOT NULL,
  task_id TEXT NOT NULL,
  mode TEXT NOT NULL CHECK (mode IN ('private', 'cloud')),
  event TEXT NOT NULL CHECK (event IN ('apply_started', 'apply_completed', 'apply_failed')),
  request_id TEXT,
  idempotency_key TEXT,
  backup_id TEXT,
  success BOOLEAN,
  actor_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  file_set_fingerprint TEXT,
  applied_files_fingerprint TEXT,
  diff_fingerprint TEXT,
  artifact_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
  details JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mirror_apply_audit_events_user_created
  ON public.mirror_apply_audit_events (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_mirror_apply_audit_events_project_task
  ON public.mirror_apply_audit_events (project_id, task_id, created_at DESC);

ALTER TABLE public.mirror_apply_audit_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "mirror_apply_audit_events_select_own" ON public.mirror_apply_audit_events;
CREATE POLICY "mirror_apply_audit_events_select_own"
ON public.mirror_apply_audit_events
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "mirror_apply_audit_events_insert_own" ON public.mirror_apply_audit_events;
CREATE POLICY "mirror_apply_audit_events_insert_own"
ON public.mirror_apply_audit_events
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id
  AND (actor_user_id IS NULL OR actor_user_id = auth.uid())
);

DROP POLICY IF EXISTS "mirror_apply_audit_events_update_own" ON public.mirror_apply_audit_events;
CREATE POLICY "mirror_apply_audit_events_update_own"
ON public.mirror_apply_audit_events
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "mirror_apply_audit_events_delete_own" ON public.mirror_apply_audit_events;
CREATE POLICY "mirror_apply_audit_events_delete_own"
ON public.mirror_apply_audit_events
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.cleanup_ai_sessions_retention(
  retention_days INTEGER DEFAULT 30,
  max_versions_per_session INTEGER DEFAULT 50
)
RETURNS TABLE (deleted_rows INTEGER, trimmed_rows INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  deleted_count INTEGER := 0;
  trimmed_count INTEGER := 0;
BEGIN
  DELETE FROM public.ai_sessions
  WHERE status IN ('completed', 'failed')
    AND updated_at < (NOW() - make_interval(days => retention_days));

  GET DIAGNOSTICS deleted_count = ROW_COUNT;

  UPDATE public.ai_sessions
  SET versions = (
    SELECT COALESCE(
      jsonb_agg(v.elem ORDER BY v.ord),
      '[]'::jsonb
    )
    FROM jsonb_array_elements(public.ai_sessions.versions) WITH ORDINALITY AS v(elem, ord)
    WHERE v.ord > GREATEST(jsonb_array_length(public.ai_sessions.versions) - max_versions_per_session, 0)
  )
  WHERE jsonb_typeof(versions) = 'array'
    AND jsonb_array_length(versions) > max_versions_per_session;

  GET DIAGNOSTICS trimmed_count = ROW_COUNT;

  RETURN QUERY SELECT deleted_count, trimmed_count;
END;
$$;

REVOKE ALL ON FUNCTION public.cleanup_ai_sessions_retention(INTEGER, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cleanup_ai_sessions_retention(INTEGER, INTEGER) TO service_role;

-- Optional: schedule daily cleanup + trim job if pg_cron is available.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    IF NOT EXISTS (
      SELECT 1
      FROM cron.job
      WHERE jobname = 'mirror_ai_sessions_retention_daily'
    ) THEN
      PERFORM cron.schedule(
        'mirror_ai_sessions_retention_daily',
        '30 2 * * *',
        $$SELECT * FROM public.cleanup_ai_sessions_retention(30, 50);$$
      );
    END IF;
  END IF;
END;
$$;

COMMIT;
