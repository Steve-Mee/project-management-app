-- Mirror storage RLS contract test
-- Execute in Supabase SQL editor (service role) after migrations.

DO $$
DECLARE
  signed_inputs_exists boolean;
  backups_exists boolean;
  policy_count integer;
  owner_guard_count integer;
  cleanup_fn_exists boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM storage.buckets
    WHERE id = 'mirror-signed-inputs' AND public = false
  ) INTO signed_inputs_exists;

  IF NOT signed_inputs_exists THEN
    RAISE EXCEPTION 'Contract violation: private bucket mirror-signed-inputs missing';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM storage.buckets
    WHERE id = 'mirror-backups' AND public = false
  ) INTO backups_exists;

  IF NOT backups_exists THEN
    RAISE EXCEPTION 'Contract violation: private bucket mirror-backups missing';
  END IF;

  SELECT COUNT(*)
  INTO policy_count
  FROM pg_policies
  WHERE schemaname = 'storage'
    AND tablename = 'objects'
    AND policyname IN (
      'mirror_signed_inputs_insert_own',
      'mirror_signed_inputs_select_own',
      'mirror_signed_inputs_update_own',
      'mirror_signed_inputs_delete_own',
      'mirror_backups_insert_own',
      'mirror_backups_select_own',
      'mirror_backups_update_own',
      'mirror_backups_delete_own'
    );

  IF policy_count <> 8 THEN
    RAISE EXCEPTION 'Contract violation: expected 8 mirror storage policies, found %', policy_count;
  END IF;

  SELECT COUNT(*)
  INTO owner_guard_count
  FROM pg_policies
  WHERE schemaname = 'storage'
    AND tablename = 'objects'
    AND policyname IN (
      'mirror_signed_inputs_insert_own',
      'mirror_signed_inputs_select_own',
      'mirror_signed_inputs_update_own',
      'mirror_signed_inputs_delete_own',
      'mirror_backups_insert_own',
      'mirror_backups_select_own',
      'mirror_backups_update_own',
      'mirror_backups_delete_own'
    )
    AND (
      COALESCE(qual, '') LIKE '%storage.foldername(name)[1] = auth.uid()::text%'
      OR COALESCE(with_check, '') LIKE '%storage.foldername(name)[1] = auth.uid()::text%'
    );

  IF owner_guard_count < 8 THEN
    RAISE EXCEPTION 'Contract violation: one or more policies missing owner-folder guard';
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'cleanup_mirror_storage_objects'
  ) INTO cleanup_fn_exists;

  IF NOT cleanup_fn_exists THEN
    RAISE EXCEPTION 'Contract violation: cleanup_mirror_storage_objects function missing';
  END IF;

  RAISE NOTICE 'Mirror storage RLS contract checks passed';
END;
$$;
