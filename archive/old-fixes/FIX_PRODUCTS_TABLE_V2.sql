-- ============================================
-- FIX PRODUCTS TABLE V2 - Handle NOT NULL constraints
-- Run this in Supabase SQL Editor RIGHT NOW
-- ============================================

-- 1. First, check current constraints
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'products'
AND is_nullable = 'NO'
ORDER BY ordinal_position;

-- 2. Add missing columns if they don't exist
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS slug VARCHAR(255);

ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS details JSONB;

ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS product_type VARCHAR(50);

-- 3. Make description nullable (if it's currently NOT NULL)
ALTER TABLE public.products 
ALTER COLUMN description DROP NOT NULL;

-- 4. Set default values for any NULL descriptions in existing records
UPDATE public.products 
SET description = '' 
WHERE description IS NULL;

-- 5. Generate slugs for existing products that don't have one
UPDATE public.products 
SET slug = LOWER(
    REGEXP_REPLACE(
        REGEXP_REPLACE(
            REGEXP_REPLACE(name, '[^a-zA-Z0-9\s-]', '', 'g'),  -- Remove special chars
            '\s+', '-', 'g'  -- Replace spaces with hyphens
        ),
        '-+', '-', 'g'  -- Replace multiple hyphens with single
    )
) || '-' || LEFT(id::text, 8)  -- Add part of ID to ensure uniqueness
WHERE slug IS NULL OR slug = '';

-- 6. Try to add unique constraint (if it doesn't exist)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'products_slug_unique'
    ) THEN
        ALTER TABLE public.products 
        ADD CONSTRAINT products_slug_unique UNIQUE (slug);
    END IF;
END $$;

-- 7. Test that insert works now with minimal fields
INSERT INTO public.products (
    name,
    sku,
    slug,
    base_price,
    status,
    category,
    description,  -- Include description with empty string
    created_at,
    updated_at
) VALUES (
    'Test Product - Delete Me',
    'TEST-' || EXTRACT(EPOCH FROM NOW())::text,
    'test-product-' || EXTRACT(EPOCH FROM NOW())::text,
    99.99,
    'active',
    'Test',
    '',  -- Empty description
    NOW(),
    NOW()
) RETURNING id, name, slug, sku, description;

-- 8. Clean up test product
DELETE FROM public.products WHERE name = 'Test Product - Delete Me';

-- 9. Show which columns are required (NOT NULL)
SELECT 
    'Required Fields' as info,
    string_agg(column_name, ', ') as required_columns
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'products'
AND is_nullable = 'NO'
AND column_default IS NULL;

-- 10. Show final status
SELECT 
    'Products table fixed!' as status,
    COUNT(*) as total_products,
    COUNT(slug) as products_with_slugs,
    COUNT(*) FILTER (WHERE description IS NOT NULL) as products_with_descriptions
FROM public.products;