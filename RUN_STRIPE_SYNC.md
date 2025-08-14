# 🚨 URGENT: Run Stripe Product Sync

## The Problem
Your 300+ products can't be purchased because they're not in Stripe!

## Quick Fix Instructions

### Step 1: Get Your Keys

1. **Stripe Secret Key** (starts with `sk_live_`)
   - Go to: https://dashboard.stripe.com/apikeys
   - Copy your **Secret key**

2. **Supabase Service Role Key**
   - Go to: https://supabase.com/dashboard/project/gvcswimqaxvylgxbklbz/settings/api
   - Copy the **service_role** key (NOT anon key)

### Step 2: Run This Command

```bash
# Replace YOUR_KEYS with actual values
STRIPE_SECRET_KEY="sk_live_YOUR_KEY" \
SUPABASE_SERVICE_KEY="YOUR_SERVICE_ROLE_KEY" \
node -e "
const script = require('./scripts/sync-products-to-stripe.ts');
// Update keys in script
const fs = require('fs');
let content = fs.readFileSync('./scripts/sync-products-to-stripe.ts', 'utf8');
content = content.replace('YOUR_SERVICE_ROLE_KEY', process.env.SUPABASE_SERVICE_KEY);
content = content.replace('sk_live_YOUR_KEY', process.env.STRIPE_SECRET_KEY);
fs.writeFileSync('./scripts/sync-products-to-stripe-temp.ts', content);
"
npx ts-node scripts/sync-products-to-stripe-temp.ts
```

### OR: Manual Method

1. Edit `scripts/sync-products-to-stripe.ts`
2. Replace on line 12-13:
   ```typescript
   const SUPABASE_SERVICE_KEY = 'YOUR_ACTUAL_SERVICE_ROLE_KEY';
   const STRIPE_SECRET_KEY = 'sk_live_YOUR_ACTUAL_KEY';
   ```

3. Run:
   ```bash
   npx ts-node scripts/sync-products-to-stripe.ts
   ```

## What This Will Do

- Creates 300+ products in Stripe
- Creates 3000+ price variants (all sizes)
- Links everything with stripe_product_id and stripe_price_id
- Takes about 30-45 minutes to complete

## Expected Output

```
🚀 Starting Supabase to Stripe sync...
Found 300 active products to sync

Processing: Emerald Green Tuxedo (TUX-001)
✅ Created Stripe product: prod_TUX_001
  ✅ Created price: Size 40R - $325.00
  ... (21 more sizes)

[continues for all products]

📊 SYNC COMPLETE:
✅ Products synced: 300/300
✅ Variants synced: 3000+
```

## After Sync Completes

1. Test checkout with any product
2. Verify in Stripe Dashboard: https://dashboard.stripe.com/products
3. Check database has stripe_product_id values

## ⚠️ Important Notes

- Use LIVE keys for production, TEST keys for testing
- The script handles rate limiting automatically
- If it fails partway, just run it again (it skips already synced products)
- Keep your keys secure - don't commit them to git!

## Need the Keys?

If you don't have them handy:
- **Stripe**: https://dashboard.stripe.com/apikeys
- **Supabase**: https://supabase.com/dashboard/project/gvcswimqaxvylgxbklbz/settings/api

Once you provide the keys, I can run this for you!