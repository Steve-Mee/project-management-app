-- Queue table for async 3D generation jobs.
-- Used by edge function: generate-3d-asset.

create table if not exists public.three_d_generation_queue (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null,
  task_id uuid null,
  user_id uuid not null,
  prompt text not null,
  settings jsonb not null default '{}'::jsonb,
  provider text not null,
  generation_plan jsonb not null default '{}'::jsonb,
  status text not null default 'queued',
  error text null,
  attempts int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_three_d_generation_queue_project_id
  on public.three_d_generation_queue(project_id);

create index if not exists idx_three_d_generation_queue_task_id
  on public.three_d_generation_queue(task_id)
  where task_id is not null;

create index if not exists idx_three_d_generation_queue_user_id
  on public.three_d_generation_queue(user_id);

create index if not exists idx_three_d_generation_queue_status_created_at
  on public.three_d_generation_queue(status, created_at);

alter table public.three_d_generation_queue enable row level security;

-- Authenticated users can read only their own queued jobs.
drop policy if exists "three_d_generation_queue_select_own" on public.three_d_generation_queue;
create policy "three_d_generation_queue_select_own"
  on public.three_d_generation_queue
  for select
  using (auth.uid() = user_id);

-- Service-role inserts from edge functions are allowed (RLS bypass for service role).
-- Keep explicit policy for authenticated inserts restricted to owner rows.
drop policy if exists "three_d_generation_queue_insert_own" on public.three_d_generation_queue;
create policy "three_d_generation_queue_insert_own"
  on public.three_d_generation_queue
  for insert
  with check (auth.uid() = user_id);

-- Only owner can update their own records (for optional client-side retry metadata).
drop policy if exists "three_d_generation_queue_update_own" on public.three_d_generation_queue;
create policy "three_d_generation_queue_update_own"
  on public.three_d_generation_queue
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
