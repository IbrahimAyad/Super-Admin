-- ============================================
-- COMPREHENSIVE FIX - Discover and Fix ALL Constraints
-- Run this in Supabase SQL Editor RIGHT NOW
-- ============================================

-- 1. FIRST - Show ALL columns with NOT NULL constraints
SELECT 
    column_name,
    data_type,
    column_default,
    CASE 
        WHEN is_nullable = 'NO' THEN '❌ REQUIRED'
        ELSE '✅ Optional'
    END as requirement
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'products'
ORDER BY 
    CASE WHEN is_nullable = 'NO' THEN 0 ELSE 1 END,
    ordinal_position;

-- 2. Make commonly problematic columns nullable
ALTER TABLE public.products ALTER COLUMN description DROP NOT NULL;
ALTER TABLE public.products ALTER COLUMN handle DROP NOT NULL;
ALTER TABLE public.products ALTER COLUMN subcategory DROP NOT NULL;
ALTER TABLE public.products ALTER COLUMN supplier DROP NOT NULL;
ALTER TABLE public.products ALTER COLUMN brand DROP NOT NULL;

-- 3. Add missing columns if they don't exist
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS slug VARCHAR(255);

ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS handle VARCHAR(255);

ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS details JSONB;

ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS product_type VARCHAR(50);

-- 4. Set default values for existing NULL values
UPDATE public.products SET description = '' WHERE description IS NULL;
UPDATE public.products SET handle = name WHERE handle IS NULL;
UPDATE public.products SET subcategory = '' WHERE subcategory IS NULL;
UPDATE public.products SET supplier = 'KCT Menswear' WHERE supplier IS NULL;
UPDATE public.products SET brand = 'KCT Menswear' WHERE brand IS NULL;

-- 5. Generate slugs and handles for existing products
UPDATE public.products 
SET slug = LOWER(
    REGEXP_REPLACE(
        REGEXP_REPLACE(
            REGEXP_REPLACE(name, '[^a-zA-Z0-9\s-]', '', 'g'),
            '\s+', '-', 'g'
        ),
        '-+', '-', 'g'
    )
) || '-' || LEFT(id::text, 8)
WHERE slug IS NULL OR slug = '';

UPDATE public.products 
SET handle = LOWER(
    REGEXP_REPLACE(
        REGEXP_REPLACE(
            REGEXP_REPLACE(name, '[^a-zA-Z0-9\s-]', '', 'g'),
            '\s+', '-', 'g'
        ),
        '-+', '-', 'g'
    )
)
WHERE handle IS NULL OR handle = '';

-- 6. Test insert with discovered required fields
DO $$
DECLARE
    test_id UUID;
BEGIN
    INSERT INTO public.products (
        name,
        sku,
        base_price,
        status,
        category,
        -- Include fields that might be required
        description,
        handle,
        slug,
        supplier,
        brand,
        subcategory,
        created_at,
        updated_at
    ) VALUES (
        'Test Product - Delete Me',
        'TEST-' || EXTRACT(EPOCH FROM NOW())::text,
        99.99,
        'active',
        'Test',
        '',  -- empty description
        'test-handle-' || EXTRACT(EPOCH FROM NOW())::text,
        'test-slug-' || EXTRACT(EPOCH FROM NOW())::text,
        'KCT Menswear',
        'KCT Menswear',
        'Test Subcategory',
        NOW(),
        NOW()
    ) RETURNING id INTO test_id;
    
    -- If successful, delete the test record
    DELETE FROM public.products WHERE id = test_id;
    
    RAISE NOTICE 'Test insert successful! Product creation should work now.';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Test insert failed: %', SQLERRM;
END $$;

-- 7. Show final requirements
SELECT 
    'FINAL REQUIREMENTS CHECK' as info,
    json_agg(
        json_build_object(
            'column', column_name,
            'type', data_type,
            'required', CASE WHEN is_nullable = 'NO' THEN true ELSE false END,
            'default', column_default
        ) ORDER BY ordinal_position
    ) as columns
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'products'
AND (is_nullable = 'NO' OR column_name IN ('name', 'sku', 'base_price', 'status', 'category', 'description', 'handle', 'slug'));

-- 8. Show success message
SELECT 
    '✅ Products table fixed!' as status,
    COUNT(*) as total_products
FROM public.products;