-- ADD PLACEHOLDER IMAGES FOR PRODUCTS WITHOUT IMAGES
-- This adds category-specific placeholder images

BEGIN;

-- Show current status
SELECT 
    'BEFORE PLACEHOLDERS' as status,
    COUNT(CASE WHEN primary_image IS NULL OR primary_image = '' THEN 1 END) as no_image,
    COUNT(CASE WHEN primary_image IS NOT NULL AND primary_image != '' THEN 1 END) as has_image
FROM products
WHERE status = 'active';

-- Add placeholder images by category
-- Using the working bucket URL pattern

-- Luxury Velvet Blazers (33 products)
UPDATE products
SET primary_image = 'https://pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2.r2.dev/kct-base-products/placeholder-velvet-blazer.jpg'
WHERE category = 'Luxury Velvet Blazers'
    AND (primary_image IS NULL OR primary_image = '')
    AND status = 'active';

-- Sparkle & Sequin Blazers (26 products)
UPDATE products
SET primary_image = 'https://pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2.r2.dev/kct-base-products/placeholder-sparkle-blazer.jpg'
WHERE category = 'Sparkle & Sequin Blazers'
    AND (primary_image IS NULL OR primary_image = '')
    AND status = 'active';

-- Men's Suits (36 products)
UPDATE products
SET primary_image = 'https://pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2.r2.dev/kct-base-products/placeholder-suit.jpg'
WHERE category = 'Men''s Suits'
    AND (primary_image IS NULL OR primary_image = '')
    AND status = 'active';

-- Vest & Tie Sets (25 products)
UPDATE products
SET primary_image = 'https://pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2.r2.dev/kct-base-products/placeholder-vest-tie.jpg'
WHERE category = 'Vest & Tie Sets'
    AND (primary_image IS NULL OR primary_image = '')
    AND status = 'active';

-- Accessories (23 products)
UPDATE products
SET primary_image = 'https://pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2.r2.dev/kct-base-products/placeholder-accessories.jpg'
WHERE category = 'Accessories'
    AND (primary_image IS NULL OR primary_image = '')
    AND status = 'active';

-- Prom & Formal Blazers (14 products)
UPDATE products
SET primary_image = 'https://pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2.r2.dev/kct-base-products/placeholder-prom-blazer.jpg'
WHERE category = 'Prom & Formal Blazers'
    AND (primary_image IS NULL OR primary_image = '')
    AND status = 'active';

-- Men's Dress Shirts (10 products)
UPDATE products
SET primary_image = 'https://pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2.r2.dev/kct-base-products/placeholder-shirt.jpg'
WHERE category = 'Men''s Dress Shirts'
    AND (primary_image IS NULL OR primary_image = '')
    AND status = 'active';

-- Regular Blazers (8 products)
UPDATE products
SET primary_image = 'https://pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2.r2.dev/kct-base-products/placeholder-blazer.jpg'
WHERE category = 'Blazers'
    AND (primary_image IS NULL OR primary_image = '')
    AND status = 'active';

-- Casual Summer Blazers (7 products)
UPDATE products
SET primary_image = 'https://pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2.r2.dev/kct-base-products/placeholder-summer-blazer.jpg'
WHERE category = 'Casual Summer Blazers'
    AND (primary_image IS NULL OR primary_image = '')
    AND status = 'active';

-- Generic placeholder for any remaining products
UPDATE products
SET primary_image = 'https://pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2.r2.dev/kct-base-products/placeholder-product.jpg'
WHERE (primary_image IS NULL OR primary_image = '')
    AND status = 'active';

-- Show results
SELECT 
    'AFTER PLACEHOLDERS' as status,
    COUNT(CASE WHEN primary_image IS NULL OR primary_image = '' THEN 1 END) as no_image,
    COUNT(CASE WHEN primary_image IS NOT NULL AND primary_image != '' THEN 1 END) as has_image
FROM products
WHERE status = 'active';

COMMIT;

-- Show what we added placeholders for
SELECT 
    category,
    COUNT(*) as products_with_placeholders
FROM products
WHERE status = 'active'
    AND primary_image LIKE '%placeholder%'
GROUP BY category
ORDER BY products_with_placeholders DESC;