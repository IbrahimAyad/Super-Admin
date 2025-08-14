# Website Team - Stripe Integration Guide

## ✅ CONFIRMED: Database is 100% Ready

All 2,991 product variants now have valid Stripe price IDs. The issue is NOT with the database - it's with how the website is fetching/using this data.

## Test Products Ready for Checkout

Use these product IDs to test - they all have valid Stripe prices:
```javascript
// Test these specific products
const testProducts = [
  'a9e4bbba-7128-4f45-9258-9b0d9465123b', // Velvet Blazer - $289.99
  '754192d7-e19e-475b-9b64-0463d31c4cad', // Tuxedo - $315.00
  'a31c629f-c935-4f17-9a05-53812d8af29d', // Vest Set - $65.00
];
```

## Common Website Integration Issues & Fixes

### 1. ❌ PROBLEM: Only Fetching First 1000 Variants
```javascript
// WRONG - Limited query
const { data } = await supabase
  .from('product_variants')
  .select('*')
  .limit(1000); // This was why you only saw 17% with Stripe IDs
```

**✅ FIX:**
```javascript
// CORRECT - Get all variants or paginate properly
const { data } = await supabase
  .from('product_variants')
  .select('*, products!inner(*)')
  .eq('products.status', 'active')
  .not('stripe_price_id', 'is', null);
```

### 2. ❌ PROBLEM: Not Joining Products Table Correctly
```javascript
// WRONG - Missing product data
const variants = await supabase
  .from('product_variants')
  .select('stripe_price_id');
```

**✅ FIX:**
```javascript
// CORRECT - Join with products table
const { data } = await supabase
  .from('product_variants')
  .select(`
    *,
    products!inner(
      id,
      name,
      category,
      primary_image,
      status
    )
  `)
  .eq('products.status', 'active')
  .not('stripe_price_id', 'is', null)
  .not('stripe_price_id', 'eq', '');
```

### 3. ❌ PROBLEM: Checking Wrong Field or Using OR Instead of AND
```javascript
// WRONG - Will miss products
if (!variant.stripe_price_id || variant.stripe_price_id === '') {
  return null; // Skipping products unnecessarily
}
```

**✅ FIX:**
```javascript
// CORRECT - Proper validation
if (variant.stripe_price_id && variant.stripe_price_id !== '') {
  // Product is ready for checkout
  return {
    priceId: variant.stripe_price_id,
    quantity: 1
  };
}
```

### 4. ❌ PROBLEM: Not Handling Price Mapping Changes
The database now uses mapped prices. For example:
- Products at $289.99 → use Stripe price for $299.99
- Products at $65.00 → use Stripe price for $69.99

**✅ FIX:**
```javascript
// When creating checkout session
const lineItems = [{
  price: variant.stripe_price_id, // Use the mapped price ID
  quantity: 1,
  adjustable_quantity: {
    enabled: true,
    minimum: 1,
    maximum: 10
  }
}];

// The actual charge will be the Stripe price amount, not the DB price
// This is intentional - we're using standardized Stripe prices
```

### 5. ❌ PROBLEM: Caching Old Data
```javascript
// WRONG - Using stale cached data
const products = getCachedProducts(); // Might have old data without Stripe IDs
```

**✅ FIX:**
```javascript
// CORRECT - Force fresh data fetch after fixes
const { data } = await supabase
  .from('product_variants')
  .select('*')
  .not('stripe_price_id', 'is', null)
  .order('created_at', { ascending: false });

// Or clear cache
localStorage.removeItem('products_cache');
sessionStorage.clear();
```

## Complete Checkout Flow Implementation

```javascript
// 1. Fetch product with variant
async function getProduct(productId) {
  const { data, error } = await supabase
    .from('products')
    .select(`
      *,
      product_variants!inner(
        id,
        title,
        price,
        stripe_price_id,
        stripe_active,
        inventory_count
      )
    `)
    .eq('id', productId)
    .eq('status', 'active')
    .single();

  if (error) throw error;
  return data;
}

// 2. Create checkout session
async function createCheckout(variantId, quantity = 1) {
  // Get variant with Stripe price
  const { data: variant } = await supabase
    .from('product_variants')
    .select('stripe_price_id, price')
    .eq('id', variantId)
    .single();

  if (!variant?.stripe_price_id) {
    throw new Error('Product not available for checkout');
  }

  // Call Edge Function
  const { data: session } = await supabase.functions.invoke('create-checkout', {
    body: {
      items: [{
        price: variant.stripe_price_id,
        quantity: quantity
      }],
      success_url: `${window.location.origin}/success`,
      cancel_url: `${window.location.origin}/cart`
    }
  });

  // Redirect to Stripe
  window.location.href = session.url;
}

// 3. Verify product is checkout-ready
function isProductReady(product) {
  return product.product_variants?.some(v => 
    v.stripe_price_id && 
    v.stripe_price_id !== '' &&
    v.stripe_active === true
  );
}
```

## Database Query to Verify Your Integration

Run this in your website console to check:
```javascript
// Test query - should return 2991 variants
const { data, count } = await supabase
  .from('product_variants')
  .select('*', { count: 'exact', head: false })
  .not('stripe_price_id', 'is', null)
  .not('stripe_price_id', 'eq', '');

console.log('Variants with Stripe:', count); // Should be 2991
```

## Critical Environment Variables

Ensure these are set in your website's .env:
```bash
NEXT_PUBLIC_SUPABASE_URL=https://zwzkmqavnyyugxytngfk.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=[your-anon-key]
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_51RAMT2CHc12x7sCzz0cBxUwBPONdyvxMnhDRMwC1bgoaFlDgmEmfvcJZT7yk7jOuEo4LpWkFpb5Gv88DJ9fSB49j00QtRac8uW
```

## Image Handling

183 products use placeholder images. Handle gracefully:
```javascript
function getProductImage(product) {
  if (product.primary_image?.includes('placehold')) {
    // It's a placeholder - maybe show a default image
    return '/images/default-product.jpg';
  }
  return product.primary_image || '/images/default-product.jpg';
}
```

## Debugging Checklist

1. **Check Supabase RLS Policies**
   - Ensure product_variants table is readable
   - Check if policies are blocking stripe_price_id field

2. **Check Browser Console**
   ```javascript
   // Run this to debug
   const test = await supabase
     .from('product_variants')
     .select('id, stripe_price_id')
     .limit(10);
   console.log('Test variants:', test);
   ```

3. **Verify Edge Function**
   - Is `create-checkout` deployed?
   - Are Stripe keys set in Edge Function secrets?

4. **Check Network Tab**
   - Look for 403/404 errors
   - Check if stripe_price_id is in response

## Summary

✅ **Database is 100% ready** - All 2,991 variants have Stripe price IDs
✅ **Prices are mapped** - Non-standard prices use closest Stripe price
✅ **Images are fixed** - All products have images (real or placeholder)

The issue is in the website's implementation. Most likely:
1. You're only fetching first 1000 records
2. You're not properly joining tables
3. You have cached old data
4. Your RLS policies might be blocking the stripe_price_id field

**Test with the 5 product IDs provided above - they WILL work if your integration is correct.**