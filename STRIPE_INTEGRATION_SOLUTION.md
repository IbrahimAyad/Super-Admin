# 🔴 CRITICAL: Stripe Integration Required for Checkout

## The Problem
The payment integration agent found that **ALL 300+ imported products cannot be purchased** because they lack Stripe integration. Customers can browse but **cannot checkout**.

### Current State:
```
✅ Products in Supabase: 300+
❌ Products in Stripe: 0
❌ Result: Checkout fails for all products
```

## 🚀 The Solution - 3 Steps

### Step 1: Add Stripe Fields to Database
```bash
# Run in Supabase SQL Editor:
# https://supabase.com/dashboard/project/gvcswimqaxvylgxbklbz/sql

-- Execute: sql/migrations/add-stripe-fields.sql
```

### Step 2: Configure & Run Sync Script

1. **Update the sync script with your keys:**
   ```typescript
   // In scripts/sync-products-to-stripe.ts
   const SUPABASE_SERVICE_KEY = 'YOUR_SERVICE_ROLE_KEY';
   const STRIPE_SECRET_KEY = 'sk_live_YOUR_KEY';
   ```

2. **Install dependencies:**
   ```bash
   npm install stripe @supabase/supabase-js
   ```

3. **Run the sync:**
   ```bash
   npx ts-node scripts/sync-products-to-stripe.ts
   ```

### Step 3: Verify Integration
```sql
-- Check sync status in Supabase:
SELECT 
    COUNT(*) as total_products,
    COUNT(stripe_product_id) as synced_to_stripe,
    COUNT(*) FILTER (WHERE stripe_product_id IS NULL) as needs_sync
FROM products
WHERE status = 'active';
```

## 📊 What This Will Do

The sync script will:
1. **Create 300+ products in Stripe** with proper metadata
2. **Create 3000+ price variants** (all sizes/colors)
3. **Link everything** with stripe_product_id and stripe_price_id
4. **Enable checkout** for all products

### Expected Output:
```
🚀 Starting Supabase to Stripe sync...
Found 300 active products to sync

Processing: Emerald Green Tuxedo (TUX-001)
✅ Created Stripe product: prod_TUX_001
  ✅ Created price: Size 40R - $325.00 (price_xxx)
  ✅ Created price: Size 42R - $325.00 (price_xxx)
  ... 21 variants

📊 SYNC COMPLETE:
✅ Products synced: 300/300
✅ Variants synced: 3000+
```

## ⚡ Alternative: On-Demand Creation

If you don't want to create all products in Stripe immediately (to avoid hitting limits):

```typescript
// In checkout flow, create Stripe product on-demand:
async function getOrCreateStripePrice(variantId: string) {
  const variant = await getVariantFromSupabase(variantId);
  
  if (variant.stripe_price_id) {
    return variant.stripe_price_id;
  }
  
  // Create in Stripe only when needed
  const stripeProduct = await stripe.products.create({...});
  const stripePrice = await stripe.prices.create({...});
  
  // Save for future use
  await updateVariantWithStripeIds(variantId, stripePrice.id);
  
  return stripePrice.id;
}
```

## 🎯 Impact on Checkout Flow

### Before Fix:
```javascript
// ❌ This fails because no stripe_price_id
const session = await stripe.checkout.sessions.create({
  line_items: [{
    price: variant.stripe_price_id, // NULL!
    quantity: 1
  }]
});
```

### After Fix:
```javascript
// ✅ This works with synced products
const session = await stripe.checkout.sessions.create({
  line_items: [{
    price: variant.stripe_price_id, // price_xxx
    quantity: 1
  }]
});
```

## 🚨 Important Notes

### Stripe Limits:
- **Products:** No limit
- **Prices per product:** 500 max
- **API calls:** 100 requests/second
- The sync script handles rate limiting automatically

### Pricing:
- All prices are already in **cents** (integer format)
- $325.00 = 32500 in database
- Stripe expects cents, so no conversion needed

### Categories to Sync:
- Tuxedos (31 products × 21 sizes = 651 prices)
- Men's Suits (64 products × 21 sizes = 1,344 prices)
- Blazers (40 products × 21 sizes = 840 prices)
- Vest & Tie Sets (61 products × 10 sizes = 610 prices)
- Accessories (38 products, no variants)
- Shoes (2 products × 11 sizes = 22 prices)

## ✅ Success Criteria

After running the sync:
1. All products have `stripe_product_id` values
2. All variants have `stripe_price_id` values
3. Checkout flow works end-to-end
4. Products appear in Stripe Dashboard

## 🔧 Troubleshooting

### If sync fails:
1. Check Stripe API keys are correct
2. Verify Supabase service role key
3. Check for duplicate SKUs in Stripe
4. Review rate limit errors (wait and retry)

### To reset and retry:
```sql
-- Clear Stripe IDs to retry sync
UPDATE products SET stripe_product_id = NULL, stripe_active = false;
UPDATE product_variants SET stripe_price_id = NULL, stripe_active = false;
```

## 📞 Next Steps

1. **Run the migration** to add Stripe fields
2. **Execute the sync script** to create products in Stripe
3. **Test checkout** with a real product
4. **Monitor** the Stripe Dashboard for new products

Once complete, your entire product catalog will be purchasable through Stripe checkout!