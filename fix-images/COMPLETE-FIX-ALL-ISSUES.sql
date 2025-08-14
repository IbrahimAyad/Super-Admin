-- COMPLETE FIX FOR ALL PRODUCT DISPLAY ISSUES
-- This fixes both image URLs and adds placeholders

BEGIN;

-- 1. Show current status
SELECT 
    'BEFORE FIX' as status,
    COUNT(*) as total_products,
    COUNT(CASE WHEN primary_image IS NOT NULL AND primary_image != '' THEN 1 END) as with_images,
    COUNT(CASE WHEN primary_image IS NULL OR primary_image = '' THEN 1 END) as without_images
FROM products
WHERE status = 'active';

-- 2. Fix any old bucket URLs (if any exist)
UPDATE products
SET primary_image = REPLACE(
    primary_image, 
    'pub-8ea1de89-a731-488f-b407-5acfb4524ad7',
    'pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2'
)
WHERE primary_image LIKE '%pub-8ea1de89-a731-488f-b407-5acfb4524ad7%';

-- 3. Add placeholder images for products without images
-- Using placehold.co which always works

-- Luxury Velvet Blazers (33 products)
UPDATE products
SET primary_image = 'https://placehold.co/400x600/6b46c1/ffffff?text=Velvet+Blazer'
WHERE category = 'Luxury Velvet Blazers'
    AND (primary_image IS NULL OR primary_image = '');

-- Sparkle & Sequin Blazers (26 products)  
UPDATE products
SET primary_image = 'https://placehold.co/400x600/fbbf24/ffffff?text=Sparkle+Blazer'
WHERE category = 'Sparkle & Sequin Blazers'
    AND (primary_image IS NULL OR primary_image = '');

-- Men's Suits (36 products missing)
UPDATE products
SET primary_image = 'https://placehold.co/400x600/1e293b/ffffff?text=Men%27s+Suit'
WHERE category = 'Men''s Suits'
    AND (primary_image IS NULL OR primary_image = '');

-- Vest & Tie Sets (25 products missing)
UPDATE products
SET primary_image = 'https://placehold.co/400x600/0f766e/ffffff?text=Vest+%26+Tie'
WHERE category = 'Vest & Tie Sets'
    AND (primary_image IS NULL OR primary_image = '');

-- Accessories (23 products missing)
UPDATE products
SET primary_image = 'https://placehold.co/400x600/b91c1c/ffffff?text=Accessory'
WHERE category = 'Accessories'
    AND (primary_image IS NULL OR primary_image = '');

-- Prom & Formal Blazers (14 products)
UPDATE products
SET primary_image = 'https://placehold.co/400x600/c2410c/ffffff?text=Formal+Blazer'
WHERE category = 'Prom & Formal Blazers'
    AND (primary_image IS NULL OR primary_image = '');

-- Men's Dress Shirts (10 products)
UPDATE products
SET primary_image = 'https://placehold.co/400x600/0284c7/ffffff?text=Dress+Shirt'
WHERE category = 'Men''s Dress Shirts'
    AND (primary_image IS NULL OR primary_image = '');

-- Regular Blazers (8 products)
UPDATE products
SET primary_image = 'https://placehold.co/400x600/7c2d12/ffffff?text=Blazer'
WHERE category = 'Blazers'
    AND (primary_image IS NULL OR primary_image = '');

-- Casual Summer Blazers (7 products)
UPDATE products
SET primary_image = 'https://placehold.co/400x600/0891b2/ffffff?text=Summer+Blazer'
WHERE category = 'Casual Summer Blazers'
    AND (primary_image IS NULL OR primary_image = '');

-- Any remaining products without images
UPDATE products
SET primary_image = 'https://placehold.co/400x600/6b7280/ffffff?text=KCT+Menswear'
WHERE (primary_image IS NULL OR primary_image = '')
    AND status = 'active';

-- 4. Note: slug field doesn't exist in this database
-- Skipping slug update

-- 5. Show results
SELECT 
    'AFTER FIX' as status,
    COUNT(*) as total_products,
    COUNT(CASE WHEN primary_image IS NOT NULL AND primary_image != '' THEN 1 END) as with_images,
    COUNT(CASE WHEN primary_image LIKE '%placehold%' THEN 1 END) as placeholder_images,
    COUNT(CASE WHEN primary_image IS NULL OR primary_image = '' THEN 1 END) as still_missing
FROM products
WHERE status = 'active';

COMMIT;

-- 6. Verify all categories now have images
SELECT 
    category,
    COUNT(*) as total,
    COUNT(CASE WHEN primary_image IS NOT NULL AND primary_image != '' THEN 1 END) as with_image,
    COUNT(CASE WHEN primary_image LIKE '%placehold%' THEN 1 END) as placeholders,
    ROUND(
        COUNT(CASE WHEN primary_image IS NOT NULL AND primary_image != '' THEN 1 END) * 100.0 / COUNT(*),
        1
    ) as percent_with_image
FROM products
WHERE status = 'active'
GROUP BY category
ORDER BY total DESC;

-- 7. Sample products to verify
SELECT 
    name,
    category,
    SUBSTRING(primary_image, 1, 50) as image_preview
FROM products
WHERE status = 'active'
ORDER BY RANDOM()
LIMIT 10;