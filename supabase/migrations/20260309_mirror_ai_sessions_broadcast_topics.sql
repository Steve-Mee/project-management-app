-- Mirror ai_sessions realtime broadcast topics
-- Replaces broad table listeners with scoped broadcast topics:
-- mirror_ai_sessions:<user_id>:<project_id>:<task_id>

BEGIN;

-- Allow authenticated clients to receive only topics bound to their user id.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'realtime'
      AND tablename = 'messages'
      AND policyname = 'mirror_ai_sessions_broadcast_select_own'
  ) THEN
    CREATE POLICY "mirror_ai_sessions_broadcast_select_own"
    ON realtime.messages
    FOR SELECT
    TO authenticated
    USING (split_part(realtime.topic(), ':', 2) = auth.uid()::text);
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.broadcast_mirror_ai_sessions_changes()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  source_row RECORD;
  topic TEXT;
BEGIN
  source_row := CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;

  IF source_row.user_id IS NULL
     OR source_row.project_id IS NULL
     OR source_row.task_id IS NULL THEN
    RETURN source_row;
  END IF;

  topic := format(
    'mirror_ai_sessions:%s:%s:%s',
    source_row.user_id::text,
    source_row.project_id::text,
    source_row.task_id::text
  );

  PERFORM realtime.broadcast_changes(
    topic,
    'ai_session_update',
    TG_OP,
    TG_TABLE_NAME,
    TG_TABLE_SCHEMA,
    NEW,
    OLD
  );

  RETURN source_row;
END;
$$;

DROP TRIGGER IF EXISTS trg_mirror_ai_sessions_broadcast ON public.ai_sessions;
CREATE TRIGGER trg_mirror_ai_sessions_broadcast
AFTER INSERT OR UPDATE OR DELETE ON public.ai_sessions
FOR EACH ROW
EXECUTE FUNCTION public.broadcast_mirror_ai_sessions_changes();

COMMIT;
