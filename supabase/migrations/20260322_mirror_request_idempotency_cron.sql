-- Mirror request idempotency cleanup schedule.
--
-- Operationalizes cleanup_mirror_request_idempotency_expired() via pg_cron.
-- Schedule policy:
-- - Every 15 minutes
-- - Batch size: 2000 rows
--
-- Idempotent behavior:
-- - If a job with the same name exists, unschedule it first
-- - Then create the canonical schedule definition

BEGIN;

DO $$
DECLARE
  existing_job_id BIGINT;
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron')
     AND to_regprocedure('public.cleanup_mirror_request_idempotency_expired(integer)') IS NOT NULL THEN
    SELECT jobid
    INTO existing_job_id
    FROM cron.job
    WHERE jobname = 'mirror_idempotency_cleanup_q15'
    LIMIT 1;

    IF existing_job_id IS NOT NULL THEN
      PERFORM cron.unschedule(existing_job_id);
    END IF;

    PERFORM cron.schedule(
      'mirror_idempotency_cleanup_q15',
      '*/15 * * * *',
      $cron$SELECT public.cleanup_mirror_request_idempotency_expired(2000);$cron$
    );
  END IF;
END;
$$;

COMMIT;
