-- ============================================
-- QUICK FIX FOR PRODUCT IMAGES RLS 403 ERRORS
-- This addresses the immediate image upload blocking issues
-- ============================================

-- 1. Check current policies on product_images
SELECT 'Current product_images policies:' as info;
SELECT 
    policyname,
    cmd as operation,
    permissive,
    roles,
    qual as condition
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'product_images';

-- 2. Drop restrictive policies that might be blocking uploads
DROP POLICY IF EXISTS "Enable read access for all users" ON public.product_images;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.product_images;
DROP POLICY IF EXISTS "Enable update for users based on email" ON public.product_images;
DROP POLICY IF EXISTS "Enable delete for users based on email" ON public.product_images;

-- 3. Create permissive policies for immediate fix
CREATE POLICY "product_images_select_permissive" ON public.product_images
    FOR SELECT USING (true);

CREATE POLICY "product_images_insert_permissive" ON public.product_images
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "product_images_update_permissive" ON public.product_images
    FOR UPDATE USING (auth.uid() IS NOT NULL);

CREATE POLICY "product_images_delete_permissive" ON public.product_images
    FOR DELETE USING (auth.uid() IS NOT NULL);

-- 4. Ensure proper grants
GRANT ALL ON public.product_images TO authenticated;
GRANT SELECT ON public.product_images TO anon;

-- 5. Check if image_url column exists and add if missing
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'product_images' 
        AND column_name = 'image_url'
    ) THEN
        ALTER TABLE public.product_images ADD COLUMN image_url text;
        RAISE NOTICE 'Added image_url column to product_images';
        
        -- Migrate data from r2_url if it exists
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'product_images' 
            AND column_name = 'r2_url'
        ) THEN
            UPDATE public.product_images 
            SET image_url = r2_url 
            WHERE r2_url IS NOT NULL AND image_url IS NULL;
            RAISE NOTICE 'Migrated r2_url data to image_url';
        END IF;
    ELSE
        RAISE NOTICE 'image_url column already exists';
    END IF;
END $$;

-- 6. Check if position column exists and add if missing
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'product_images' 
        AND column_name = 'position'
    ) THEN
        ALTER TABLE public.product_images ADD COLUMN position integer DEFAULT 0;
        RAISE NOTICE 'Added position column to product_images';
        
        -- Migrate data from sort_order if it exists
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'product_images' 
            AND column_name = 'sort_order'
        ) THEN
            UPDATE public.product_images 
            SET position = sort_order 
            WHERE sort_order IS NOT NULL;
            RAISE NOTICE 'Migrated sort_order data to position';
        END IF;
    ELSE
        RAISE NOTICE 'position column already exists';
    END IF;
END $$;

-- 7. Verification
SELECT 'Final verification:' as info;
SELECT 
    tablename,
    COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
AND tablename = 'product_images'
GROUP BY tablename;

SELECT 'Column structure:' as info;
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'product_images'
AND column_name IN ('image_url', 'r2_url', 'position', 'sort_order')
ORDER BY column_name;