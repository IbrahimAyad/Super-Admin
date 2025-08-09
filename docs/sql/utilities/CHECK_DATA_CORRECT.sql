-- ============================================
-- CHECK WHAT DATA EXISTS IN THE SYSTEM (CORRECT VERSION)
-- ============================================

-- Check if there's any data in the main tables
SELECT 
  'DATA STATUS CHECK' as report,
  table_name,
  record_count,
  CASE 
    WHEN record_count = 0 THEN '📭 Empty'
    WHEN table_name = 'products' AND record_count > 50 THEN '🎭 Likely has dummy data'
    ELSE '📦 Has data (' || record_count || ' records)'
  END as status
FROM (
  SELECT 'products' as table_name, COUNT(*) as record_count FROM products
  UNION ALL
  SELECT 'product_variants', COUNT(*) FROM product_variants
  UNION ALL
  SELECT 'customers', COUNT(*) FROM customers
  UNION ALL
  SELECT 'orders', COUNT(*) FROM orders
  UNION ALL
  SELECT 'analytics_events', COUNT(*) FROM analytics_events
  UNION ALL
  SELECT 'email_logs', COUNT(*) FROM email_logs
  UNION ALL
  SELECT 'inventory_movements', COUNT(*) FROM inventory_movements
) data_check
ORDER BY 
  CASE 
    WHEN record_count > 0 THEN 0 
    ELSE 1 
  END, 
  record_count DESC;

-- Check sample products to see if they're dummy data
SELECT 
  'SAMPLE PRODUCTS' as check,
  COUNT(*) as total_products,
  COUNT(*) FILTER (WHERE name ILIKE '%test%' OR name ILIKE '%sample%' OR name ILIKE '%dummy%') as test_products
FROM products;

-- Check if products have Stripe IDs (real vs dummy)
SELECT 
  'STRIPE INTEGRATION' as check,
  COUNT(*) as total_products,
  COUNT(*) FILTER (WHERE stripe_product_id IS NOT NULL) as products_with_stripe,
  COUNT(*) FILTER (WHERE stripe_product_id IS NULL) as products_without_stripe
FROM products;

-- Check orders to see if they're real or test
SELECT 
  'ORDER ANALYSIS' as check,
  COUNT(*) as total_orders,
  COUNT(*) FILTER (WHERE stripe_payment_intent_id IS NOT NULL) as real_orders,
  COUNT(*) FILTER (WHERE stripe_payment_intent_id IS NULL) as possible_test_orders,
  MAX(created_at)::DATE as last_order_date
FROM orders;

-- Show first 5 product names (using subquery)
SELECT 
  'FIRST 5 PRODUCTS' as check,
  STRING_AGG(name, ', ') as product_names
FROM (
  SELECT name 
  FROM products 
  ORDER BY created_at 
  LIMIT 5
) first_products;

-- Show last 5 product names (most recent)
SELECT 
  'LAST 5 PRODUCTS' as check,
  STRING_AGG(name, ', ') as product_names
FROM (
  SELECT name 
  FROM products 
  ORDER BY created_at DESC 
  LIMIT 5
) recent_products;