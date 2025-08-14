-- INVESTIGATE WHY ONLY 41 PRODUCTS WERE UPDATED

-- 1. Check how many products still have placeholders or old images
SELECT 
    'Products needing updates' as check_type,
    COUNT(*) as total,
    COUNT(CASE WHEN primary_image LIKE '%placehold%' THEN 1 END) as with_placeholders,
    COUNT(CASE WHEN primary_image LIKE '%pub-5cd%' THEN 1 END) as with_old_r2,
    COUNT(CASE WHEN primary_image LIKE '%8ea0502%' THEN 1 END) as with_new_gallery
FROM products
WHERE status = 'active';

-- 2. Check by category - see which categories didn't get updated
SELECT 
    category,
    COUNT(*) as total_products,
    COUNT(CASE WHEN primary_image LIKE '%8ea0502%' THEN 1 END) as updated_to_gallery,
    COUNT(CASE WHEN primary_image LIKE '%placehold%' THEN 1 END) as still_placeholder,
    COUNT(CASE WHEN primary_image LIKE '%pub-5cd%' THEN 1 END) as still_old_r2
FROM products
WHERE status = 'active'
GROUP BY category
ORDER BY total_products DESC;

-- 3. Check if the matching conditions were too restrictive
SELECT 
    'Categories in database' as info,
    category,
    COUNT(*) as count
FROM products
WHERE status = 'active'
    AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
GROUP BY category
ORDER BY count DESC;

-- 4. Sample products that should have been updated but weren't
SELECT 
    name,
    category,
    sku,
    SUBSTRING(primary_image, 1, 50) as current_image
FROM products
WHERE status = 'active'
    AND (primary_image LIKE '%placehold%' OR primary_image LIKE '%pub-5cd%')
    AND category IN ('Luxury Velvet Blazers', 'Sparkle & Sequin Blazers', 'Vest & Tie Sets')
LIMIT 10;

-- 5. Check if there are duplicate updates (same image used multiple times)
SELECT 
    primary_image,
    COUNT(*) as products_using_this_image
FROM products
WHERE status = 'active'
    AND primary_image LIKE '%8ea0502%'
GROUP BY primary_image
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;