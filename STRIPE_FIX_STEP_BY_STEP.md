# 📋 STRIPE FIX - Complete Step-by-Step Guide

## 📁 File Locations

All files are in: `/Users/ibrahim/Desktop/Super-Admin/`

### SQL Files (Run in Supabase):
1. `PROTECTED_CORE_PRODUCTS.sql` - Verify core products are safe
2. `SAFE_STRIPE_CLEANUP.sql` - Clear only new imports
3. `MAP_NEW_PRODUCTS_TO_EXISTING_PRICES.sql` - Map to existing prices
4. `CHECK_STRIPE_STATUS.sql` - Verify everything worked

### Reference Docs:
- `FINAL_STRIPE_FIX_PLAN.md` - Complete strategy
- `STRIPE_CLEANUP_AND_FIX.md` - Detailed instructions
- `SMART_STRIPE_MAPPING.md` - Price mapping logic

## 🎯 EXACT Order to Run

### Step 1: Check Current Status (2 min)
```sql
-- Run in Supabase SQL Editor
-- File: CHECK_STRIPE_STATUS.sql
-- This shows how many products have Stripe IDs
```

### Step 2: Verify Core Products Protected (1 min)
```sql
-- Run in Supabase SQL Editor
-- File: PROTECTED_CORE_PRODUCTS.sql
-- Run ONLY the SELECT queries (not the UPDATE yet)
-- This lists your July 28 products that we'll keep
```

### Step 3: Clear ONLY New Imports (2 min)
```sql
-- Run in Supabase SQL Editor
-- File: SAFE_STRIPE_CLEANUP.sql
-- This clears Stripe IDs from August imports ONLY
-- Your core products stay untouched
```

### Step 4: Map New Products to Existing Prices (3 min)
```sql
-- Run in Supabase SQL Editor
-- File: MAP_NEW_PRODUCTS_TO_EXISTING_PRICES.sql
-- This reuses your existing Stripe price IDs
```

### Step 5: Final Verification (1 min)
```sql
-- Run in Supabase SQL Editor
-- Check everything is mapped:

SELECT 
  CASE 
    WHEN p.created_at < '2025-08-01' THEN 'Core Product'
    ELSE 'New Import'
  END as product_type,
  p.category,
  COUNT(DISTINCT p.id) as products,
  COUNT(pv.stripe_price_id) as with_stripe,
  COUNT(*) - COUNT(pv.stripe_price_id) as without_stripe
FROM products p
JOIN product_variants pv ON pv.product_id = p.id
WHERE p.status = 'active'
GROUP BY product_type, p.category
ORDER BY product_type, p.category;
```

### Step 6: Handle Missing Prices (If Any)
```sql
-- Check what prices don't have matches:
SELECT DISTINCT
  pv.price / 100.0 as price_usd,
  COUNT(*) as variants_needing_price
FROM product_variants pv
WHERE pv.stripe_price_id IS NULL
GROUP BY pv.price
ORDER BY pv.price;

-- For any missing (like $329.99, $349.99):
-- Option A: Create 2 new prices in Stripe Dashboard
-- Option B: Map to closest existing price
```

### Step 7: Clean Stripe Dashboard (Optional, 5 min)
1. Go to https://dashboard.stripe.com/products
2. Search for "Velvet"
3. Select all duplicate blazers
4. Click "..." → "Archive products"
5. Repeat for "Sparkle", "Suspender", etc.

## ✅ Expected Results

After running all steps:

**Core Products (July 28):**
- Premium Business Suits: ✅ Still working
- Ties: ✅ Still working
- Bundles: ✅ Still working
- Shirts: ✅ Still working

**New Imports (August):**
- Velvet Blazers: ✅ Mapped to suit prices
- Tuxedos: ✅ Mapped to suit prices
- Accessories: ✅ Mapped to tie prices

**Stripe Dashboard:**
- Active: ~41 core products
- Archived: 200+ duplicates

## 🚨 If Something Goes Wrong

### Restore Core Products:
```sql
-- If core products lost their Stripe IDs, restore them:
UPDATE product_variants pv
SET stripe_price_id = 'price_1Rpv2tCHc12x7sCzVvLRto3m'
FROM products p
WHERE p.id = pv.product_id
AND p.name = 'Premium Navy Business Suit'
AND pv.price = 17999;
-- Repeat for other core products
```

### Check What's Not Working:
```sql
-- Find products without Stripe IDs:
SELECT 
  p.name,
  p.category,
  p.created_at,
  COUNT(*) as variants_without_stripe
FROM products p
JOIN product_variants pv ON pv.product_id = p.id
WHERE pv.stripe_price_id IS NULL
GROUP BY p.name, p.category, p.created_at
ORDER BY p.created_at;
```

## 📊 Success Metrics

You know it worked when:
1. ✅ All July 28 products still have Stripe IDs
2. ✅ New products are mapped to existing prices
3. ✅ Checkout works for all products
4. ✅ No new Stripe products were created
5. ✅ Stripe dashboard has ~41 active products (not 200+)

## Total Time: ~10 minutes

---

**Remember**: We're NOT deleting anything, just remapping to use your existing price structure!