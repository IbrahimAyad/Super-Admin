-- ================================================================
-- DATABASE FIXES - CLEAN VERSION FOR SUPABASE
-- ================================================================
-- Simplified version without PostgreSQL-specific columns
-- ================================================================

-- ================================================================
-- PART 1: DIAGNOSTIC CHECKS
-- ================================================================

-- Check current table structures
SELECT 'DIAGNOSTIC: Checking admin_users table structure' as section;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'admin_users'
ORDER BY ordinal_position;

SELECT 'DIAGNOSTIC: Checking admin_sessions table structure' as section;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'admin_sessions'
ORDER BY ordinal_position;

SELECT 'DIAGNOSTIC: Checking product_images table structure' as section;
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'product_images'
ORDER BY ordinal_position;

-- ================================================================
-- PART 2: SIMPLIFY SESSION MANAGEMENT
-- ================================================================

-- Drop complex session cleanup triggers that cause errors
DROP TRIGGER IF EXISTS cleanup_expired_sessions_trigger ON public.admin_sessions;
DROP FUNCTION IF EXISTS public.cleanup_expired_sessions() CASCADE;
DROP FUNCTION IF EXISTS public.cleanup_excessive_sessions() CASCADE;

-- Create simplified session management for single admin
CREATE OR REPLACE FUNCTION public.simple_session_check()
RETURNS boolean AS $$
BEGIN
    -- For single admin system, just check if authenticated
    RETURN auth.role() = 'authenticated';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ================================================================
-- PART 3: UNIFY IMAGE STORAGE
-- ================================================================

-- Add unified image_url column if missing (handles both R2 and Supabase)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'product_images' 
        AND column_name = 'image_url'
    ) THEN
        ALTER TABLE public.product_images ADD COLUMN image_url TEXT;
        
        -- Migrate existing r2_url data to image_url
        UPDATE public.product_images 
        SET image_url = r2_url 
        WHERE r2_url IS NOT NULL AND image_url IS NULL;
        
        RAISE NOTICE 'Added image_url column and migrated data';
    END IF;
END $$;

-- Ensure position column exists for drag-drop
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'product_images' 
        AND column_name = 'position'
    ) THEN
        ALTER TABLE public.product_images ADD COLUMN position INTEGER;
        
        -- Set default positions based on sort_order if it exists
        UPDATE public.product_images 
        SET position = sort_order::integer 
        WHERE sort_order IS NOT NULL AND position IS NULL;
        
        RAISE NOTICE 'Added position column for drag-drop';
    END IF;
END $$;

-- ================================================================
-- PART 4: ULTRA-SIMPLE RLS POLICIES
-- ================================================================

-- Products table - simple policies
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "products_select_policy" ON public.products;
DROP POLICY IF EXISTS "products_insert_policy" ON public.products;
DROP POLICY IF EXISTS "products_update_policy" ON public.products;
DROP POLICY IF EXISTS "products_delete_policy" ON public.products;

-- Public read, authenticated write
CREATE POLICY "products_public_read" ON public.products
    FOR SELECT USING (true);

CREATE POLICY "products_auth_all" ON public.products
    FOR ALL USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- Product images table - simple policies
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "product_images_select_policy" ON public.product_images;
DROP POLICY IF EXISTS "product_images_insert_policy" ON public.product_images;
DROP POLICY IF EXISTS "product_images_update_policy" ON public.product_images;
DROP POLICY IF EXISTS "product_images_delete_policy" ON public.product_images;

-- Public read, authenticated write
CREATE POLICY "images_public_read" ON public.product_images
    FOR SELECT USING (true);

CREATE POLICY "images_auth_all" ON public.product_images
    FOR ALL USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- Admin tables - authenticated only
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'admin_users'
    ) THEN
        ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
        
        DROP POLICY IF EXISTS "admin_users_select_policy" ON public.admin_users;
        DROP POLICY IF EXISTS "admin_users_insert_policy" ON public.admin_users;
        DROP POLICY IF EXISTS "admin_users_update_policy" ON public.admin_users;
        
        CREATE POLICY "admin_users_auth_all" ON public.admin_users
            FOR ALL USING (auth.role() = 'authenticated')
            WITH CHECK (auth.role() = 'authenticated');
    END IF;
    
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
        
        CREATE POLICY "admin_sessions_auth_all" ON public.admin_sessions
            FOR ALL USING (auth.role() = 'authenticated')
            WITH CHECK (auth.role() = 'authenticated');
    END IF;
END $$;

-- ================================================================
-- PART 5: STORAGE BUCKET POLICIES
-- ================================================================

-- Ensure product-images bucket is properly configured
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO UPDATE
SET public = true;

-- Simple storage policies
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete images" ON storage.objects;

CREATE POLICY "Anyone can view images" ON storage.objects
    FOR SELECT USING (bucket_id = 'product-images');

CREATE POLICY "Authenticated can manage images" ON storage.objects
    FOR ALL USING (
        bucket_id = 'product-images' 
        AND auth.role() = 'authenticated'
    )
    WITH CHECK (
        bucket_id = 'product-images' 
        AND auth.role() = 'authenticated'
    );

-- ================================================================
-- PART 6: GRANTS
-- ================================================================

-- Grant all permissions to authenticated role
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- ================================================================
-- PART 7: CREATE IMAGE URL STANDARDIZATION FUNCTION
-- ================================================================

CREATE OR REPLACE FUNCTION public.get_image_url(p_image_url TEXT, p_r2_url TEXT)
RETURNS TEXT AS $$
BEGIN
    -- Return whichever URL exists, preferring image_url
    RETURN COALESCE(p_image_url, p_r2_url);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ================================================================
-- PART 8: VERIFICATION
-- ================================================================

-- Check RLS status
SELECT 'RLS Status Check:' as section;
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
AND tablename IN ('products', 'product_images', 'admin_users', 'admin_sessions')
ORDER BY tablename;

-- Check if image columns are properly set up
SELECT 'Image columns check:' as section;
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'product_images' 
            AND column_name = 'image_url'
        ) THEN 'image_url column EXISTS'
        ELSE 'image_url column MISSING'
    END as image_url_status,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'product_images' 
            AND column_name = 'position'
        ) THEN 'position column EXISTS'
        ELSE 'position column MISSING'
    END as position_status;

-- Final status
SELECT 'DATABASE FIXES APPLIED SUCCESSFULLY!' as status;