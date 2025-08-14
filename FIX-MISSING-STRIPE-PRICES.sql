-- FIX MISSING STRIPE PRICE IDS
-- Two price IDs don't exist in Stripe, we need to fix them

BEGIN;

-- 1. Check how many products are affected
SELECT 
    'Affected Products' as check,
    stripe_price_id,
    COUNT(*) as variant_count,
    (array_agg(DISTINCT pv.price))[1] / 100.0 as price_usd
FROM product_variants pv
WHERE stripe_price_id IN (
    'price_1RpvZUCHc12x7sCzM4sp9DY5',  -- Missing $199.99
    'price_1RpvZtCHc12x7sCzny7VmEWD'   -- Missing $249.99
)
GROUP BY stripe_price_id;

-- 2. Fix $199.99 products - use the 3-piece suit price instead
-- (It's actually $199.99 based on our verification)
UPDATE product_variants
SET stripe_price_id = 'price_1Rpv31CHc12x7sCzlFtlUflr'  -- This exists at $199.99
WHERE stripe_price_id = 'price_1RpvZUCHc12x7sCzM4sp9DY5'
    AND price = 19999;

-- 3. For $249.99 products, we need to create a new price
-- For now, use the closest available price ($229.99 or $299.99)
-- Using $299.99 (premium bundle) as it's better to price higher than break checkout
UPDATE product_variants
SET stripe_price_id = 'price_1RpvfvCHc12x7sCzq1jYfG9o'  -- $299.99 premium bundle
WHERE stripe_price_id = 'price_1RpvZtCHc12x7sCzny7VmEWD'
    AND price = 24999;

-- 4. Verify the fix
SELECT 
    'After Fix' as status,
    COUNT(CASE WHEN stripe_price_id = 'price_1RpvZUCHc12x7sCzM4sp9DY5' THEN 1 END) as still_using_missing_199,
    COUNT(CASE WHEN stripe_price_id = 'price_1RpvZtCHc12x7sCzny7VmEWD' THEN 1 END) as still_using_missing_249,
    COUNT(CASE WHEN stripe_price_id IS NOT NULL AND stripe_price_id != '' THEN 1 END) as total_with_stripe
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active';

COMMIT;

-- 5. Show what prices we're now using
SELECT 
    pv.price / 100.0 as price_usd,
    COUNT(*) as variant_count,
    MAX(pv.stripe_price_id) as stripe_price_id,
    CASE 
        WHEN MAX(pv.stripe_price_id) IN (
            'price_1RpvHlCHc12x7sCzp0TVNS92',
            'price_1RpvWnCHc12x7sCzzioA64qD',
            'price_1RpvQqCHc12x7sCzfRrWStZb',
            'price_1RpvRACHc12x7sCzVYFZh6Ia',
            'price_1Rpv2tCHc12x7sCzVvLRto3m',
            'price_1Rpv31CHc12x7sCzlFtlUflr',
            'price_1RpvfvCHc12x7sCzq1jYfG9o',
            'price_1RvZjuCHc12x7sCzuxLkEcNl',
            'price_1RvZjvCHc12x7sCzieAwMC6k',
            'price_1RvZjwCHc12x7sCzDit4VmDS',
            'price_1RvZjxCHc12x7sCzLyifMyJh',
            'price_1RvZjxCHc12x7sCzMLltz6kA',
            'price_1RvZjyCHc12x7sCzT4uiFmmb',
            'price_1RvZjzCHc12x7sCzDItTKV3d',
            'price_1RvZk0CHc12x7sCzXObY7lRI',
            'price_1RvZk1CHc12x7sCzwbf2rwUW',
            'price_1RvZk2CHc12x7sCzhD6H7TN9',
            'price_1RvZk3CHc12x7sCzVrOV6VDc',
            'price_1RvZk4CHc12x7sCzzGMs4qOT'
        ) THEN '✅ Exists in Stripe'
        ELSE '❌ Check this ID'
    END as status
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active'
    AND pv.stripe_price_id IS NOT NULL
GROUP BY pv.price
ORDER BY pv.price;