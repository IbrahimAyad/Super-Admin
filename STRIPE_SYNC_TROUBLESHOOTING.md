# Stripe Sync Troubleshooting Guide

## Issue: Sync Freezing/Failing on Collections

The sync is freezing because Edge Functions have limits:
- **Timeout**: 30 seconds max
- **Memory**: 150MB max
- **Payload**: 6MB max

## Quick Fix: Restart and Clear Cache

### Terminal/Browser Restart Steps:
```bash
# 1. Clear any hung processes
killall node 2>/dev/null || true

# 2. Clear npm cache
npm cache clean --force

# 3. Clear Next.js cache
rm -rf .next
rm -rf node_modules/.cache

# 4. Restart the development server
npm run dev
```

### Browser Steps:
1. **Hard Refresh**: Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows)
2. **Clear Site Data**: 
   - Open DevTools (F12)
   - Application tab → Storage → Clear site data
3. **Re-login** to admin panel

### Vercel Deployment Cache:
If using Vercel deployment:
1. Go to Vercel Dashboard
2. Settings → Functions → Clear Cache
3. Redeploy: `vercel --prod --force`

## Immediate Solutions

### 1. Use Manual Batch Sync (Recommended)
Instead of syncing entire categories, sync specific products:

```javascript
// In browser console while on Stripe Sync page
// This syncs products one at a time with delays

async function syncProductsSlowly() {
  const products = await getProductsToSync(); // Get your products
  
  for (let i = 0; i < products.length; i++) {
    console.log(`Syncing product ${i + 1} of ${products.length}`);
    await syncSingleProduct(products[i]);
    
    // Wait 2 seconds between each product to avoid rate limits
    await new Promise(resolve => setTimeout(resolve, 2000));
  }
}
```

### 2. Check Edge Function Logs
```bash
# In Supabase Dashboard
1. Go to: Functions → sync-stripe-product → Logs
2. Look for timeout or memory errors
3. Check for Stripe API rate limit errors
```

### 3. Current Sync Status Check
Run this SQL to see what's actually synced:
```sql
-- Check sync status by category
SELECT 
  category,
  COUNT(*) as total,
  COUNT(stripe_product_id) as synced,
  COUNT(*) - COUNT(stripe_product_id) as remaining
FROM products
GROUP BY category
ORDER BY remaining DESC;

-- Find products that failed to sync
SELECT id, name, category, stripe_product_id
FROM products
WHERE stripe_product_id IS NULL
ORDER BY category, name
LIMIT 20;
```

## Better Approach: Direct Database Update

Since the Edge Function is struggling, you can sync directly through Stripe Dashboard:

### Option 1: Use Stripe CLI
```bash
# Install Stripe CLI
brew install stripe/stripe-cli/stripe

# Login to Stripe
stripe login

# Create products from CSV
stripe products create \
  --name="Product Name" \
  --description="Description" \
  --default-price-data[currency]=usd \
  --default-price-data[unit_amount]=5000
```

### Option 2: Stripe Dashboard Import
1. Go to https://dashboard.stripe.com/products
2. Click "Add Product" → "Import"
3. Upload CSV with your products

### Option 3: Create Smaller Edge Function
Create a simplified sync function that handles one product at a time:

```typescript
// New Edge Function: sync-single-product
import { serve } from "https://deno.land/std@0.190.0/http/server.ts";
import Stripe from "https://esm.sh/stripe@14.21.0";

serve(async (req) => {
  const { productId } = await req.json();
  
  // Only sync ONE product
  const product = await getProduct(productId);
  const stripeProduct = await stripe.products.create({
    name: product.name,
    metadata: { supabase_id: product.id }
  });
  
  // Update database
  await updateProduct(product.id, stripeProduct.id);
  
  return new Response(JSON.stringify({ success: true }));
});
```

## Why It's Freezing

1. **Too Many Variants**: Some products have many variants, creating multiple Stripe prices
2. **Rate Limits**: Stripe limits API calls to ~100 requests per second
3. **Edge Function Timeout**: 30-second limit is hit with large batches
4. **Memory**: Complex products with images may exceed memory limits

## Recommended Fix

### Step 1: Check What's Already Synced
```sql
SELECT COUNT(*) FROM products WHERE stripe_product_id IS NOT NULL;
```

### Step 2: Sync Remaining Products in Small Batches
- Use the UI to sync 5 products at a time
- Or create a script to sync one by one
- Monitor Edge Function logs for errors

### Step 3: For Large Collections (50+ products)
Consider using Stripe's bulk import feature instead of the API.

## Prevention

For future syncs:
1. Always use Progressive Sync mode
2. Sync small batches (5-10 products max)
3. Monitor Edge Function logs
4. Add retry logic for failed products
5. Consider background jobs instead of Edge Functions for large operations

## Emergency Recovery

If sync is completely stuck:
```sql
-- Reset sync status for failed products
UPDATE products 
SET stripe_product_id = NULL 
WHERE stripe_product_id = 'failed' 
   OR stripe_product_id = '';

-- Check which categories need syncing
SELECT category, COUNT(*) 
FROM products 
WHERE stripe_product_id IS NULL 
GROUP BY category;
```

## Contact Support

If issues persist:
- Check Stripe Dashboard for any created products
- Review Edge Function logs in Supabase
- Consider manual product creation for critical items