-- SIMPLE FIX FOR PRODUCT IMAGES
-- This focuses only on the products table

BEGIN;

-- 1. Show current status
SELECT 
    'BEFORE FIX' as status,
    COUNT(CASE WHEN primary_image LIKE '%pub-8ea%' THEN 1 END) as old_bucket,
    COUNT(CASE WHEN primary_image LIKE '%pub-5cd%' THEN 1 END) as new_bucket,
    COUNT(CASE WHEN primary_image IS NULL OR primary_image = '' THEN 1 END) as no_image,
    COUNT(*) as total
FROM products
WHERE status = 'active';

-- 2. Fix products using old bucket (pub-8ea...) to new bucket (pub-5cd...)
UPDATE products
SET primary_image = REPLACE(
    primary_image, 
    'pub-8ea1de89-a731-488f-b407-5acfb4524ad7',
    'pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2'
)
WHERE primary_image LIKE '%pub-8ea1de89-a731-488f-b407-5acfb4524ad7%';

-- 3. Show results after fix
SELECT 
    'AFTER FIX' as status,
    COUNT(CASE WHEN primary_image LIKE '%pub-8ea%' THEN 1 END) as old_bucket,
    COUNT(CASE WHEN primary_image LIKE '%pub-5cd%' THEN 1 END) as new_bucket,
    COUNT(CASE WHEN primary_image IS NULL OR primary_image = '' THEN 1 END) as no_image,
    COUNT(*) as total
FROM products
WHERE status = 'active';

COMMIT;

-- 4. Show sample of fixed products
SELECT 
    name,
    category,
    primary_image
FROM products
WHERE status = 'active'
    AND primary_image LIKE '%pub-5cd%'
ORDER BY RANDOM()
LIMIT 10;

-- 5. Show products that still need images
SELECT 
    'Products without images' as status,
    name,
    category,
    sku
FROM products
WHERE status = 'active'
    AND (primary_image IS NULL OR primary_image = '')
LIMIT 20;