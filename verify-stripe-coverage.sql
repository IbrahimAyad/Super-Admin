-- VERIFY STRIPE INTEGRATION COVERAGE
-- Check the actual state of Stripe integration

-- 1. Total counts without any limits
SELECT 
    'Total Coverage' as check_type,
    COUNT(*) as total_variants,
    COUNT(stripe_price_id) as has_stripe_price_id,
    COUNT(CASE WHEN stripe_price_id IS NOT NULL AND stripe_price_id != '' THEN 1 END) as valid_stripe_id,
    ROUND(
        COUNT(CASE WHEN stripe_price_id IS NOT NULL AND stripe_price_id != '' THEN 1 END) * 100.0 / COUNT(*),
        2
    ) as percent_with_stripe
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active';

-- 2. Check first 1000 variants (what the test saw)
SELECT 
    'First 1000 Variants' as check_type,
    COUNT(*) as total,
    COUNT(CASE WHEN stripe_price_id IS NOT NULL AND stripe_price_id != '' THEN 1 END) as with_stripe,
    ROUND(
        COUNT(CASE WHEN stripe_price_id IS NOT NULL AND stripe_price_id != '' THEN 1 END) * 100.0 / COUNT(*),
        2
    ) as percent
FROM (
    SELECT stripe_price_id
    FROM product_variants pv
    JOIN products p ON p.id = pv.product_id
    WHERE p.status = 'active'
    ORDER BY pv.created_at ASC
    LIMIT 1000
) as first_1000;

-- 3. Check by creation date
SELECT 
    DATE(pv.created_at) as created_date,
    COUNT(*) as variant_count,
    COUNT(CASE WHEN stripe_price_id IS NOT NULL AND stripe_price_id != '' THEN 1 END) as with_stripe,
    ROUND(
        COUNT(CASE WHEN stripe_price_id IS NOT NULL AND stripe_price_id != '' THEN 1 END) * 100.0 / COUNT(*),
        2
    ) as percent_with_stripe
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active'
GROUP BY DATE(pv.created_at)
ORDER BY created_date DESC;

-- 4. Check if there are variants without Stripe IDs
SELECT 
    p.name,
    p.category,
    pv.title,
    pv.price / 100.0 as price_usd,
    pv.stripe_price_id,
    pv.created_at
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active'
    AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '')
LIMIT 20;

-- 5. Summary by price point
SELECT 
    pv.price / 100.0 as price_usd,
    COUNT(*) as total_variants,
    COUNT(CASE WHEN stripe_price_id IS NOT NULL AND stripe_price_id != '' THEN 1 END) as with_stripe,
    COUNT(CASE WHEN stripe_price_id IS NULL OR stripe_price_id = '' THEN 1 END) as without_stripe,
    MAX(stripe_price_id) as sample_stripe_id
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active'
GROUP BY pv.price
ORDER BY COUNT(*) DESC;