-- PRODUCT SUMMARY EXPORT
-- Get a summary view of all products

-- 1. Main product list with key details
SELECT 
    p.name,
    p.category,
    p.sku,
    CONCAT('$', MIN(pv.price) / 100.0, ' - $', MAX(pv.price) / 100.0) as price_range,
    COUNT(DISTINCT pv.id) as variants,
    MAX(CASE WHEN pv.stripe_price_id IS NOT NULL THEN 'Yes' ELSE 'No' END) as has_stripe,
    CASE 
        WHEN p.primary_image LIKE '%placehold%' THEN 'Placeholder'
        WHEN p.primary_image LIKE '%8ea0502%' THEN 'New Gallery'
        WHEN p.primary_image LIKE '%pub-5cd%' THEN 'Old R2'
        WHEN p.primary_image IS NOT NULL THEN 'Has Image'
        ELSE 'No Image'
    END as image_type,
    SUM(pv.inventory_count) as total_inventory
FROM products p
LEFT JOIN product_variants pv ON pv.product_id = p.id
WHERE p.status = 'active'
GROUP BY p.id, p.name, p.category, p.sku, p.primary_image
ORDER BY p.category, p.name;

-- 2. Category summary
SELECT 
    '--- CATEGORY SUMMARY ---' as divider;

SELECT 
    category,
    COUNT(DISTINCT p.id) as products,
    COUNT(pv.id) as total_variants,
    CONCAT('$', MIN(pv.price) / 100.0) as min_price,
    CONCAT('$', MAX(pv.price) / 100.0) as max_price,
    CONCAT('$', ROUND(AVG(pv.price) / 100.0, 2)) as avg_price,
    SUM(pv.inventory_count) as total_inventory
FROM products p
LEFT JOIN product_variants pv ON pv.product_id = p.id
WHERE p.status = 'active'
GROUP BY category
ORDER BY COUNT(DISTINCT p.id) DESC;

-- 3. Integration status
SELECT 
    '--- INTEGRATION STATUS ---' as divider;

SELECT 
    'Stripe Integration' as metric,
    COUNT(CASE WHEN pv.stripe_price_id IS NOT NULL AND pv.stripe_price_id != '' THEN 1 END) as ready,
    COUNT(CASE WHEN pv.stripe_price_id IS NULL OR pv.stripe_price_id = '' THEN 1 END) as missing,
    ROUND(
        COUNT(CASE WHEN pv.stripe_price_id IS NOT NULL AND pv.stripe_price_id != '' THEN 1 END) * 100.0 / COUNT(*),
        1
    ) || '%' as coverage
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active';

SELECT 
    'Image Status' as metric,
    COUNT(CASE WHEN p.primary_image NOT LIKE '%placehold%' AND p.primary_image IS NOT NULL THEN 1 END) as real_images,
    COUNT(CASE WHEN p.primary_image LIKE '%placehold%' THEN 1 END) as placeholders,
    ROUND(
        COUNT(CASE WHEN p.primary_image NOT LIKE '%placehold%' AND p.primary_image IS NOT NULL THEN 1 END) * 100.0 / COUNT(*),
        1
    ) || '%' as coverage
FROM products p
WHERE p.status = 'active';