-- Mirror RLS contract checks
-- Run manually or in CI with psql against a migrated database.

-- 1) Required tables exist.
select exists (
  select 1 from information_schema.tables
  where table_schema = 'public' and table_name = 'mirror_apply_audit_events'
) as has_mirror_apply_audit_events;

select exists (
  select 1 from information_schema.tables
  where table_schema = 'public' and table_name = 'mirror_templates'
) as has_mirror_templates;

-- 2) RLS is enabled on critical mirror tables.
select relname, relrowsecurity
from pg_class
where relname in ('mirror_apply_audit_events', 'mirror_templates')
order by relname;

-- 3) Policies exist for owner/admin paths.
select schemaname, tablename, policyname
from pg_policies
where tablename in ('mirror_apply_audit_events', 'mirror_templates')
order by tablename, policyname;

-- 4) Storage policies for mirror buckets are present.
select schemaname, tablename, policyname
from pg_policies
where schemaname = 'storage'
  and tablename = 'objects'
  and (
    policyname ilike '%mirror%'
    or qual ilike '%mirror%'
    or with_check ilike '%mirror%'
  )
order by policyname;
