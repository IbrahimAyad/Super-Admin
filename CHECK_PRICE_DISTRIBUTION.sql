-- Check Price Distribution Across All Products
-- This shows if all products really use standard prices

-- Show all unique prices and their count
SELECT 
    price / 100.0 as price_usd,
    price as price_cents,
    COUNT(*) as variant_count,
    STRING_AGG(DISTINCT p.category, ', ') as categories
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active'
GROUP BY price
ORDER BY price;

-- Check if prices match standard set
WITH standard_prices AS (
    SELECT unnest(ARRAY[2499, 4999, 7999, 9999, 12999, 17999, 19999, 22999, 24999, 29999, 32999, 34999]) as price
)
SELECT 
    CASE 
        WHEN sp.price IS NOT NULL THEN 'Standard'
        ELSE 'Non-Standard'
    END as price_type,
    pv.price / 100.0 as price_usd,
    COUNT(*) as variant_count
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
LEFT JOIN standard_prices sp ON sp.price = pv.price
WHERE p.status = 'active'
GROUP BY price_type, pv.price
ORDER BY price_type, pv.price;

-- Summary statistics
SELECT 
    COUNT(DISTINCT price) as unique_prices,
    MIN(price) / 100.0 as min_price_usd,
    MAX(price) / 100.0 as max_price_usd,
    COUNT(*) as total_variants
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active';

-- Variants that don't match standard prices (if any)
WITH standard_prices AS (
    SELECT unnest(ARRAY[2499, 4999, 7999, 9999, 12999, 17999, 19999, 22999, 24999, 29999, 32999, 34999]) as price
)
SELECT 
    pv.sku,
    pv.title,
    pv.price / 100.0 as price_usd,
    p.category
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
LEFT JOIN standard_prices sp ON sp.price = pv.price
WHERE p.status = 'active'
AND sp.price IS NULL
LIMIT 20;