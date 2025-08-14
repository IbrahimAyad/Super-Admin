-- FINAL VERIFICATION - 100% STRIPE COVERAGE CHECK
-- Run this to confirm all products are ready for checkout

-- 1. Overall Coverage (Should be 100%)
SELECT 
    '🎯 FINAL COVERAGE' as check_type,
    COUNT(*) as total_variants,
    COUNT(CASE WHEN stripe_price_id IS NOT NULL AND stripe_price_id != '' THEN 1 END) as with_stripe_id,
    COUNT(CASE WHEN stripe_price_id IS NULL OR stripe_price_id = '' THEN 1 END) as without_stripe_id,
    ROUND(
        COUNT(CASE WHEN stripe_price_id IS NOT NULL AND stripe_price_id != '' THEN 1 END) * 100.0 / COUNT(*),
        2
    ) || '%' as coverage_percent
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active';

-- 2. Check if ANY variants still missing Stripe IDs
SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✅ SUCCESS: All variants have Stripe IDs!'
        ELSE '❌ WARNING: ' || COUNT(*) || ' variants still missing Stripe IDs'
    END as status
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active'
    AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- 3. Price mapping summary
SELECT 
    '💰 PRICE MAPPINGS' as summary,
    COUNT(DISTINCT pv.price) as unique_prices,
    COUNT(DISTINCT stripe_price_id) as unique_stripe_prices,
    MIN(pv.price/100.0) as min_price_usd,
    MAX(pv.price/100.0) as max_price_usd
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active';

-- 4. Top 10 most used Stripe prices
SELECT 
    stripe_price_id,
    COUNT(*) as variant_count,
    MIN(pv.price/100.0) || ' - ' || MAX(pv.price/100.0) as price_range_usd,
    STRING_AGG(DISTINCT p.category, ', ' ORDER BY p.category) as categories
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active'
    AND stripe_price_id IS NOT NULL
GROUP BY stripe_price_id
ORDER BY COUNT(*) DESC
LIMIT 10;

-- 5. Products ready for checkout (should be 274)
SELECT 
    '🛒 CHECKOUT READY' as status,
    COUNT(DISTINCT p.id) as total_products,
    COUNT(DISTINCT CASE WHEN pv.stripe_price_id IS NOT NULL THEN p.id END) as products_with_stripe,
    COUNT(DISTINCT CASE WHEN p.primary_image IS NOT NULL THEN p.id END) as products_with_images,
    COUNT(DISTINCT CASE 
        WHEN pv.stripe_price_id IS NOT NULL 
        AND p.primary_image IS NOT NULL 
        THEN p.id 
    END) as fully_ready_products
FROM products p
JOIN product_variants pv ON pv.product_id = p.id
WHERE p.status = 'active';

-- 6. Sample 5 random products to test checkout
SELECT 
    '🧪 TEST THESE PRODUCTS' as test_group,
    p.id,
    p.name,
    p.category,
    pv.price/100.0 as price_usd,
    pv.stripe_price_id,
    CASE 
        WHEN p.primary_image LIKE '%placehold%' THEN '📷 Placeholder'
        ELSE '✅ Real Image'
    END as image_status
FROM products p
JOIN product_variants pv ON pv.product_id = p.id
WHERE p.status = 'active'
    AND pv.stripe_price_id IS NOT NULL
ORDER BY RANDOM()
LIMIT 5;