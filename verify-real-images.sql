-- VERIFY REAL IMAGE UPDATE SUCCESS

-- 1. Overall status
SELECT 
    'IMAGE STATUS' as check,
    COUNT(*) as total_products,
    COUNT(CASE WHEN primary_image LIKE '%r2.dev%' THEN 1 END) as real_images,
    COUNT(CASE WHEN primary_image LIKE '%placehold%' THEN 1 END) as placeholder_images,
    COUNT(CASE WHEN primary_image IS NULL OR primary_image = '' THEN 1 END) as no_images,
    ROUND(
        COUNT(CASE WHEN primary_image LIKE '%r2.dev%' THEN 1 END) * 100.0 / COUNT(*),
        1
    ) || '%' as percent_real_images
FROM products
WHERE status = 'active';

-- 2. Category breakdown
SELECT 
    category,
    COUNT(*) as total,
    COUNT(CASE WHEN primary_image LIKE '%r2.dev%' THEN 1 END) as real,
    COUNT(CASE WHEN primary_image LIKE '%placehold%' THEN 1 END) as placeholder,
    ROUND(
        COUNT(CASE WHEN primary_image LIKE '%r2.dev%' THEN 1 END) * 100.0 / COUNT(*),
        0
    ) || '%' as percent_real
FROM products
WHERE status = 'active'
GROUP BY category
ORDER BY COUNT(*) DESC;

-- 3. Products still needing real images
SELECT 
    'STILL NEED IMAGES' as status,
    COUNT(*) as count
FROM products
WHERE status = 'active'
    AND primary_image LIKE '%placehold%';

-- 4. Show some products that still have placeholders (if any)
SELECT 
    name,
    category,
    primary_image
FROM products
WHERE status = 'active'
    AND primary_image LIKE '%placehold%'
LIMIT 10;

-- 5. Success confirmation
SELECT 
    CASE 
        WHEN COUNT(CASE WHEN primary_image LIKE '%placehold%' THEN 1 END) = 0 
        THEN '🎉 SUCCESS: All products have real images!'
        ELSE '✅ PROGRESS: ' || COUNT(CASE WHEN primary_image LIKE '%r2.dev%' THEN 1 END) || ' products have real images, ' || 
             COUNT(CASE WHEN primary_image LIKE '%placehold%' THEN 1 END) || ' still need updating'
    END as final_status
FROM products
WHERE status = 'active';