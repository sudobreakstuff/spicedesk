-- ============================================================
-- Fix: Auth trigger for auto-creating workspace on signup
-- Run this in Supabase SQL Editor
-- ============================================================

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

    INSERT INTO public.workspaces (id, name, created_by)
    VALUES (gen_random_uuid(), v_name || '''s Store', NEW.id)
    RETURNING id INTO v_workspace_id;

    INSERT INTO public.workspace_members (workspace_id, user_id, role)
    VALUES (v_workspace_id, NEW.id, 'owner');

    RETURN NEW;
END;
$$;

-- Grant execution to supabase_auth_admin
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO supabase_auth_admin;
GRANT ALL ON TABLE public.workspaces TO supabase_auth_admin;
GRANT ALL ON TABLE public.workspace_members TO supabase_auth_admin;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();
