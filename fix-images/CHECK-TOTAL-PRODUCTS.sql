-- CHECK TOTAL PRODUCT COUNT AND STATUS

-- 1. Overall totals
SELECT 
    COUNT(*) as total_all_products,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active_products,
    COUNT(CASE WHEN status = 'draft' THEN 1 END) as draft_products,
    COUNT(CASE WHEN status = 'archived' THEN 1 END) as archived_products
FROM products;

-- 2. Active products image status
SELECT 
    'Active Products' as category,
    COUNT(*) as total,
    COUNT(CASE WHEN primary_image IS NOT NULL AND primary_image != '' THEN 1 END) as has_image,
    COUNT(CASE WHEN primary_image IS NULL OR primary_image = '' THEN 1 END) as no_image
FROM products
WHERE status = 'active';

-- 3. ALL products (including draft/archived) image status
SELECT 
    'ALL Products' as category,
    COUNT(*) as total,
    COUNT(CASE WHEN primary_image IS NOT NULL AND primary_image != '' THEN 1 END) as has_image,
    COUNT(CASE WHEN primary_image IS NULL OR primary_image = '' THEN 1 END) as no_image
FROM products;

-- 4. Breakdown by status and image
SELECT 
    status,
    COUNT(*) as product_count,
    COUNT(CASE WHEN primary_image IS NOT NULL AND primary_image != '' THEN 1 END) as with_image,
    COUNT(CASE WHEN primary_image IS NULL OR primary_image = '' THEN 1 END) as without_image
FROM products
GROUP BY status
ORDER BY product_count DESC;

-- 5. Recent products (might be the new imports)
SELECT 
    'Products added in last 30 days' as timeframe,
    COUNT(*) as total,
    COUNT(CASE WHEN primary_image IS NOT NULL AND primary_image != '' THEN 1 END) as with_image,
    COUNT(CASE WHEN primary_image IS NULL OR primary_image = '' THEN 1 END) as without_image
FROM products
WHERE created_at > NOW() - INTERVAL '30 days';

-- 6. Category totals for ALL products
SELECT 
    category,
    status,
    COUNT(*) as count
FROM products
GROUP BY category, status
ORDER BY category, status;