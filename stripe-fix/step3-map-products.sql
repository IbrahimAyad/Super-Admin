-- STEP 3: Map All Products to Stripe Prices
-- Run this AFTER creating prices in Step 2
-- Update the NEED_TO_CREATE placeholders with actual price IDs from Step 2

BEGIN;

-- First, check current unmapped products
SELECT 
    'Products needing Stripe prices' as status,
    p.category,
    pv.price / 100.0 as price_usd,
    COUNT(*) as variant_count
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active' 
    AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '')
GROUP BY p.category, pv.price
ORDER BY pv.price;

-- MAP ALL PRODUCTS TO STRIPE PRICES

-- $10.00 - Socks, Pocket Squares
UPDATE product_variants pv
SET stripe_price_id = 'price_1RvZjuCHc12x7sCzuxLkEcNl', -- $10.00
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 1000
AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $15.00 - Tie Clips
UPDATE product_variants pv
SET stripe_price_id = 'price_1RvZjvCHc12x7sCzieAwMC6k', -- $15.00
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 1500
AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $24.99 - Ties & Bow Ties (EXISTING)
UPDATE product_variants pv
SET stripe_price_id = 'price_1RpvHlCHc12x7sCzp0TVNS92',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 2499
AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $29.99 - Belts
UPDATE product_variants pv
SET stripe_price_id = 'price_1RvZjwCHc12x7sCzDit4VmDS', -- $29.99
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 2999
AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $39.99 - Dress Shirts, Cufflinks (EXISTING)
UPDATE product_variants pv
SET stripe_price_id = 'price_1RpvWnCHc12x7sCzzioA64qD',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 3999
AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $44.99 - Turtlenecks
UPDATE product_variants pv
SET stripe_price_id = 'price_1RvZjxCHc12x7sCzLyifMyJh', -- $44.99
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 4499
AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $49.99 - Vests, Suspenders, Collarless Shirts
UPDATE product_variants pv
SET stripe_price_id = 'price_1RvZjxCHc12x7sCzMLltz6kA', -- $49.99
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 4999
AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $59.99 - Dress Pants, Stretch Shirts
UPDATE product_variants pv
SET stripe_price_id = 'price_1RvZjyCHc12x7sCzT4uiFmmb', -- $59.99
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 5999
AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $69.99 - Shiny Shirts, Tuxedo/Satin Pants
UPDATE product_variants pv
SET stripe_price_id = 'price_1RvZjzCHc12x7sCzDItTKV3d', -- $69.99
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 6999
AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $79.99 - Loafers, Some Shoes
UPDATE product_variants pv
SET stripe_price_id = 'price_1RvZk0CHc12x7sCzXObY7lRI', -- $79.99
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 7999
AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $89.99 - Other Dress Shoes
UPDATE product_variants pv
SET stripe_price_id = 'price_1RvZk1CHc12x7sCzwbf2rwUW', -- $89.99
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 8999
AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $99.99 - Classic Dress Shoes, Spiked Shoes (EXISTING BUNDLE)
UPDATE product_variants pv
SET stripe_price_id = 'price_1RpvQqCHc12x7sCzfRrWStZb',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 9999
AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $129.99 - Premium Sweaters
UPDATE product_variants pv
SET stripe_price_id = 'price_1RvZk2CHc12x7sCzhD6H7TN9', -- $129.99
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 12999
AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $149.99 - Premium Sweaters (EXISTING BUNDLE)
UPDATE product_variants pv
SET stripe_price_id = 'price_1RpvRACHc12x7sCzVYFZh6Ia',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 14999
AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $179.99 - Suits, Tuxedos (EXISTING 2-PIECE)
UPDATE product_variants pv
SET stripe_price_id = 'price_1Rpv2tCHc12x7sCzVvLRto3m',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 17999
AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $199.99 - Premium Suits, Blazers, Jackets (EXISTING STARTER)
UPDATE product_variants pv
SET stripe_price_id = 'price_1RpvZUCHc12x7sCzM4sp9DY5',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 19999
AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $229.99 - Deluxe Suits, Velvet Blazers (EXISTING 3-PIECE)
UPDATE product_variants pv
SET stripe_price_id = 'price_1Rpv31CHc12x7sCzlFtlUflr',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 22999
AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $249.99 - Executive Suits, Sparkle Blazers (EXISTING PROFESSIONAL)
UPDATE product_variants pv
SET stripe_price_id = 'price_1RpvZtCHc12x7sCzny7VmEWD',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 24999
AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $299.99 - Luxury Suits (EXISTING PREMIUM)
UPDATE product_variants pv
SET stripe_price_id = 'price_1RpvfvCHc12x7sCzq1jYfG9o',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 29999
AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $329.99 - Ultra Premium Suits
UPDATE product_variants pv
SET stripe_price_id = 'price_1RvZk3CHc12x7sCzVrOV6VDc', -- $329.99
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 32999
AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- $349.99 - Exclusive Suits
UPDATE product_variants pv
SET stripe_price_id = 'price_1RvZk4CHc12x7sCzzGMs4qOT', -- $349.99
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 34999
AND (pv.stripe_price_id IS NULL OR pv.stripe_price_id = '');

-- Verify mapping results
SELECT 
    status,
    COUNT(*) as variant_count
FROM (
    SELECT 
        CASE 
            WHEN pv.stripe_price_id IS NULL OR pv.stripe_price_id = '' THEN 'Not Mapped'
            ELSE 'Mapped to Stripe'
        END as status
    FROM product_variants pv
    JOIN products p ON p.id = pv.product_id
    WHERE p.status = 'active'
) as mapping_status
GROUP BY status;

COMMIT;

-- Show summary
SELECT 
    'Products now ready for checkout!' as message,
    COUNT(DISTINCT p.id) as total_products,
    COUNT(pv.id) as total_variants,
    COUNT(CASE WHEN pv.stripe_price_id IS NOT NULL AND pv.stripe_price_id != '' THEN 1 END) as mapped_variants
FROM products p
JOIN product_variants pv ON pv.product_id = p.id
WHERE p.status = 'active';