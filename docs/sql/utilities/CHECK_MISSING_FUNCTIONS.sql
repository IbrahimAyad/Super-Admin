-- ============================================
-- CHECK FOR MISSING DATABASE FUNCTIONS & TABLES
-- ============================================

-- Check if these critical tables exist
SELECT 
  'CRITICAL TABLES CHECK' as category,
  table_name,
  EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = t.table_name
  ) as exists
FROM (
  VALUES 
    -- Stripe sync tables
    ('stripe_sync_log'),
    ('stripe_sync_summary'),
    -- Bundle tables
    ('product_bundles'),
    ('bundle_items'),
    -- Marketing tables
    ('marketing_campaigns'),
    ('email_campaigns'),
    -- Review tables
    ('product_reviews'),
    -- Collection tables
    ('collections'),
    ('collection_products'),
    -- Customer service tables
    ('support_tickets'),
    -- Integration tables
    ('integrations'),
    ('integration_logs')
) t(table_name)
ORDER BY exists DESC, table_name;

-- Check if these critical functions exist
SELECT 
  'CRITICAL FUNCTIONS CHECK' as category,
  routine_name,
  EXISTS (
    SELECT 1 FROM information_schema.routines 
    WHERE routine_schema = 'public' AND routine_name = f.routine_name
  ) as exists
FROM (
  VALUES 
    -- Stripe sync functions
    ('sync_stripe_product'),
    ('get_sync_progress_by_category'),
    -- Order functions
    ('process_order_payment'),
    ('calculate_order_totals'),
    -- Customer functions
    ('get_customer_stats'),
    ('merge_duplicate_customers'),
    -- Marketing functions
    ('send_marketing_email'),
    ('track_campaign_conversion'),
    -- Bundle functions
    ('calculate_bundle_price'),
    ('validate_bundle_stock')
) f(routine_name)
ORDER BY exists DESC, routine_name;

-- Check for Edge Functions that might be missing
SELECT 
  'EDGE FUNCTIONS NEEDED' as category,
  function_name,
  'Create in Supabase Dashboard' as action
FROM (
  VALUES 
    ('sync-stripe-product'),
    ('process-payment'),
    ('send-marketing-email'),
    ('generate-report'),
    ('validate-order')
) e(function_name);

-- Check for missing RPC functions that UI expects
SELECT 
  'RPC FUNCTIONS STATUS' as category,
  routine_name as function_name,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.routines 
      WHERE routine_schema = 'public' AND routine_name = r.routine_name
    ) THEN 'EXISTS ✅'
    ELSE 'MISSING ❌ - Need to create'
  END as status
FROM (
  VALUES 
    ('import_customers_from_csv'),
    ('import_products_from_csv'),
    ('get_sync_progress_by_category'),
    ('calculate_order_totals'),
    ('get_customer_lifetime_value'),
    ('get_product_performance'),
    ('process_bulk_orders'),
    ('generate_analytics_report')
) r(routine_name)
ORDER BY status DESC;