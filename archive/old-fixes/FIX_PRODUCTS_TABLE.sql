-- ============================================
-- FIX PRODUCTS TABLE - Add Missing Columns
-- Run this in Supabase SQL Editor RIGHT NOW
-- ============================================

-- 1. Add slug column if it doesn't exist
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS slug VARCHAR(255);

-- 2. Generate slugs for existing products that don't have one
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

-- 3. Make slug unique after populating it
ALTER TABLE public.products 
ADD CONSTRAINT products_slug_unique UNIQUE (slug);

-- 4. Add other missing columns
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS details JSONB;

ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS product_type VARCHAR(50);

-- 5. Verify all columns exist
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'products'
ORDER BY ordinal_position;

-- 6. Test that insert works now
INSERT INTO public.products (
    name,
    sku,
    slug,
    base_price,
    status,
    category,
    created_at,
    updated_at
) VALUES (
    'Test Product - Delete Me',
    'TEST-' || EXTRACT(EPOCH FROM NOW())::text,
    'test-product-' || EXTRACT(EPOCH FROM NOW())::text,
    99.99,
    'active',
    'Test',
    NOW(),
    NOW()
) RETURNING id, name, slug, sku;

-- 7. Clean up test product (optional - comment out if you want to keep it)
DELETE FROM public.products WHERE name = 'Test Product - Delete Me';

-- 8. Show final status
SELECT 
    'Products table fixed!' as status,
    COUNT(*) as total_products,
    COUNT(slug) as products_with_slugs
FROM public.products;