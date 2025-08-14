-- STEP 4: Verify Stripe Integration
-- Run this AFTER mapping products in Step 3

-- 1. Check overall mapping status
SELECT 
    '=== STRIPE INTEGRATION STATUS ===' as title;

SELECT 
    status,
    COUNT(*) as variant_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM (
    SELECT 
        CASE 
            WHEN pv.stripe_price_id IS NULL OR pv.stripe_price_id = '' THEN '❌ Not Mapped'
            WHEN pv.stripe_price_id LIKE 'REPLACE%' THEN '⚠️ Needs Update'
            ELSE '✅ Mapped to Stripe'
        END as status
    FROM product_variants pv
    JOIN products p ON p.id = pv.product_id
    WHERE p.status = 'active'
) as status_check
GROUP BY status
ORDER BY status;

-- 2. Check by category
SELECT 
    '=== STATUS BY CATEGORY ===' as title;

SELECT 
    p.category,
    COUNT(DISTINCT p.id) as products,
    COUNT(pv.id) as variants,
    COUNT(CASE WHEN pv.stripe_price_id IS NOT NULL AND pv.stripe_price_id != '' 
               AND pv.stripe_price_id NOT LIKE 'REPLACE%' THEN 1 END) as mapped_variants,
    ROUND(COUNT(CASE WHEN pv.stripe_price_id IS NOT NULL AND pv.stripe_price_id != '' 
               AND pv.stripe_price_id NOT LIKE 'REPLACE%' THEN 1 END) * 100.0 / COUNT(pv.id), 2) as mapped_percent
FROM products p
JOIN product_variants pv ON pv.product_id = p.id
WHERE p.status = 'active'
GROUP BY p.category
ORDER BY mapped_percent DESC, p.category;

-- 3. Check price distribution
SELECT 
    '=== PRICE DISTRIBUTION ===' as title;

SELECT 
    pv.price / 100.0 as price_usd,
    COUNT(*) as variant_count,
    MAX(pv.stripe_price_id) as sample_stripe_id,
    CASE 
        WHEN MAX(pv.stripe_price_id) IS NULL OR MAX(pv.stripe_price_id) = '' THEN '❌ Missing'
        WHEN MAX(pv.stripe_price_id) LIKE 'REPLACE%' THEN '⚠️ Needs Update'
        ELSE '✅ Mapped'
    END as status
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active'
GROUP BY pv.price
ORDER BY pv.price;

-- 4. Products still needing attention
SELECT 
    '=== PRODUCTS NEEDING ATTENTION ===' as title;

SELECT 
    p.name,
    p.category,
    pv.price / 100.0 as price_usd,
    pv.stripe_price_id,
    CASE 
        WHEN pv.stripe_price_id IS NULL OR pv.stripe_price_id = '' THEN 'No Stripe ID'
        WHEN pv.stripe_price_id LIKE 'REPLACE%' THEN 'Needs real price ID from Step 2'
        ELSE 'Unknown issue'
    END as issue
FROM products p
JOIN product_variants pv ON pv.product_id = p.id
WHERE p.status = 'active'
    AND (pv.stripe_price_id IS NULL 
         OR pv.stripe_price_id = ''
         OR pv.stripe_price_id LIKE 'REPLACE%')
LIMIT 20;

-- 5. Final summary
SELECT 
    '=== FINAL SUMMARY ===' as title;

WITH stats AS (
    SELECT 
        COUNT(DISTINCT p.id) as total_products,
        COUNT(pv.id) as total_variants,
        COUNT(CASE WHEN pv.stripe_price_id IS NOT NULL 
                   AND pv.stripe_price_id != '' 
                   AND pv.stripe_price_id NOT LIKE 'REPLACE%' THEN 1 END) as mapped_variants,
        COUNT(CASE WHEN pv.stripe_price_id IS NULL 
                   OR pv.stripe_price_id = '' THEN 1 END) as unmapped_variants,
        COUNT(CASE WHEN pv.stripe_price_id LIKE 'REPLACE%' THEN 1 END) as needs_update_variants
    FROM products p
    JOIN product_variants pv ON pv.product_id = p.id
    WHERE p.status = 'active'
)
SELECT 
    total_products as "Total Products",
    total_variants as "Total Variants",
    mapped_variants as "✅ Ready for Checkout",
    unmapped_variants as "❌ Not Mapped",
    needs_update_variants as "⚠️ Needs Price IDs",
    ROUND(mapped_variants * 100.0 / total_variants, 2) as "% Ready"
FROM stats;

-- 6. Test a few products to ensure they're ready
SELECT 
    '=== SAMPLE PRODUCTS READY FOR CHECKOUT ===' as title;

SELECT 
    p.name,
    p.category,
    pv.title as variant,
    pv.price / 100.0 as price_usd,
    pv.stripe_price_id,
    pv.stripe_active
FROM products p
JOIN product_variants pv ON pv.product_id = p.id
WHERE p.status = 'active'
    AND pv.stripe_price_id IS NOT NULL
    AND pv.stripe_price_id != ''
    AND pv.stripe_price_id NOT LIKE 'REPLACE%'
    AND pv.stripe_active = true
ORDER BY RANDOM()
LIMIT 10;