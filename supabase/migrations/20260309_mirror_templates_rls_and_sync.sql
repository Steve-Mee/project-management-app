-- Mirror templates: DB-first canonical source with RLS and deterministic seed sync.
-- This migration makes the database the source of truth for template catalog state.

BEGIN;

CREATE TABLE IF NOT EXISTS public.mirror_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_key TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  icon_name TEXT NOT NULL,
  tags TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  seed_content TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  seed_managed BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

ALTER TABLE public.mirror_templates
  ADD COLUMN IF NOT EXISTS seed_managed BOOLEAN NOT NULL DEFAULT true;

CREATE INDEX IF NOT EXISTS idx_mirror_templates_key
  ON public.mirror_templates(template_key);

CREATE INDEX IF NOT EXISTS idx_mirror_templates_active
  ON public.mirror_templates(is_active);

CREATE INDEX IF NOT EXISTS idx_mirror_templates_seed_managed
  ON public.mirror_templates(seed_managed);

ALTER TABLE public.mirror_templates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "mirror_templates_select_policy" ON public.mirror_templates;
CREATE POLICY "mirror_templates_select_policy"
ON public.mirror_templates
FOR SELECT
TO authenticated
USING (
  is_active = true
  OR COALESCE(public.has_permission('manage_templates'), false)
);

DROP POLICY IF EXISTS "mirror_templates_insert_policy" ON public.mirror_templates;
CREATE POLICY "mirror_templates_insert_policy"
ON public.mirror_templates
FOR INSERT
TO authenticated
WITH CHECK (
  COALESCE(public.has_permission('manage_templates'), false)
);

DROP POLICY IF EXISTS "mirror_templates_update_policy" ON public.mirror_templates;
CREATE POLICY "mirror_templates_update_policy"
ON public.mirror_templates
FOR UPDATE
TO authenticated
USING (
  COALESCE(public.has_permission('manage_templates'), false)
)
WITH CHECK (
  COALESCE(public.has_permission('manage_templates'), false)
);

DROP POLICY IF EXISTS "mirror_templates_delete_policy" ON public.mirror_templates;
CREATE POLICY "mirror_templates_delete_policy"
ON public.mirror_templates
FOR DELETE
TO authenticated
USING (
  COALESCE(public.has_permission('manage_templates'), false)
);

CREATE OR REPLACE FUNCTION public.sync_mirror_templates_seed()
RETURNS TABLE(upserted_count INTEGER, deactivated_count INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  upsert_count INTEGER := 0;
  disable_count INTEGER := 0;
BEGIN
  INSERT INTO public.mirror_templates (
    template_key,
    title,
    description,
    icon_name,
    tags,
    seed_content,
    is_active,
    seed_managed,
    updated_at
  )
  VALUES
    (
      'flutter-feature',
      'Flutter Feature Module',
      'Scaffold a complete feature with state, UI, and tests.',
      'widgets_outlined',
      ARRAY['flutter', 'feature', 'riverpod'],
      'Create a Flutter feature module with:\n- state management via Riverpod\n- screen, view model, and repository layers\n- unit and widget tests\n- clear file structure and TODO markers',
      true,
      true,
      NOW()
    ),
    (
      'api-integration',
      'API Integration',
      'Generate robust API client, models, and retry handling.',
      'cloud_outlined',
      ARRAY['api', 'http', 'models'],
      'Implement API integration with:\n- typed request/response models\n- error mapping and retry strategy\n- logging hooks and parsing guards\n- a short integration test checklist',
      true,
      true,
      NOW()
    ),
    (
      'bugfix-patch',
      'Bugfix Patch',
      'Focused fix with minimal risk and verification steps.',
      'bug_report_outlined',
      ARRAY['bugfix', 'safe-change'],
      'Apply a minimal bugfix patch:\n- keep behavior unchanged outside the fix scope\n- include guard clauses and null safety checks\n- add regression tests if possible\n- summarize potential risks',
      true,
      true,
      NOW()
    ),
    (
      'performance-pass',
      'Performance Pass',
      'Optimize hotspots and reduce UI jank where possible.',
      'speed_outlined',
      ARRAY['performance', 'profiling'],
      'Perform a performance pass:\n- identify hot paths and rebuild bottlenecks\n- reduce expensive operations in build methods\n- memoize or cache safely where useful\n- report expected perf impact',
      true,
      true,
      NOW()
    ),
    (
      'test-suite',
      'Test Suite Booster',
      'Expand coverage for core flows and failure cases.',
      'rule_folder_outlined',
      ARRAY['tests', 'coverage', 'quality'],
      'Create an expanded test suite:\n- happy path and edge case tests\n- async failure and timeout scenarios\n- concise fixtures and reusable helpers\n- coverage notes for remaining gaps',
      true,
      true,
      NOW()
    )
  ON CONFLICT (template_key) DO UPDATE
  SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    icon_name = EXCLUDED.icon_name,
    tags = EXCLUDED.tags,
    seed_content = EXCLUDED.seed_content,
    is_active = EXCLUDED.is_active,
    seed_managed = EXCLUDED.seed_managed,
    updated_at = NOW();

  GET DIAGNOSTICS upsert_count = ROW_COUNT;

  UPDATE public.mirror_templates
  SET
    is_active = false,
    updated_at = NOW()
  WHERE seed_managed = true
    AND template_key NOT IN (
      'flutter-feature',
      'api-integration',
      'bugfix-patch',
      'performance-pass',
      'test-suite'
    );

  GET DIAGNOSTICS disable_count = ROW_COUNT;

  RETURN QUERY SELECT upsert_count, disable_count;
END;
$$;

REVOKE ALL ON FUNCTION public.sync_mirror_templates_seed() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.sync_mirror_templates_seed() TO service_role;

-- Canonical seed sync: run once during migration and re-use in future migrations.
SELECT * FROM public.sync_mirror_templates_seed();

COMMIT;
