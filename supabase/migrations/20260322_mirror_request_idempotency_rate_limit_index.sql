-- Mirror gateway rate-limit query index hardening.
--
-- Supports the per-user limiter query pattern:
--   user_id = ?
--   status IN ('processing', 'completed')
--   created_at >= window_start
--   expires_at > now()

BEGIN;

CREATE INDEX IF NOT EXISTS idx_mirror_request_idempotency_rate_limit_window
  ON public.mirror_request_idempotency (user_id, status, created_at DESC, expires_at DESC)
  WHERE status IN ('processing', 'completed');

COMMIT;
