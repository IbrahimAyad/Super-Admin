# Complete Stripe Product Synchronization Guide

## 🚀 Overview

This system safely synchronizes your 182 products from Supabase to Stripe for payment processing. The implementation includes advanced features like progressive sync, dry-run mode, retry logic, comprehensive logging, and rollback capabilities.

## ✅ What's Already Complete

### 1. Database Schema
- ✅ Stripe fields added to products table (`stripe_product_id`, `stripe_sync_status`, `stripe_synced_at`)
- ✅ Stripe fields added to variants table (`stripe_price_id`)
- ✅ Comprehensive audit logging table (`stripe_sync_log`)
- ✅ Monitoring views (`stripe_sync_summary`, `products_pending_stripe_sync`)

### 2. Edge Functions
- ✅ `sync-stripe-product` - Handles individual product sync
- ✅ `sync-stripe-products` - Handles bulk sync operations
- ✅ Error handling and logging
- ✅ Rate limiting and retries

### 3. Sync Service (`stripeSync.ts`)
- ✅ Batch processing (5 products per batch)
- ✅ Dry-run mode with validation
- ✅ Progressive sync strategy
- ✅ Retry logic with exponential backoff
- ✅ Comprehensive error handling
- ✅ Rollback capabilities
- ✅ Progress tracking

### 4. UI Components
- ✅ `StripeSyncManager` component
- ✅ Added to admin navigation (`/admin/stripe-sync`)
- ✅ Progress tracking and phase display
- ✅ Safety controls and monitoring

## 🛠️ Setup Instructions

### Step 1: Configure Stripe API Keys

1. **Get your Stripe keys**:
   - Go to [Stripe Dashboard](https://dashboard.stripe.com/apikeys)
   - Copy your Publishable key (starts with `pk_test_` or `pk_live_`)
   - Copy your Secret key (starts with `sk_test_` or `sk_live_`)

2. **Set the publishable key** (already configured):
   ```bash
   # In .env file:
   VITE_STRIPE_PUBLISHABLE_KEY=pk_test_51QI05fGVWJ6gPEPRJl3E0qJYFCEVH5UNTxnJRgO7KGKkbp8L2a5jgJc2ZAqV6Jp4eVkrWHRJrZoShzwHdOKwQyYm00jGDsGRxm
   ```

3. **Set the secret key in Supabase**:
   ```bash
   # Using Supabase CLI:
   supabase secrets set STRIPE_SECRET_KEY=sk_test_your-actual-secret-key-here
   
   # Or via Supabase Dashboard:
   # Go to Project Settings > Edge Functions > Secrets
   # Add: STRIPE_SECRET_KEY = sk_test_your-actual-secret-key-here
   ```

### Step 2: Deploy Edge Functions (if needed)

```bash
# Deploy the sync functions
supabase functions deploy sync-stripe-product
supabase functions deploy sync-stripe-products
```

### Step 3: Verify Database Migration

The migration should already be applied, but you can verify:

```sql
-- Check if Stripe columns exist
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'products' 
AND column_name LIKE 'stripe_%';

-- Check sync log table
SELECT COUNT(*) FROM stripe_sync_log;
```

## 🎯 How to Use the Sync System

### Access the Sync Manager
1. Go to your admin dashboard
2. Navigate to **System > Stripe Sync** in the sidebar
3. The URL will be: `/admin/stripe-sync`

### Recommended Sync Process

#### Phase 1: Validation (Dry Run)
1. **Enable Dry Run Mode** ✅
2. **Enable Progressive Sync** ✅ (recommended for first sync)
3. Click **"Start Progressive Dry Run"**
4. Review the results in the UI and console logs

#### Phase 2: Test with Smallest Category
1. **Keep Dry Run Mode ON**
2. **Disable Progressive Sync**
3. **Select only "Sparkle Vest Sets"** (4 products)
4. Click **"Start Dry Run"**
5. Verify no errors

#### Phase 3: Real Sync - Smallest Category
1. **Disable Dry Run Mode** ⚠️
2. **Keep "Sparkle Vest Sets" selected**
3. Click **"Start Sync"**
4. Verify products appear in Stripe Dashboard

#### Phase 4: Progressive Sync All Categories
1. **Disable Dry Run Mode** ⚠️
2. **Enable Progressive Sync** ✅
3. **Deselect all categories** (progressive mode will handle all)
4. Click **"Start Progressive Sync"**
5. Monitor progress through all 9 phases

## 📊 Monitoring and Progress

### Real-time Monitoring
- **Overall Progress**: Shows total products synced vs pending
- **Category Progress**: Shows sync status per category
- **Phase Progress**: Shows individual phase results during progressive sync
- **Error Tracking**: Real-time error display and logging

### Database Monitoring
```sql
-- Overall sync status
SELECT * FROM stripe_sync_summary;

-- Detailed progress by category
SELECT 
  category,
  COUNT(*) as total,
  COUNT(stripe_product_id) as synced,
  COUNT(*) - COUNT(stripe_product_id) as pending
FROM products 
GROUP BY category 
ORDER BY total DESC;

-- Recent sync operations
SELECT * FROM stripe_sync_log 
ORDER BY created_at DESC 
LIMIT 20;

-- Products with sync errors
SELECT p.name, p.category, p.stripe_sync_error
FROM products p 
WHERE stripe_sync_status = 'failed';
```

## 🚨 Safety Features

### 1. Non-Destructive
- Only adds Stripe IDs to existing records
- Never modifies existing product data
- Completely reversible

### 2. Dry Run Mode
- Test all operations without making changes
- Validates product data before sync
- Identifies potential issues early

### 3. Progressive Sync
- Syncs categories from smallest to largest
- Allows for early issue detection
- Reduces risk of large-scale failures

### 4. Retry Logic
- Automatic retries with exponential backoff
- Handles temporary network issues
- Skips permanent errors (invalid data)

### 5. Rollback Capabilities
```javascript
// Rollback specific products
await stripeSyncService.rollbackSync(['product-id-1', 'product-id-2']);

// Or use the emergency rollback in the UI
```

### 6. Rate Limiting
- Processes 5 products per batch
- 2-second delays between batches
- 5-second delays between progressive phases

## ⚡ Expected Performance

### Sync Times (Approximate)
- **Sparkle Vest Sets** (4 products): ~30 seconds
- **Casual Summer Blazers** (7 products): ~45 seconds
- **Full Progressive Sync** (182 products): ~15-20 minutes

### Stripe Rate Limits
- Stripe allows 100 requests/second
- Our system uses 5 products/batch = well within limits
- Edge Functions handle rate limiting automatically

## 🔧 Troubleshooting

### Common Issues

#### 1. "Stripe is not configured"
- **Solution**: Verify `VITE_STRIPE_PUBLISHABLE_KEY` in `.env`
- **Check**: Key should start with `pk_test_` or `pk_live_`

#### 2. "Edge Function not ready"
- **Solution**: Deploy functions: `supabase functions deploy sync-stripe-product`
- **Check**: Verify `STRIPE_SECRET_KEY` in Supabase secrets

#### 3. "Product has no variants"
- **Solution**: Products need at least one variant (price)
- **Fix**: Add variants to products in your database

#### 4. Sync stuck/slow
- **Solution**: Check Stripe Dashboard for rate limiting
- **Fix**: Increase delays between batches if needed

### Error Recovery
```javascript
// Check for failed products
const failedProducts = await supabase
  .from('products')
  .select('id, name, stripe_sync_error')
  .eq('stripe_sync_status', 'failed');

// Retry specific products
await stripeSyncService.syncProducts({
  productIds: failedProducts.map(p => p.id),
  skipExisting: false
});
```

## 📈 Post-Sync Verification

### 1. Stripe Dashboard
- Go to [Stripe Dashboard > Products](https://dashboard.stripe.com/products)
- Verify all 182 products appear
- Check that prices are created for each variant

### 2. Database Verification
```sql
-- Count synced products
SELECT 
  COUNT(*) as total_products,
  COUNT(stripe_product_id) as synced_products,
  COUNT(stripe_product_id) * 100.0 / COUNT(*) as sync_percentage
FROM products;

-- Verify variants have prices
SELECT 
  COUNT(*) as total_variants,
  COUNT(stripe_price_id) as synced_variants
FROM product_variants;
```

### 3. Test Checkout
- Create a test order with synced products
- Verify Stripe checkout works correctly
- Confirm webhooks update order status

## 🔄 Rollback Instructions

### Partial Rollback (Specific Products)
```javascript
// Via service
await stripeSyncService.rollbackSync(['product-id-1', 'product-id-2']);
```

### Complete Rollback (Emergency)
```sql
-- Remove all Stripe data (DANGEROUS - use with caution!)
UPDATE products SET 
  stripe_product_id = NULL,
  stripe_sync_status = 'pending',
  stripe_synced_at = NULL,
  stripe_sync_error = NULL;

UPDATE product_variants SET 
  stripe_price_id = NULL;

-- Clear sync logs
DELETE FROM stripe_sync_log;
```

## 🎉 Success Metrics

After successful sync, you should have:
- ✅ 182 products in Stripe
- ✅ All product variants as Stripe prices  
- ✅ Metadata linking Stripe IDs to Supabase IDs
- ✅ Complete audit trail in `stripe_sync_log`
- ✅ Real-time checkout capability

## 🔗 Next Steps

1. **Test Checkout Flow**: Create test orders with synced products
2. **Setup Webhooks**: Ensure Stripe webhooks update order status
3. **Inventory Sync**: Configure bidirectional inventory updates
4. **Go Live**: Switch to live Stripe keys when ready
5. **Monitoring**: Set up alerts for sync failures

## 📞 Support

If you encounter issues:
1. Check the sync logs in the UI
2. Review the database `stripe_sync_log` table
3. Verify Stripe Dashboard for created products
4. Use dry-run mode to test changes
5. Use rollback if needed and retry

The system is designed to be safe, reliable, and fully recoverable. Start with dry-run mode and progress through the phases carefully.