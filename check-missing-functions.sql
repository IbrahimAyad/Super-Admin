-- Check for missing database functions that are causing errors

-- Check if these functions exist
SELECT 
  p.proname as function_name,
  n.nspname as schema_name,
  pg_get_function_identity_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname IN (
  'get_recent_orders',
  'log_login_attempt', 
  'transfer_guest_cart'
)
AND n.nspname = 'public'
ORDER BY p.proname;

-- Check if login_attempts table exists
SELECT 
  table_name,
  table_schema
FROM information_schema.tables 
WHERE table_name = 'login_attempts'
AND table_schema = 'public';

-- Check all available RPC functions
SELECT 
  p.proname as function_name,
  n.nspname as schema_name,
  pg_get_function_identity_arguments(p.oid) as arguments,
  obj_description(p.oid, 'pg_proc') as description
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.prokind = 'f'  -- Only functions, not procedures
ORDER BY p.proname;

-- Check if there are any auth-related tables
SELECT 
  table_name
FROM information_schema.tables 
WHERE table_schema = 'public'
AND (
  table_name LIKE '%login%' 
  OR table_name LIKE '%auth%'
  OR table_name LIKE '%session%'
)
ORDER BY table_name;