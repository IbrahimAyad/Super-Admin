-- CHECK ROW LEVEL SECURITY POLICIES
-- This might be limiting which products are visible

-- 1. Check if RLS is enabled on products table
SELECT 
    tablename,
    rowsecurity,
    CASE 
        WHEN rowsecurity THEN '⚠️ RLS ENABLED - Policies apply!'
        ELSE '✅ RLS DISABLED - All rows visible'
    END as status
FROM pg_tables
WHERE schemaname = 'public' 
    AND tablename IN ('products', 'product_variants', 'product_images');

-- 2. Check existing policies on products table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'products';

-- 3. Check if anon role can see all products
SELECT 
    'Anon Role Visibility Test' as test,
    COUNT(*) as total_products,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active_products,
    COUNT(CASE WHEN status = 'draft' THEN 1 END) as draft_products
FROM products;

-- 4. Check for any filters in the database
SELECT 
    status,
    visibility,
    COUNT(*) as product_count
FROM products
GROUP BY status, visibility
ORDER BY product_count DESC;

-- 5. Check if there's a limit in any views
SELECT 
    viewname,
    definition
FROM pg_views
WHERE schemaname = 'public'
    AND definition LIKE '%product%'
    AND definition LIKE '%LIMIT%';