-- Check for blazers in products_enhanced table

-- 1. Find all blazer products
SELECT 
    id,
    name,
    sku,
    category,
    subcategory,
    base_price,
    status
FROM products_enhanced
WHERE LOWER(name) LIKE '%blazer%'
   OR LOWER(category) LIKE '%blazer%'
   OR LOWER(subcategory) LIKE '%blazer%'
ORDER BY category, name;

-- 2. Check which blazers don't have variants
SELECT 
    pe.id,
    pe.name,
    pe.sku,
    pe.category,
    pe.base_price,
    COUNT(pv.id) as variant_count
FROM products_enhanced pe
LEFT JOIN products p ON pe.id = p.id
LEFT JOIN product_variants pv ON p.id = pv.product_id
WHERE LOWER(pe.name) LIKE '%blazer%'
   OR LOWER(pe.category) LIKE '%blazer%'
   OR LOWER(pe.subcategory) LIKE '%blazer%'
GROUP BY pe.id, pe.name, pe.sku, pe.category, pe.base_price
ORDER BY variant_count, pe.category, pe.name;

-- 3. Check if blazers exist in products table
SELECT 
    pe.name as enhanced_name,
    pe.sku as enhanced_sku,
    p.name as products_name,
    p.sku as products_sku,
    CASE WHEN p.id IS NULL THEN 'NOT SYNCED' ELSE 'SYNCED' END as sync_status
FROM products_enhanced pe
LEFT JOIN products p ON pe.id = p.id
WHERE LOWER(pe.name) LIKE '%blazer%'
   OR LOWER(pe.category) LIKE '%blazer%'
LIMIT 20;

-- 4. Count total blazers
SELECT 
    COUNT(*) as total_blazer_products,
    COUNT(DISTINCT category) as blazer_categories
FROM products_enhanced
WHERE LOWER(name) LIKE '%blazer%'
   OR LOWER(category) LIKE '%blazer%';