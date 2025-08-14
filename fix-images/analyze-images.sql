-- ANALYZE IMAGE SITUATION
-- Run this in Supabase SQL Editor to understand the current state

-- 1. Overall image statistics
SELECT 
    'Image Statistics' as analysis,
    COUNT(*) as total_products,
    COUNT(primary_image) as has_primary_image,
    COUNT(CASE WHEN primary_image IS NOT NULL AND primary_image != '' THEN 1 END) as has_image_url,
    COUNT(CASE WHEN primary_image IS NULL OR primary_image = '' THEN 1 END) as missing_image
FROM products 
WHERE status = 'active';

-- 2. Image URL patterns (which buckets are being used)
SELECT 
    'Image URL Patterns' as analysis,
    CASE 
        WHEN primary_image LIKE '%pub-8ea%' THEN 'Old Bucket (pub-8ea...)'
        WHEN primary_image LIKE '%pub-5cd%' THEN 'New Bucket (pub-5cd...)'
        WHEN primary_image LIKE '%kct-base-products%' THEN 'kct-base-products'
        WHEN primary_image LIKE '%kct-new-website-products%' THEN 'kct-new-website-products'
        WHEN primary_image LIKE '%suitshirttie%' THEN 'suitshirttie'
        WHEN primary_image IS NULL OR primary_image = '' THEN 'No Image'
        ELSE 'Other Pattern'
    END as bucket_type,
    COUNT(*) as product_count
FROM products
WHERE status = 'active'
GROUP BY bucket_type
ORDER BY product_count DESC;

-- 3. Sample of broken images (old bucket)
SELECT 
    'Sample Broken Images' as analysis,
    name,
    category,
    primary_image
FROM products
WHERE status = 'active'
    AND primary_image LIKE '%pub-8ea%'
LIMIT 10;

-- 4. Products without images
SELECT 
    'Products Without Images' as analysis,
    name,
    category,
    sku
FROM products
WHERE status = 'active'
    AND (primary_image IS NULL OR primary_image = '')
LIMIT 10;

-- 5. Check if product_images table exists and its structure
SELECT 
    'Product Images Table Structure' as analysis,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'product_images'
ORDER BY ordinal_position;

-- 6. Category breakdown
SELECT 
    category,
    COUNT(*) as total_products,
    COUNT(CASE WHEN primary_image IS NOT NULL AND primary_image != '' THEN 1 END) as has_image,
    COUNT(CASE WHEN primary_image IS NULL OR primary_image = '' THEN 1 END) as missing_image,
    ROUND(
        COUNT(CASE WHEN primary_image IS NOT NULL AND primary_image != '' THEN 1 END) * 100.0 / COUNT(*), 
        2
    ) as image_percentage
FROM products
WHERE status = 'active'
GROUP BY category
ORDER BY total_products DESC;