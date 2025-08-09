-- Check which tables actually exist in your database
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Check if orders table has any data
SELECT COUNT(*) as order_count FROM orders;

-- Check if products table has any data  
SELECT COUNT(*) as product_count FROM products;

-- Check if customers table exists
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'customers'
) as customers_exists;

-- Test the get_dashboard_stats function
SELECT get_dashboard_stats();