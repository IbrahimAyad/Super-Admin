# SQL Migration Order - SAFE DEPLOYMENT GUIDE

Run these SQL migrations in the Supabase SQL Editor in this **EXACT ORDER** to ensure all dependencies are met:

## ✅ Order of Execution:

### 1️⃣ **053_order_processing_tables.sql**
**Creates:** Order status history, shipping labels tables
**Dependencies:** Requires existing orders table
**Safe to run:** YES - Creates new tables only

### 2️⃣ **054_email_system.sql**
**Creates:** Email logs, templates, queue tables
**Dependencies:** Requires customers and orders tables
**Safe to run:** YES - Creates new tables and triggers

### 3️⃣ **055_inventory_automation.sql**
**Creates:** Inventory movements, low stock alerts, thresholds
**Dependencies:** Requires inventory, product_variants, orders tables
**Safe to run:** YES - Creates new tables and automation triggers

### 4️⃣ **056_daily_reports.sql**
**Creates:** Daily reports storage table
**Dependencies:** Requires email_queue table from step 2
**Safe to run:** YES - Creates new table only

## 📋 Step-by-Step Instructions:

1. **Open Supabase SQL Editor**
   - Go to your project dashboard
   - Navigate to SQL Editor

2. **Run Each Migration:**
   ```sql
   -- Step 1: Copy contents of 053_order_processing_tables.sql
   -- Paste and click "Run"
   -- Wait for success message
   
   -- Step 2: Copy contents of 054_email_system.sql
   -- Paste and click "Run"
   -- Wait for success message
   
   -- Step 3: Copy contents of 055_inventory_automation.sql
   -- Paste and click "Run"
   -- Wait for success message
   
   -- Step 4: Copy contents of 056_daily_reports.sql
   -- Paste and click "Run"
   -- Wait for success message
   ```

3. **Verify Installation:**
   Run this query to check all tables were created:
   ```sql
   SELECT table_name 
   FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name IN (
     'order_status_history',
     'shipping_labels', 
     'email_logs',
     'email_templates',
     'email_queue',
     'inventory_movements',
     'low_stock_alerts',
     'inventory_thresholds',
     'daily_reports'
   )
   ORDER BY table_name;
   ```
   
   You should see 9 rows returned.

## ⚠️ Important Notes:

1. **DO NOT skip any migration** - They build on each other
2. **DO NOT run out of order** - Dependencies will fail
3. **Each migration is idempotent** - Safe to run multiple times (uses IF NOT EXISTS)
4. **Triggers are created** - Orders will automatically sync inventory after migration 055
5. **RLS is enabled** - All new tables have Row Level Security enabled

## 🔄 Rollback (if needed):

If you need to rollback, run these in REVERSE order:
```sql
-- Remove in reverse order to handle dependencies
DROP TABLE IF EXISTS daily_reports CASCADE;
DROP TABLE IF EXISTS inventory_thresholds CASCADE;
DROP TABLE IF EXISTS low_stock_alerts CASCADE;
DROP TABLE IF EXISTS inventory_movements CASCADE;
DROP TABLE IF EXISTS email_queue CASCADE;
DROP TABLE IF EXISTS email_templates CASCADE;
DROP TABLE IF EXISTS email_logs CASCADE;
DROP TABLE IF EXISTS shipping_labels CASCADE;
DROP TABLE IF EXISTS order_status_history CASCADE;

-- Remove functions and triggers
DROP FUNCTION IF EXISTS sync_inventory_on_order() CASCADE;
DROP FUNCTION IF EXISTS sync_inventory_on_refund() CASCADE;
DROP FUNCTION IF EXISTS send_order_status_email() CASCADE;
DROP FUNCTION IF EXISTS update_order_status() CASCADE;
```

## ✅ After Successful Migration:

1. **Deploy Edge Functions:**
   - send-email
   - daily-report

2. **Set Environment Variables:**
   - RESEND_API_KEY (for email sending)
   - Stripe keys (already set)

3. **Test Features:**
   - Create a test order to verify inventory sync
   - Check email queue population
   - Verify low stock alerts trigger

## 📊 What Each Migration Enables:

- **053:** Order processing workflow, status tracking, shipping labels
- **054:** Automated email notifications for order updates
- **055:** Real-time inventory tracking, low stock alerts
- **056:** Daily business reports with metrics and comparisons

All migrations are production-ready and tested!