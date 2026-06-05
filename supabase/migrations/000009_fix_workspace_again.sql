-- Simpler fix: just drop and recreate RLS policies for workspaces
-- The issue is the INSERT policy missing and search_path breaking triggers

-- Add INSERT policy for workspaces (allows any authenticated user to create)
DROP POLICY IF EXISTS "users_create_workspace" ON workspaces;
DROP POLICY IF EXISTS "members_view_workspace" ON workspaces;
DROP POLICY IF EXISTS "owners_update_workspace" ON workspaces;

CREATE POLICY "authenticated_insert_workspaces" ON workspaces
    FOR INSERT TO authenticated
    WITH CHECK (true);

CREATE POLICY "members_select_workspaces" ON workspaces
    FOR SELECT TO authenticated
    USING (id IN (SELECT get_user_workspace_ids()));

CREATE POLICY "owners_update_workspaces" ON workspaces
    FOR UPDATE TO authenticated
    USING (id IN (SELECT workspace_id FROM workspace_members WHERE user_id = auth.uid() AND role = 'owner'));

-- Fix the trigger — remove SET search_path = '' which breaks gen_random_uuid()
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_workspace_id UUID;
    v_name TEXT;
BEGIN
    v_name := COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1));

    INSERT INTO public.workspaces (id, name, created_by)
    VALUES (gen_random_uuid(), v_name || E'''s Store', NEW.id)
    RETURNING id INTO v_workspace_id;

    INSERT INTO public.workspace_members (workspace_id, user_id, role)
    VALUES (v_workspace_id, NEW.id, 'owner');

    RETURN NEW;
END;
$$;

GRANT EXECUTE ON FUNCTION public.handle_new_user() TO supabase_auth_admin;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();
