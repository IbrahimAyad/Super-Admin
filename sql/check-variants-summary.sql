-- Check complete summary of all created variants

-- 1. Total counts by category
SELECT 
    p.category,
    COUNT(DISTINCT p.id) as product_count,
    COUNT(pv.id) as total_variants,
    MIN(pv.inventory_quantity) as min_inventory,
    MAX(pv.inventory_quantity) as max_inventory,
    ROUND(AVG(pv.inventory_quantity)) as avg_inventory
FROM products p
LEFT JOIN product_variants pv ON p.id = pv.product_id
WHERE p.sku LIKE 'F25-%' OR p.sku LIKE 'ACC-%'
GROUP BY p.category
ORDER BY p.category;

-- 2. Check if all products have variants
SELECT 
    p.category,
    p.name,
    p.sku,
    COUNT(pv.id) as variant_count
FROM products p
LEFT JOIN product_variants pv ON p.id = pv.product_id
WHERE (p.sku LIKE 'F25-%' OR p.sku LIKE 'ACC-%')
GROUP BY p.category, p.name, p.sku
HAVING COUNT(pv.id) = 0
ORDER BY p.category, p.name;

-- 3. Grand total
SELECT 
    COUNT(DISTINCT p.id) as total_products,
    COUNT(pv.id) as total_variants,
    SUM(pv.inventory_quantity) as total_inventory_units
FROM products p
LEFT JOIN product_variants pv ON p.id = pv.product_id
WHERE p.sku LIKE 'F25-%' OR p.sku LIKE 'ACC-%';