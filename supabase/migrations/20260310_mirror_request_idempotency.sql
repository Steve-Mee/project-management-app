-- Mirror gateway idempotency request ledger.
-- Ensures repeated gateway requests resolve to a stable request record.

BEGIN;

CREATE TABLE IF NOT EXISTS public.mirror_request_idempotency (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  idempotency_key TEXT NOT NULL,
  request_hash TEXT NOT NULL,
  request_id TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),
  expiry TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  CONSTRAINT mirror_request_idempotency_user_action_key_unique
    UNIQUE (user_id, action, idempotency_key)
);

CREATE INDEX IF NOT EXISTS idx_mirror_request_idempotency_user_created
  ON public.mirror_request_idempotency (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_mirror_request_idempotency_request_id
  ON public.mirror_request_idempotency (request_id);

CREATE INDEX IF NOT EXISTS idx_mirror_request_idempotency_expiry
  ON public.mirror_request_idempotency (expiry);

ALTER TABLE public.mirror_request_idempotency ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "mirror_request_idempotency_select_own" ON public.mirror_request_idempotency;
CREATE POLICY "mirror_request_idempotency_select_own"
ON public.mirror_request_idempotency
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "mirror_request_idempotency_insert_own" ON public.mirror_request_idempotency;
CREATE POLICY "mirror_request_idempotency_insert_own"
ON public.mirror_request_idempotency
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "mirror_request_idempotency_update_own" ON public.mirror_request_idempotency;
CREATE POLICY "mirror_request_idempotency_update_own"
ON public.mirror_request_idempotency
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "mirror_request_idempotency_delete_own" ON public.mirror_request_idempotency;
CREATE POLICY "mirror_request_idempotency_delete_own"
ON public.mirror_request_idempotency
FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.cleanup_mirror_request_idempotency_expired(
  batch_size INTEGER DEFAULT 1000
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  deleted_count INTEGER := 0;
BEGIN
  DELETE FROM public.mirror_request_idempotency
  WHERE expiry < NOW()
  AND (batch_size IS NULL OR (user_id, action, idempotency_key) IN (
    SELECT user_id, action, idempotency_key
    FROM public.mirror_request_idempotency
    WHERE expiry < NOW()
    ORDER BY expiry ASC
    LIMIT batch_size
  ));

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;

REVOKE ALL ON FUNCTION public.cleanup_mirror_request_idempotency_expired(INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cleanup_mirror_request_idempotency_expired(INTEGER) TO service_role;

COMMIT;
