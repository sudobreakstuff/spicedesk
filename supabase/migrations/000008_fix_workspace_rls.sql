-- Fix: Allow authenticated users to create workspaces
-- The missing INSERT policy was blocking workspace creation

-- Drop the old SELECT-only policy
DROP POLICY IF EXISTS "members_view" ON workspaces;
DROP POLICY IF EXISTS "workspace_access" ON workspaces;

-- Allow authenticated users to create workspaces (they become owner automatically)
CREATE POLICY "users_create_workspace" ON workspaces
    FOR INSERT TO authenticated
    WITH CHECK (true);

-- Allow workspace members to view their workspaces
CREATE POLICY "members_view_workspace" ON workspaces
    FOR SELECT TO authenticated
    USING (id IN (SELECT get_user_workspace_ids()));

-- Allow workspace owners to update their workspaces
CREATE POLICY "owners_update_workspace" ON workspaces
    FOR UPDATE TO authenticated
    USING (id IN (
        SELECT workspace_id FROM workspace_members 
        WHERE user_id = auth.uid() AND role = 'owner'
    ))
    WITH CHECK (id IN (
        SELECT workspace_id FROM workspace_members 
        WHERE user_id = auth.uid() AND role = 'owner'
    ));

-- Fix the auto-workspace trigger to be more robust
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_workspace_id UUID;
    v_name TEXT;
BEGIN
    v_name := COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1));

    -- Insert workspace (bypasses RLS because we're SECURITY DEFINER)
    INSERT INTO public.workspaces (id, name, created_by)
    VALUES (gen_random_uuid(), v_name || E'\'s Store', NEW.id)
    RETURNING id INTO v_workspace_id;

    -- Add user as owner (bypasses RLS because we're SECURITY DEFINER)
    INSERT INTO public.workspace_members (workspace_id, user_id, role)
    VALUES (v_workspace_id, NEW.id, 'owner');

    RETURN NEW;
END;
$$;

GRANT EXECUTE ON FUNCTION public.handle_new_user() TO supabase_auth_admin;
GRANT ALL ON TABLE public.workspaces TO supabase_auth_admin;
GRANT ALL ON TABLE public.workspace_members TO supabase_auth_admin;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();
