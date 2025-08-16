-- Check for OLD products that exist in products table but NOT in products_enhanced
-- These would be legacy products that can be safely removed

-- 1. Count products in each table
SELECT 
    'products table' as table_name,
    COUNT(*) as total_count
FROM products
UNION ALL
SELECT 
    'products_enhanced table' as table_name,
    COUNT(*) as total_count
FROM products_enhanced;

-- 2. Find products that exist ONLY in products table (not in products_enhanced)
SELECT 
    p.id,
    p.name,
    p.sku,
    p.category,
    p.base_price,
    p.created_at,
    CASE 
        WHEN pe.id IS NULL THEN 'OLD - Can be removed'
        ELSE 'Exists in both tables'
    END as status
FROM products p
LEFT JOIN products_enhanced pe ON p.id = pe.id
WHERE pe.id IS NULL  -- Only show products NOT in products_enhanced
ORDER BY p.created_at
LIMIT 50;

-- 3. Count by category for old products
SELECT 
    p.category,
    COUNT(*) as count,
    MIN(p.created_at) as oldest_product,
    MAX(p.created_at) as newest_product
FROM products p
LEFT JOIN products_enhanced pe ON p.id = pe.id
WHERE pe.id IS NULL  -- Only old products
GROUP BY p.category
ORDER BY count DESC;

-- 4. Check if old products have any related data
WITH old_products AS (
    SELECT p.id, p.name, p.sku
    FROM products p
    LEFT JOIN products_enhanced pe ON p.id = pe.id
    WHERE pe.id IS NULL
)
SELECT 
    'Old Products' as type,
    COUNT(DISTINCT op.id) as product_count,
    COUNT(DISTINCT pv.id) as variant_count,
    COUNT(DISTINCT oi.product_id) as products_with_order_items
FROM old_products op
LEFT JOIN product_variants pv ON op.id = pv.product_id
LEFT JOIN order_items oi ON op.id = oi.product_id;

-- 5. Sample of old products with their SKU patterns
SELECT 
    SUBSTRING(p.sku FROM 1 FOR 3) as sku_prefix,
    COUNT(*) as count,
    STRING_AGG(DISTINCT p.category, ', ') as categories,
    MIN(p.name) as sample_product
FROM products p
LEFT JOIN products_enhanced pe ON p.id = pe.id
WHERE pe.id IS NULL  -- Only old products
GROUP BY SUBSTRING(p.sku FROM 1 FOR 3)
ORDER BY count DESC;

-- 6. Check for core products (28 original Stripe products)
SELECT 
    p.id,
    p.name,
    p.sku,
    p.stripe_product_id,
    p.base_price,
    CASE 
        WHEN p.stripe_product_id IS NOT NULL THEN 'Core Stripe Product'
        WHEN pe.id IS NULL THEN 'Old Product - No Enhanced'
        ELSE 'Synced to Enhanced'
    END as product_type
FROM products p
LEFT JOIN products_enhanced pe ON p.id = pe.id
WHERE p.stripe_product_id IS NOT NULL
   OR pe.id IS NULL
ORDER BY product_type, p.name
LIMIT 30;