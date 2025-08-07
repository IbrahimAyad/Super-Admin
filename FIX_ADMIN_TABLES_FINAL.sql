-- ============================================
-- FIX ADMIN TABLES - HANDLES EXISTING STRUCTURE
-- ============================================

-- First, check what columns exist in admin_users
SELECT 'Current admin_users columns:' as check_type;
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'admin_users'
ORDER BY ordinal_position;

-- Add missing columns to admin_users if they don't exist
DO $$ 
BEGIN
    -- Add email column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'admin_users' 
        AND column_name = 'email'
    ) THEN
        ALTER TABLE public.admin_users ADD COLUMN email TEXT;
        RAISE NOTICE 'Added email column to admin_users';
    END IF;

    -- Add full_name column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'admin_users' 
        AND column_name = 'full_name'
    ) THEN
        ALTER TABLE public.admin_users ADD COLUMN full_name TEXT;
        RAISE NOTICE 'Added full_name column to admin_users';
    END IF;

    -- Add role column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'admin_users' 
        AND column_name = 'role'
    ) THEN
        ALTER TABLE public.admin_users ADD COLUMN role TEXT DEFAULT 'admin';
        RAISE NOTICE 'Added role column to admin_users';
    END IF;

    -- Add permissions column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'admin_users' 
        AND column_name = 'permissions'
    ) THEN
        ALTER TABLE public.admin_users ADD COLUMN permissions JSONB DEFAULT '{}';
        RAISE NOTICE 'Added permissions column to admin_users';
    END IF;

    -- Add last_login column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'admin_users' 
        AND column_name = 'last_login'
    ) THEN
        ALTER TABLE public.admin_users ADD COLUMN last_login TIMESTAMPTZ;
        RAISE NOTICE 'Added last_login column to admin_users';
    END IF;

    -- Add updated_at column if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'admin_users' 
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.admin_users ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
        RAISE NOTICE 'Added updated_at column to admin_users';
    END IF;
END $$;

-- ============================================
-- CREATE OR UPDATE ADMIN USER
-- ============================================

-- First check if current user already exists in admin_users
DO $$ 
DECLARE
    v_user_id UUID;
    v_email TEXT;
BEGIN
    -- Get current user info
    v_user_id := auth.uid();
    v_email := auth.email();
    
    IF v_user_id IS NOT NULL THEN
        -- Check if user already exists
        IF EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = v_user_id) THEN
            -- Update existing user
            UPDATE public.admin_users 
            SET 
                email = COALESCE(email, v_email),
                last_login = NOW(),
                updated_at = NOW(),
                role = COALESCE(role, 'super_admin'),
                permissions = COALESCE(permissions, '{"all": true}'::jsonb)
            WHERE user_id = v_user_id;
            
            RAISE NOTICE 'Updated existing admin user';
        ELSE
            -- Insert new user
            INSERT INTO public.admin_users (
                user_id, 
                email, 
                role, 
                permissions,
                created_at,
                updated_at
            )
            VALUES (
                v_user_id,
                v_email,
                'super_admin',
                '{"all": true}'::jsonb,
                NOW(),
                NOW()
            );
            
            RAISE NOTICE 'Created new admin user';
        END IF;
    END IF;
END $$;

-- ============================================
-- FIX ADMIN TABLES RLS POLICIES
-- ============================================

-- Enable RLS on admin_users
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DROP POLICY IF EXISTS "admin_users_select_policy" ON public.admin_users;
DROP POLICY IF EXISTS "admin_users_insert_policy" ON public.admin_users;
DROP POLICY IF EXISTS "admin_users_update_policy" ON public.admin_users;
DROP POLICY IF EXISTS "admin_users_delete_policy" ON public.admin_users;

-- Create simple permissive policies for authenticated users
CREATE POLICY "admin_users_select_policy" ON public.admin_users
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "admin_users_insert_policy" ON public.admin_users
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "admin_users_update_policy" ON public.admin_users
    FOR UPDATE 
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "admin_users_delete_policy" ON public.admin_users
    FOR DELETE USING (auth.role() = 'authenticated');

-- Enable RLS on admin_sessions if it exists
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'admin_sessions'
    ) THEN
        ALTER TABLE public.admin_sessions ENABLE ROW LEVEL SECURITY;
        
        -- Drop existing policies
        DROP POLICY IF EXISTS "admin_sessions_select_policy" ON public.admin_sessions;
        DROP POLICY IF EXISTS "admin_sessions_insert_policy" ON public.admin_sessions;
        DROP POLICY IF EXISTS "admin_sessions_update_policy" ON public.admin_sessions;
        DROP POLICY IF EXISTS "admin_sessions_delete_policy" ON public.admin_sessions;
        
        -- Create new policies
        CREATE POLICY "admin_sessions_select_policy" ON public.admin_sessions
            FOR SELECT USING (auth.role() = 'authenticated');
        
        CREATE POLICY "admin_sessions_insert_policy" ON public.admin_sessions
            FOR INSERT WITH CHECK (auth.role() = 'authenticated');
        
        CREATE POLICY "admin_sessions_update_policy" ON public.admin_sessions
            FOR UPDATE 
            USING (auth.role() = 'authenticated')
            WITH CHECK (auth.role() = 'authenticated');
        
        CREATE POLICY "admin_sessions_delete_policy" ON public.admin_sessions
            FOR DELETE USING (auth.role() = 'authenticated');
            
        RAISE NOTICE 'Admin sessions policies updated';
    END IF;
END $$;

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

GRANT ALL ON public.admin_users TO authenticated;
GRANT ALL ON public.admin_sessions TO authenticated;

-- ============================================
-- STORAGE BUCKET POLICIES FOR IMAGES
-- ============================================

-- Ensure product-images bucket exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO UPDATE
SET public = true;

-- Drop and recreate storage policies
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete images" ON storage.objects;

-- Create permissive storage policies
CREATE POLICY "Public Access" ON storage.objects
    FOR SELECT USING (bucket_id = 'product-images');

CREATE POLICY "Authenticated users can upload images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'product-images' 
        AND auth.role() = 'authenticated'
    );

CREATE POLICY "Authenticated users can update images" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'product-images' 
        AND auth.role() = 'authenticated'
    );

CREATE POLICY "Authenticated users can delete images" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'product-images' 
        AND auth.role() = 'authenticated'
    );

-- ============================================
-- VERIFY FIXES
-- ============================================

-- Check admin_users table structure after fixes
SELECT 'Admin users table after fixes:' as check_type;
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'admin_users'
ORDER BY ordinal_position;

-- Check current user admin status
SELECT 'Current user admin status:' as check_type;
SELECT 
    au.user_id,
    au.email,
    au.role,
    au.permissions,
    CASE 
        WHEN au.user_id IS NOT NULL THEN 'ADMIN USER EXISTS'
        ELSE 'NO ADMIN USER'
    END as status
FROM public.admin_users au
WHERE au.user_id = auth.uid();

-- Check if all critical tables have RLS enabled
SELECT 'RLS Status:' as check_type;
SELECT 
    schemaname,
    tablename,
    CASE 
        WHEN rowsecurity THEN 'ENABLED'
        ELSE 'DISABLED'
    END as rls_status
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('products', 'product_images', 'admin_users', 'admin_sessions');

SELECT 'ADMIN TABLES FIXED SUCCESSFULLY!' as status;