-- Mirror idempotency response cache columns (P0 blocker).
--
-- Adds response cache columns required by the runtime idempotency contract:
-- 1) response_status INTEGER
-- 2) response_body TEXT
-- 3) response_content_type TEXT

BEGIN;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'mirror_request_idempotency'
  ) THEN
    RAISE EXCEPTION 'mirror_request_idempotency table is required before running response cache column migration';
  END IF;
END;
$$;

ALTER TABLE public.mirror_request_idempotency
ADD COLUMN IF NOT EXISTS response_status INTEGER,
ADD COLUMN IF NOT EXISTS response_body TEXT,
ADD COLUMN IF NOT EXISTS response_content_type TEXT;

COMMIT;