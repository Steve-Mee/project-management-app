-- Mirror usage metering: per-request log for billing and abuse detection.
--
-- Adds:
-- 1) mirror_usage_logs table with user/project/task/mode/duration/token/status fields
-- 2) Indexes for per-user queries, per-project/task queries, and time-range scans
-- 3) RLS: authenticated users can insert and select their own rows (no update/delete)
-- 4) service_role-only cleanup function for retention pruning

BEGIN;

CREATE TABLE IF NOT EXISTS public.mirror_usage_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  project_id TEXT NOT NULL,
  task_id TEXT NOT NULL,
  mode TEXT NOT NULL CHECK (mode IN ('private', 'cloud')),
  action TEXT NOT NULL CHECK (action IN ('compile', 'apply')),
  duration_ms INTEGER CHECK (duration_ms IS NULL OR duration_ms >= 0),
  token_estimate INTEGER CHECK (token_estimate IS NULL OR token_estimate >= 0),
  status TEXT NOT NULL CHECK (status IN ('success', 'failed', 'rate_limited', 'timeout', 'upstream_error')),
  request_id TEXT,
  idempotency_key TEXT,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Fast per-user history queries (most recent first)
CREATE INDEX IF NOT EXISTS idx_mirror_usage_logs_user_created
  ON public.mirror_usage_logs (user_id, created_at DESC);

-- Aggregate queries per project / task
CREATE INDEX IF NOT EXISTS idx_mirror_usage_logs_project_task
  ON public.mirror_usage_logs (project_id, task_id, created_at DESC);

-- Time-range scans for abuse detection and billing windows
CREATE INDEX IF NOT EXISTS idx_mirror_usage_logs_created_at
  ON public.mirror_usage_logs (created_at DESC);

-- Status-filtered queries (e.g. count rate_limited events per user)
CREATE INDEX IF NOT EXISTS idx_mirror_usage_logs_user_status
  ON public.mirror_usage_logs (user_id, status, created_at DESC);

ALTER TABLE public.mirror_usage_logs ENABLE ROW LEVEL SECURITY;

-- Users may only read their own rows
DROP POLICY IF EXISTS "mirror_usage_logs_select_own" ON public.mirror_usage_logs;
CREATE POLICY "mirror_usage_logs_select_own"
ON public.mirror_usage_logs
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Users may only insert rows attributed to themselves
DROP POLICY IF EXISTS "mirror_usage_logs_insert_own" ON public.mirror_usage_logs;
CREATE POLICY "mirror_usage_logs_insert_own"
ON public.mirror_usage_logs
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- No user-facing UPDATE: metering rows are immutable once written
-- No user-facing DELETE: retention is service_role only (see cleanup function below)

-- Retention pruning function (service_role only).
-- Deletes rows older than retention_days belonging to a specific user,
-- or all users when user_id_filter is NULL.
CREATE OR REPLACE FUNCTION public.cleanup_mirror_usage_logs_retention(
  retention_days INTEGER DEFAULT 90,
  batch_size INTEGER DEFAULT 1000,
  user_id_filter UUID DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  deleted_count INTEGER := 0;
  cutoff TIMESTAMP WITH TIME ZONE;
BEGIN
  IF retention_days IS NULL OR retention_days < 1 THEN
    RAISE EXCEPTION 'retention_days must be a positive integer';
  END IF;

  IF batch_size IS NULL OR batch_size < 1 THEN
    RAISE EXCEPTION 'batch_size must be a positive integer';
  END IF;

  cutoff := NOW() - make_interval(days => retention_days);

  IF user_id_filter IS NOT NULL THEN
    DELETE FROM public.mirror_usage_logs
    WHERE id IN (
      SELECT id
      FROM public.mirror_usage_logs
      WHERE user_id = user_id_filter
        AND created_at < cutoff
      ORDER BY created_at ASC
      LIMIT batch_size
    );
  ELSE
    DELETE FROM public.mirror_usage_logs
    WHERE id IN (
      SELECT id
      FROM public.mirror_usage_logs
      WHERE created_at < cutoff
      ORDER BY created_at ASC
      LIMIT batch_size
    );
  END IF;

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;

REVOKE ALL ON FUNCTION public.cleanup_mirror_usage_logs_retention(INTEGER, INTEGER, UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cleanup_mirror_usage_logs_retention(INTEGER, INTEGER, UUID) TO service_role;

COMMIT;
