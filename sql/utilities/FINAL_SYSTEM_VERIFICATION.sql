-- ============================================
-- FINAL SYSTEM VERIFICATION
-- Confirms all components are installed and operational
-- ============================================

-- 1. CHECK ALL CORE SYSTEMS
SELECT 
  'System Status Check' as report_type,
  system_name,
  CASE WHEN component_count = expected_count THEN '✅ READY' ELSE '❌ INCOMPLETE' END as status,
  component_count || '/' || expected_count as components
FROM (
  SELECT 
    'Order Processing' as system_name,
    COUNT(*) as component_count,
    5 as expected_count
  FROM information_schema.tables
  WHERE table_name IN ('orders', 'order_status_history', 'order_events', 'order_shipments', 'shipping_labels')
  
  UNION ALL
  
  SELECT 
    'Email System',
    COUNT(*),
    3
  FROM information_schema.tables
  WHERE table_name IN ('email_logs', 'email_templates', 'email_queue')
  
  UNION ALL
  
  SELECT 
    'Inventory Management',
    COUNT(*),
    3
  FROM information_schema.tables
  WHERE table_name IN ('inventory_movements', 'low_stock_alerts', 'inventory_thresholds')
  
  UNION ALL
  
  SELECT 
    'Analytics System',
    COUNT(*),
    6
  FROM information_schema.tables
  WHERE table_name IN ('analytics_events', 'analytics_sessions', 'analytics_page_views', 
                       'analytics_conversions', 'analytics_daily_summary', 'analytics_product_performance')
  
  UNION ALL
  
  SELECT 
    'Financial System',
    COUNT(*),
    2
  FROM information_schema.tables
  WHERE table_name IN ('refund_requests', 'checkout_sessions')
  
  UNION ALL
  
  SELECT 
    'Reporting System',
    COUNT(*),
    1
  FROM information_schema.tables
  WHERE table_name = 'daily_reports'
) system_check

UNION ALL

-- 2. CHECK CRITICAL FUNCTIONS
SELECT 
  'Critical Functions' as report_type,
  'Core Functions' as system_name,
  CASE WHEN COUNT(*) >= 10 THEN '✅ READY' ELSE '❌ MISSING SOME' END as status,
  COUNT(*) || ' functions' as components
FROM information_schema.routines
WHERE routine_name IN (
  'sync_inventory_on_order',
  'sync_inventory_on_refund',
  'check_low_stock',
  'update_order_status',
  'queue_email',
  'send_order_status_email',
  'track_analytics_event',
  'get_analytics_summary',
  'process_refund',
  'update_sync_progress'
)

UNION ALL

-- 3. CHECK TRIGGERS
SELECT 
  'Automation Triggers' as report_type,
  'Triggers' as system_name,
  CASE WHEN COUNT(*) >= 2 THEN '✅ READY' ELSE '❌ MISSING' END as status,
  COUNT(*) || ' active triggers' as components
FROM information_schema.triggers
WHERE trigger_name IN (
  'trigger_sync_inventory_on_order',
  'trigger_sync_inventory_on_refund',
  'trigger_send_order_status_email'
)

ORDER BY report_type, system_name;

-- ============================================
-- DETAILED COMPONENT LIST
-- ============================================

SELECT 
  '📊 COMPLETE SYSTEM INVENTORY' as title;

-- Tables Count
SELECT 
  'Tables' as component_type,
  COUNT(*) as total_count,
  STRING_AGG(table_name, ', ' ORDER BY table_name) as list
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    -- Core tables
    'products', 'product_variants', 'customers', 'orders',
    -- Order system
    'order_status_history', 'order_events', 'order_shipments', 'order_returns', 'shipping_labels',
    -- Email system
    'email_logs', 'email_templates', 'email_queue',
    -- Inventory system
    'inventory_movements', 'low_stock_alerts', 'inventory_thresholds',
    -- Analytics system
    'analytics_events', 'analytics_sessions', 'analytics_page_views', 
    'analytics_conversions', 'analytics_daily_summary', 'analytics_product_performance',
    -- Financial system
    'refund_requests', 'checkout_sessions',
    -- Reporting
    'daily_reports'
  )

UNION ALL

-- Functions Count
SELECT 
  'Functions' as component_type,
  COUNT(*) as total_count,
  STRING_AGG(routine_name, ', ' ORDER BY routine_name) as list
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_type = 'FUNCTION'
  AND routine_name IN (
    'sync_inventory_on_order', 'sync_inventory_on_refund', 'check_low_stock',
    'update_order_status', 'bulk_update_order_status', 'queue_email',
    'process_email_queue', 'send_order_status_email', 'track_analytics_event',
    'get_analytics_summary', 'get_inventory_status', 'process_refund',
    'update_sync_progress'
  )

UNION ALL

-- Triggers Count
SELECT 
  'Triggers' as component_type,
  COUNT(*) as total_count,
  STRING_AGG(trigger_name, ', ' ORDER BY trigger_name) as list
FROM information_schema.triggers
WHERE trigger_schema = 'public';

-- ============================================
-- OPERATIONAL READINESS
-- ============================================

SELECT 
  '🚀 OPERATIONAL STATUS' as title,
  CASE 
    WHEN (
      SELECT COUNT(*) >= 20 FROM information_schema.tables 
      WHERE table_schema = 'public' 
        AND table_name IN (
          'orders', 'order_status_history', 'order_events', 
          'email_logs', 'email_queue', 'inventory_movements',
          'low_stock_alerts', 'analytics_events', 'refund_requests'
        )
    ) THEN 'SYSTEM FULLY OPERATIONAL ✅'
    ELSE 'SYSTEM PARTIALLY OPERATIONAL ⚠️'
  END as status,
  'KCT Admin System v1.0' as version;