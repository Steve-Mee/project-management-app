-- Database setup for project management app
-- Run this in Supabase SQL editor to create the necessary tables

-- Projects table
CREATE TABLE IF NOT EXISTS projects (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'In Progress',
  user_id UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Project members table
CREATE TABLE IF NOT EXISTS project_members (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(project_id, user_id)
);

-- Invitations table
CREATE TABLE IF NOT EXISTS invitations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'member', 'viewer')),
  token TEXT NOT NULL UNIQUE,
  invited_by UUID NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'expired', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tasks table (assuming it exists for the policies)
CREATE TABLE IF NOT EXISTS tasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'todo',
  assigned_to UUID,
  user_id UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Analytics table for tracking events
CREATE TABLE IF NOT EXISTS analytics (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event TEXT NOT NULL,
  user_id UUID,
  project_id UUID,
  entity_id UUID,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB,
  minimal BOOLEAN DEFAULT false
);

-- Analytics events table (issue #073 canonical sink)
CREATE TABLE IF NOT EXISTS analytics_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event TEXT NOT NULL,
  user_id UUID,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  parameters JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- A/B testing configurations table
CREATE TABLE IF NOT EXISTS ab_configs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  key TEXT NOT NULL UNIQUE,
  value JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Feature flags table (issue #071)
CREATE TABLE IF NOT EXISTS feature_flags (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  key TEXT NOT NULL UNIQUE,
  enabled BOOLEAN NOT NULL DEFAULT false,
  value JSONB,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User saved filter views table
CREATE TABLE IF NOT EXISTS user_views (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL,
  view_name TEXT NOT NULL,
  filter_data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, view_name)
);

-- AI usage per user for token metering
CREATE TABLE IF NOT EXISTS ai_usage (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL,
  tokens_used INTEGER NOT NULL DEFAULT 0,
  monthly_limit INTEGER NOT NULL DEFAULT 1000,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_project_members_project_id ON project_members(project_id);
CREATE INDEX IF NOT EXISTS idx_project_members_user_id ON project_members(user_id);
CREATE INDEX IF NOT EXISTS idx_invitations_project_id ON invitations(project_id);
CREATE INDEX IF NOT EXISTS idx_invitations_token ON invitations(token);
CREATE INDEX IF NOT EXISTS idx_invitations_email ON invitations(email);
CREATE INDEX IF NOT EXISTS idx_tasks_project_id ON tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_analytics_event ON analytics(event);
CREATE INDEX IF NOT EXISTS idx_analytics_user_id ON analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_timestamp ON analytics(timestamp);
CREATE INDEX IF NOT EXISTS idx_analytics_events_event ON analytics_events(event);
CREATE INDEX IF NOT EXISTS idx_analytics_events_user_id ON analytics_events(user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_events_timestamp ON analytics_events(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_user_views_user_id ON user_views(user_id);
CREATE INDEX IF NOT EXISTS idx_user_views_view_name ON user_views(view_name);
CREATE INDEX IF NOT EXISTS idx_ai_usage_user_id ON ai_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_feature_flags_key ON feature_flags(key);
CREATE INDEX IF NOT EXISTS idx_feature_flags_enabled ON feature_flags(enabled);
CREATE INDEX IF NOT EXISTS idx_feature_flags_updated_at ON feature_flags(updated_at DESC);

CREATE TABLE IF NOT EXISTS ai_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  project_id TEXT,
  task_id TEXT,
  mode TEXT CHECK (mode IN ('private', 'cloud')),
  status TEXT CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  versions JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Mirror staging storage bucket (Prompt 2 EOF)
-- Dashboard note:
-- 1) Supabase Dashboard > Storage: verify bucket `mirror_staging` exists and is private.
-- 2) Keep this insert idempotent for environments where the bucket already exists.
INSERT INTO storage.buckets (id, name, public)
VALUES ('mirror_staging', 'mirror_staging', false)
ON CONFLICT (id) DO NOTHING;

-- Prompt 2 EOF storage RLS policies for per-user folder access: {user_id}/...
CREATE POLICY "mirror_staging_upload_own_folder_prompt_2_eof" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'mirror_staging'
  AND storage.foldername(name)[1] = auth.uid()::text
);

CREATE POLICY "mirror_staging_download_own_folder_prompt_2_eof" ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'mirror_staging'
  AND storage.foldername(name)[1] = auth.uid()::text
);

-- Mirror staging storage bucket (Prompt 2)
-- Dashboard note:
-- 1) Supabase Dashboard > Storage: verify bucket `mirror_staging` exists and is private.
-- 2) Keep this insert idempotent for environments where the bucket already exists.
INSERT INTO storage.buckets (id, name, public)
VALUES ('mirror_staging', 'mirror_staging', false)
ON CONFLICT (id) DO NOTHING;

-- Prompt 2 storage RLS policies for per-user folder access: {user_id}/...
CREATE POLICY "mirror_staging_upload_own_folder_prompt_2" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'mirror_staging'
  AND storage.foldername(name)[1] = auth.uid()::text
);

CREATE POLICY "mirror_staging_download_own_folder_prompt_2" ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'mirror_staging'
  AND storage.foldername(name)[1] = auth.uid()::text
);

-- Mirror staging storage bucket
-- Dashboard note:
-- 1) Supabase Dashboard > Storage: verify bucket `mirror_staging` exists and is private.
-- 2) If the bucket already exists from Dashboard/manual setup, keep this INSERT idempotent via ON CONFLICT.
INSERT INTO storage.buckets (id, name, public)
VALUES ('mirror_staging', 'mirror_staging', false)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS policies for per-user folder access: {user_id}/...
-- Upload: authenticated users can write only into their own top-level folder.
CREATE POLICY "mirror_staging_upload_own_folder" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'mirror_staging'
  AND storage.foldername(name)[1] = auth.uid()::text
);

-- Download: authenticated users can read only from their own top-level folder.
CREATE POLICY "mirror_staging_download_own_folder" ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'mirror_staging'
  AND storage.foldername(name)[1] = auth.uid()::text
);

CREATE TABLE IF NOT EXISTS ai_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  project_id TEXT,
  task_id TEXT,
  mode TEXT CHECK (mode IN ('private', 'cloud')),
  status TEXT CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  versions JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Mirror staging storage bucket (Prompt 2 FINAL EOF)
-- Dashboard note:
-- 1) Supabase Dashboard > Storage: verify bucket `mirror_staging` exists and is private.
-- 2) Keep this insert idempotent for environments where the bucket already exists.
INSERT INTO storage.buckets (id, name, public)
VALUES ('mirror_staging', 'mirror_staging', false)
ON CONFLICT (id) DO NOTHING;

-- Prompt 2 FINAL EOF storage RLS policies for per-user folder access: {user_id}/...
CREATE POLICY "mirror_staging_upload_own_folder_prompt_2_final_eof" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'mirror_staging'
  AND storage.foldername(name)[1] = auth.uid()::text
);

CREATE POLICY "mirror_staging_download_own_folder_prompt_2_final_eof" ON storage.objects
FOR SELECT TO authenticated
USING (
  bucket_id = 'mirror_staging'
  AND storage.foldername(name)[1] = auth.uid()::text
);

-- Mirror templates catalog (Prompt 23)
CREATE TABLE IF NOT EXISTS mirror_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_key TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  icon_name TEXT NOT NULL,
  tags TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  seed_content TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mirror_templates_key ON mirror_templates(template_key);
CREATE INDEX IF NOT EXISTS idx_mirror_templates_active ON mirror_templates(is_active);

INSERT INTO mirror_templates (template_key, title, description, icon_name, tags, seed_content, is_active)
VALUES
  (
    'flutter-feature',
    'Flutter Feature Module',
    'Scaffold a complete feature with state, UI, and tests.',
    'widgets_outlined',
    ARRAY['flutter', 'feature', 'riverpod'],
    'Create a Flutter feature module with:\n- state management via Riverpod\n- screen, view model, and repository layers\n- unit and widget tests\n- clear file structure and TODO markers',
    true
  ),
  (
    'api-integration',
    'API Integration',
    'Generate robust API client, models, and retry handling.',
    'cloud_outlined',
    ARRAY['api', 'http', 'models'],
    'Implement API integration with:\n- typed request/response models\n- error mapping and retry strategy\n- logging hooks and parsing guards\n- a short integration test checklist',
    true
  ),
  (
    'bugfix-patch',
    'Bugfix Patch',
    'Focused fix with minimal risk and verification steps.',
    'bug_report_outlined',
    ARRAY['bugfix', 'safe-change'],
    'Apply a minimal bugfix patch:\n- keep behavior unchanged outside the fix scope\n- include guard clauses and null safety checks\n- add regression tests if possible\n- summarize potential risks',
    true
  ),
  (
    'performance-pass',
    'Performance Pass',
    'Optimize hotspots and reduce UI jank where possible.',
    'speed_outlined',
    ARRAY['performance', 'profiling'],
    'Perform a performance pass:\n- identify hot paths and rebuild bottlenecks\n- reduce expensive operations in build methods\n- memoize or cache safely where useful\n- report expected perf impact',
    true
  ),
  (
    'test-suite',
    'Test Suite Booster',
    'Expand coverage for core flows and failure cases.',
    'rule_folder_outlined',
    ARRAY['tests', 'coverage', 'quality'],
    'Create an expanded test suite:\n- happy path and edge case tests\n- async failure and timeout scenarios\n- concise fixtures and reusable helpers\n- coverage notes for remaining gaps',
    true
  )
ON CONFLICT (template_key) DO UPDATE
SET
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  icon_name = EXCLUDED.icon_name,
  tags = EXCLUDED.tags,
  seed_content = EXCLUDED.seed_content,
  is_active = EXCLUDED.is_active,
  updated_at = NOW();
