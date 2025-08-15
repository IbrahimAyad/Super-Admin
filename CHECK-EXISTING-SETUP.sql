-- ================================================================
-- CHECK WHAT ALREADY EXISTS IN DATABASE
-- ================================================================

-- 1. Check if functions already exist (might be causing conflicts)
SELECT '===== EXISTING FUNCTIONS =====' as section;
SELECT 
  routine_name,
  routine_type,
  data_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
  AND routine_name IN ('get_recent_orders', 'transfer_guest_cart', 'get_dashboard_stats')
ORDER BY routine_name;

-- 2. Check if tables exist
SELECT '===== EXISTING TABLES =====' as section;
SELECT 
  table_name,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_name IN ('orders', 'customers', 'reviews', 'cart_items', 'admin_users', 'products')
ORDER BY table_name;

-- 3. Check orders table structure specifically
SELECT '===== ORDERS TABLE COLUMNS =====' as section;
SELECT 
  ordinal_position,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'orders'
ORDER BY ordinal_position;

-- 4. Check for any existing get_recent_orders functions with different signatures
SELECT '===== ALL GET_RECENT_ORDERS SIGNATURES =====' as section;
SELECT 
  proname as function_name,
  pronargs as arg_count,
  proargtypes::text as arg_types,
  prorettype::regtype as return_type
FROM pg_proc
WHERE proname = 'get_recent_orders'
  AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- 5. Check if there's a view blocking table creation
SELECT '===== VIEWS THAT MIGHT BLOCK =====' as section;
SELECT 
  table_name as view_name,
  view_definition
FROM information_schema.views
WHERE table_schema = 'public'
  AND table_name IN ('reviews', 'cart_items');

-- 6. Check current user permissions
SELECT '===== CURRENT USER PERMISSIONS =====' as section;
SELECT 
  current_user,
  has_database_privilege(current_database(), 'CREATE') as can_create,
  has_schema_privilege('public', 'CREATE') as can_create_in_public;