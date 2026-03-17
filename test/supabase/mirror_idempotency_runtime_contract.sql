-- Mirror idempotency runtime contract test
-- Execute in Supabase SQL editor (service role) after migrations.

DO $$
DECLARE
  table_exists boolean;
  required_columns_count integer;
  required_column_types_count integer;
  legacy_expiry_exists boolean;
  expires_at_index_exists boolean;
  cleanup_fn_exists boolean;
  cleanup_fn_def text;
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

  SELECT COUNT(*)
  INTO required_columns_count
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'mirror_request_idempotency'
    AND column_name IN (
      'expires_at',
      'response_status',
      'response_body',
      'response_content_type'
    );

  IF required_columns_count <> 4 THEN
    RAISE EXCEPTION 'Contract violation: expected expires_at + 3 response cache columns, found %', required_columns_count;
  END IF;

  SELECT COUNT(*)
  INTO required_column_types_count
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'mirror_request_idempotency'
    AND (
      (column_name = 'expires_at' AND data_type = 'timestamp with time zone')
      OR (column_name = 'response_status' AND data_type = 'integer')
      OR (column_name = 'response_body' AND data_type = 'text')
      OR (column_name = 'response_content_type' AND data_type = 'text')
    );

  IF required_column_types_count <> 4 THEN
    RAISE EXCEPTION 'Contract violation: one or more runtime columns have unexpected data types';
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'mirror_request_idempotency'
      AND column_name = 'expiry'
  ) INTO legacy_expiry_exists;

  IF legacy_expiry_exists THEN
    RAISE EXCEPTION 'Contract violation: legacy expiry column still present';
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'mirror_request_idempotency'
      AND indexname = 'idx_mirror_request_idempotency_expires_at'
      AND indexdef ILIKE '%(expires_at)%'
  ) INTO expires_at_index_exists;

  IF NOT expires_at_index_exists THEN
    RAISE EXCEPTION 'Contract violation: missing idx_mirror_request_idempotency_expires_at on expires_at';
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'cleanup_mirror_request_idempotency_expired'
  ) INTO cleanup_fn_exists;

  IF NOT cleanup_fn_exists THEN
    RAISE EXCEPTION 'Contract violation: cleanup_mirror_request_idempotency_expired function missing';
  END IF;

  SELECT pg_get_functiondef(p.oid)
  INTO cleanup_fn_def
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname = 'cleanup_mirror_request_idempotency_expired'
  LIMIT 1;

  IF COALESCE(cleanup_fn_def, '') NOT ILIKE '%expires_at%' THEN
    RAISE EXCEPTION 'Contract violation: cleanup function must reference expires_at';
  END IF;

  IF COALESCE(cleanup_fn_def, '') ILIKE '%expiry%' THEN
    RAISE EXCEPTION 'Contract violation: cleanup function still references legacy expiry';
  END IF;

  RAISE NOTICE 'Mirror idempotency runtime contract checks passed';
END;
$$;