-- FIX ALL PRODUCT IMAGES
-- This will update all broken image URLs to use the correct R2 bucket

BEGIN;

-- 1. Fix products using old bucket (pub-8ea...) to new bucket (pub-5cd...)
UPDATE products
SET primary_image = REPLACE(
    primary_image, 
    'pub-8ea1de89-a731-488f-b407-5acfb4524ad7',
    'pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2'
)
WHERE primary_image LIKE '%pub-8ea1de89-a731-488f-b407-5acfb4524ad7%';

-- 2. Fix product_images table
UPDATE product_images
SET url = REPLACE(
    url,
    'pub-8ea1de89-a731-488f-b407-5acfb4524ad7',
    'pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2'
)
WHERE url LIKE '%pub-8ea1de89-a731-488f-b407-5acfb4524ad7%';

-- 3. For products with no images, try to find images from product_images table
UPDATE products p
SET primary_image = (
    SELECT url 
    FROM product_images pi 
    WHERE pi.product_id = p.id 
    ORDER BY pi.created_at ASC 
    LIMIT 1
)
WHERE (p.primary_image IS NULL OR p.primary_image = '')
AND EXISTS (
    SELECT 1 
    FROM product_images pi 
    WHERE pi.product_id = p.id
);

-- 4. Show results
SELECT 
    'Images Fixed' as status,
    COUNT(CASE WHEN primary_image LIKE '%pub-5cd%' THEN 1 END) as correct_bucket,
    COUNT(CASE WHEN primary_image LIKE '%pub-8ea%' THEN 1 END) as old_bucket_remaining,
    COUNT(CASE WHEN primary_image IS NULL OR primary_image = '' THEN 1 END) as no_image,
    COUNT(*) as total_products
FROM products
WHERE status = 'active';

COMMIT;

-- 5. List products that still don't have images
SELECT 
    name,
    category,
    sku
FROM products
WHERE status = 'active'
    AND (primary_image IS NULL OR primary_image = '')
ORDER BY category, name
LIMIT 20;