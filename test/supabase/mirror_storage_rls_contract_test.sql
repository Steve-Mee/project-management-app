-- Mirror storage RLS contract test
-- Execute in Supabase SQL editor (service role) after migrations.

DO $$
DECLARE
  owner_uid uuid := '00000000-0000-0000-0000-000000000123'::uuid;
  signed_inputs_exists boolean;
  backups_exists boolean;
  policy_count integer;
  owner_guard_count integer;
  cleanup_fn_exists boolean;
  owner_path text := 'owner-uid-123/project-1/task-1/backup-1/input/lib/main.dart';
  non_owner_path text := 'other-uid-999/project-1/task-1/backup-1/input/lib/main.dart';
  owner_insert_ok boolean := false;
  non_owner_blocked boolean := false;
  can_probe_with_authenticated_role boolean := true;
  owner_probe_name text := owner_uid::text || '/project-rls/task-rls/backup-rls/input/owner_probe.txt';
  non_owner_probe_name text := 'other-uid-999/project-rls/task-rls/backup-rls/input/non_owner_probe.txt';
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

  PERFORM set_config('request.jwt.claim.sub', owner_uid::text, true);

  IF auth.uid() IS DISTINCT FROM owner_uid THEN
    RAISE EXCEPTION 'Contract violation: auth.uid context simulation failed';
  END IF;

  IF storage.foldername(owner_path)[1] <> auth.uid()::text THEN
    RAISE EXCEPTION 'Contract violation: owner path must resolve to auth.uid first segment';
  END IF;

  IF storage.foldername(non_owner_path)[1] = auth.uid()::text THEN
    RAISE EXCEPTION 'Contract violation: non-owner path must not resolve to auth.uid first segment';
  END IF;

  IF storage.foldername(owner_path)[1] <> 'owner-uid-123' THEN
    RAISE EXCEPTION 'Contract violation: owner path no longer resolves uid in first folder segment';
  END IF;

  IF storage.foldername(non_owner_path)[1] = 'owner-uid-123' THEN
    RAISE EXCEPTION 'Contract violation: non-owner path unexpectedly matches owner uid segment';
  END IF;

  -- Optional live probe: verify owner/non-owner write behavior under authenticated role.
  -- Some SQL execution contexts may not allow role switch; in that case, static policy checks above remain authoritative.
  BEGIN
    EXECUTE 'SET LOCAL ROLE authenticated';
  EXCEPTION WHEN OTHERS THEN
    can_probe_with_authenticated_role := false;
    RAISE NOTICE 'Mirror contract: skipping live RLS probe because role switch failed: %', SQLERRM;
  END;

  IF can_probe_with_authenticated_role THEN
    BEGIN
      INSERT INTO storage.objects (bucket_id, name)
      VALUES ('mirror-signed-inputs', owner_probe_name);
      owner_insert_ok := true;
    EXCEPTION WHEN OTHERS THEN
      owner_insert_ok := false;
    END;

    BEGIN
      INSERT INTO storage.objects (bucket_id, name)
      VALUES ('mirror-signed-inputs', non_owner_probe_name);
      non_owner_blocked := false;
    EXCEPTION WHEN OTHERS THEN
      non_owner_blocked := true;
    END;

    IF NOT owner_insert_ok THEN
      RAISE EXCEPTION 'Contract violation: owner path insert should be allowed under authenticated role';
    END IF;

    IF NOT non_owner_blocked THEN
      RAISE EXCEPTION 'Contract violation: non-owner path insert should be denied under authenticated role';
    END IF;

    DELETE FROM storage.objects
    WHERE bucket_id = 'mirror-signed-inputs'
      AND name = owner_probe_name;
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

  RAISE NOTICE 'Mirror storage RLS contract checks passed (policy + path-shape)';
END;
$$;
