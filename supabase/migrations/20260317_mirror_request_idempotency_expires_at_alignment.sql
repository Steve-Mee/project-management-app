-- Mirror idempotency expiry field alignment (P0 blocker).
--
-- Aligns DB schema with thin gateway runtime contract by:
-- 1) Renaming expiry -> expires_at
-- 2) Ensuring response cache columns exist
-- 3) Updating index naming/definition for expires_at
-- 4) Replacing cleanup function logic to target expires_at

BEGIN;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'mirror_request_idempotency'
  ) THEN
    RAISE EXCEPTION 'mirror_request_idempotency table is required before running expires_at alignment migration';
  END IF;
END;
$$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'mirror_request_idempotency'
      AND column_name = 'expiry'
  )
  AND NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'mirror_request_idempotency'
      AND column_name = 'expires_at'
  ) THEN
    EXECUTE 'ALTER TABLE public.mirror_request_idempotency RENAME COLUMN expiry TO expires_at';
  END IF;
END;
$$;

ALTER TABLE public.mirror_request_idempotency
ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE public.mirror_request_idempotency
ADD COLUMN IF NOT EXISTS response_status INTEGER,
ADD COLUMN IF NOT EXISTS response_body TEXT,
ADD COLUMN IF NOT EXISTS response_content_type TEXT;

DROP INDEX IF EXISTS public.idx_mirror_request_idempotency_expiry;
CREATE INDEX IF NOT EXISTS idx_mirror_request_idempotency_expires_at
  ON public.mirror_request_idempotency (expires_at);

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
  WHERE expires_at < NOW()
  AND (batch_size IS NULL OR (user_id, action, idempotency_key) IN (
    SELECT user_id, action, idempotency_key
    FROM public.mirror_request_idempotency
    WHERE expires_at < NOW()
    ORDER BY expires_at ASC
    LIMIT batch_size
  ));

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;

REVOKE ALL ON FUNCTION public.cleanup_mirror_request_idempotency_expired(INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cleanup_mirror_request_idempotency_expired(INTEGER) TO service_role;

COMMIT;