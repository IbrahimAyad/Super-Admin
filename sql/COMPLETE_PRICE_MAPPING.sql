-- KCT Menswear Complete Price Mapping
-- Maps all products to correct Stripe prices based on category and price

-- First, check current price distribution
SELECT 
    p.category,
    pv.price / 100.0 as price_usd,
    COUNT(*) as variant_count,
    MAX(pv.stripe_price_id) as sample_stripe_id
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active'
GROUP BY p.category, pv.price
ORDER BY p.category, pv.price;

-- Map products based on YOUR defined price structure

-- ACCESSORIES & SMALL ITEMS
-- $10.00 - Socks, Pocket Squares
UPDATE product_variants pv
SET stripe_price_id = 'NEED_TO_CREATE_10',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 1000
AND pv.stripe_price_id IS NULL;

-- $15.00 - Tie Clips
UPDATE product_variants pv
SET stripe_price_id = 'NEED_TO_CREATE_15',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 1500
AND pv.stripe_price_id IS NULL;

-- $24.99 - Ties & Bow Ties (USE EXISTING)
UPDATE product_variants pv
SET stripe_price_id = 'price_1RpvHlCHc12x7sCzp0TVNS92', -- Your existing tie price
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 2499
AND pv.stripe_price_id IS NULL;

-- $29.99 - Belts
UPDATE product_variants pv
SET stripe_price_id = 'NEED_TO_CREATE_29_99',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 2999
AND pv.stripe_price_id IS NULL;

-- $39.99 - Dress Shirts, Cufflinks (USE EXISTING SHIRT PRICE)
UPDATE product_variants pv
SET stripe_price_id = 'price_1RpvWnCHc12x7sCzzioA64qD', -- Your existing shirt price
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 3999
AND pv.stripe_price_id IS NULL;

-- $44.99 - Turtlenecks
UPDATE product_variants pv
SET stripe_price_id = 'NEED_TO_CREATE_44_99',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 4499
AND pv.stripe_price_id IS NULL;

-- $49.99 - Vests, Suspenders, Collarless Shirts
UPDATE product_variants pv
SET stripe_price_id = 'NEED_TO_CREATE_49_99',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 4999
AND pv.stripe_price_id IS NULL;

-- $59.99 - Dress Pants, Stretch Shirts
UPDATE product_variants pv
SET stripe_price_id = 'NEED_TO_CREATE_59_99',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 5999
AND pv.stripe_price_id IS NULL;

-- $69.99 - Shiny Shirts, Tuxedo/Satin Pants
UPDATE product_variants pv
SET stripe_price_id = 'NEED_TO_CREATE_69_99',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 6999
AND pv.stripe_price_id IS NULL;

-- $79.99 - Loafers, Some Shoes
UPDATE product_variants pv
SET stripe_price_id = 'NEED_TO_CREATE_79_99',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 7999
AND pv.stripe_price_id IS NULL;

-- $89.99 - Other Dress Shoes
UPDATE product_variants pv
SET stripe_price_id = 'NEED_TO_CREATE_89_99',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 8999
AND pv.stripe_price_id IS NULL;

-- $99.99 - Classic Dress Shoes, Spiked Shoes (USE EXISTING BUNDLE)
UPDATE product_variants pv
SET stripe_price_id = 'price_1RpvQqCHc12x7sCzfRrWStZb', -- 5-tie bundle price
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 9999
AND pv.stripe_price_id IS NULL;

-- $129.99 - Premium Sweaters
UPDATE product_variants pv
SET stripe_price_id = 'NEED_TO_CREATE_129_99',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 12999
AND pv.stripe_price_id IS NULL;

-- $149.99 - Premium Sweaters (USE EXISTING BUNDLE)
UPDATE product_variants pv
SET stripe_price_id = 'price_1RpvRACHc12x7sCzVYFZh6Ia', -- 8-tie bundle
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 14999
AND pv.stripe_price_id IS NULL;

-- $179.99 - Suits, Tuxedos (USE EXISTING 2-PIECE)
UPDATE product_variants pv
SET stripe_price_id = 'price_1Rpv2tCHc12x7sCzVvLRto3m', -- 2-piece suit
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 17999
AND pv.stripe_price_id IS NULL;

-- $199.99 - Premium Suits, Blazers, Jackets (USE EXISTING STARTER BUNDLE)
UPDATE product_variants pv
SET stripe_price_id = 'price_1RpvZUCHc12x7sCzM4sp9DY5', -- Starter bundle
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 19999
AND pv.stripe_price_id IS NULL;

-- $229.99 - Deluxe Suits, Velvet Blazers (USE EXISTING 3-PIECE)
UPDATE product_variants pv
SET stripe_price_id = 'price_1Rpv31CHc12x7sCzlFtlUflr', -- 3-piece suit
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 22999
AND pv.stripe_price_id IS NULL;

-- $249.99 - Executive Suits, Sparkle Blazers (USE EXISTING PROFESSIONAL BUNDLE)
UPDATE product_variants pv
SET stripe_price_id = 'price_1RpvZtCHc12x7sCzny7VmEWD', -- Professional bundle
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 24999
AND pv.stripe_price_id IS NULL;

-- $299.99 - Luxury Suits (USE EXISTING PREMIUM BUNDLE)
UPDATE product_variants pv
SET stripe_price_id = 'price_1RpvfvCHc12x7sCzq1jYfG9o', -- Premium bundle
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 29999
AND pv.stripe_price_id IS NULL;

-- $329.99 - Ultra Premium Suits
UPDATE product_variants pv
SET stripe_price_id = 'NEED_TO_CREATE_329_99',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 32999
AND pv.stripe_price_id IS NULL;

-- $349.99 - Exclusive Suits
UPDATE product_variants pv
SET stripe_price_id = 'NEED_TO_CREATE_349_99',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 34999
AND pv.stripe_price_id IS NULL;

-- Final check: What still needs mapping?
SELECT 
    'Still Need Stripe Price' as status,
    pv.price / 100.0 as price_usd,
    COUNT(*) as variant_count,
    STRING_AGG(DISTINCT p.category, ', ') as categories
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE pv.stripe_price_id LIKE 'NEED_TO_CREATE%'
OR pv.stripe_price_id IS NULL
GROUP BY pv.price
ORDER BY pv.price;

-- Summary of mapping
SELECT 
    CASE 
        WHEN pv.stripe_price_id IS NULL THEN 'Not Mapped'
        WHEN pv.stripe_price_id LIKE 'NEED_TO_CREATE%' THEN 'Needs New Price'
        ELSE 'Mapped to Existing'
    END as status,
    COUNT(*) as variant_count
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active'
GROUP BY status;