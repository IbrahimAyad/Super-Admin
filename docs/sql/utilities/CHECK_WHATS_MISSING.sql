-- ============================================
-- CHECK WHAT'S MISSING FOR FULL OPERATION
-- ============================================

-- Check which critical tables are missing
SELECT 
  'MISSING CRITICAL TABLES' as check_type,
  table_name,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = t.table_name
    ) THEN '✅ EXISTS'
    ELSE '❌ MISSING'
  END as status
FROM (
  VALUES 
    ('orders'),
    ('order_status_history'),
    ('order_events'),
    ('email_logs'),
    ('email_queue'),
    ('inventory_movements'),
    ('low_stock_alerts'),
    ('analytics_events'),
    ('refund_requests')
) t(table_name)
WHERE NOT EXISTS (
  SELECT 1 FROM information_schema.tables 
  WHERE table_schema = 'public' AND table_name = t.table_name
)

UNION ALL

-- Count how many of the 9 critical tables exist
SELECT 
  'CRITICAL TABLES SUMMARY' as check_type,
  'Total Critical Tables' as table_name,
  COUNT(*) || ' of 9 exist' as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN (
    'orders', 'order_status_history', 'order_events', 
    'email_logs', 'email_queue', 'inventory_movements',
    'low_stock_alerts', 'analytics_events', 'refund_requests'
  )

ORDER BY check_type, table_name;

-- ============================================
-- DETAILED CHECK OF ALL EXPECTED TABLES
-- ============================================

SELECT 
  'TABLE EXISTENCE CHECK' as report,
  table_name,
  EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = expected.table_name
  ) as exists
FROM (
  VALUES 
    -- Core tables
    ('products'),
    ('product_variants'),
    ('customers'),
    ('orders'),
    -- Order system (from migration 053)
    ('order_status_history'),
    ('shipping_labels'),
    -- Order optimization (from migration 048)
    ('order_events'),
    ('order_shipments'),
    ('order_returns'),
    -- Email system (from migration 054)
    ('email_logs'),
    ('email_templates'),
    ('email_queue'),
    -- Inventory system (from migration 055)
    ('inventory_movements'),
    ('low_stock_alerts'),
    ('inventory_thresholds'),
    -- Analytics (from migration 050)
    ('analytics_events'),
    ('analytics_sessions'),
    ('analytics_page_views'),
    ('analytics_conversions'),
    ('analytics_daily_summary'),
    ('analytics_product_performance'),
    -- Financial (from migration 051)
    ('refund_requests'),
    -- Reporting (from migration 056)
    ('daily_reports')
) expected(table_name)
ORDER BY exists DESC, table_name;