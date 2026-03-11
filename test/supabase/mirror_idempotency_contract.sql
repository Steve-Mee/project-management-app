-- Mirror idempotency contract test
-- Execute in Supabase SQL editor (service role) after migrations.

DO $$
DECLARE
  table_exists boolean;
  expected_column_count integer;
  unique_guard_exists boolean;
  rls_enabled boolean;
  policy_count integer;
  owner_guard_count integer;
  idx_user_created_exists boolean;
  idx_request_id_exists boolean;
  idx_expiry_exists boolean;
  cleanup_fn_exists boolean;
  cleanup_fn_security_definer boolean;
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
      'expiry',
      'created_at'
    );

  IF expected_column_count <> 8 THEN
    RAISE EXCEPTION 'Contract violation: expected 8 required columns on mirror_request_idempotency, found %', expected_column_count;
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
      AND indexname = 'idx_mirror_request_idempotency_expiry'
      AND indexdef LIKE '%(expiry)%'
  ) INTO idx_expiry_exists;

  IF NOT idx_expiry_exists THEN
    RAISE EXCEPTION 'Contract violation: missing idx_mirror_request_idempotency_expiry';
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

  RAISE NOTICE 'Mirror idempotency contract checks passed';
END;
$$;
