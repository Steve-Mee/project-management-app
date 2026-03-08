-- Mirror storage hardening
-- Adds private buckets used by Mirror apply flow, enforces owner-only folder access,
-- and applies a 7-day object lifecycle for signed URL artifacts.

BEGIN;

-- 1) Buckets
INSERT INTO storage.buckets (id, name, public)
VALUES ('mirror-signed-inputs', 'mirror-signed-inputs', false)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('mirror-backups', 'mirror-backups', false)
ON CONFLICT (id) DO NOTHING;

-- 2) Owner-only RLS for mirror-signed-inputs
DROP POLICY IF EXISTS "mirror_signed_inputs_insert_own" ON storage.objects;
CREATE POLICY "mirror_signed_inputs_insert_own"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'mirror-signed-inputs'
  AND storage.foldername(name)[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "mirror_signed_inputs_select_own" ON storage.objects;
CREATE POLICY "mirror_signed_inputs_select_own"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'mirror-signed-inputs'
  AND storage.foldername(name)[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "mirror_signed_inputs_update_own" ON storage.objects;
CREATE POLICY "mirror_signed_inputs_update_own"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'mirror-signed-inputs'
  AND storage.foldername(name)[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'mirror-signed-inputs'
  AND storage.foldername(name)[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "mirror_signed_inputs_delete_own" ON storage.objects;
CREATE POLICY "mirror_signed_inputs_delete_own"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'mirror-signed-inputs'
  AND storage.foldername(name)[1] = auth.uid()::text
);

-- 3) Owner-only RLS for mirror-backups
DROP POLICY IF EXISTS "mirror_backups_insert_own" ON storage.objects;
CREATE POLICY "mirror_backups_insert_own"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'mirror-backups'
  AND storage.foldername(name)[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "mirror_backups_select_own" ON storage.objects;
CREATE POLICY "mirror_backups_select_own"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'mirror-backups'
  AND storage.foldername(name)[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "mirror_backups_update_own" ON storage.objects;
CREATE POLICY "mirror_backups_update_own"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'mirror-backups'
  AND storage.foldername(name)[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'mirror-backups'
  AND storage.foldername(name)[1] = auth.uid()::text
);

DROP POLICY IF EXISTS "mirror_backups_delete_own" ON storage.objects;
CREATE POLICY "mirror_backups_delete_own"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'mirror-backups'
  AND storage.foldername(name)[1] = auth.uid()::text
);

-- 4) 7-day lifecycle cleanup for signed URL artifacts
CREATE OR REPLACE FUNCTION public.cleanup_mirror_storage_objects(
  retention_days integer DEFAULT 7
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, storage
AS $$
DECLARE
  deleted_count integer := 0;
BEGIN
  DELETE FROM storage.objects
  WHERE bucket_id IN ('mirror-signed-inputs', 'mirror-backups')
    AND created_at < (now() - make_interval(days => retention_days));

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;

REVOKE ALL ON FUNCTION public.cleanup_mirror_storage_objects(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cleanup_mirror_storage_objects(integer) TO service_role;

-- Optional: schedule hourly cleanup if pg_cron is enabled.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    IF NOT EXISTS (
      SELECT 1
      FROM cron.job
      WHERE jobname = 'mirror_storage_cleanup_hourly'
    ) THEN
      PERFORM cron.schedule(
        'mirror_storage_cleanup_hourly',
        '0 * * * *',
        $$SELECT public.cleanup_mirror_storage_objects(7);$$
      );
    END IF;
  END IF;
END;
$$;

COMMIT;
