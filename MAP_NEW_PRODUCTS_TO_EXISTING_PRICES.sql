-- Map ONLY New Products to Your Existing Core Product Prices
-- This keeps your core products untouched and working

-- First, let's see your existing price IDs from core products
WITH existing_prices AS (
  SELECT DISTINCT 
    pv.price,
    pv.stripe_price_id,
    p.name as example_product
  FROM product_variants pv
  JOIN products p ON p.id = pv.product_id
  WHERE pv.stripe_price_id IS NOT NULL
  AND pv.stripe_price_id LIKE 'price_%'
  ORDER BY pv.price
)
SELECT 
  price / 100.0 as price_usd,
  stripe_price_id,
  example_product
FROM existing_prices;

-- Now map ONLY the new products (without Stripe IDs) to these existing prices

-- Map all $24.99 items (Accessories) to your existing tie price
UPDATE product_variants pv
SET stripe_price_id = (
  SELECT stripe_price_id 
  FROM product_variants 
  WHERE price = 2499 
  AND stripe_price_id IS NOT NULL 
  LIMIT 1
),
stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 2499
AND pv.stripe_price_id IS NULL;

-- Map all $49.99 items to your existing vest/bundle price
UPDATE product_variants pv
SET stripe_price_id = (
  SELECT stripe_price_id 
  FROM product_variants 
  WHERE price = 4999 
  AND stripe_price_id IS NOT NULL 
  LIMIT 1
),
stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 4999
AND pv.stripe_price_id IS NULL;

-- Map all $79.99 items to your existing shirt price
UPDATE product_variants pv
SET stripe_price_id = (
  SELECT stripe_price_id 
  FROM product_variants 
  WHERE price = 7999 
  AND stripe_price_id IS NOT NULL 
  LIMIT 1
),
stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 7999
AND pv.stripe_price_id IS NULL;

-- Map all $99.99 items to your existing bundle price
UPDATE product_variants pv
SET stripe_price_id = (
  SELECT stripe_price_id 
  FROM product_variants 
  WHERE price = 9999 
  AND stripe_price_id IS NOT NULL 
  LIMIT 1
),
stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 9999
AND pv.stripe_price_id IS NULL;

-- Map all $179.99 items to your existing 2-piece suit price
UPDATE product_variants pv
SET stripe_price_id = (
  SELECT stripe_price_id 
  FROM product_variants 
  WHERE price = 17999 
  AND stripe_price_id IS NOT NULL 
  LIMIT 1
),
stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 17999
AND pv.stripe_price_id IS NULL;

-- Map all $229.99 items to your existing 3-piece suit price
UPDATE product_variants pv
SET stripe_price_id = (
  SELECT stripe_price_id 
  FROM product_variants 
  WHERE price = 22999 
  AND stripe_price_id IS NOT NULL 
  LIMIT 1
),
stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 22999
AND pv.stripe_price_id IS NULL;

-- Map all $249.99 items to your existing premium bundle price
UPDATE product_variants pv
SET stripe_price_id = (
  SELECT stripe_price_id 
  FROM product_variants 
  WHERE price = 24999 
  AND stripe_price_id IS NOT NULL 
  LIMIT 1
),
stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 24999
AND pv.stripe_price_id IS NULL;

-- Map all $299.99 items to your existing premium bundle price
UPDATE product_variants pv
SET stripe_price_id = (
  SELECT stripe_price_id 
  FROM product_variants 
  WHERE price = 29999 
  AND stripe_price_id IS NOT NULL 
  LIMIT 1
),
stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 29999
AND pv.stripe_price_id IS NULL;

-- Check results
SELECT 
  p.category,
  pv.price / 100.0 as price_usd,
  COUNT(*) as variants,
  COUNT(pv.stripe_price_id) as mapped,
  COUNT(*) - COUNT(pv.stripe_price_id) as unmapped
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active'
GROUP BY p.category, pv.price
ORDER BY p.category, pv.price;

-- Show what prices don't have matches (need new Stripe prices)
SELECT DISTINCT
  pv.price / 100.0 as price_usd,
  p.category,
  COUNT(*) as variants_needing_price
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE pv.stripe_price_id IS NULL
AND p.status = 'active'
GROUP BY pv.price, p.category
ORDER BY pv.price;