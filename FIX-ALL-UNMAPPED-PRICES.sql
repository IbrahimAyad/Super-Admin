-- FIX ALL UNMAPPED PRODUCT VARIANTS
-- Map all non-standard prices to the closest Stripe price

BEGIN;

-- Show current status
SELECT 
    'BEFORE FIX' as status,
    COUNT(*) as total_variants,
    COUNT(CASE WHEN stripe_price_id IS NOT NULL AND stripe_price_id != '' THEN 1 END) as with_stripe,
    COUNT(CASE WHEN stripe_price_id IS NULL OR stripe_price_id = '' THEN 1 END) as without_stripe
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active';

-- Map products to the closest available Stripe price
-- We'll use a CASE statement to map each price range

-- $34.99 products → $29.99
UPDATE product_variants pv
SET stripe_price_id = 'price_1RvZjwCHc12x7sCzDit4VmDS',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
    AND pv.price = 3499
    AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $65.00 products → $69.99
UPDATE product_variants pv
SET stripe_price_id = 'price_1RvZjzCHc12x7sCzDItTKV3d',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
    AND pv.price = 6500
    AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $79.98 products → $79.99
UPDATE product_variants pv
SET stripe_price_id = 'price_1RvZk0CHc12x7sCzXObY7lRI',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
    AND pv.price = 7998
    AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $84.99 products → $89.99
UPDATE product_variants pv
SET stripe_price_id = 'price_1RvZk1CHc12x7sCzwbf2rwUW',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
    AND pv.price = 8499
    AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $125.00 products → $129.99
UPDATE product_variants pv
SET stripe_price_id = 'price_1RvZk2CHc12x7sCzhD6H7TN9',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
    AND pv.price = 12500
    AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $165.00 products → $149.96 (8-tie bundle)
UPDATE product_variants pv
SET stripe_price_id = 'price_1RpvRACHc12x7sCzVYFZh6Ia',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
    AND pv.price = 16500
    AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $245.00 products → $249.99
UPDATE product_variants pv
SET stripe_price_id = 'price_1Rvb1UCHc12x7sCzxi5I4Z3M',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
    AND pv.price = 24500
    AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $259.99 products → $249.99
UPDATE product_variants pv
SET stripe_price_id = 'price_1Rvb1UCHc12x7sCzxi5I4Z3M',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
    AND pv.price = 25999
    AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $265.00, $275.00, $279.99, $285.00, $289.99, $295.00 → $299.99
UPDATE product_variants pv
SET stripe_price_id = 'price_1RpvfvCHc12x7sCzq1jYfG9o',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
    AND pv.price IN (26500, 27500, 27999, 28500, 28999, 29500)
    AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $315.00, $325.00, $335.00, $345.00 → $329.99
UPDATE product_variants pv
SET stripe_price_id = 'price_1RvZk3CHc12x7sCzVrOV6VDc',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
    AND pv.price IN (31500, 32500, 33500, 34500)
    AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $355.00, $365.00, $385.00, $395.00 and above → $349.99
UPDATE product_variants pv
SET stripe_price_id = 'price_1RvZk4CHc12x7sCzzGMs4qOT',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
    AND pv.price >= 35500
    AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- Show results after fix
SELECT 
    'AFTER FIX' as status,
    COUNT(*) as total_variants,
    COUNT(CASE WHEN stripe_price_id IS NOT NULL AND stripe_price_id != '' THEN 1 END) as with_stripe,
    COUNT(CASE WHEN stripe_price_id IS NULL OR stripe_price_id = '' THEN 1 END) as without_stripe,
    ROUND(
        COUNT(CASE WHEN stripe_price_id IS NOT NULL AND stripe_price_id != '' THEN 1 END) * 100.0 / COUNT(*),
        2
    ) as percent_with_stripe
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active';

COMMIT;

-- Verify by price point
SELECT 
    pv.price / 100.0 as price_usd,
    COUNT(*) as total_variants,
    MAX(stripe_price_id) as stripe_price_id,
    CASE 
        WHEN MAX(stripe_price_id) IS NOT NULL THEN '✅ Mapped'
        ELSE '❌ Still Missing'
    END as status
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active'
GROUP BY pv.price
ORDER BY COUNT(*) DESC
LIMIT 20;