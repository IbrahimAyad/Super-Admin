-- ================================================================
-- COMPREHENSIVE DATABASE FUNCTION AUDIT
-- Shows ALL functions in the database with details
-- ================================================================

-- 1. ALL FUNCTIONS IN THE DATABASE
SELECT '===== ALL PUBLIC SCHEMA FUNCTIONS =====' as section;
SELECT 
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as arguments,
  t.typname as return_type,
  CASE 
    WHEN p.prokind = 'f' THEN 'Function'
    WHEN p.prokind = 'p' THEN 'Procedure'
    WHEN p.prokind = 'a' THEN 'Aggregate'
    WHEN p.prokind = 'w' THEN 'Window'
  END as type,
  obj_description(p.oid, 'pg_proc') as description
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
JOIN pg_type t ON p.prorettype = t.oid
WHERE n.nspname = 'public'
ORDER BY p.proname;

-- 2. FUNCTIONS GROUPED BY CATEGORY (based on name patterns)
SELECT '===== FUNCTIONS BY CATEGORY =====' as section;
SELECT 
  CASE 
    WHEN proname LIKE '%order%' THEN '📦 Orders'
    WHEN proname LIKE '%customer%' THEN '👤 Customers'
    WHEN proname LIKE '%product%' THEN '📱 Products'
    WHEN proname LIKE '%cart%' THEN '🛒 Cart'
    WHEN proname LIKE '%payment%' OR proname LIKE '%stripe%' THEN '💳 Payments'
    WHEN proname LIKE '%dashboard%' OR proname LIKE '%stats%' OR proname LIKE '%metric%' THEN '📊 Dashboard/Stats'
    WHEN proname LIKE '%inventory%' THEN '📦 Inventory'
    WHEN proname LIKE '%search%' THEN '🔍 Search'
    WHEN proname LIKE '%auth%' OR proname LIKE '%user%' THEN '🔐 Auth/Users'
    WHEN proname LIKE '%email%' OR proname LIKE '%notification%' THEN '📧 Email/Notifications'
    WHEN proname LIKE '%review%' OR proname LIKE '%rating%' THEN '⭐ Reviews'
    WHEN proname LIKE '%shipping%' THEN '🚚 Shipping'
    WHEN proname LIKE '%tax%' THEN '💰 Tax'
    WHEN proname LIKE '%report%' OR proname LIKE '%analytics%' THEN '📈 Reports/Analytics'
    WHEN proname LIKE '%admin%' THEN '👨‍💼 Admin'
    ELSE '🔧 Other/Utility'
  END as category,
  COUNT(*) as function_count,
  string_agg(proname, ', ' ORDER BY proname) as function_names
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
GROUP BY category
ORDER BY category;

-- 3. DUPLICATE FUNCTIONS (same name, different signatures)
SELECT '===== DUPLICATE FUNCTION NAMES (OVERLOADED) =====' as section;
SELECT 
  proname as function_name,
  COUNT(*) as version_count,
  string_agg(pg_get_function_identity_arguments(oid), ' | ' ORDER BY pronargs) as different_signatures
FROM pg_proc
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
GROUP BY proname
HAVING COUNT(*) > 1
ORDER BY version_count DESC, proname;

-- 4. FUNCTIONS THAT MIGHT BE CAUSING ISSUES
SELECT '===== POTENTIALLY PROBLEMATIC FUNCTIONS =====' as section;
SELECT 
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as arguments,
  CASE
    WHEN p.proname = 'get_recent_orders' THEN '⚠️ Multiple versions might exist'
    WHEN p.proname = 'transfer_guest_cart' THEN '⚠️ References cart_items table'
    WHEN p.proname LIKE '%customer%' AND prosrc LIKE '%customer_id%' THEN '⚠️ References customer_id column'
    WHEN prosrc LIKE '%LEFT JOIN customers%' THEN '⚠️ Joins with customers table'
    ELSE 'Check implementation'
  END as potential_issue
FROM pg_proc p
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  AND (
    proname IN ('get_recent_orders', 'transfer_guest_cart', 'get_dashboard_stats')
    OR prosrc LIKE '%customer_id%'
    OR prosrc LIKE '%reviews%'
    OR prosrc LIKE '%cart_items%'
  )
ORDER BY p.proname;

-- 5. RECENTLY CREATED FUNCTIONS (last 30 days)
SELECT '===== RECENTLY CREATED/MODIFIED FUNCTIONS =====' as section;
SELECT 
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as arguments,
  obj_description(p.oid, 'pg_proc') as description
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  -- Note: PostgreSQL doesn't track creation time, so we'll look for common recent function names
  AND p.proname IN (
    'get_recent_orders', 'transfer_guest_cart', 'get_dashboard_stats',
    'get_dashboard_stats_optimized', 'get_admin_products_paginated',
    'refresh_admin_products_summary', 'get_product_counts', 'get_recent_activity'
  )
ORDER BY p.proname;

-- 6. FUNCTIONS WITH COMPLEX DEPENDENCIES
SELECT '===== FUNCTIONS WITH TABLE DEPENDENCIES =====' as section;
WITH function_dependencies AS (
  SELECT DISTINCT
    p.proname as function_name,
    c.relname as depends_on_table
  FROM pg_proc p
  JOIN pg_depend d ON d.objid = p.oid
  JOIN pg_class c ON c.oid = d.refobjid
  WHERE p.pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    AND c.relkind = 'r' -- regular tables only
    AND c.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
)
SELECT 
  function_name,
  COUNT(*) as table_count,
  string_agg(depends_on_table, ', ' ORDER BY depends_on_table) as tables_used
FROM function_dependencies
GROUP BY function_name
ORDER BY table_count DESC, function_name;

-- 7. FUNCTION RETURN TYPES
SELECT '===== FUNCTION RETURN TYPES =====' as section;
SELECT 
  t.typname as return_type,
  COUNT(*) as function_count,
  string_agg(p.proname, ', ' ORDER BY p.proname) as function_names
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
JOIN pg_type t ON p.prorettype = t.oid
WHERE n.nspname = 'public'
GROUP BY t.typname
ORDER BY function_count DESC;

-- 8. FUNCTIONS THAT MIGHT NEED CLEANUP
SELECT '===== SUGGESTED CLEANUP ACTIONS =====' as section;
SELECT 
  'DROP FUNCTION IF EXISTS ' || oid::regprocedure || ';' as drop_command,
  proname as function_name,
  'Duplicate or potentially conflicting' as reason
FROM pg_proc
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  AND proname IN (
    SELECT proname 
    FROM pg_proc 
    WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
    GROUP BY proname 
    HAVING COUNT(*) > 1
  )
ORDER BY proname;

-- 9. COUNT SUMMARY
SELECT '===== SUMMARY STATISTICS =====' as section;
SELECT 
  'Total Functions' as metric,
  COUNT(*) as count
FROM pg_proc
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
UNION ALL
SELECT 
  'Functions with duplicates',
  COUNT(DISTINCT proname)
FROM pg_proc
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
GROUP BY proname
HAVING COUNT(*) > 1
UNION ALL
SELECT 
  'Tables referenced in functions',
  COUNT(DISTINCT c.relname)
FROM pg_proc p
JOIN pg_depend d ON d.objid = p.oid
JOIN pg_class c ON c.oid = d.refobjid
WHERE p.pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  AND c.relkind = 'r';

-- Final check
SELECT '✅ Function audit complete. Review the results above to identify issues.' as status;