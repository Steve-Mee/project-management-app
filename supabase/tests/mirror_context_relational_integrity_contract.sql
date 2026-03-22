-- Mirror context relational integrity contract test
-- Execute in Supabase SQL editor (service role) after migrations.
-- Goal: verify UUID context columns and FK constraints exist as expected.

DO $$
DECLARE
  ai_sessions_exists boolean;
  audit_exists boolean;
  usage_exists boolean;

  ai_project_uuid_not_null boolean;
  ai_task_uuid_not_null boolean;

  ai_project_fk_exists boolean;
  ai_task_fk_exists boolean;
  audit_project_fk_exists boolean;
  audit_task_fk_exists boolean;
  usage_project_fk_exists boolean;
  usage_task_fk_exists boolean;

  ai_project_fk_validated boolean;
  ai_task_fk_validated boolean;
  audit_project_fk_validated boolean;
  audit_task_fk_validated boolean;
  usage_project_fk_validated boolean;
  usage_task_fk_validated boolean;

  idx_ai_exists boolean;
  idx_audit_exists boolean;
  idx_usage_exists boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'ai_sessions'
  ) INTO ai_sessions_exists;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'mirror_apply_audit_events'
  ) INTO audit_exists;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'mirror_usage_logs'
  ) INTO usage_exists;

  IF NOT ai_sessions_exists OR NOT audit_exists OR NOT usage_exists THEN
    RAISE EXCEPTION 'Contract violation: required Mirror context tables are missing';
  END IF;

  SELECT (c.is_nullable = 'NO')
  INTO ai_project_uuid_not_null
  FROM information_schema.columns c
  WHERE c.table_schema = 'public'
    AND c.table_name = 'ai_sessions'
    AND c.column_name = 'project_uuid'
  LIMIT 1;

  SELECT (c.is_nullable = 'NO')
  INTO ai_task_uuid_not_null
  FROM information_schema.columns c
  WHERE c.table_schema = 'public'
    AND c.table_name = 'ai_sessions'
    AND c.column_name = 'task_uuid'
  LIMIT 1;

  IF COALESCE(ai_project_uuid_not_null, false) IS NOT true THEN
    RAISE EXCEPTION 'Contract violation: ai_sessions.project_uuid must be NOT NULL';
  END IF;

  IF COALESCE(ai_task_uuid_not_null, false) IS NOT true THEN
    RAISE EXCEPTION 'Contract violation: ai_sessions.task_uuid must be NOT NULL';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'ai_sessions_project_uuid_fkey'
      AND conrelid = 'public.ai_sessions'::regclass
  ) INTO ai_project_fk_exists;

  SELECT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'ai_sessions_task_uuid_fkey'
      AND conrelid = 'public.ai_sessions'::regclass
  ) INTO ai_task_fk_exists;

  SELECT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'mirror_apply_audit_events_project_uuid_fkey'
      AND conrelid = 'public.mirror_apply_audit_events'::regclass
  ) INTO audit_project_fk_exists;

  SELECT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'mirror_apply_audit_events_task_uuid_fkey'
      AND conrelid = 'public.mirror_apply_audit_events'::regclass
  ) INTO audit_task_fk_exists;

  SELECT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'mirror_usage_logs_project_uuid_fkey'
      AND conrelid = 'public.mirror_usage_logs'::regclass
  ) INTO usage_project_fk_exists;

  SELECT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'mirror_usage_logs_task_uuid_fkey'
      AND conrelid = 'public.mirror_usage_logs'::regclass
  ) INTO usage_task_fk_exists;

  IF NOT ai_project_fk_exists OR NOT ai_task_fk_exists THEN
    RAISE EXCEPTION 'Contract violation: ai_sessions UUID FK constraints are missing';
  END IF;

  IF NOT audit_project_fk_exists OR NOT audit_task_fk_exists THEN
    RAISE EXCEPTION 'Contract violation: mirror_apply_audit_events UUID FK constraints are missing';
  END IF;

  IF NOT usage_project_fk_exists OR NOT usage_task_fk_exists THEN
    RAISE EXCEPTION 'Contract violation: mirror_usage_logs UUID FK constraints are missing';
  END IF;

  SELECT convalidated INTO ai_project_fk_validated
  FROM pg_constraint
  WHERE conname = 'ai_sessions_project_uuid_fkey'
    AND conrelid = 'public.ai_sessions'::regclass
  LIMIT 1;

  SELECT convalidated INTO ai_task_fk_validated
  FROM pg_constraint
  WHERE conname = 'ai_sessions_task_uuid_fkey'
    AND conrelid = 'public.ai_sessions'::regclass
  LIMIT 1;

  SELECT convalidated INTO audit_project_fk_validated
  FROM pg_constraint
  WHERE conname = 'mirror_apply_audit_events_project_uuid_fkey'
    AND conrelid = 'public.mirror_apply_audit_events'::regclass
  LIMIT 1;

  SELECT convalidated INTO audit_task_fk_validated
  FROM pg_constraint
  WHERE conname = 'mirror_apply_audit_events_task_uuid_fkey'
    AND conrelid = 'public.mirror_apply_audit_events'::regclass
  LIMIT 1;

  SELECT convalidated INTO usage_project_fk_validated
  FROM pg_constraint
  WHERE conname = 'mirror_usage_logs_project_uuid_fkey'
    AND conrelid = 'public.mirror_usage_logs'::regclass
  LIMIT 1;

  SELECT convalidated INTO usage_task_fk_validated
  FROM pg_constraint
  WHERE conname = 'mirror_usage_logs_task_uuid_fkey'
    AND conrelid = 'public.mirror_usage_logs'::regclass
  LIMIT 1;

  IF COALESCE(ai_project_fk_validated, false) IS NOT true
     OR COALESCE(ai_task_fk_validated, false) IS NOT true THEN
    RAISE EXCEPTION 'Contract violation: ai_sessions UUID FK constraints are not validated';
  END IF;

  IF COALESCE(audit_project_fk_validated, false) IS NOT true
     OR COALESCE(audit_task_fk_validated, false) IS NOT true THEN
    RAISE EXCEPTION 'Contract violation: mirror_apply_audit_events UUID FK constraints are not validated';
  END IF;

  IF COALESCE(usage_project_fk_validated, false) IS NOT true
     OR COALESCE(usage_task_fk_validated, false) IS NOT true THEN
    RAISE EXCEPTION 'Contract violation: mirror_usage_logs UUID FK constraints are not validated';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
      AND indexname = 'idx_ai_sessions_user_project_uuid_task_uuid'
  ) INTO idx_ai_exists;

  SELECT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
      AND indexname = 'idx_mirror_apply_audit_events_project_uuid_task_uuid'
  ) INTO idx_audit_exists;

  SELECT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
      AND indexname = 'idx_mirror_usage_logs_project_uuid_task_uuid'
  ) INTO idx_usage_exists;

  IF NOT idx_ai_exists OR NOT idx_audit_exists OR NOT idx_usage_exists THEN
    RAISE EXCEPTION 'Contract violation: expected UUID context indexes are missing';
  END IF;

  RAISE NOTICE 'Mirror context relational integrity contract checks passed';
END;
$$;
