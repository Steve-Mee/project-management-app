-- SQL voor RLS policies voor per-project membership

-- Enable RLS op alle relevante tabellen
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics ENABLE ROW LEVEL SECURITY;

-- A/B testing configs policies - allow authenticated users to read configs
CREATE POLICY "ab_configs_select_policy" ON ab_configs
FOR SELECT USING (auth.role() = 'authenticated');

-- Analytics policies - allow authenticated users to insert their own events
CREATE POLICY "analytics_insert_policy" ON analytics
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "analytics_select_policy" ON analytics
FOR SELECT USING (auth.uid() = user_id);

-- Projects policies
-- SELECT: alleen leden van het project
CREATE POLICY "projects_select_policy" ON projects
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = projects.id
    AND project_members.user_id = auth.uid()
  )
);

-- INSERT: iedereen kan projecten maken (membership wordt apart toegevoegd)
CREATE POLICY "projects_insert_policy" ON projects
FOR INSERT WITH CHECK (true);

-- UPDATE: alleen owner, admin, member kunnen updaten
CREATE POLICY "projects_update_policy" ON projects
FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = projects.id
    AND project_members.user_id = auth.uid()
    AND project_members.role IN ('owner', 'admin', 'member')
  )
);

-- DELETE: alleen owner kan verwijderen
CREATE POLICY "projects_delete_policy" ON projects
FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = projects.id
    AND project_members.user_id = auth.uid()
    AND project_members.role = 'owner'
  )
);

-- Project members policies
-- SELECT: iedereen kan zien wie lid is van projecten waar ze lid van zijn
CREATE POLICY "project_members_select_policy" ON project_members
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM project_members pm
    WHERE pm.project_id = project_members.project_id
    AND pm.user_id = auth.uid()
  )
);

-- INSERT: owner/admin kunnen leden toevoegen, OF gebruiker kan zichzelf toevoegen als owner bij project creatie
CREATE POLICY "project_members_insert_policy" ON project_members
FOR INSERT WITH CHECK (
  -- Allow if user is already owner/admin of the project
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = NEW.project_id
    AND project_members.user_id = auth.uid()
    AND project_members.role IN ('owner', 'admin')
  )
  -- OR allow if user is creating their own membership as owner (for new projects)
  OR (NEW.user_id = auth.uid() AND NEW.role = 'owner')
);

-- UPDATE: alleen owner/admin kunnen rollen wijzigen
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
  -- Zorg dat er altijd minstens één owner blijft
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

-- DELETE: alleen owner/admin kunnen leden verwijderen, niet zichzelf als laatste owner
CREATE POLICY "project_members_delete_policy" ON project_members
FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = OLD.project_id
    AND project_members.user_id = auth.uid()
    AND project_members.role IN ('owner', 'admin')
  ) AND
  -- Niet de laatste owner verwijderen
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

-- Invitations policies (assuming invitations table: id, email, project_id, role, invited_by, status, etc.)
-- SELECT: alleen owner/admin van het project kunnen uitnodigingen zien
CREATE POLICY "invitations_select_policy" ON invitations
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = invitations.project_id
    AND project_members.user_id = auth.uid()
    AND project_members.role IN ('owner', 'admin')
  )
);

-- INSERT: alleen owner/admin kunnen uitnodigen
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

-- UPDATE: alleen de genodigde kan accepteren/weigeren
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

-- DELETE: owner/admin kunnen uitnodigingen verwijderen
CREATE POLICY "invitations_delete_policy" ON invitations
FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = invitations.project_id
    AND project_members.user_id = auth.uid()
    AND project_members.role IN ('owner', 'admin')
  )
);

-- Voor tasks: vergelijkbaar met projects
-- SELECT: alleen leden
CREATE POLICY "tasks_select_policy" ON tasks
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = tasks.project_id
    AND project_members.user_id = auth.uid()
  )
);

-- INSERT: alleen member+ kunnen taken toevoegen
CREATE POLICY "tasks_insert_policy" ON tasks
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = NEW.project_id
    AND project_members.user_id = auth.uid()
    AND project_members.role IN ('owner', 'admin', 'member')
  )
);

-- UPDATE: alleen member+ kunnen taken bijwerken
CREATE POLICY "tasks_update_policy" ON tasks
FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = tasks.project_id
    AND project_members.user_id = auth.uid()
    AND project_members.role IN ('owner', 'admin', 'member')
  )
);

-- DELETE: alleen owner/admin kunnen taken verwijderen
CREATE POLICY "tasks_delete_policy" ON tasks
FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM project_members
    WHERE project_members.project_id = tasks.project_id
    AND project_members.user_id = auth.uid()
    AND project_members.role IN ('owner', 'admin')
  )
);</content>
<parameter name="filePath">c:\my_project_management_app\supabase_policies.sql