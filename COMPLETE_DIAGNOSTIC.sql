-- ============================================
-- COMPLETE DIAGNOSTIC - CHECK ALL RECENT TABLES
-- ============================================

-- Check all tables from migrations 045-056
SELECT 
  'TABLES' as category,
  table_name,
  EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = t.table_name
  ) as exists
FROM (
  VALUES 
    -- From 048
    ('order_events'),
    ('order_shipments'),
    ('order_returns'),
    -- From 050
    ('analytics_events'),
    ('analytics_sessions'),
    ('analytics_page_views'),
    ('analytics_conversions'),
    -- From 051
    ('refund_requests'),
    -- From 052
    ('analytics_daily_summary'),
    ('analytics_product_performance'),
    -- From 053
    ('order_status_history'),
    ('shipping_labels'),
    -- From 054
    ('email_logs'),
    ('email_templates'),
    ('email_queue'),
    -- From 055
    ('inventory_movements'),
    ('low_stock_alerts'),
    ('inventory_thresholds'),
    -- From 056
    ('daily_reports')
) t(table_name)

UNION ALL

-- Check important columns
SELECT 
  'COLUMNS' as category,
  table_name || '.' || column_name as table_name,
  EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = c.table_name 
      AND column_name = c.column_name
  ) as exists
FROM (
  VALUES 
    -- Stripe fields
    ('products', 'stripe_product_id'),
    ('products', 'stripe_sync_status'),
    ('product_variants', 'stripe_price_id'),
    -- Order fields
    ('orders', 'financial_status'),
    ('orders', 'fulfillment_status'),
    ('orders', 'carrier_name'),
    ('orders', 'tracking_number'),
    ('orders', 'confirmed_at'),
    ('orders', 'shipped_at'),
    ('orders', 'delivered_at'),
    ('orders', 'cancelled_at'),
    ('orders', 'cancellation_reason'),
    -- Inventory fields in product_variants
    ('product_variants', 'available_quantity'),
    ('product_variants', 'reserved_quantity'),
    ('product_variants', 'inventory_quantity')
) c(table_name, column_name)

UNION ALL

-- Check important functions
SELECT 
  'FUNCTIONS' as category,
  routine_name,
  EXISTS (
    SELECT 1 FROM information_schema.routines 
    WHERE routine_schema = 'public' AND routine_name = f.routine_name
  ) as exists
FROM (
  VALUES 
    -- Sync functions
    ('update_sync_progress'),
    ('sync_inventory_on_order'),
    ('sync_inventory_on_refund'),
    ('check_low_stock'),
    ('update_order_status'),
    ('bulk_update_order_status'),
    -- Email functions
    ('queue_email'),
    ('process_email_queue'),
    ('send_order_status_email'),
    -- Analytics functions
    ('track_analytics_event'),
    ('get_analytics_summary'),
    ('get_inventory_status'),
    -- Refund functions
    ('process_refund')
) f(routine_name)

ORDER BY category, table_name;

-- ============================================
-- SUMMARY COUNT
-- ============================================
SELECT 
  'SUMMARY' as report,
  COUNT(*) FILTER (WHERE category = 'TABLES' AND exists = true) as tables_exist,
  COUNT(*) FILTER (WHERE category = 'TABLES' AND exists = false) as tables_missing,
  COUNT(*) FILTER (WHERE category = 'COLUMNS' AND exists = true) as columns_exist,
  COUNT(*) FILTER (WHERE category = 'COLUMNS' AND exists = false) as columns_missing,
  COUNT(*) FILTER (WHERE category = 'FUNCTIONS' AND exists = true) as functions_exist,
  COUNT(*) FILTER (WHERE category = 'FUNCTIONS' AND exists = false) as functions_missing
FROM (
  SELECT 
    'TABLES' as category,
    EXISTS (
      SELECT 1 FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = t.table_name
    ) as exists
  FROM (
    VALUES 
      ('order_events'), ('order_shipments'), ('order_returns'),
      ('analytics_events'), ('analytics_sessions'), ('analytics_page_views'),
      ('analytics_conversions'), ('refund_requests'), ('analytics_daily_summary'),
      ('analytics_product_performance'), ('order_status_history'), ('shipping_labels'),
      ('email_logs'), ('email_templates'), ('email_queue'),
      ('inventory_movements'), ('low_stock_alerts'), ('inventory_thresholds'),
      ('daily_reports')
  ) t(table_name)
  
  UNION ALL
  
  SELECT 
    'COLUMNS' as category,
    EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_schema = 'public' AND table_name = c.table_name AND column_name = c.column_name
    ) as exists
  FROM (
    VALUES 
      ('products', 'stripe_product_id'), ('products', 'stripe_sync_status'),
      ('product_variants', 'stripe_price_id'), ('orders', 'financial_status'),
      ('orders', 'fulfillment_status'), ('orders', 'carrier_name'),
      ('orders', 'tracking_number'), ('orders', 'confirmed_at'),
      ('orders', 'shipped_at'), ('orders', 'delivered_at'),
      ('orders', 'cancelled_at'), ('orders', 'cancellation_reason'),
      ('product_variants', 'available_quantity'), ('product_variants', 'reserved_quantity'),
      ('product_variants', 'inventory_quantity')
  ) c(table_name, column_name)
  
  UNION ALL
  
  SELECT 
    'FUNCTIONS' as category,
    EXISTS (
      SELECT 1 FROM information_schema.routines 
      WHERE routine_schema = 'public' AND routine_name = f.routine_name
    ) as exists
  FROM (
    VALUES 
      ('update_sync_progress'), ('sync_inventory_on_order'), ('sync_inventory_on_refund'),
      ('check_low_stock'), ('update_order_status'), ('bulk_update_order_status'),
      ('queue_email'), ('process_email_queue'), ('send_order_status_email'),
      ('track_analytics_event'), ('get_analytics_summary'), ('get_inventory_status'),
      ('process_refund')
  ) f(routine_name)
) all_checks;