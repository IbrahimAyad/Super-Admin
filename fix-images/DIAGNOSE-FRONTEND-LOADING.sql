-- DIAGNOSE WHY ONLY 51.5% OF PRODUCTS LOAD ON FRONTEND

-- 1. Check total counts
SELECT 
    'Database Totals' as check_point,
    COUNT(*) as total_products,
    COUNT(DISTINCT category) as total_categories
FROM products
WHERE status = 'active' AND visibility = true;

-- 2. Products per category (matches frontend report?)
SELECT 
    category,
    COUNT(*) as db_count,
    CASE 
        WHEN category = 'Accessories' THEN '✅ 100% loading'
        WHEN category = 'Men''s Suits' THEN '⚠️ 79.6% loading'
        WHEN category = 'Tuxedos' THEN '❌ 38.7% loading'
        WHEN category LIKE '%Blazer%' THEN '❌ Low % loading'
        ELSE '❓ Unknown'
    END as frontend_status
FROM products
WHERE status = 'active' AND visibility = true
GROUP BY category
ORDER BY COUNT(*) DESC;

-- 3. Check for duplicate SKUs (might cause issues)
SELECT 
    'Duplicate SKUs' as issue,
    sku,
    COUNT(*) as count
FROM products
WHERE status = 'active'
GROUP BY sku
HAVING COUNT(*) > 1;

-- 4. Check for products with missing required fields
SELECT 
    'Missing Fields' as issue,
    COUNT(CASE WHEN id IS NULL THEN 1 END) as no_id,
    COUNT(CASE WHEN name IS NULL OR name = '' THEN 1 END) as no_name,
    COUNT(CASE WHEN slug IS NULL OR slug = '' THEN 1 END) as no_slug,
    COUNT(CASE WHEN category IS NULL OR category = '' THEN 1 END) as no_category,
    COUNT(CASE WHEN base_price IS NULL THEN 1 END) as no_price
FROM products
WHERE status = 'active' AND visibility = true;

-- 5. Check RLS for anon users (frontend uses anon key)
SELECT 
    tablename,
    policyname,
    cmd,
    roles,
    CASE 
        WHEN 'anon' = ANY(roles) THEN '✅ Anon can access'
        WHEN 'authenticated' = ANY(roles) THEN '⚠️ Auth required'
        ELSE '❌ No anon access'
    END as anon_access
FROM pg_policies
WHERE tablename IN ('products', 'product_variants', 'product_images');

-- 6. Check if there's a limit in Supabase settings
SELECT 
    'Pagination Check' as check_type,
    274 as total_products,
    141 as loading_on_frontend,
    133 as missing,
    ROUND(141::numeric / 274 * 100, 1) as percent_loading;

-- 7. Products with potential JSON/special character issues
SELECT 
    'Special Characters' as potential_issue,
    name,
    category
FROM products
WHERE status = 'active' 
    AND visibility = true
    AND (
        name LIKE '%"%' OR 
        name LIKE '%''%' OR
        name LIKE '%&%' OR
        description LIKE '%<%' OR
        description LIKE '%>%'
    )
LIMIT 10;

-- 8. Check created_at distribution (maybe only recent products load?)
SELECT 
    DATE(created_at) as created_date,
    COUNT(*) as products_created
FROM products
WHERE status = 'active' AND visibility = true
GROUP BY DATE(created_at)
ORDER BY created_date DESC
LIMIT 10;