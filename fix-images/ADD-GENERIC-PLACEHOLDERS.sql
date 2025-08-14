-- ADD GENERIC PLACEHOLDER IMAGES
-- Uses publicly available placeholder images

BEGIN;

-- Show current status
SELECT 
    category,
    COUNT(*) as total,
    COUNT(CASE WHEN primary_image IS NULL OR primary_image = '' THEN 1 END) as missing_images
FROM products
WHERE status = 'active'
    AND (primary_image IS NULL OR primary_image = '')
GROUP BY category;

-- Add placeholder images using a generic placeholder service
-- These will at least show something instead of broken images

-- Suits and Tuxedos
UPDATE products
SET primary_image = 'https://placehold.co/400x600/1a1a1a/ffffff?text=KCT+Suit'
WHERE category IN ('Men''s Suits')
    AND (primary_image IS NULL OR primary_image = '')
    AND status = 'active';

-- All Blazer types
UPDATE products
SET primary_image = 'https://placehold.co/400x600/2c3e50/ffffff?text=KCT+Blazer'
WHERE category IN ('Luxury Velvet Blazers', 'Sparkle & Sequin Blazers', 'Prom & Formal Blazers', 'Blazers', 'Casual Summer Blazers')
    AND (primary_image IS NULL OR primary_image = '')
    AND status = 'active';

-- Vest & Tie Sets
UPDATE products
SET primary_image = 'https://placehold.co/400x600/34495e/ffffff?text=Vest+%26+Tie'
WHERE category = 'Vest & Tie Sets'
    AND (primary_image IS NULL OR primary_image = '')
    AND status = 'active';

-- Accessories
UPDATE products
SET primary_image = 'https://placehold.co/400x600/7f8c8d/ffffff?text=Accessory'
WHERE category = 'Accessories'
    AND (primary_image IS NULL OR primary_image = '')
    AND status = 'active';

-- Dress Shirts
UPDATE products
SET primary_image = 'https://placehold.co/400x600/3498db/ffffff?text=Dress+Shirt'
WHERE category = 'Men''s Dress Shirts'
    AND (primary_image IS NULL OR primary_image = '')
    AND status = 'active';

-- Any remaining products
UPDATE products
SET primary_image = 'https://placehold.co/400x600/95a5a6/ffffff?text=KCT+Menswear'
WHERE (primary_image IS NULL OR primary_image = '')
    AND status = 'active';

-- Show results
SELECT 
    'Results' as status,
    COUNT(*) as total_products,
    COUNT(CASE WHEN primary_image LIKE '%placehold%' THEN 1 END) as with_placeholders,
    COUNT(CASE WHEN primary_image IS NULL OR primary_image = '' THEN 1 END) as still_missing
FROM products
WHERE status = 'active';

COMMIT;

-- Verify by category
SELECT 
    category,
    COUNT(*) as total,
    COUNT(CASE WHEN primary_image LIKE '%placehold%' THEN 1 END) as placeholders,
    COUNT(CASE WHEN primary_image IS NULL OR primary_image = '' THEN 1 END) as missing
FROM products
WHERE status = 'active'
GROUP BY category
ORDER BY total DESC;