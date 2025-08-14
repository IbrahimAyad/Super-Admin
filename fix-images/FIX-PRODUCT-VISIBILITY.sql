-- FIX PRODUCT VISIBILITY ISSUES
-- Ensure all products can be loaded on frontend

BEGIN;

-- 1. Check current visibility status
SELECT 
    'Current Status' as check_type,
    status,
    visibility,
    COUNT(*) as count
FROM products
GROUP BY status, visibility;

-- 2. Make sure all active products are visible
UPDATE products
SET visibility = true
WHERE status = 'active'
    AND (visibility IS NULL OR visibility = false);

-- 3. Fix any products with null status (set to active if they have price)
UPDATE products p
SET status = 'active'
WHERE p.status IS NULL
    AND EXISTS (
        SELECT 1 FROM product_variants pv 
        WHERE pv.product_id = p.id 
        AND pv.price > 0
    );

-- 4. Ensure products have proper fields for frontend
UPDATE products
SET 
    slug = LOWER(REPLACE(REPLACE(name, ' ', '-'), '''', ''))
WHERE slug IS NULL OR slug = '';

-- 5. Check if all required fields are present
SELECT 
    'Missing Required Fields' as issue,
    COUNT(CASE WHEN name IS NULL OR name = '' THEN 1 END) as no_name,
    COUNT(CASE WHEN category IS NULL OR category = '' THEN 1 END) as no_category,
    COUNT(CASE WHEN status IS NULL THEN 1 END) as no_status,
    COUNT(CASE WHEN visibility IS NULL THEN 1 END) as no_visibility
FROM products
WHERE status = 'active';

-- 6. Final count after fixes
SELECT 
    'After Fixes' as status,
    COUNT(*) as total_products,
    COUNT(CASE WHEN status = 'active' AND visibility = true THEN 1 END) as visible_active,
    COUNT(CASE WHEN status = 'active' AND (visibility = false OR visibility IS NULL) THEN 1 END) as hidden_active
FROM products;

COMMIT;

-- 7. List categories and their product counts
SELECT 
    category,
    COUNT(*) as total,
    COUNT(CASE WHEN status = 'active' AND visibility = true THEN 1 END) as visible,
    COUNT(CASE WHEN status = 'active' AND (visibility = false OR visibility IS NULL) THEN 1 END) as hidden
FROM products
GROUP BY category
ORDER BY total DESC;