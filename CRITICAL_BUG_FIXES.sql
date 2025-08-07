-- ============================================
-- CRITICAL BUG FIXES FOR SUPABASE DATABASE
-- ============================================
-- Run this script in Supabase SQL Editor to fix critical 400/401/403 errors
-- Last updated: 2025-08-07

-- ============================================
-- 1. FIX PRODUCTS TABLE PERMISSIONS & POLICIES
-- ============================================

-- Ensure RLS is enabled
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Drop existing problematic policies
DROP POLICY IF EXISTS "Allow public read" ON public.products;
DROP POLICY IF EXISTS "Allow authenticated write" ON public.products;
DROP POLICY IF EXISTS "authenticated_users_can_read_products" ON public.products;
DROP POLICY IF EXISTS "authenticated_users_can_modify_products" ON public.products;

-- Create comprehensive policies for products
CREATE POLICY "products_select_policy" ON public.products
    FOR SELECT 
    USING (true); -- Allow public read access to products

CREATE POLICY "products_insert_policy" ON public.products
    FOR INSERT 
    WITH CHECK (
        auth.role() = 'authenticated' OR 
        auth.role() = 'service_role'
    );

CREATE POLICY "products_update_policy" ON public.products
    FOR UPDATE 
    USING (
        auth.role() = 'authenticated' OR 
        auth.role() = 'service_role'
    )
    WITH CHECK (
        auth.role() = 'authenticated' OR 
        auth.role() = 'service_role'
    );

CREATE POLICY "products_delete_policy" ON public.products
    FOR DELETE 
    USING (
        auth.role() = 'authenticated' OR 
        auth.role() = 'service_role'
    );

-- ============================================
-- 2. FIX PRODUCT_IMAGES TABLE PERMISSIONS
-- ============================================

-- Ensure RLS is enabled
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "product_images_select_policy" ON public.product_images;
DROP POLICY IF EXISTS "product_images_insert_policy" ON public.product_images;
DROP POLICY IF EXISTS "product_images_update_policy" ON public.product_images;
DROP POLICY IF EXISTS "product_images_delete_policy" ON public.product_images;

-- Create policies for product_images
CREATE POLICY "product_images_select_policy" ON public.product_images
    FOR SELECT 
    USING (true); -- Allow public read access to product images

CREATE POLICY "product_images_insert_policy" ON public.product_images
    FOR INSERT 
    WITH CHECK (
        auth.role() = 'authenticated' OR 
        auth.role() = 'service_role'
    );

CREATE POLICY "product_images_update_policy" ON public.product_images
    FOR UPDATE 
    USING (
        auth.role() = 'authenticated' OR 
        auth.role() = 'service_role'
    )
    WITH CHECK (
        auth.role() = 'authenticated' OR 
        auth.role() = 'service_role'
    );

CREATE POLICY "product_images_delete_policy" ON public.product_images
    FOR DELETE 
    USING (
        auth.role() = 'authenticated' OR 
        auth.role() = 'service_role'
    );

-- ============================================
-- 3. FIX PRODUCT_VARIANTS TABLE PERMISSIONS
-- ============================================

-- Ensure RLS is enabled and create policies if table exists
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'product_variants'
    ) THEN
        ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;
        
        DROP POLICY IF EXISTS "product_variants_select_policy" ON public.product_variants;
        DROP POLICY IF EXISTS "product_variants_insert_policy" ON public.product_variants;
        DROP POLICY IF EXISTS "product_variants_update_policy" ON public.product_variants;
        DROP POLICY IF EXISTS "product_variants_delete_policy" ON public.product_variants;

        CREATE POLICY "product_variants_select_policy" ON public.product_variants
            FOR SELECT 
            USING (true);

        CREATE POLICY "product_variants_insert_policy" ON public.product_variants
            FOR INSERT 
            WITH CHECK (auth.role() = 'authenticated' OR auth.role() = 'service_role');

        CREATE POLICY "product_variants_update_policy" ON public.product_variants
            FOR UPDATE 
            USING (auth.role() = 'authenticated' OR auth.role() = 'service_role')
            WITH CHECK (auth.role() = 'authenticated' OR auth.role() = 'service_role');

        CREATE POLICY "product_variants_delete_policy" ON public.product_variants
            FOR DELETE 
            USING (auth.role() = 'authenticated' OR auth.role() = 'service_role');
    END IF;
END $$;

-- ============================================
-- 4. FIX ADMIN_USERS TABLE POLICIES
-- ============================================

-- Drop problematic policies
DROP POLICY IF EXISTS "safe_admin_status_check" ON public.admin_users;
DROP POLICY IF EXISTS "admins_can_modify_admin_users" ON public.admin_users;
DROP POLICY IF EXISTS "admins_can_update_admin_users" ON public.admin_users;
DROP POLICY IF EXISTS "admins_can_delete_admin_users" ON public.admin_users;

-- Create simplified policies
CREATE POLICY "admin_users_select_policy" ON public.admin_users
    FOR SELECT 
    USING (
        auth.uid() = user_id OR 
        auth.role() = 'service_role' OR
        auth.role() = 'authenticated'
    );

CREATE POLICY "admin_users_insert_policy" ON public.admin_users
    FOR INSERT 
    WITH CHECK (
        auth.uid() = user_id OR 
        auth.role() = 'service_role'
    );

CREATE POLICY "admin_users_update_policy" ON public.admin_users
    FOR UPDATE 
    USING (
        auth.uid() = user_id OR 
        auth.role() = 'service_role'
    )
    WITH CHECK (
        auth.uid() = user_id OR 
        auth.role() = 'service_role'
    );

-- ============================================
-- 5. FIX ADMIN_SESSIONS TABLE POLICIES
-- ============================================

-- Ensure admin_sessions table exists and has proper policies
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'admin_sessions'
    ) THEN
        ALTER TABLE public.admin_sessions ENABLE ROW LEVEL SECURITY;
        
        DROP POLICY IF EXISTS "admin_sessions_select_policy" ON public.admin_sessions;
        DROP POLICY IF EXISTS "admin_sessions_insert_policy" ON public.admin_sessions;
        DROP POLICY IF EXISTS "admin_sessions_update_policy" ON public.admin_sessions;
        DROP POLICY IF EXISTS "admin_sessions_delete_policy" ON public.admin_sessions;

        CREATE POLICY "admin_sessions_select_policy" ON public.admin_sessions
            FOR SELECT 
            USING (
                auth.uid() = user_id OR 
                auth.role() = 'service_role'
            );

        CREATE POLICY "admin_sessions_insert_policy" ON public.admin_sessions
            FOR INSERT 
            WITH CHECK (
                auth.uid() = user_id OR 
                auth.role() = 'service_role'
            );

        CREATE POLICY "admin_sessions_update_policy" ON public.admin_sessions
            FOR UPDATE 
            USING (
                auth.uid() = user_id OR 
                auth.role() = 'service_role'
            );

        CREATE POLICY "admin_sessions_delete_policy" ON public.admin_sessions
            FOR DELETE 
            USING (
                auth.uid() = user_id OR 
                auth.role() = 'service_role'
            );
    END IF;
END $$;

-- ============================================
-- 6. GRANT NECESSARY PERMISSIONS
-- ============================================

-- Grant permissions to authenticated users
GRANT ALL ON public.products TO authenticated;
GRANT ALL ON public.product_images TO authenticated;
GRANT ALL ON public.admin_users TO authenticated;

-- Grant permissions to product_variants if it exists
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'product_variants'
    ) THEN
        GRANT ALL ON public.product_variants TO authenticated;
    END IF;
END $$;

-- Grant permissions to admin_sessions if it exists
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'admin_sessions'
    ) THEN
        GRANT ALL ON public.admin_sessions TO authenticated;
    END IF;
END $$;

-- ============================================
-- 7. ENSURE PRODUCT_IMAGES SCHEMA IS CORRECT
-- ============================================

-- Check if product_images has correct column names
DO $$ 
DECLARE
    has_image_url boolean;
    has_url boolean;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'product_images' 
        AND column_name = 'image_url'
    ) INTO has_image_url;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'product_images' 
        AND column_name = 'url'
    ) INTO has_url;
    
    -- If we have 'url' but not 'image_url', rename it
    IF has_url AND NOT has_image_url THEN
        ALTER TABLE public.product_images RENAME COLUMN url TO image_url;
        RAISE NOTICE 'Renamed column url to image_url in product_images table';
    END IF;
    
    -- Ensure position column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'product_images' 
        AND column_name = 'position'
    ) THEN
        ALTER TABLE public.product_images ADD COLUMN position integer DEFAULT 0;
        RAISE NOTICE 'Added position column to product_images table';
    END IF;
    
    -- Ensure image_type column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'product_images' 
        AND column_name = 'image_type'
    ) THEN
        ALTER TABLE public.product_images ADD COLUMN image_type text DEFAULT 'gallery';
        RAISE NOTICE 'Added image_type column to product_images table';
    END IF;
END $$;

-- ============================================
-- 8. VERIFICATION QUERIES
-- ============================================

-- Check auth status
SELECT 
    'Current Auth Status' as info,
    auth.uid() as user_id,
    auth.role() as role,
    CASE 
        WHEN auth.uid() IS NOT NULL THEN 'Authenticated'
        ELSE 'Not Authenticated'
    END as status;

-- Check table policies
SELECT 
    'Table Policies' as info,
    tablename,
    COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('products', 'product_images', 'admin_users', 'admin_sessions', 'product_variants')
GROUP BY tablename
ORDER BY tablename;

-- Check product_images schema
SELECT 
    'Product Images Schema' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'product_images' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Test product read access
SELECT 
    'Product Access Test' as info,
    COUNT(*) as product_count
FROM products
LIMIT 1;

-- ============================================
-- 9. FINAL NOTES
-- ============================================
-- After running this script:
-- 1. Clear browser cache and cookies
-- 2. Sign out and sign back in
-- 3. Try creating/updating products again
-- 4. Check browser console for any remaining errors
-- 
-- If issues persist, the problem may be with:
-- - Storage bucket policies (run supabase-storage-setup.sql)
-- - Environment variables (check VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY)
-- - Network/CORS issues