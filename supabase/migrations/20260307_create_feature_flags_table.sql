-- Create feature_flags table for issue #071.
-- Safe to run multiple times.

CREATE TABLE IF NOT EXISTS public.feature_flags (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  key TEXT NOT NULL UNIQUE,
  enabled BOOLEAN NOT NULL DEFAULT false,
  value JSONB,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_feature_flags_key ON public.feature_flags(key);
CREATE INDEX IF NOT EXISTS idx_feature_flags_enabled ON public.feature_flags(enabled);
CREATE INDEX IF NOT EXISTS idx_feature_flags_updated_at ON public.feature_flags(updated_at DESC);

ALTER TABLE public.feature_flags ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "feature_flags_select_policy" ON public.feature_flags;
CREATE POLICY "feature_flags_select_policy" ON public.feature_flags
FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "feature_flags_insert_policy" ON public.feature_flags;
CREATE POLICY "feature_flags_insert_policy" ON public.feature_flags
FOR INSERT WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

DROP POLICY IF EXISTS "feature_flags_update_policy" ON public.feature_flags;
CREATE POLICY "feature_flags_update_policy" ON public.feature_flags
FOR UPDATE USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

DROP POLICY IF EXISTS "feature_flags_delete_policy" ON public.feature_flags;
CREATE POLICY "feature_flags_delete_policy" ON public.feature_flags
FOR DELETE USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
