# Missing Migrations 045-050 Analysis

Based on your product_variants table structure, here's what you need to run:

## ✅ Already Run (Skip These):
- **047_create_product_variants_table.sql** - Your table already exists

## ❓ Possibly Missing (Check & Run if Needed):

### 1. **045_add_stripe_fields_safely.sql**
**Check if needed:** Look if `stripe_product_id` exists in products table
```sql
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'products' AND column_name = 'stripe_product_id';
```
If empty, run this migration.

### 2. **046_add_sync_progress_function.sql**
**Purpose:** Adds progress tracking for product sync
**Safe to run:** YES - Creates functions only

### 3. **048_optimize_orders_schema.sql**
**Purpose:** Optimizes orders table performance
**Check if needed:**
```sql
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'orders' AND column_name IN ('financial_status', 'fulfillment_status');
```
If empty, you might need this.

### 4. **049_orders_performance_optimization.sql**
**Purpose:** Adds indexes for better performance
**Safe to run:** YES - Only adds indexes

### 5. **050_create_analytics_system.sql**
**Purpose:** Creates analytics tables and functions
**Check if needed:**
```sql
SELECT EXISTS (
  SELECT 1 FROM information_schema.tables 
  WHERE table_name = 'analytics_events'
);
```
If false, run this.

### 6. **050_orders_rls_policies.sql** 
**Purpose:** Sets up Row Level Security
**Safe to run:** YES - Only adds policies

## 🔍 Quick Check Command:

Run this to see which tables/functions exist:
```sql
SELECT 
  'products.stripe_product_id' as feature,
  EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' AND column_name = 'stripe_product_id'
  ) as exists
UNION ALL
SELECT 
  'analytics_events table',
  EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'analytics_events'
  )
UNION ALL
SELECT 
  'order_events table',
  EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'order_events'
  )
UNION ALL
SELECT 
  'sync_progress function',
  EXISTS (
    SELECT 1 FROM information_schema.routines 
    WHERE routine_name = 'update_sync_progress'
  );
```

## 📋 Recommended Order to Run:

If the checks show they're missing, run in this order:

1. **045_add_stripe_fields_safely.sql** - Adds Stripe fields
2. **046_add_sync_progress_function.sql** - Adds sync tracking
3. **048_optimize_orders_schema.sql** - Optimizes orders (if needed)
4. **049_orders_performance_optimization.sql** - Adds performance indexes
5. **050_create_analytics_system.sql** - Creates analytics
6. **050_orders_rls_policies.sql** - Adds security policies

## ⚠️ Important Notes:

1. **048 might conflict** if you already have some of these columns
2. **Two files named 050** - Run both (analytics first, then RLS)
3. All are **safe to re-run** - They use IF NOT EXISTS
4. **Skip 047** - Your product_variants table already exists

## 🎯 Quick Fix for Common Issues:

If you get errors about existing objects, you can safely skip that migration or modify it to use IF NOT EXISTS clauses.