-- SAFE Cleanup - Only Clear NEW Products, Keep Core Products
-- This will preserve your original suits, ties, bundles, etc.

-- Step 1: Identify which products to keep (your core products)
-- These are products created in July (your original products)
WITH core_products AS (
  SELECT DISTINCT pv.stripe_price_id
  FROM product_variants pv
  JOIN products p ON p.id = pv.product_id
  WHERE pv.stripe_price_id IS NOT NULL
  AND (
    -- Keep all suits (your original 14 suits)
    p.name LIKE '%Navy Suit%' OR
    p.name LIKE '%Beige Suit%' OR
    p.name LIKE '%Black Suit%' OR
    p.name LIKE '%Brown Suit%' OR
    p.name LIKE '%Burgundy Suit%' OR
    p.name LIKE '%Charcoal Grey Suit%' OR
    p.name LIKE '%Dark Brown Suit%' OR
    p.name LIKE '%Emerald Suit%' OR
    p.name LIKE '%Hunter Green Suit%' OR
    p.name LIKE '%Indigo Suit%' OR
    p.name LIKE '%Light Grey Suit%' OR
    p.name LIKE '%Midnight Blue Suit%' OR
    p.name LIKE '%Sand Suit%' OR
    p.name LIKE '%Tan Suit%'
  )
)
SELECT 'Core products to keep:', COUNT(DISTINCT stripe_price_id) 
FROM core_products;

-- Step 2: Only clear Stripe IDs from NEW imported products (blazers, tuxedos, etc)
-- This preserves your core products
UPDATE product_variants pv
SET stripe_price_id = NULL, 
    stripe_active = false
FROM products p
WHERE p.id = pv.product_id
AND pv.stripe_price_id IS NOT NULL
AND (
  -- Only clear the new imported products
  p.category IN ('Luxury Velvet Blazers', 'Tuxedos', 'Vest & Tie Sets') OR
  p.name LIKE '%Velvet%' OR
  p.name LIKE '%Blazer%' OR
  p.name LIKE '%Sparkle%' OR
  p.name LIKE '%Suspender%' OR
  p.name LIKE '%Casual%' OR
  p.name LIKE '%Prom%' OR
  p.name LIKE '%Tuxedo%'
)
-- BUT NOT the core suits
AND p.name NOT IN (
  'Navy Suit', 'Beige Suit', 'Black Suit', 'Brown Suit',
  'Burgundy Suit', 'Charcoal Grey Suit', 'Dark Brown Suit',
  'Emerald Suit', 'Hunter Green Suit', 'Indigo Suit',
  'Light Grey Suit', 'Midnight Blue Suit', 'Sand Suit', 'Tan Suit'
);

-- Step 3: Clear product IDs only for imported products
UPDATE products 
SET stripe_product_id = NULL,
    stripe_active = false
WHERE (
  category IN ('Luxury Velvet Blazers', 'Tuxedos', 'Vest & Tie Sets') OR
  name LIKE '%Velvet%' OR
  name LIKE '%Blazer%' OR
  name LIKE '%Sparkle%' OR
  name LIKE '%Suspender%' OR
  name LIKE '%Tuxedo%'
)
AND created_at > '2025-08-01'; -- Only products created in August (new imports)

-- Step 4: Check what we're keeping vs clearing
SELECT 
  CASE 
    WHEN pv.stripe_price_id IS NOT NULL THEN 'Keeping (Core Products)'
    ELSE 'Ready to Remap'
  END as status,
  p.category,
  COUNT(*) as variant_count
FROM product_variants pv
JOIN products p ON p.id = pv.product_id
WHERE p.status = 'active'
GROUP BY status, p.category
ORDER BY status, p.category;

-- Step 5: Show which products still have Stripe IDs (should be your core products)
SELECT 
  p.name,
  p.category,
  COUNT(pv.id) as variant_count,
  COUNT(pv.stripe_price_id) as mapped_count
FROM products p
JOIN product_variants pv ON pv.product_id = p.id
WHERE pv.stripe_price_id IS NOT NULL
GROUP BY p.name, p.category
ORDER BY p.category, p.name
LIMIT 20;