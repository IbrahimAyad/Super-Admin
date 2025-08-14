# 🧹 Stripe Cleanup & Smart Fix Guide

## Current Problem
You have **209+ duplicate products** in Stripe from the initial sync attempt. Each velvet blazer was created multiple times!

## The Smart Solution

### Step 1: Clean Database First (2 min)
```sql
-- Reset all Stripe IDs in Supabase
UPDATE product_variants 
SET stripe_price_id = NULL, 
    stripe_active = false
WHERE stripe_price_id IS NOT NULL;

UPDATE products 
SET stripe_product_id = NULL,
    stripe_active = false
WHERE stripe_product_id IS NOT NULL;

-- Check it worked
SELECT COUNT(*) as cleared_variants
FROM product_variants 
WHERE stripe_price_id IS NULL;
```

### Step 2: Clean Up Stripe (Optional - 10 min)
**Option A: Archive via Dashboard**
1. Go to https://dashboard.stripe.com/products
2. Select all the duplicate products
3. Click "Archive" (safer than delete)

**Option B: Use Script**
```bash
# Edit scripts/cleanup-stripe-products.ts with your key
npx ts-node scripts/cleanup-stripe-products.ts
```

### Step 3: Map to Your EXISTING Prices (5 min)

Since you already have these prices from your core products, just reuse them:

```sql
-- Map all products to your existing Stripe prices

-- $24.99 items (Accessories, Ties) → Use your tie price
UPDATE product_variants pv
SET stripe_price_id = 'price_1RpvHlCHc12x7sCzp0TVNS92',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 2499
AND pv.stripe_price_id IS NULL;

-- $49.99 items (Vests, Suspenders) → Use 5-tie bundle or create one
UPDATE product_variants pv
SET stripe_price_id = 'price_1RpvQqCHc12x7sCzfRrWStZb',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 4999
AND pv.stripe_price_id IS NULL;

-- $79.99 items → Use shirt price
UPDATE product_variants pv
SET stripe_price_id = 'price_1RpvWnCHc12x7sCzzioA64qD',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 7999
AND pv.stripe_price_id IS NULL;

-- $99.99 items → Use 5-tie bundle price
UPDATE product_variants pv
SET stripe_price_id = 'price_1RpvQqCHc12x7sCzfRrWStZb',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 9999
AND pv.stripe_price_id IS NULL;

-- $129.99 items → Use 8-tie bundle price
UPDATE product_variants pv
SET stripe_price_id = 'price_1RpvRACHc12x7sCzVYFZh6Ia',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 12999
AND pv.stripe_price_id IS NULL;

-- $179.99 items → Use 2-piece suit price
UPDATE product_variants pv
SET stripe_price_id = 'price_1Rpv2tCHc12x7sCzVvLRto3m',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 17999
AND pv.stripe_price_id IS NULL;

-- $199.99 items → Use any 2-piece suit variant
UPDATE product_variants pv
SET stripe_price_id = 'price_1Rpv3FCHc12x7sCzg9nHaXkM', -- Beige 2-piece
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 19999
AND pv.stripe_price_id IS NULL;

-- $229.99 items → Use 3-piece suit price
UPDATE product_variants pv
SET stripe_price_id = 'price_1Rpv31CHc12x7sCzlFtlUflr',
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 22999
AND pv.stripe_price_id IS NULL;

-- $249.99 items → Use any 3-piece suit variant
UPDATE product_variants pv
SET stripe_price_id = 'price_1Rpv3QCHc12x7sCzMVTfaqEE', -- Beige 3-piece
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 24999
AND pv.stripe_price_id IS NULL;

-- $299.99 items → Use premium bundle
UPDATE product_variants pv
SET stripe_price_id = 'price_1RpvaBCHc12x7sCzRV6Hy0Im', -- Executive bundle
    stripe_active = true
FROM products p
WHERE p.id = pv.product_id
AND pv.price = 29999
AND pv.stripe_price_id IS NULL;

-- Check what's mapped
SELECT 
    pv.price / 100.0 as price_usd,
    COUNT(*) as variants_mapped
FROM product_variants pv
WHERE pv.stripe_price_id IS NOT NULL
GROUP BY pv.price
ORDER BY pv.price;
```

### Step 4: Handle Remaining Prices

For prices that don't have an exact match ($329.99, $349.99), you have 3 options:

**Option A: Create just those 2 prices**
```javascript
// In Stripe Dashboard or API
stripe.prices.create({
  product: 'prod_QqwGwxRIvwnebD', // Use one of your existing products
  unit_amount: 32999, // $329.99
  currency: 'usd',
  nickname: 'Premium Price - $329.99'
});
```

**Option B: Map to closest existing price**
```sql
-- Map $329.99 → $299.99
UPDATE product_variants 
SET stripe_price_id = 'price_1RpvaBCHc12x7sCzRV6Hy0Im',
    stripe_active = true
WHERE price = 32999;
```

**Option C: Adjust product prices to standard tiers**
```sql
-- Change $329.99 → $299.99
UPDATE product_variants 
SET price = 29999
WHERE price = 32999;
```

## Why This Works

1. **Stripe doesn't care** what product name the price is attached to
2. When someone buys a "Velvet Navy Blazer" for $249.99:
   - You send Stripe the $249.99 price ID
   - Your database stores "Velvet Navy Blazer Size 42R"
   - Stripe just processes $249.99
   - Customer receipt shows your product name from checkout metadata

## Final Verification

```sql
-- Check coverage
SELECT 
    CASE 
        WHEN stripe_price_id IS NOT NULL THEN 'Mapped'
        ELSE 'Needs Mapping'
    END as status,
    COUNT(*) as variant_count,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() as percentage
FROM product_variants
GROUP BY status;

-- See unmapped prices
SELECT DISTINCT 
    price / 100.0 as price_usd,
    COUNT(*) as variants
FROM product_variants
WHERE stripe_price_id IS NULL
GROUP BY price
ORDER BY price;
```

## Time Estimate

1. Clear database: 2 minutes
2. Clean Stripe (optional): 10 minutes
3. Run mapping SQL: 3 minutes
4. Create 2-3 missing prices: 5 minutes

**Total: 20 minutes vs 45+ minutes**

## The Result

- ✅ All products purchasable
- ✅ Clean Stripe dashboard (no duplicates)
- ✅ Reusing existing infrastructure
- ✅ Easy to manage going forward

This is EXACTLY how enterprise e-commerce works - price tiers, not individual prices!