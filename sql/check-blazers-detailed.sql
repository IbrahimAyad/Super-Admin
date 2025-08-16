-- Detailed check of blazer products and their variants

-- 1. Check blazer categories and SKU patterns
SELECT 
    category,
    subcategory,
    COUNT(*) as count,
    MIN(sku) as sample_sku,
    MIN(base_price) as min_price,
    MAX(base_price) as max_price
FROM products_enhanced
WHERE LOWER(name) LIKE '%blazer%'
   OR LOWER(category) LIKE '%blazer%'
GROUP BY category, subcategory
ORDER BY count DESC;

-- 2. Check if blazers are in products table and have variants
SELECT 
    pe.category,
    COUNT(DISTINCT pe.id) as blazers_in_enhanced,
    COUNT(DISTINCT p.id) as blazers_in_products,
    COUNT(DISTINCT pv.product_id) as blazers_with_variants,
    COUNT(pv.id) as total_variants
FROM products_enhanced pe
LEFT JOIN products p ON pe.id = p.id
LEFT JOIN product_variants pv ON p.id = pv.product_id
WHERE LOWER(pe.name) LIKE '%blazer%'
   OR LOWER(pe.category) LIKE '%blazer%'
GROUP BY pe.category;

-- 3. Sample of blazers without variants
SELECT 
    pe.name,
    pe.sku,
    pe.category,
    pe.base_price,
    CASE WHEN p.id IS NULL THEN 'Not in products table' 
         WHEN pv.id IS NULL THEN 'No variants'
         ELSE 'Has variants' END as status
FROM products_enhanced pe
LEFT JOIN products p ON pe.id = p.id
LEFT JOIN product_variants pv ON p.id = pv.product_id
WHERE (LOWER(pe.name) LIKE '%blazer%' OR LOWER(pe.category) LIKE '%blazer%')
AND pv.id IS NULL
LIMIT 10;

-- 4. Check SKU patterns to understand blazer types
SELECT 
    SUBSTRING(sku FROM 1 FOR 3) as sku_prefix,
    COUNT(*) as count,
    STRING_AGG(DISTINCT category, ', ') as categories
FROM products_enhanced
WHERE LOWER(name) LIKE '%blazer%' OR LOWER(category) LIKE '%blazer%'
GROUP BY SUBSTRING(sku FROM 1 FOR 3)
ORDER BY count DESC;