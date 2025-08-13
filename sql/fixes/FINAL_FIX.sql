-- ============================================
-- FINAL FIX - Only handle columns that EXIST
-- Run this in Supabase SQL Editor RIGHT NOW
-- ============================================

-- 1. Show EXACTLY what columns exist and their requirements
SELECT 
    column_name,
    data_type,
    CASE 
        WHEN is_nullable = 'NO' THEN '❌ REQUIRED (NOT NULL)'
        ELSE '✅ Optional (nullable)'
    END as requirement,
    column_default as default_value
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'products'
ORDER BY 
    CASE WHEN is_nullable = 'NO' THEN 0 ELSE 1 END,
    column_name;

-- 2. Add columns that we KNOW are needed (if they don't exist)
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS slug VARCHAR(255);

ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS handle VARCHAR(255);

-- 3. Make existing columns nullable if they're causing issues
DO $$ 
BEGIN
    -- Only alter columns that exist
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'products' AND column_name = 'description') THEN
        ALTER TABLE public.products ALTER COLUMN description DROP NOT NULL;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'products' AND column_name = 'handle') THEN
        ALTER TABLE public.products ALTER COLUMN handle DROP NOT NULL;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'products' AND column_name = 'subcategory') THEN
        ALTER TABLE public.products ALTER COLUMN subcategory DROP NOT NULL;
    END IF;
END $$;

-- 4. Update existing records to have values for important fields
UPDATE public.products 
SET description = COALESCE(description, '')
WHERE description IS NULL;

UPDATE public.products 
SET handle = COALESCE(handle, LOWER(REGEXP_REPLACE(name, '[^a-z0-9]+', '-', 'g')))
WHERE handle IS NULL OR handle = '';

UPDATE public.products 
SET slug = COALESCE(slug, LOWER(REGEXP_REPLACE(name, '[^a-z0-9]+', '-', 'g')) || '-' || LEFT(id::text, 8))
WHERE slug IS NULL OR slug = '';

-- 5. Show the MINIMAL required fields for insert
WITH required_cols AS (
    SELECT column_name, data_type
    FROM information_schema.columns
    WHERE table_schema = 'public' 
    AND table_name = 'products'
    AND is_nullable = 'NO'
    AND column_default IS NULL
)
SELECT 
    'MINIMAL REQUIRED FIELDS:' as info,
    string_agg(column_name || ' (' || data_type || ')', ', ') as required_fields
FROM required_cols;

-- 6. Test insert with only what exists
DO $$
DECLARE
    test_id UUID;
    test_success BOOLEAN := false;
BEGIN
    -- Try insert with common fields
    BEGIN
        INSERT INTO public.products (
            name,
            sku,
            base_price,
            status,
            category,
            description,
            created_at,
            updated_at
        ) VALUES (
            'Test Product - Will Delete',
            'TEST-' || EXTRACT(EPOCH FROM NOW())::text,
            99.99,
            'active',
            'Test',
            '',
            NOW(),
            NOW()
        ) RETURNING id INTO test_id;
        
        test_success := true;
        DELETE FROM public.products WHERE id = test_id;
        RAISE NOTICE '✅ Basic insert works! Product creation should work.';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '❌ Basic insert failed: %', SQLERRM;
    END;
    
    -- If basic failed, try with handle
    IF NOT test_success THEN
        BEGIN
            INSERT INTO public.products (
                name,
                sku,
                base_price,
                status,
                category,
                description,
                handle,
                created_at,
                updated_at
            ) VALUES (
                'Test Product - Will Delete',
                'TEST-' || EXTRACT(EPOCH FROM NOW())::text,
                99.99,
                'active',
                'Test',
                '',
                'test-handle-' || EXTRACT(EPOCH FROM NOW())::text,
                NOW(),
                NOW()
            ) RETURNING id INTO test_id;
            
            DELETE FROM public.products WHERE id = test_id;
            RAISE NOTICE '✅ Insert with handle works!';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '❌ Insert with handle failed: %', SQLERRM;
        END;
    END IF;
END $$;

-- 7. Final status
SELECT 
    '🎯 Products Table Status' as info,
    COUNT(*) as total_products,
    COUNT(DISTINCT category) as categories,
    COUNT(slug) as products_with_slugs,
    COUNT(handle) as products_with_handles
FROM public.products;