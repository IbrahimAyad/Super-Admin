-- Copy and paste ONLY this SQL code into Supabase SQL Editor:

SELECT 
  'products.stripe_product_id column' as feature,
  EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' AND column_name = 'stripe_product_id'
  ) as exists,
  '045_add_stripe_fields_safely.sql' as migration_file
  
UNION ALL

SELECT 
  'products.stripe_sync_status column',
  EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' AND column_name = 'stripe_sync_status'
  ),
  '045_add_stripe_fields_safely.sql'
  
UNION ALL

SELECT 
  'update_sync_progress function',
  EXISTS (
    SELECT 1 FROM information_schema.routines 
    WHERE routine_name = 'update_sync_progress'
  ),
  '046_add_sync_progress_function.sql'
  
UNION ALL

SELECT 
  'orders.financial_status column',
  EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'orders' AND column_name = 'financial_status'
  ),
  '048_optimize_orders_schema.sql'
  
UNION ALL

SELECT 
  'order_events table',
  EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'order_events'
  ),
  '048_optimize_orders_schema.sql'
  
UNION ALL

SELECT 
  'order_shipments table',
  EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'order_shipments'
  ),
  '048_optimize_orders_schema.sql'
  
UNION ALL

SELECT 
  'analytics_events table',
  EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'analytics_events'
  ),
  '050_create_analytics_system.sql'
  
UNION ALL

SELECT 
  'analytics_sessions table',
  EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'analytics_sessions'
  ),
  '050_create_analytics_system.sql'
  
UNION ALL

SELECT 
  'refund_requests table',
  EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'refund_requests'
  ),
  '051_create_refund_tables.sql'

ORDER BY migration_file, feature;