-- Mirror idempotency response-cache schema contract test
-- Execute in Supabase SQL editor (service role) after migrations.

DO $$
DECLARE
  table_exists boolean;
  response_status_exists boolean;
  response_status_type text;
  response_body_exists boolean;
  response_body_type text;
  response_content_type_exists boolean;
  response_content_type_type text;
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

  SELECT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'mirror_request_idempotency'
      AND column_name = 'response_status'
  ) INTO response_status_exists;

  IF NOT response_status_exists THEN
    RAISE EXCEPTION 'Contract violation: response_status column missing on mirror_request_idempotency';
  END IF;

  SELECT c.data_type
  INTO response_status_type
  FROM information_schema.columns c
  WHERE c.table_schema = 'public'
    AND c.table_name = 'mirror_request_idempotency'
    AND c.column_name = 'response_status'
  LIMIT 1;

  IF COALESCE(response_status_type, '') <> 'integer' THEN
    RAISE EXCEPTION 'Contract violation: response_status must be INTEGER, found %', COALESCE(response_status_type, '<null>');
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'mirror_request_idempotency'
      AND column_name = 'response_body'
  ) INTO response_body_exists;

  IF NOT response_body_exists THEN
    RAISE EXCEPTION 'Contract violation: response_body column missing on mirror_request_idempotency';
  END IF;

  SELECT c.data_type
  INTO response_body_type
  FROM information_schema.columns c
  WHERE c.table_schema = 'public'
    AND c.table_name = 'mirror_request_idempotency'
    AND c.column_name = 'response_body'
  LIMIT 1;

  IF COALESCE(response_body_type, '') <> 'text' THEN
    RAISE EXCEPTION 'Contract violation: response_body must be TEXT, found %', COALESCE(response_body_type, '<null>');
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'mirror_request_idempotency'
      AND column_name = 'response_content_type'
  ) INTO response_content_type_exists;

  IF NOT response_content_type_exists THEN
    RAISE EXCEPTION 'Contract violation: response_content_type column missing on mirror_request_idempotency';
  END IF;

  SELECT c.data_type
  INTO response_content_type_type
  FROM information_schema.columns c
  WHERE c.table_schema = 'public'
    AND c.table_name = 'mirror_request_idempotency'
    AND c.column_name = 'response_content_type'
  LIMIT 1;

  IF COALESCE(response_content_type_type, '') <> 'text' THEN
    RAISE EXCEPTION 'Contract violation: response_content_type must be TEXT, found %', COALESCE(response_content_type_type, '<null>');
  END IF;

  RAISE NOTICE 'Mirror idempotency response-cache schema contract checks passed';
END;
$$;