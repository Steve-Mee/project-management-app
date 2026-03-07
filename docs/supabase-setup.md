# Supabase Setup Documentation

This document describes the current Supabase backend setup for `my_project_management_app`, including database schema, row-level security (RLS), storage buckets, and Edge Functions.

## Table of Contents

1. [Setup Instructions](#setup-instructions)
2. [Project Structure](#project-structure)
3. [SQL Schema](#sql-schema)
4. [RLS Policies](#rls-policies)
5. [Storage Buckets](#storage-buckets)
6. [Edge Functions](#edge-functions)

## Setup Instructions

1. Create a Supabase project in the Supabase dashboard and note:
- Project URL (`SUPABASE_URL`)
- Anon key (`SUPABASE_ANON_KEY`)
- Service role key (`SUPABASE_SERVICE_ROLE_KEY`)

2. Link local CLI to your project:

```bash
supabase login
supabase link --project-ref <your-project-ref>
```

3. Apply schema SQL and migrations:
- Run `supabase_setup.sql` in the SQL editor for base tables.
- Apply migration files in `supabase/migrations/` (for example `20260304_create_ai_usage_table.sql`).

4. Enable and verify RLS:
- RLS is enabled on core tables in `supabase_policies.sql`.
- Run policy SQL from `supabase_policies.sql`.

5. Add app/runtime keys:
- Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` to app environment config.
- Add function secrets (for example `SUPABASE_SERVICE_ROLE_KEY`, `STRIPE_SECRET_KEY`, `RESEND_API_KEY`) using `supabase secrets set`.

6. Deploy Edge Functions (if used):

```bash
supabase functions deploy invite-user
supabase functions deploy stripe_webhook
```

7. Add new policies as needed:
- Use the step-by-step "How to add a new policy" instructions in the [RLS Policies](#rls-policies) section.

## Project Structure

```text
supabase/
  config.toml
  migrations/
    20260304_create_ai_usage_table.sql
  functions/
    _shared/
      cors.ts
    invite-user/
      index.ts
    stripe_webhook/
      index.ts

supabase_setup.sql
supabase_policies.sql
```

## SQL Schema

Primary schema source:
- `supabase_setup.sql`

```sql
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
```

Additional migration reference:
- `supabase/migrations/20260304_create_ai_usage_table.sql`

```sql
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
```

## RLS Policies

Primary RLS source:
- `supabase_policies.sql`

Additional RLS in migration:
- `supabase/migrations/20260304_create_ai_usage_table.sql`

RLS enablement currently applied:

```sql
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_flags ENABLE ROW LEVEL SECURITY;
```

### `ab_configs`

Policy summary:
- `ab_configs_select_policy`: allows authenticated users to read feature/config values.

```sql
CREATE POLICY "ab_configs_select_policy" ON ab_configs
FOR SELECT USING (auth.role() = 'authenticated');
```

### `feature_flags`

Policy summary:
- `feature_flags_select_policy`: allows authenticated users to read feature flag values.
- `feature_flags_insert_policy`: only users with JWT app metadata role `admin` can insert flags.
- `feature_flags_update_policy`: only users with JWT app metadata role `admin` can update flags.
- `feature_flags_delete_policy`: only users with JWT app metadata role `admin` can delete flags.

```sql
CREATE POLICY "feature_flags_select_policy" ON feature_flags
FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "feature_flags_insert_policy" ON feature_flags
FOR INSERT WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

CREATE POLICY "feature_flags_update_policy" ON feature_flags
FOR UPDATE USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

CREATE POLICY "feature_flags_delete_policy" ON feature_flags
FOR DELETE USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');
```

Note:
- If your auth setup does not expose `app_metadata.role`, write operations will be denied (safe default).
- The UI will report save failures and keep local state consistent.
- For real writes, the auth token `app_metadata` must include the `admin` role claim.
- Without that claim, the admin UI shows a clean error and intentionally does not mutate data.
- On successful writes, the app records `feature_flag_changed` audit events in `analytics` for the authenticated user.

### `analytics`

Policy summary:
- `analytics_insert_policy`: users can only insert analytics rows where `user_id` matches `auth.uid()`.
- `analytics_select_policy`: users can only read their own analytics rows.

```sql
CREATE POLICY "analytics_insert_policy" ON analytics
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "analytics_select_policy" ON analytics
FOR SELECT USING (auth.uid() = user_id);
```

### `projects`

Policy summary:
- `projects_select_policy`: only project members can read a project.
- `projects_insert_policy`: project creation is allowed; membership is enforced separately.
- `projects_update_policy`: only `owner`, `admin`, `member` can update.
- `projects_delete_policy`: only `owner` can delete.

```sql
CREATE POLICY "projects_select_policy" ON projects
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = projects.id
    AND project_members.user_id = auth.uid()
  )
);

CREATE POLICY "projects_insert_policy" ON projects
FOR INSERT WITH CHECK (true);

CREATE POLICY "projects_update_policy" ON projects
FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = projects.id
    AND project_members.user_id = auth.uid()
    AND project_members.role IN ('owner', 'admin', 'member')
  )
);

CREATE POLICY "projects_delete_policy" ON projects
FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = projects.id
    AND project_members.user_id = auth.uid()
    AND project_members.role = 'owner'
  )
);
```

### `project_members`

Policy summary:
- `project_members_select_policy`: members can see membership records for projects they belong to.
- `project_members_insert_policy`: owner/admin can add members; self-add as `owner` is allowed for new project bootstrap.
- `project_members_update_policy`: owner/admin can update roles with a safeguard to prevent removing the last owner.
- `project_members_delete_policy`: owner/admin can remove members, except removing the last owner.

```sql
CREATE POLICY "project_members_select_policy" ON project_members
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM project_members pm
    WHERE pm.project_id = project_members.project_id
    AND pm.user_id = auth.uid()
  )
);

CREATE POLICY "project_members_insert_policy" ON project_members
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = NEW.project_id
    AND project_members.user_id = auth.uid()
    AND project_members.role IN ('owner', 'admin')
  )
  OR (NEW.user_id = auth.uid() AND NEW.role = 'owner')
);

CREATE POLICY "project_members_update_policy" ON project_members
FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = NEW.project_id
    AND project_members.user_id = auth.uid()
    AND project_members.role IN ('owner', 'admin')
  )
)
WITH CHECK (
  NOT (
    OLD.role = 'owner' AND NEW.role != 'owner' AND
    NOT EXISTS (
      SELECT 1 FROM project_members pm
      WHERE pm.project_id = NEW.project_id
      AND pm.user_id != OLD.user_id
      AND pm.role = 'owner'
    )
  )
);

CREATE POLICY "project_members_delete_policy" ON project_members
FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = OLD.project_id
    AND project_members.user_id = auth.uid()
    AND project_members.role IN ('owner', 'admin')
  ) AND
  NOT (
    OLD.role = 'owner' AND
    NOT EXISTS (
      SELECT 1 FROM project_members pm
      WHERE pm.project_id = OLD.project_id
      AND pm.user_id != OLD.user_id
      AND pm.role = 'owner'
    )
  )
);
```

### `invitations`

Policy summary:
- `invitations_select_policy`: only owner/admin can read project invitations.
- `invitations_insert_policy`: only owner/admin can create invitations, and `invited_by` must be current user.
- `invitations_update_policy`: invited user (email match) or owner/admin can update invitations.
- `invitations_delete_policy`: only owner/admin can delete invitations.

```sql
CREATE POLICY "invitations_select_policy" ON invitations
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = invitations.project_id
    AND project_members.user_id = auth.uid()
    AND project_members.role IN ('owner', 'admin')
  )
);

CREATE POLICY "invitations_insert_policy" ON invitations
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = NEW.project_id
    AND project_members.user_id = auth.uid()
    AND project_members.role IN ('owner', 'admin')
  ) AND
  NEW.invited_by = auth.uid()
);

CREATE POLICY "invitations_update_policy" ON invitations
FOR UPDATE USING (
  NEW.email = (SELECT email FROM auth.users WHERE id = auth.uid()) OR
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = invitations.project_id
    AND project_members.user_id = auth.uid()
    AND project_members.role IN ('owner', 'admin')
  )
);

CREATE POLICY "invitations_delete_policy" ON invitations
FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = invitations.project_id
    AND project_members.user_id = auth.uid()
    AND project_members.role IN ('owner', 'admin')
  )
);
```

### `tasks`

Policy summary:
- `tasks_select_policy`: all project members can view tasks.
- `tasks_insert_policy`: `owner`, `admin`, `member` can create tasks.
- `tasks_update_policy`: `owner`, `admin`, `member` can update tasks.
- `tasks_delete_policy`: only `owner`, `admin` can delete tasks.

```sql
CREATE POLICY "tasks_select_policy" ON tasks
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = tasks.project_id
    AND project_members.user_id = auth.uid()
  )
);

CREATE POLICY "tasks_insert_policy" ON tasks
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = NEW.project_id
    AND project_members.user_id = auth.uid()
    AND project_members.role IN ('owner', 'admin', 'member')
  )
);

CREATE POLICY "tasks_update_policy" ON tasks
FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = tasks.project_id
    AND project_members.user_id = auth.uid()
    AND project_members.role IN ('owner', 'admin', 'member')
  )
);

CREATE POLICY "tasks_delete_policy" ON tasks
FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = tasks.project_id
    AND project_members.user_id = auth.uid()
    AND project_members.role IN ('owner', 'admin')
  )
);
```

### `user_views`

Policy summary:
- `user_views_select_policy`: users can read only their own saved views.
- `user_views_insert_policy`: users can insert only their own saved views.
- `user_views_update_policy`: users can update only their own saved views.
- `user_views_delete_policy`: users can delete only their own saved views.

```sql
CREATE POLICY "user_views_select_policy" ON user_views
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "user_views_insert_policy" ON user_views
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_views_update_policy" ON user_views
FOR UPDATE USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_views_delete_policy" ON user_views
FOR DELETE USING (auth.uid() = user_id);
```

### `ai_usage`

Policy summary:
- `ai_usage_select_policy`: users can read only their own usage row.
- `ai_usage_insert_policy`: users can insert only rows tied to their own user id.
- `ai_usage_update_policy`: users can update only their own usage row.

```sql
CREATE POLICY "ai_usage_select_policy" ON ai_usage
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "ai_usage_insert_policy" ON ai_usage
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "ai_usage_update_policy" ON ai_usage
FOR UPDATE USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
```

Migration-safe variant used for `public.ai_usage`:

```sql
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
```

How to add a new policy:
1. Enable RLS on the table if not already enabled.

```sql
ALTER TABLE <table_name> ENABLE ROW LEVEL SECURITY;
```

2. Create operation-specific policies with explicit names.

```sql
CREATE POLICY "<table>_select_policy" ON <table_name>
FOR SELECT USING (<access_condition>);

CREATE POLICY "<table>_insert_policy" ON <table_name>
FOR INSERT WITH CHECK (<insert_condition>);

CREATE POLICY "<table>_update_policy" ON <table_name>
FOR UPDATE USING (<update_access_condition>)
WITH CHECK (<update_write_condition>);

CREATE POLICY "<table>_delete_policy" ON <table_name>
FOR DELETE USING (<delete_condition>);
```

3. Prefer ownership checks (`auth.uid() = user_id`) or membership/role checks via `EXISTS` queries.
4. Add the policy SQL to a migration file under `supabase/migrations/`.
5. For idempotent migrations, guard with `IF NOT EXISTS` checks against `pg_policies` when needed.
6. Validate with both authorized and unauthorized users before deployment.

## Storage Buckets

Current documented buckets:
- `avatars`: profile images for users.
- `project_files`: files and attachments scoped to projects.

Note:
- No storage bucket SQL/migration was found in the current repository yet. The examples below are the recommended baseline to implement.

### Bucket Setup (Example SQL)

```sql
-- Create storage buckets
INSERT INTO storage.buckets (id, name, public)
VALUES
  ('avatars', 'avatars', true),
  ('project_files', 'project_files', false)
ON CONFLICT (id) DO NOTHING;
```

### Security Rules (Example SQL Policies)

```sql
-- AVATARS
-- Public read, user can only write/delete their own avatar path: <user_id>/...
CREATE POLICY "avatars_public_read" ON storage.objects
FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "avatars_user_upload_own_folder" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'avatars'
  AND auth.role() = 'authenticated'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "avatars_user_update_own_folder" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "avatars_user_delete_own_folder" ON storage.objects
FOR DELETE USING (
  bucket_id = 'avatars'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- PROJECT FILES
-- Private files: only authenticated users with project membership should access.
-- Recommended path format: <project_id>/<file_name>
CREATE POLICY "project_files_member_read" ON storage.objects
FOR SELECT USING (
  bucket_id = 'project_files'
  AND EXISTS (
    SELECT 1 FROM project_members pm
    WHERE pm.project_id::text = (storage.foldername(name))[1]
    AND pm.user_id = auth.uid()
  )
);

CREATE POLICY "project_files_member_upload" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'project_files'
  AND EXISTS (
    SELECT 1 FROM project_members pm
    WHERE pm.project_id::text = (storage.foldername(name))[1]
    AND pm.user_id = auth.uid()
    AND pm.role IN ('owner', 'admin', 'member')
  )
);

CREATE POLICY "project_files_member_update" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'project_files'
  AND EXISTS (
    SELECT 1 FROM project_members pm
    WHERE pm.project_id::text = (storage.foldername(name))[1]
    AND pm.user_id = auth.uid()
    AND pm.role IN ('owner', 'admin', 'member')
  )
);

CREATE POLICY "project_files_admin_delete" ON storage.objects
FOR DELETE USING (
  bucket_id = 'project_files'
  AND EXISTS (
    SELECT 1 FROM project_members pm
    WHERE pm.project_id::text = (storage.foldername(name))[1]
    AND pm.user_id = auth.uid()
    AND pm.role IN ('owner', 'admin')
  )
);
```

### Upload/Download Examples

```dart
// Upload avatar (path: <user_id>/avatar.png)
await supabase.storage
    .from('avatars')
    .upload('${userId}/avatar.png', avatarFile);

// Public avatar URL
final avatarUrl = supabase.storage
    .from('avatars')
    .getPublicUrl('${userId}/avatar.png');

// Upload project file (path: <project_id>/spec.pdf)
await supabase.storage
    .from('project_files')
    .upload('${projectId}/spec.pdf', projectFile);

// Download project file bytes
final fileBytes = await supabase.storage
    .from('project_files')
    .download('${projectId}/spec.pdf');
```

## Edge Functions

Current Edge Functions:
- `invite-user` (`supabase/functions/invite-user/index.ts`)
  - Handles project invitation creation, auth checks, and permission checks.
- `stripe_webhook` (`supabase/functions/stripe_webhook/index.ts`)
  - Handles Stripe webhook events and updates subscription state.

Shared function code:
- `_shared/cors.ts` (`supabase/functions/_shared/cors.ts`)
  - Reusable CORS headers for function responses.

How to deploy:

```bash
# 1) Login and link project (one-time per environment)
supabase login
supabase link --project-ref <your-project-ref>

# 2) Deploy individual functions
supabase functions deploy invite-user
supabase functions deploy stripe_webhook

# 3) (Optional) deploy all changed functions
supabase functions deploy
```

Set required secrets before deploy/runtime:

```bash
supabase secrets set \
  SUPABASE_URL=<your-supabase-url> \
  SUPABASE_ANON_KEY=<your-anon-key> \
  SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key> \
  STRIPE_SECRET_KEY=<your-stripe-secret> \
  RESEND_API_KEY=<your-resend-key>
```

Example code structure:

```text
supabase/
  functions/
    _shared/
      cors.ts
    my-function/
      index.ts
```

```ts
import { corsHeaders } from '../_shared/cors.ts'

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  // Validate request, authorize user, run business logic.
  return new Response(JSON.stringify({ success: true }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
})
```
