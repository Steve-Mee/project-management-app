-- Mirror idempotency contract test
-- Execute in Supabase SQL editor (service role) after migrations.

DO $$
DECLARE
  table_exists boolean;
  expected_column_count integer;
  required_column_types_count integer;
  unique_guard_exists boolean;
  rls_enabled boolean;
  policy_count integer;
  owner_guard_count integer;
  idx_user_created_exists boolean;
  idx_request_id_exists boolean;
  idx_expires_at_exists boolean;
  cleanup_fn_exists boolean;
  cleanup_fn_security_definer boolean;
  status_default_expr text;
  status_check_exists boolean;
  status_check_def text;
  invalid_status_rows integer;
  legacy_expiry_exists boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'mirror_request_idempotency'
  ) INTO table_exists;

  IF NOT table_exists THEN
    RAISE EXCEPTION 'Contract violation: mirror_request_idempotency table missing';
  END IF;

  SELECT COUNT(*)
  INTO expected_column_count
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name = 'mirror_request_idempotency'
    AND column_name IN (
      'user_id',
      'action',
      'idempotency_key',
      'request_hash',
      'request_id',
      'status',
      'expires_at',
      'created_at',
      'response_status',
      'response_body',
      'response_content_type'
    );

  IF expected_column_count <> 11 THEN
    RAISE EXCEPTION 'Contract violation: expected 11 required columns on mirror_request_idempotency, found %', expected_column_count;
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
    RAISE EXCEPTION 'Contract violation: runtime response cache columns have unexpected data types';
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
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE n.nspname = 'public'
      AND t.relname = 'mirror_request_idempotency'
      AND c.contype IN ('u', 'p')
      AND c.conkey = ARRAY[
        (SELECT attnum FROM pg_attribute WHERE attrelid = t.oid AND attname = 'user_id' AND NOT attisdropped),
        (SELECT attnum FROM pg_attribute WHERE attrelid = t.oid AND attname = 'action' AND NOT attisdropped),
        (SELECT attnum FROM pg_attribute WHERE attrelid = t.oid AND attname = 'idempotency_key' AND NOT attisdropped)
      ]::smallint[]
  ) INTO unique_guard_exists;

  IF NOT unique_guard_exists THEN
    RAISE EXCEPTION 'Contract violation: missing UNIQUE/PRIMARY KEY guard on (user_id, action, idempotency_key)';
  END IF;

  SELECT c.relrowsecurity
  INTO rls_enabled
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relname = 'mirror_request_idempotency';

  IF COALESCE(rls_enabled, false) = false THEN
    RAISE EXCEPTION 'Contract violation: RLS is not enabled on mirror_request_idempotency';
  END IF;

  SELECT COUNT(*)
  INTO policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'mirror_request_idempotency'
    AND policyname IN (
      'mirror_request_idempotency_select_own',
      'mirror_request_idempotency_insert_own',
      'mirror_request_idempotency_update_own',
      'mirror_request_idempotency_delete_own'
    );

  IF policy_count <> 4 THEN
    RAISE EXCEPTION 'Contract violation: expected 4 owner policies, found %', policy_count;
  END IF;

  SELECT COUNT(*)
  INTO owner_guard_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'mirror_request_idempotency'
    AND policyname IN (
      'mirror_request_idempotency_select_own',
      'mirror_request_idempotency_insert_own',
      'mirror_request_idempotency_update_own',
      'mirror_request_idempotency_delete_own'
    )
    AND (
      COALESCE(qual, '') LIKE '%auth.uid() = user_id%'
      OR COALESCE(with_check, '') LIKE '%auth.uid() = user_id%'
    );

  IF owner_guard_count < 4 THEN
    RAISE EXCEPTION 'Contract violation: one or more policies missing auth.uid owner guard';
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'mirror_request_idempotency'
      AND indexname = 'idx_mirror_request_idempotency_user_created'
      AND indexdef LIKE '%(user_id, created_at DESC)%'
  ) INTO idx_user_created_exists;

  IF NOT idx_user_created_exists THEN
    RAISE EXCEPTION 'Contract violation: missing idx_mirror_request_idempotency_user_created';
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'mirror_request_idempotency'
      AND indexname = 'idx_mirror_request_idempotency_request_id'
      AND indexdef LIKE '%(request_id)%'
  ) INTO idx_request_id_exists;

  IF NOT idx_request_id_exists THEN
    RAISE EXCEPTION 'Contract violation: missing idx_mirror_request_idempotency_request_id';
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'mirror_request_idempotency'
      AND indexname = 'idx_mirror_request_idempotency_expires_at'
      AND indexdef LIKE '%(expires_at)%'
  ) INTO idx_expires_at_exists;

  IF NOT idx_expires_at_exists THEN
    RAISE EXCEPTION 'Contract violation: missing idx_mirror_request_idempotency_expires_at';
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

  SELECT p.prosecdef
  INTO cleanup_fn_security_definer
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname = 'cleanup_mirror_request_idempotency_expired'
  LIMIT 1;

  IF COALESCE(cleanup_fn_security_definer, false) = false THEN
    RAISE EXCEPTION 'Contract violation: cleanup function must be SECURITY DEFINER';
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
  INTO invalid_status_rows
  FROM public.mirror_request_idempotency
  WHERE status NOT IN ('processing', 'completed', 'failed');

  IF invalid_status_rows <> 0 THEN
    RAISE EXCEPTION 'Contract violation: found % rows with invalid status values', invalid_status_rows;
  END IF;

  RAISE NOTICE 'Mirror idempotency contract checks passed';
END;
$$;
