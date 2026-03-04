-- Create ai_usage table for per-user AI token metering
-- Safe to run multiple times

CREATE TABLE IF NOT EXISTS public.ai_usage (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL,
  tokens_used INTEGER NOT NULL DEFAULT 0,
  monthly_limit INTEGER NOT NULL DEFAULT 1000,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

CREATE INDEX IF NOT EXISTS idx_ai_usage_user_id ON public.ai_usage(user_id);

ALTER TABLE public.ai_usage ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'ai_usage' AND policyname = 'ai_usage_select_policy'
  ) THEN
    CREATE POLICY ai_usage_select_policy ON public.ai_usage
      FOR SELECT USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'ai_usage' AND policyname = 'ai_usage_insert_policy'
  ) THEN
    CREATE POLICY ai_usage_insert_policy ON public.ai_usage
      FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'ai_usage' AND policyname = 'ai_usage_update_policy'
  ) THEN
    CREATE POLICY ai_usage_update_policy ON public.ai_usage
      FOR UPDATE USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;
