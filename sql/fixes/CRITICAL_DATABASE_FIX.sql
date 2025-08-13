-- ============================================
-- CRITICAL DATABASE SCHEMA AND RLS FIXES
-- Addresses all blocking errors in the system
-- ============================================

-- First, let's diagnose the current state
\echo '=== DIAGNOSTIC PHASE ==='

-- 1. Check products table structure
SELECT 'Products Table Structure' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'products'
ORDER BY ordinal_position;

-- 2. Check product_images table structure  
SELECT 'Product Images Table Structure' as info;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'product_images'
ORDER BY ordinal_position;

-- 3. Check if admin tables exist
SELECT 'Admin Tables Check' as info;
SELECT 
    table_name,
    CASE WHEN table_name IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END as status
FROM information_schema.tables
WHERE table_schema = 'public' 
AND table_name IN ('admin_users', 'admin_sessions')
ORDER BY table_name;

-- 4. Check current RLS policies on problem tables
SELECT 'Current RLS Policies' as info;
SELECT 
    tablename,
    policyname,
    cmd as operation,
    permissive,
    roles,
    qual as condition
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('products', 'product_images', 'product_variants', 'admin_users', 'admin_sessions')
ORDER BY tablename, policyname;

\echo '=== FIX PHASE 1: SCHEMA FIXES ==='

-- 5. Add missing subcategory column to products if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'products' 
        AND column_name = 'subcategory'
    ) THEN
        ALTER TABLE public.products 
        ADD COLUMN subcategory text;
        RAISE NOTICE 'Added subcategory column to products table';
    ELSE
        RAISE NOTICE 'subcategory column already exists in products table';
    END IF;
END $$;

-- 6. Ensure product_images has correct image_url column (not just r2_url)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'product_images' 
        AND column_name = 'image_url'
    ) THEN
        -- Add image_url column
        ALTER TABLE public.product_images 
        ADD COLUMN image_url text;
        
        -- Copy existing r2_url values to image_url if they exist
        UPDATE public.product_images 
        SET image_url = r2_url 
        WHERE r2_url IS NOT NULL AND image_url IS NULL;
        
        RAISE NOTICE 'Added image_url column to product_images table';
    ELSE
        RAISE NOTICE 'image_url column already exists in product_images table';
    END IF;
END $$;

-- 7. Ensure product_images has correct position column (not just sort_order)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'product_images' 
        AND column_name = 'position'
    ) THEN
        -- Add position column
        ALTER TABLE public.product_images 
        ADD COLUMN position integer DEFAULT 0;
        
        -- Copy existing sort_order values to position if they exist
        UPDATE public.product_images 
        SET position = sort_order 
        WHERE sort_order IS NOT NULL;
        
        RAISE NOTICE 'Added position column to product_images table';
    ELSE
        RAISE NOTICE 'position column already exists in product_images table';
    END IF;
END $$;

-- 8. Create admin_users table if missing
CREATE TABLE IF NOT EXISTS public.admin_users (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    email text NOT NULL UNIQUE,
    role text DEFAULT 'admin' CHECK (role IN ('admin', 'super_admin', 'editor')),
    is_active boolean DEFAULT true,
    permissions jsonb DEFAULT '{"read": true, "write": true, "delete": true}',
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    last_login timestamp with time zone
);

-- 9. Create admin_sessions table if missing
CREATE TABLE IF NOT EXISTS public.admin_sessions (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    admin_user_id uuid REFERENCES public.admin_users(id) ON DELETE CASCADE,
    session_token text NOT NULL UNIQUE,
    ip_address inet,
    user_agent text,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    is_active boolean DEFAULT true
);

\echo '=== FIX PHASE 2: RLS POLICY FIXES ==='

-- 10. Enable RLS on all tables
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_sessions ENABLE ROW LEVEL SECURITY;

-- 11. Create is_admin function if it doesn't exist
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check if current user is in admin_users table and is active
    RETURN EXISTS (
        SELECT 1 
        FROM public.admin_users 
        WHERE user_id = auth.uid() 
        AND is_active = true
    );
END;
$$;

-- 12. Drop existing policies and recreate them (clean slate approach)
DROP POLICY IF EXISTS "products_select_all" ON public.products;
DROP POLICY IF EXISTS "products_insert_admin" ON public.products;
DROP POLICY IF EXISTS "products_update_admin" ON public.products;
DROP POLICY IF EXISTS "products_delete_admin" ON public.products;

DROP POLICY IF EXISTS "product_images_select_all" ON public.product_images;
DROP POLICY IF EXISTS "product_images_insert_admin" ON public.product_images;
DROP POLICY IF EXISTS "product_images_update_admin" ON public.product_images;
DROP POLICY IF EXISTS "product_images_delete_admin" ON public.product_images;

DROP POLICY IF EXISTS "product_variants_select_all" ON public.product_variants;
DROP POLICY IF EXISTS "product_variants_insert_admin" ON public.product_variants;
DROP POLICY IF EXISTS "product_variants_update_admin" ON public.product_variants;
DROP POLICY IF EXISTS "product_variants_delete_admin" ON public.product_variants;

DROP POLICY IF EXISTS "admin_users_admin_access" ON public.admin_users;
DROP POLICY IF EXISTS "admin_sessions_admin_access" ON public.admin_sessions;

-- 13. Create permissive policies for products table
CREATE POLICY "products_select_all" ON public.products
    FOR SELECT USING (true);

CREATE POLICY "products_insert_admin" ON public.products
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL AND (
            public.is_admin() OR 
            auth.uid() IN (SELECT user_id FROM public.admin_users WHERE is_active = true)
        )
    );

CREATE POLICY "products_update_admin" ON public.products
    FOR UPDATE USING (
        auth.uid() IS NOT NULL AND (
            public.is_admin() OR 
            auth.uid() IN (SELECT user_id FROM public.admin_users WHERE is_active = true)
        )
    );

CREATE POLICY "products_delete_admin" ON public.products
    FOR DELETE USING (
        auth.uid() IS NOT NULL AND (
            public.is_admin() OR 
            auth.uid() IN (SELECT user_id FROM public.admin_users WHERE is_active = true)
        )
    );

-- 14. Create permissive policies for product_images table
CREATE POLICY "product_images_select_all" ON public.product_images
    FOR SELECT USING (true);

CREATE POLICY "product_images_insert_admin" ON public.product_images
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL AND (
            public.is_admin() OR 
            auth.uid() IN (SELECT user_id FROM public.admin_users WHERE is_active = true)
        )
    );

CREATE POLICY "product_images_update_admin" ON public.product_images
    FOR UPDATE USING (
        auth.uid() IS NOT NULL AND (
            public.is_admin() OR 
            auth.uid() IN (SELECT user_id FROM public.admin_users WHERE is_active = true)
        )
    );

CREATE POLICY "product_images_delete_admin" ON public.product_images
    FOR DELETE USING (
        auth.uid() IS NOT NULL AND (
            public.is_admin() OR 
            auth.uid() IN (SELECT user_id FROM public.admin_users WHERE is_active = true)
        )
    );

-- 15. Create permissive policies for product_variants table
CREATE POLICY "product_variants_select_all" ON public.product_variants
    FOR SELECT USING (true);

CREATE POLICY "product_variants_insert_admin" ON public.product_variants
    FOR INSERT WITH CHECK (
        auth.uid() IS NOT NULL AND (
            public.is_admin() OR 
            auth.uid() IN (SELECT user_id FROM public.admin_users WHERE is_active = true)
        )
    );

CREATE POLICY "product_variants_update_admin" ON public.product_variants
    FOR UPDATE USING (
        auth.uid() IS NOT NULL AND (
            public.is_admin() OR 
            auth.uid() IN (SELECT user_id FROM public.admin_users WHERE is_active = true)
        )
    );

CREATE POLICY "product_variants_delete_admin" ON public.product_variants
    FOR DELETE USING (
        auth.uid() IS NOT NULL AND (
            public.is_admin() OR 
            auth.uid() IN (SELECT user_id FROM public.admin_users WHERE is_active = true)
        )
    );

-- 16. Create policies for admin tables
CREATE POLICY "admin_users_admin_access" ON public.admin_users
    FOR ALL USING (
        auth.uid() IS NOT NULL AND (
            public.is_admin() OR 
            user_id = auth.uid()
        )
    );

CREATE POLICY "admin_sessions_admin_access" ON public.admin_sessions
    FOR ALL USING (
        auth.uid() IS NOT NULL AND (
            public.is_admin() OR 
            admin_user_id IN (SELECT id FROM public.admin_users WHERE user_id = auth.uid())
        )
    );

\echo '=== FIX PHASE 3: GRANTS AND PERMISSIONS ==='

-- 17. Ensure proper grants for authenticated users
GRANT ALL ON public.products TO authenticated;
GRANT ALL ON public.product_images TO authenticated;
GRANT ALL ON public.product_variants TO authenticated;
GRANT ALL ON public.admin_users TO authenticated;
GRANT ALL ON public.admin_sessions TO authenticated;

-- 18. Ensure anon users can at least read products and images
GRANT SELECT ON public.products TO anon;
GRANT SELECT ON public.product_images TO anon;
GRANT SELECT ON public.product_variants TO anon;

\echo '=== FIX PHASE 4: CREATE INITIAL ADMIN USER ==='

-- 19. Create initial admin user if none exists
DO $$
DECLARE
    admin_auth_id uuid;
    existing_admin_count integer;
BEGIN
    -- Check if any admin users exist
    SELECT COUNT(*) INTO existing_admin_count FROM public.admin_users;
    
    IF existing_admin_count = 0 THEN
        -- Look for a user with admin email
        SELECT id INTO admin_auth_id 
        FROM auth.users 
        WHERE email = 'admin@kctmenswear.com' 
        LIMIT 1;
        
        IF admin_auth_id IS NOT NULL THEN
            -- Create admin user record
            INSERT INTO public.admin_users (
                user_id, 
                email, 
                role, 
                is_active, 
                permissions
            ) VALUES (
                admin_auth_id,
                'admin@kctmenswear.com',
                'super_admin',
                true,
                '{"read": true, "write": true, "delete": true, "manage_users": true}'
            );
            RAISE NOTICE 'Created admin user record for existing auth user';
        ELSE
            RAISE NOTICE 'No auth user found with admin email. Please create one first.';
        END IF;
    ELSE
        RAISE NOTICE 'Admin users already exist (%), skipping creation', existing_admin_count;
    END IF;
END $$;

\echo '=== VERIFICATION PHASE ==='

-- 20. Final verification
SELECT 'Final Schema Check' as info;
SELECT 
    table_name,
    CASE 
        WHEN table_name = 'products' THEN 
            CASE WHEN EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_schema = 'public' AND table_name = 'products' AND column_name = 'subcategory'
            ) THEN '✓ subcategory exists' ELSE '✗ subcategory missing' END
        WHEN table_name = 'product_images' THEN 
            CASE WHEN EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_schema = 'public' AND table_name = 'product_images' AND column_name = 'image_url'
            ) THEN '✓ image_url exists' ELSE '✗ image_url missing' END
        ELSE '✓ exists'
    END as column_status
FROM information_schema.tables
WHERE table_schema = 'public' 
AND table_name IN ('products', 'product_images', 'product_variants', 'admin_users', 'admin_sessions');

-- 21. Show policy count per table
SELECT 'Policy Verification' as info;
SELECT 
    tablename,
    COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('products', 'product_images', 'product_variants', 'admin_users', 'admin_sessions')
GROUP BY tablename
ORDER BY tablename;

-- 22. Show admin user status
SELECT 'Admin Users Status' as info;
SELECT 
    au.email,
    au.role,
    au.is_active,
    CASE WHEN u.id IS NOT NULL THEN '✓ auth user exists' ELSE '✗ auth user missing' END as auth_status
FROM public.admin_users au
LEFT JOIN auth.users u ON u.id = au.user_id;

\echo '=== FIX COMPLETE ==='
\echo 'All critical database schema and RLS issues have been addressed.'
\echo 'The system should now allow:'
\echo '- Product updates with subcategory field'
\echo '- Product image uploads and management'
\echo '- Admin user authentication and access'
\echo ''
\echo 'If issues persist, check the application logs for specific error details.'