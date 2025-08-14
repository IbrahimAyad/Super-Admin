-- List of Core Products to PROTECT (Never Clear These)
-- These are your original products from July 28

-- Step 1: View all protected core products
SELECT DISTINCT
  p.name,
  p.category,
  pv.price / 100.0 as price_usd,
  pv.stripe_price_id,
  p.created_at::date as created_date
FROM products p
JOIN product_variants pv ON pv.product_id = p.id
WHERE pv.stripe_price_id IS NOT NULL
AND (
  -- All Premium Business Suits
  p.name LIKE 'Premium % Business Suit' OR
  
  -- All regular suits
  p.name IN (
    'Navy Suit', 'Beige Suit', 'Black Suit', 'Brown Suit',
    'Burgundy Suit', 'Charcoal Grey Suit', 'Dark Brown Suit',
    'Emerald Suit', 'Hunter Green Suit', 'Indigo Suit',
    'Light Grey Suit', 'Midnight Blue Suit', 'Sand Suit', 'Tan Suit'
  ) OR
  
  -- All ties
  p.name LIKE '%Tie%' AND p.created_at < '2025-08-01' OR
  
  -- All bundles
  p.name LIKE '%Bundle%' AND p.created_at < '2025-08-01' OR
  
  -- All shirts
  p.name LIKE '%Dress Shirt%'
)
ORDER BY p.category, p.name;

-- Step 2: Count protected products
SELECT 
  'Protected Core Products' as status,
  COUNT(DISTINCT p.id) as product_count,
  COUNT(DISTINCT pv.id) as variant_count
FROM products p
JOIN product_variants pv ON pv.product_id = p.id
WHERE pv.stripe_price_id IS NOT NULL
AND p.created_at < '2025-08-01';

-- Step 3: ONLY clear NEW imports (August products)
-- This preserves ALL July 28 products
UPDATE product_variants pv
SET stripe_price_id = NULL, 
    stripe_active = false
FROM products p
WHERE p.id = pv.product_id
AND p.created_at >= '2025-08-01'  -- Only August imports
AND (
  p.name LIKE '%Velvet%' OR
  p.name LIKE '%Blazer%' OR
  p.name LIKE '%Sparkle%' OR
  p.name LIKE '%Suspender%' OR
  p.name LIKE '%Tuxedo%' OR
  p.name LIKE '%Casual%' OR
  p.name LIKE '%Prom%'
);

-- Step 4: Verify core products still have their Stripe IDs
SELECT 
  'Core Products Status After Cleanup' as check_type,
  p.category,
  COUNT(DISTINCT p.id) as products,
  COUNT(pv.stripe_price_id) as with_stripe_id,
  COUNT(*) - COUNT(pv.stripe_price_id) as without_stripe_id
FROM products p
JOIN product_variants pv ON pv.product_id = p.id
WHERE p.created_at < '2025-08-01'  -- July products
GROUP BY p.category
ORDER BY p.category;

-- Step 5: Show what needs mapping (should only be new imports)
SELECT 
  p.category,
  COUNT(DISTINCT p.id) as products_needing_stripe
FROM products p
JOIN product_variants pv ON pv.product_id = p.id
WHERE pv.stripe_price_id IS NULL
AND p.status = 'active'
GROUP BY p.category;