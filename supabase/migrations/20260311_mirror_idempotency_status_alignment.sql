-- Mirror idempotency status alignment (P0 blocker).
--
-- Aligns the status contract with runtime behavior by:
-- 1) Migrating legacy 'pending' rows to 'processing'
-- 2) Updating status default to 'processing'
-- 3) Replacing status CHECK constraint with processing/completed/failed

BEGIN;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'mirror_request_idempotency'
  ) THEN
    RAISE EXCEPTION 'mirror_request_idempotency table is required before running status alignment migration';
  END IF;
END;
$$;

UPDATE public.mirror_request_idempotency
SET status = 'processing'
WHERE status = 'pending';

ALTER TABLE public.mirror_request_idempotency
ALTER COLUMN status SET DEFAULT 'processing';

DO $$
DECLARE
  check_constraint RECORD;
BEGIN
  FOR check_constraint IN
    SELECT c.conname
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE n.nspname = 'public'
      AND t.relname = 'mirror_request_idempotency'
      AND c.contype = 'c'
      AND pg_get_constraintdef(c.oid) ILIKE '%status%'
  LOOP
    EXECUTE format(
      'ALTER TABLE public.mirror_request_idempotency DROP CONSTRAINT IF EXISTS %I',
      check_constraint.conname
    );
  END LOOP;
END;
$$;

ALTER TABLE public.mirror_request_idempotency
ADD CONSTRAINT mirror_request_idempotency_status_check
CHECK (status IN ('processing', 'completed', 'failed'));

DO $$
DECLARE
  invalid_count INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO invalid_count
  FROM public.mirror_request_idempotency
  WHERE status NOT IN ('processing', 'completed', 'failed');

  IF invalid_count > 0 THEN
    RAISE EXCEPTION 'status alignment failed: found % invalid status rows after migration', invalid_count;
  END IF;
END;
$$;

COMMIT;
