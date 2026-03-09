-- Idempotente baseline voor public.ai_sessions
-- Zorgt voor tabel, kolommen, indexen, RLS en canonical owner policy.

BEGIN;

CREATE TABLE IF NOT EXISTS public.ai_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  project_id TEXT NOT NULL,
  task_id TEXT NOT NULL,
  prompt TEXT NOT NULL DEFAULT '',
  mode TEXT NOT NULL DEFAULT 'private' CHECK (mode IN ('private', 'cloud')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'running', 'completed', 'failed')),
  versions JSONB NOT NULL DEFAULT '[]'::jsonb,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.ai_sessions
  ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid(),
  ADD COLUMN IF NOT EXISTS user_id UUID,
  ADD COLUMN IF NOT EXISTS project_id TEXT,
  ADD COLUMN IF NOT EXISTS task_id TEXT,
  ADD COLUMN IF NOT EXISTS prompt TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS mode TEXT DEFAULT 'private',
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS versions JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'ai_sessions_pkey'
      AND conrelid = 'public.ai_sessions'::regclass
  ) THEN
    ALTER TABLE public.ai_sessions
      ADD CONSTRAINT ai_sessions_pkey PRIMARY KEY (id);
  END IF;
END;
$$;

ALTER TABLE public.ai_sessions
  ALTER COLUMN id SET DEFAULT gen_random_uuid(),
  ALTER COLUMN user_id SET NOT NULL,
  ALTER COLUMN project_id SET NOT NULL,
  ALTER COLUMN task_id SET NOT NULL,
  ALTER COLUMN prompt SET NOT NULL,
  ALTER COLUMN mode SET NOT NULL,
  ALTER COLUMN status SET NOT NULL,
  ALTER COLUMN versions SET NOT NULL,
  ALTER COLUMN metadata SET NOT NULL,
  ALTER COLUMN created_at SET NOT NULL,
  ALTER COLUMN updated_at SET NOT NULL;

ALTER TABLE public.ai_sessions
  DROP CONSTRAINT IF EXISTS ai_sessions_mode_check,
  ADD CONSTRAINT ai_sessions_mode_check
    CHECK (mode IN ('private', 'cloud'));

ALTER TABLE public.ai_sessions
  DROP CONSTRAINT IF EXISTS ai_sessions_status_check,
  ADD CONSTRAINT ai_sessions_status_check
    CHECK (status IN ('pending', 'running', 'completed', 'failed'));

CREATE INDEX IF NOT EXISTS idx_ai_sessions_user_project_task
  ON public.ai_sessions (user_id, project_id, task_id);

CREATE INDEX IF NOT EXISTS idx_ai_sessions_updated_at
  ON public.ai_sessions (updated_at DESC);

CREATE OR REPLACE FUNCTION public.set_ai_sessions_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_ai_sessions_set_updated_at ON public.ai_sessions;
CREATE TRIGGER trg_ai_sessions_set_updated_at
BEFORE UPDATE ON public.ai_sessions
FOR EACH ROW
EXECUTE FUNCTION public.set_ai_sessions_updated_at();

ALTER TABLE public.ai_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ai_sessions_select_policy" ON public.ai_sessions;
DROP POLICY IF EXISTS "ai_sessions_insert_policy" ON public.ai_sessions;
DROP POLICY IF EXISTS "ai_sessions_update_policy" ON public.ai_sessions;
DROP POLICY IF EXISTS "ai_sessions_delete_policy" ON public.ai_sessions;
DROP POLICY IF EXISTS "ai_sessions_owner_read" ON public.ai_sessions;
DROP POLICY IF EXISTS "ai_sessions_owner_write" ON public.ai_sessions;
DROP POLICY IF EXISTS "ai_sessions_owner_policy" ON public.ai_sessions;

CREATE POLICY "ai_sessions_owner_policy" ON public.ai_sessions
FOR ALL TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

COMMIT;
