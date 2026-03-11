-- Mirror idempotency status contract test
-- Execute in Supabase SQL editor (service role) after migrations.

DO $$
DECLARE
  table_exists boolean;
  status_column_exists boolean;
  status_default_expr text;
  status_check_exists boolean;
  status_check_def text;
  pending_rows integer;
  invalid_rows integer;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'mirror_request_idempotency'
  ) INTO table_exists;

  IF NOT table_exists THEN
    RAISE EXCEPTION 'Contract violation: mirror_request_idempotency table missing';
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'mirror_request_idempotency'
      AND column_name = 'status'
  ) INTO status_column_exists;

  IF NOT status_column_exists THEN
    RAISE EXCEPTION 'Contract violation: status column missing on mirror_request_idempotency';
  END IF;

  SELECT pg_get_expr(d.adbin, d.adrelid)
  INTO status_default_expr
  FROM pg_attribute a
  JOIN pg_class t ON t.oid = a.attrelid
  JOIN pg_namespace n ON n.oid = t.relnamespace
  LEFT JOIN pg_attrdef d ON d.adrelid = a.attrelid AND d.adnum = a.attnum
  WHERE n.nspname = 'public'
    AND t.relname = 'mirror_request_idempotency'
    AND a.attname = 'status'
    AND NOT a.attisdropped;

  IF COALESCE(status_default_expr, '') NOT IN ('''processing''::text', '''processing''') THEN
    RAISE EXCEPTION 'Contract violation: status default must be processing, found %', COALESCE(status_default_expr, '<null>');
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE n.nspname = 'public'
      AND t.relname = 'mirror_request_idempotency'
      AND c.conname = 'mirror_request_idempotency_status_check'
      AND c.contype = 'c'
  ) INTO status_check_exists;

  IF NOT status_check_exists THEN
    RAISE EXCEPTION 'Contract violation: mirror_request_idempotency_status_check missing';
  END IF;

  SELECT pg_get_constraintdef(c.oid)
  INTO status_check_def
  FROM pg_constraint c
  JOIN pg_class t ON t.oid = c.conrelid
  JOIN pg_namespace n ON n.oid = t.relnamespace
  WHERE n.nspname = 'public'
    AND t.relname = 'mirror_request_idempotency'
    AND c.conname = 'mirror_request_idempotency_status_check'
    AND c.contype = 'c'
  LIMIT 1;

  IF COALESCE(status_check_def, '') NOT ILIKE '%processing%'
     OR COALESCE(status_check_def, '') NOT ILIKE '%completed%'
     OR COALESCE(status_check_def, '') NOT ILIKE '%failed%' THEN
    RAISE EXCEPTION 'Contract violation: status CHECK must include processing/completed/failed, found %', COALESCE(status_check_def, '<null>');
  END IF;

  SELECT COUNT(*)
  INTO pending_rows
  FROM public.mirror_request_idempotency
  WHERE status = 'pending';

  IF pending_rows <> 0 THEN
    RAISE EXCEPTION 'Contract violation: expected 0 pending rows after alignment, found %', pending_rows;
  END IF;

  SELECT COUNT(*)
  INTO invalid_rows
  FROM public.mirror_request_idempotency
  WHERE status NOT IN ('processing', 'completed', 'failed');

  IF invalid_rows <> 0 THEN
    RAISE EXCEPTION 'Contract violation: found % rows with invalid status values', invalid_rows;
  END IF;

  RAISE NOTICE 'Mirror idempotency status contract checks passed';
END;
$$;
