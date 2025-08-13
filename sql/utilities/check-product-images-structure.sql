-- ============================================
-- CHECK PRODUCT_IMAGES TABLE STRUCTURE
-- ============================================

-- 1. Check what columns exist in product_images table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'product_images'
ORDER BY ordinal_position;

-- 2. Look at sample data from product_images
SELECT * 
FROM product_images
LIMIT 5;

-- 3. Check if there's an r2_url column instead
SELECT 
    id,
    product_id,
    CASE 
        WHEN r2_url LIKE 'https://gvcswimqaxvylgxbklbz.supabase.co%' THEN '✅ Correct Supabase URL'
        WHEN r2_url LIKE 'http%' THEN '⚠️ Different domain URL'
        WHEN r2_url LIKE '/%' THEN '📁 Absolute path'
        WHEN r2_url IS NULL THEN '❌ NULL'
        WHEN r2_url = '' THEN '❌ Empty'
        ELSE '📄 Filename/path only'
    END as url_status,
    substring(r2_url from 1 for 150) as url_sample
FROM product_images
WHERE r2_url IS NOT NULL
LIMIT 20;

-- 4. Count URLs by pattern (using r2_url)
SELECT 
    CASE 
        WHEN r2_url LIKE 'https://gvcswimqaxvylgxbklbz.supabase.co%' THEN '✅ Correct Supabase URLs'
        WHEN r2_url LIKE 'http%' THEN '⚠️ Other HTTP URLs'
        WHEN r2_url IS NULL OR r2_url = '' THEN '❌ Empty/NULL'
        ELSE '📄 Just paths/filenames'
    END as url_type,
    COUNT(*) as count
FROM product_images
GROUP BY url_type
ORDER BY count DESC;

-- 5. Show actual r2_url values
SELECT DISTINCT substring(r2_url from 1 for 200) as r2_url_sample
FROM product_images
WHERE r2_url IS NOT NULL AND r2_url != ''
LIMIT 10;