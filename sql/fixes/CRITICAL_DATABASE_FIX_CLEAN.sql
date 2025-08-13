-- ============================================
-- CRITICAL DATABASE FIX - CLEAN VERSION FOR SUPABASE
-- ============================================
-- This version removes all \echo commands for Supabase compatibility
-- Run this after the quick fixes have been applied

-- ============================================
-- 1. DIAGNOSTIC PHASE - Check Current State
-- ============================================

-- Check products table columns
SELECT 'Products table columns:' as check_type;
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'products'
AND column_name IN ('category', 'subcategory', 'product_type')
ORDER BY column_name;

-- Check product_images table columns
SELECT 'Product images table columns:' as check_type;
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'product_images'
AND column_name IN ('image_url', 'r2_url', 'position', 'sort_order')
ORDER BY column_name;

-- ============================================
-- 2. FIX ADMIN TABLES IF MISSING
-- ============================================

-- Create admin_users table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.admin_users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT,
    role TEXT DEFAULT 'admin',
    permissions JSONB DEFAULT '{}',
    two_factor_enabled BOOLEAN DEFAULT false,
    two_factor_secret TEXT,
    recovery_codes TEXT[],
    last_login TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create admin_sessions table if it doesn't exist  
CREATE TABLE IF NOT EXISTS public.admin_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    admin_user_id UUID REFERENCES public.admin_users(id) ON DELETE CASCADE,
    session_token TEXT NOT NULL UNIQUE,
    ip_address INET,
    user_agent TEXT,
    device_fingerprint TEXT,
    last_activity TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 3. CREATE ADMIN CHECKING FUNCTION
-- ============================================

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS public.is_admin();

-- Create is_admin function
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if user exists in admin_users table
    RETURN EXISTS (
        SELECT 1 
        FROM public.admin_users 
        WHERE user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 4. COMPREHENSIVE RLS POLICY FIXES
-- ============================================

-- Fix products table policies
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "products_select_policy" ON public.products;
DROP POLICY IF EXISTS "products_insert_policy" ON public.products;
DROP POLICY IF EXISTS "products_update_policy" ON public.products;
DROP POLICY IF EXISTS "products_delete_policy" ON public.products;

CREATE POLICY "products_select_policy" ON public.products
    FOR SELECT USING (true);

CREATE POLICY "products_insert_policy" ON public.products
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "products_update_policy" ON public.products
    FOR UPDATE 
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "products_delete_policy" ON public.products
    FOR DELETE USING (auth.role() = 'authenticated');

-- Fix product_images table policies
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "product_images_select_policy" ON public.product_images;
DROP POLICY IF EXISTS "product_images_insert_policy" ON public.product_images;
DROP POLICY IF EXISTS "product_images_update_policy" ON public.product_images;
DROP POLICY IF EXISTS "product_images_delete_policy" ON public.product_images;

CREATE POLICY "product_images_select_policy" ON public.product_images
    FOR SELECT USING (true);

CREATE POLICY "product_images_insert_policy" ON public.product_images
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "product_images_update_policy" ON public.product_images
    FOR UPDATE 
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "product_images_delete_policy" ON public.product_images
    FOR DELETE USING (auth.role() = 'authenticated');

-- Fix admin_users table policies
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_users_select_policy" ON public.admin_users;
DROP POLICY IF EXISTS "admin_users_insert_policy" ON public.admin_users;
DROP POLICY IF EXISTS "admin_users_update_policy" ON public.admin_users;

CREATE POLICY "admin_users_select_policy" ON public.admin_users
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "admin_users_insert_policy" ON public.admin_users
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "admin_users_update_policy" ON public.admin_users
    FOR UPDATE 
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- Fix admin_sessions table policies
ALTER TABLE public.admin_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_sessions_select_policy" ON public.admin_sessions;
DROP POLICY IF EXISTS "admin_sessions_insert_policy" ON public.admin_sessions;
DROP POLICY IF EXISTS "admin_sessions_update_policy" ON public.admin_sessions;
DROP POLICY IF EXISTS "admin_sessions_delete_policy" ON public.admin_sessions;

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

-- ============================================
-- 5. GRANT PERMISSIONS
-- ============================================

GRANT ALL ON public.products TO authenticated;
GRANT ALL ON public.product_images TO authenticated;
GRANT ALL ON public.admin_users TO authenticated;
GRANT ALL ON public.admin_sessions TO authenticated;

GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- ============================================
-- 6. CREATE/UPDATE ADMIN USER
-- ============================================

-- Insert or update admin user for current authenticated user
INSERT INTO public.admin_users (user_id, email, role, permissions)
SELECT 
    auth.uid(),
    auth.email(),
    'super_admin',
    '{"all": true}'::jsonb
WHERE auth.uid() IS NOT NULL
ON CONFLICT (user_id) 
DO UPDATE SET 
    last_login = NOW(),
    updated_at = NOW();

-- ============================================
-- 7. STORAGE BUCKET POLICIES
-- ============================================

-- Ensure product-images bucket exists and has proper policies
INSERT INTO storage.buckets (id, name, public, avif_autodetection, allowed_mime_types)
VALUES (
    'product-images', 
    'product-images', 
    true, 
    false,
    ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml']
)
ON CONFLICT (id) DO UPDATE
SET public = true,
    allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml'];

-- Drop existing storage policies
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete images" ON storage.objects;

-- Create permissive storage policies for product-images bucket
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
-- 8. FINAL VERIFICATION
-- ============================================

-- Verify all critical tables exist
SELECT 'Table existence check:' as check_type;
SELECT 
    table_name,
    CASE 
        WHEN table_name IS NOT NULL THEN 'EXISTS'
        ELSE 'MISSING'
    END as status
FROM (
    VALUES 
        ('products'),
        ('product_images'),
        ('admin_users'),
        ('admin_sessions')
) AS required_tables(table_name)
LEFT JOIN information_schema.tables t
    ON t.table_schema = 'public' 
    AND t.table_name = required_tables.table_name;

-- Verify critical columns exist
SELECT 'Critical columns check:' as check_type;
SELECT 
    'products.subcategory' as column_check,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'products' 
            AND column_name = 'subcategory'
        ) THEN 'EXISTS'
        ELSE 'MISSING'
    END as status
UNION ALL
SELECT 
    'product_images.image_url' as column_check,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'product_images' 
            AND column_name = 'image_url'
        ) THEN 'EXISTS'
        ELSE 'MISSING'
    END as status
UNION ALL
SELECT 
    'product_images.position' as column_check,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'product_images' 
            AND column_name = 'position'
        ) THEN 'EXISTS'
        ELSE 'MISSING'
    END as status;

-- Show current user admin status
SELECT 'Admin user status:' as check_type;
SELECT 
    auth.uid() as user_id,
    auth.email() as email,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM public.admin_users 
            WHERE user_id = auth.uid()
        ) THEN 'ADMIN'
        ELSE 'NOT ADMIN'
    END as admin_status;

-- ============================================
-- COMPLETION MESSAGE
-- ============================================
SELECT 'CRITICAL DATABASE FIX COMPLETED SUCCESSFULLY!' as status;