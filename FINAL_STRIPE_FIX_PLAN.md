# Final Stripe Fix Plan - Protecting Core Products

## 🛡️ Protected Core Products (Will NOT Touch)
All products created on **July 28** including:
- ✅ Premium Tan Business Suit
- ✅ Premium Sand Business Suit  
- ✅ Premium Midnight Blue Business Suit
- ✅ Premium Light Grey Business Suit
- ✅ Premium Indigo Business Suit
- ✅ Premium Hunter Green Business Suit
- ✅ Premium Emerald Business Suit
- ✅ Premium Dark Brown Business Suit
- ✅ Premium Charcoal Grey Business Suit
- ✅ Premium Burgundy Business Suit
- ✅ Premium Brown Business Suit
- ✅ Premium Black Business Suit
- ✅ Premium Beige Business Suit
- ✅ Premium Navy Business Suit
- ✅ All Tie Products
- ✅ All Bundle Products
- ✅ All Dress Shirts

## 🧹 What We'll Clean (August Imports Only)
- ❌ Velvet Blazers (209 duplicates)
- ❌ Sparkle products
- ❌ Suspenders
- ❌ Tuxedos
- ❌ Casual products
- ❌ Prom products

## The Safe 3-Step Process

### Step 1: Verify Core Products Are Safe
```sql
-- Run this first to see your protected products
SELECT 
  p.name,
  p.created_at::date as created,
  COUNT(pv.stripe_price_id) as has_stripe
FROM products p
JOIN product_variants pv ON pv.product_id = p.id
WHERE p.created_at < '2025-08-01'
GROUP BY p.name, p.created_at
ORDER BY p.name;
```

### Step 2: Clear ONLY August Imports
```sql
-- This only affects products created in August
UPDATE product_variants pv
SET stripe_price_id = NULL, stripe_active = false
FROM products p
WHERE p.id = pv.product_id
AND p.created_at >= '2025-08-01';  -- ONLY August products
```

### Step 3: Map New Products to Core Prices
```sql
-- Example: Map all new $179.99 products to your existing suit price
UPDATE product_variants pv
SET stripe_price_id = (
  SELECT stripe_price_id 
  FROM product_variants pv2
  JOIN products p2 ON p2.id = pv2.product_id
  WHERE p2.name = 'Premium Navy Business Suit'
  AND pv2.price = 17999
  LIMIT 1
)
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 17999
AND pv.stripe_price_id IS NULL;
```

## What Happens in Stripe Dashboard

### Your Core Products (Keep Active):
- Premium Business Suits (14 products × 2 prices = 28 items)
- Ties (4 products)
- Bundles (7 products)
- Shirts (2 products)
**Total: ~41 core products stay active**

### Duplicate Imports (Archive):
- Men's Velvet Blazers (209 duplicates)
- Other duplicates
**Archive these in Stripe Dashboard**

## Price Mapping Strategy

Your existing prices from core products:
- $24.99 → Ties (use for all accessories)
- $39.99 → Shirts  
- $99.97 → 5-Tie Bundle
- $149.96 → 8-Tie Bundle
- $179.99 → 2-piece suits (use for blazers too)
- $199.00 → Starter Bundle
- $199.95 → 11-Tie Bundle
- $229.99 → Professional Bundle
- $249.99 → Executive Bundle
- $299.99 → Premium Bundle

New products will use these SAME price IDs!

## Final Check
After running the cleanup:
```sql
-- Should show all core products still have Stripe IDs
SELECT 
  CASE 
    WHEN p.created_at < '2025-08-01' THEN 'Core Product (Protected)'
    ELSE 'New Import (Remapped)'
  END as product_type,
  COUNT(DISTINCT p.id) as products,
  COUNT(pv.stripe_price_id) as with_stripe
FROM products p
JOIN product_variants pv ON pv.product_id = p.id
GROUP BY product_type;
```

## Timeline
1. Run verification query: 1 minute
2. Clear August imports: 1 minute  
3. Map to existing prices: 3 minutes
4. Archive duplicates in Stripe: 5 minutes

**Total: 10 minutes**

Your core products remain 100% functional throughout!