-- ============================================
-- CHECK YOUR IMAGE URLS
-- ============================================
-- Run this first to understand what's in your database

-- 1. Check if storage buckets exist
SELECT id, name, public 
FROM storage.buckets
WHERE name IN ('product-images', 'customer-avatars');

-- 2. See sample of current image URLs
SELECT 
    id,
    product_id,
    substring(url from 1 for 150) as url_sample,
    CASE 
        WHEN url LIKE 'https://gvcswimqaxvylgxbklbz.supabase.co%' THEN '✅ Correct Supabase URL'
        WHEN url LIKE 'http%' THEN '⚠️ Different domain URL'
        WHEN url LIKE '/%' THEN '📁 Absolute path'
        WHEN url IS NULL THEN '❌ NULL'
        WHEN url = '' THEN '❌ Empty'
        ELSE '📄 Filename only'
    END as url_status
FROM product_images
LIMIT 20;

-- 3. Count URLs by pattern
SELECT 
    CASE 
        WHEN url LIKE 'https://gvcswimqaxvylgxbklbz.supabase.co%' THEN '✅ Correct Supabase URLs'
        WHEN url LIKE 'http%' THEN '⚠️ Other HTTP URLs'
        WHEN url IS NULL OR url = '' THEN '❌ Empty/NULL'
        ELSE '📄 Just paths/filenames'
    END as url_type,
    COUNT(*) as count
FROM product_images
GROUP BY url_type
ORDER BY count DESC;

-- 4. Show a few full URLs to see the exact format
SELECT url
FROM product_images
WHERE url IS NOT NULL AND url != ''
LIMIT 5;