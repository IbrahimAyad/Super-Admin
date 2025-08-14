-- FINAL FIX FOR STRIPE PRICE IDS
-- This replaces the 2 non-existent price IDs with correct ones

BEGIN;

-- 1. Show what we're fixing
SELECT 
    'Before Fix' as status,
    stripe_price_id,
    COUNT(*) as variants_affected
FROM product_variants
WHERE stripe_price_id IN (
    'price_1RpvZUCHc12x7sCzM4sp9DY5',  -- Doesn't exist (was for $199.99)
    'price_1RpvZtCHc12x7sCzny7VmEWD'   -- Doesn't exist (was for $249.99)
)
GROUP BY stripe_price_id;

-- 2. Fix $199.99 products
-- Use the 3-piece suit price which is actually $199.99 (verified)
UPDATE product_variants
SET stripe_price_id = 'price_1Rpv31CHc12x7sCzlFtlUflr'
WHERE stripe_price_id = 'price_1RpvZUCHc12x7sCzM4sp9DY5';

-- 3. Fix $249.99 products  
-- Use the new price we just created
UPDATE product_variants
SET stripe_price_id = 'price_1Rvb1UCHc12x7sCzxi5I4Z3M'
WHERE stripe_price_id = 'price_1RpvZtCHc12x7sCzny7VmEWD';

-- 4. Also update any $249.99 products that might not have a price ID
UPDATE product_variants
SET stripe_price_id = 'price_1Rvb1UCHc12x7sCzxi5I4Z3M',
    stripe_active = true
WHERE price = 24999 
    AND (stripe_price_id IS NULL OR stripe_price_id = '' OR stripe_price_id IN (
        'price_1RpvZtCHc12x7sCzny7VmEWD'
    ));

-- 5. Verify the fix
SELECT 
    'After Fix' as status,
    COUNT(CASE WHEN stripe_price_id = 'price_1RpvZUCHc12x7sCzM4sp9DY5' THEN 1 END) as using_bad_199_id,
    COUNT(CASE WHEN stripe_price_id = 'price_1RpvZtCHc12x7sCzny7VmEWD' THEN 1 END) as using_bad_249_id,
    COUNT(CASE WHEN stripe_price_id IS NULL OR stripe_price_id = '' THEN 1 END) as no_stripe_id,
    COUNT(*) as total_variants
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active';

COMMIT;

-- 6. Final check - all price IDs should now exist in Stripe
SELECT 
    DISTINCT stripe_price_id,
    COUNT(*) as variant_count,
    MIN(price/100.0) as min_price,
    MAX(price/100.0) as max_price
FROM product_variants
WHERE stripe_price_id IS NOT NULL 
    AND stripe_price_id != ''
GROUP BY stripe_price_id
ORDER BY MIN(price);

-- These are all the VALID Stripe price IDs we're using:
-- price_1RvZjuCHc12x7sCzuxLkEcNl - $10.00
-- price_1RvZjvCHc12x7sCzieAwMC6k - $15.00  
-- price_1RpvHlCHc12x7sCzp0TVNS92 - $24.99
-- price_1RvZjwCHc12x7sCzDit4VmDS - $29.99
-- price_1RpvWnCHc12x7sCzzioA64qD - $39.99
-- price_1RvZjxCHc12x7sCzLyifMyJh - $44.99
-- price_1RvZjxCHc12x7sCzMLltz6kA - $49.99
-- price_1RvZjyCHc12x7sCzT4uiFmmb - $59.99
-- price_1RvZjzCHc12x7sCzDItTKV3d - $69.99
-- price_1RvZk0CHc12x7sCzXObY7lRI - $79.99
-- price_1RvZk1CHc12x7sCzwbf2rwUW - $89.99
-- price_1RpvQqCHc12x7sCzfRrWStZb - $99.97
-- price_1RvZk2CHc12x7sCzhD6H7TN9 - $129.99
-- price_1RpvRACHc12x7sCzVYFZh6Ia - $149.96
-- price_1Rpv2tCHc12x7sCzVvLRto3m - $179.99
-- price_1Rpv31CHc12x7sCzlFtlUflr - $199.99
-- price_1Rvb1UCHc12x7sCzxi5I4Z3M - $249.99 (NEW)
-- price_1RpvfvCHc12x7sCzq1jYfG9o - $299.99
-- price_1RvZk3CHc12x7sCzVrOV6VDc - $329.99
-- price_1RvZk4CHc12x7sCzzGMs4qOT - $349.99