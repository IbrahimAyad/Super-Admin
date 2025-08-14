-- SIMPLE IMAGE ANALYSIS
-- Run this to understand the current image situation

-- 1. Overall image statistics
SELECT 
    COUNT(*) as total_products,
    COUNT(CASE WHEN primary_image IS NOT NULL AND primary_image != '' THEN 1 END) as has_image,
    COUNT(CASE WHEN primary_image IS NULL OR primary_image = '' THEN 1 END) as no_image,
    ROUND(
        COUNT(CASE WHEN primary_image IS NOT NULL AND primary_image != '' THEN 1 END) * 100.0 / COUNT(*),
        2
    ) as percent_with_images
FROM products 
WHERE status = 'active';

-- 2. Bucket breakdown
SELECT 
    CASE 
        WHEN primary_image LIKE '%pub-8ea1de89-a731-488f-b407-5acfb4524ad7%' THEN '❌ OLD BUCKET (Broken)'
        WHEN primary_image LIKE '%pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2%' THEN '✅ NEW BUCKET (Working)'
        WHEN primary_image LIKE '%kct-base-products%' THEN '📦 kct-base-products'
        WHEN primary_image LIKE '%kct-new-website-products%' THEN '📦 kct-new-website-products'
        WHEN primary_image LIKE '%suitshirttie%' THEN '📦 suitshirttie'
        WHEN primary_image IS NULL OR primary_image = '' THEN '❓ No Image'
        ELSE '🔍 Other'
    END as bucket_status,
    COUNT(*) as product_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM products
WHERE status = 'active'
GROUP BY bucket_status
ORDER BY product_count DESC;

-- 3. Category breakdown
SELECT 
    category,
    COUNT(*) as products,
    COUNT(CASE WHEN primary_image LIKE '%pub-8ea%' THEN 1 END) as broken_images,
    COUNT(CASE WHEN primary_image IS NULL OR primary_image = '' THEN 1 END) as no_image,
    COUNT(CASE WHEN primary_image LIKE '%pub-5cd%' THEN 1 END) as working_images
FROM products
WHERE status = 'active'
GROUP BY category
ORDER BY products DESC;

-- 4. Sample broken images (old bucket)
SELECT 
    name,
    category,
    SUBSTRING(primary_image, 1, 100) as image_url_start
FROM products
WHERE status = 'active'
    AND primary_image LIKE '%pub-8ea1de89-a731-488f-b407-5acfb4524ad7%'
LIMIT 10;

-- 5. Sample working images (new bucket)
SELECT 
    name,
    category,
    SUBSTRING(primary_image, 1, 100) as image_url_start
FROM products
WHERE status = 'active'
    AND primary_image LIKE '%pub-5cd73a21-13cf-48bd-8d3f-e0fdcbcb0db2%'
LIMIT 5;