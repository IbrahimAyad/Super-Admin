# Website Update: Enhanced Products Ready (Stripe Setup Later)

## Current Status
The enhanced products system is **FULLY OPERATIONAL** with 69+ blazers loaded. The products are displaying correctly in the admin panel.

## Important: Stripe Integration
The `stripe_product_id` and `stripe_active` fields are intentionally NULL/false because:
1. We're using a **20-tier standardized pricing system** (TIER_1 to TIER_20)
2. Stripe products will be created **per tier, not per product**
3. This reduces Stripe products from 1000+ to just 20

## What the Website Needs to Know

### 1. Products ARE Ready
```javascript
// Products are fully accessible and ready to display
const { data: products } = await supabase
  .from('products_enhanced')
  .select('*')
  .eq('status', 'active')
  .eq('category', 'Blazers');
// This returns 69+ products with images, prices, etc.
```

### 2. Checkout Flow (Temporary)
Until Stripe tiers are set up, use this approach:
```javascript
// For checkout, use the base_price field directly
const checkoutData = {
  product_name: product.name,
  product_sku: product.sku,
  amount: product.base_price, // Price in cents
  price_tier: product.price_tier, // e.g., "TIER_7"
  // Don't rely on stripe_product_id yet
};

// Option A: Create Stripe checkout session with custom price
const session = await stripe.checkout.sessions.create({
  line_items: [{
    price_data: {
      currency: 'usd',
      product_data: {
        name: product.name,
        description: product.description,
        images: [product.images.hero?.url],
        metadata: {
          sku: product.sku,
          tier: product.price_tier
        }
      },
      unit_amount: product.base_price
    },
    quantity: 1
  }],
  mode: 'payment',
  success_url: `${YOUR_DOMAIN}/success`,
  cancel_url: `${YOUR_DOMAIN}/cancel`
});
```

### 3. Price Tier Mapping
```javascript
// Standard price tiers (will become Stripe products later)
const PRICE_TIERS = {
  'TIER_1': { min: 5000, max: 7499 },    // $50-74
  'TIER_2': { min: 7500, max: 9999 },    // $75-99
  'TIER_3': { min: 10000, max: 12499 },  // $100-124
  'TIER_4': { min: 12500, max: 14999 },  // $125-149
  'TIER_5': { min: 15000, max: 19999 },  // $150-199
  'TIER_6': { min: 20000, max: 24999 },  // $200-249
  'TIER_7': { min: 25000, max: 29999 },  // $250-299
  'TIER_8': { min: 30000, max: 39999 },  // $300-399
  'TIER_9': { min: 40000, max: 49999 },  // $400-499
  'TIER_10': { min: 50000, max: 59999 }, // $500-599
  // ... up to TIER_20
};
```

### 4. Display Products NOW
Products are ready to display immediately:
```javascript
// All these fields are populated and working:
product.name           // "Men's Black Floral Pattern Prom Blazer"
product.sku            // "PB-001-BLK-FLORAL"
product.handle         // "mens-black-floral-pattern-prom-blazer"
product.base_price     // 27999 (cents)
product.price_tier     // "TIER_7"
product.images.hero.url // "https://cdn.kctmenswear.com/..."
product.status         // "active"
```

## Summary for Website Team

✅ **Products are ready** - 69+ blazers with images, prices, descriptions
✅ **Images are live** - All CDN URLs at cdn.kctmenswear.com are working
✅ **Prices are set** - Using base_price field (in cents)
❌ **Stripe IDs not set** - Will be added when we create 20 tier products in Stripe
⏸️ **Temporary checkout** - Use price_data instead of price_id for now

## Next Steps
1. **Admin team**: Will create 20 Stripe products (one per tier)
2. **Admin team**: Will map products to Stripe tier IDs
3. **Website team**: Can display products immediately
4. **Website team**: Use temporary checkout with price_data until Stripe tiers ready

## The Key Message
**Don't wait for Stripe setup - products are ready to display and sell NOW!** Just use `price_data` in checkout instead of `price_id` temporarily.