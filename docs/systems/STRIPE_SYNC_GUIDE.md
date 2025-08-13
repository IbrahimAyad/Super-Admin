# Stripe Product Sync - Safe Implementation Guide

## 🎯 What This Does

This system safely adds Stripe integration to your 182 existing products without modifying any existing data. It only adds new columns to store Stripe IDs.

## 🛡️ Safety Features

### 1. **Non-Destructive**
- ✅ Only ADDS new columns (stripe_product_id, stripe_price_id)
- ✅ Never modifies existing product data
- ✅ All changes are reversible

### 2. **Incremental Sync**
- ✅ Sync by category or individual products
- ✅ Skip already-synced products
- ✅ Batch processing to avoid rate limits

### 3. **Rollback Support**
- ✅ Complete rollback script included
- ✅ Can rollback individual products
- ✅ Audit trail for all operations

## 📋 Implementation Steps

### Step 1: Apply Database Migration (SAFE)

```bash
# Run the migration to add Stripe columns
supabase migration up
```

Or manually in Supabase SQL Editor:
```sql
-- Copy contents of: supabase/migrations/045_add_stripe_fields_safely.sql
```

This migration:
- Adds nullable columns (no constraints)
- Creates helper views for monitoring
- Sets up audit logging
- Is completely reversible

### Step 2: Deploy Edge Function

```bash
# Deploy the sync function
supabase functions deploy sync-stripe-product
```

### Step 3: Use Sync Manager UI

1. Navigate to `/admin/stripe-sync` in your admin panel
2. Start with **Dry Run Mode** enabled
3. Select one category to test (e.g., "Suspender & Bowtie Sets" - only 10 products)
4. Review results
5. If successful, disable Dry Run and sync for real

## 🔄 Sync Process

### Test with Small Category First
```javascript
// Start with smallest category (4 products)
await stripeSyncService.syncProducts({
  dryRun: true,
  categories: ['Sparkle Vest Sets'],
  skipExisting: true
});
```

### Progressive Sync
1. **Phase 1**: Sync "Sparkle Vest Sets" (4 products)
2. **Phase 2**: Sync "Casual Summer Blazers" (7 products)
3. **Phase 3**: Sync "Suspender & Bowtie Sets" (10 products)
4. **Phase 4**: Sync remaining categories

## 🚨 Rollback Instructions

### Rollback Specific Products
```javascript
// Rollback by product IDs
await stripeSyncService.rollbackSync(['product-id-1', 'product-id-2']);
```

### Complete Rollback (Emergency)
```sql
-- Remove all Stripe fields and data
ALTER TABLE public.products 
DROP COLUMN stripe_product_id,
DROP COLUMN stripe_sync_status,
DROP COLUMN stripe_sync_error,
DROP COLUMN stripe_synced_at;

ALTER TABLE public.product_variants 
DROP COLUMN stripe_price_id;

DROP TABLE stripe_sync_log;
```

## 📊 Monitoring

### Check Sync Status
```sql
-- View sync summary
SELECT * FROM stripe_sync_summary;

-- View pending products
SELECT * FROM products_pending_stripe_sync;

-- View sync logs
SELECT * FROM stripe_sync_log ORDER BY created_at DESC;
```

### Monitor in UI
- Go to `/admin/stripe-sync`
- View real-time progress
- Check error logs
- See which products are synced

## ⚙️ Configuration Requirements

### Already Configured ✅
- `STRIPE_SECRET_KEY` - Already in Supabase Edge Functions
- Edge Functions deployed and working
- Orders already have Stripe payment intents

### Need to Verify
- Stripe webhook endpoints are configured
- Products in Stripe dashboard match expected format

## 🎯 Benefits After Sync

Once products are synced to Stripe:

1. **Direct Checkout**: Create Stripe checkout sessions with product prices
2. **Inventory Sync**: Track inventory between Stripe and Supabase
3. **Price Management**: Update prices in one place
4. **Subscription Support**: Enable recurring billing if needed
5. **Tax Calculation**: Stripe Tax integration
6. **Reporting**: Unified reporting in Stripe Dashboard

## ⚠️ Important Notes

1. **Prices are Immutable**: In Stripe, you can't change a price - you archive it and create a new one
2. **SKUs Optional**: Stripe will generate IDs if SKUs aren't provided
3. **Metadata Preserved**: All Supabase IDs are stored in Stripe metadata
4. **Rate Limits**: Stripe allows 100 requests/second, we limit to 5 products/batch

## 🤝 Support

If you encounter issues:

1. Check `stripe_sync_log` table for errors
2. Review Stripe Dashboard for created products
3. Use Dry Run mode to test without changes
4. Rollback and retry if needed

## Next Steps After Sync

1. **Test Checkout**: Create a test order with synced products
2. **Verify Webhooks**: Ensure Stripe webhooks update Supabase
3. **Setup Inventory Sync**: Configure bi-directional inventory updates
4. **Enable Production**: Switch from test to live keys when ready