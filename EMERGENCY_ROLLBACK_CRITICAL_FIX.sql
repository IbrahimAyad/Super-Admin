-- ============================================
-- EMERGENCY ROLLBACK FOR CRITICAL DATABASE FIXES
-- Use this if the main fix causes issues
-- ============================================

\echo '=== EMERGENCY ROLLBACK STARTING ==='

-- 1. Drop the policies we created (in reverse order)
DROP POLICY IF EXISTS "admin_sessions_admin_access" ON public.admin_sessions;
DROP POLICY IF EXISTS "admin_users_admin_access" ON public.admin_users;

DROP POLICY IF EXISTS "product_variants_delete_admin" ON public.product_variants;
DROP POLICY IF EXISTS "product_variants_update_admin" ON public.product_variants;
DROP POLICY IF EXISTS "product_variants_insert_admin" ON public.product_variants;
DROP POLICY IF EXISTS "product_variants_select_all" ON public.product_variants;

DROP POLICY IF EXISTS "product_images_delete_admin" ON public.product_images;
DROP POLICY IF EXISTS "product_images_update_admin" ON public.product_images;
DROP POLICY IF EXISTS "product_images_insert_admin" ON public.product_images;
DROP POLICY IF EXISTS "product_images_select_all" ON public.product_images;

DROP POLICY IF EXISTS "products_delete_admin" ON public.products;
DROP POLICY IF EXISTS "products_update_admin" ON public.products;
DROP POLICY IF EXISTS "products_insert_admin" ON public.products;
DROP POLICY IF EXISTS "products_select_all" ON public.products;

-- 2. Temporarily disable RLS to allow recovery
ALTER TABLE public.products DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_images DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_variants DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_sessions DISABLE ROW LEVEL SECURITY;

\echo '=== RLS DISABLED FOR RECOVERY ==='

-- 3. Create minimal permissive policies for emergency access
CREATE POLICY "emergency_products_access" ON public.products FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "emergency_images_access" ON public.product_images FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "emergency_variants_access" ON public.product_variants FOR ALL USING (true) WITH CHECK (true);

-- 4. Re-enable RLS with emergency policies
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_variants ENABLE ROW LEVEL SECURITY;

\echo '=== EMERGENCY ACCESS POLICIES CREATED ==='

-- 5. Show current state
SELECT 'Emergency Rollback Status' as info;
SELECT 
    tablename,
    COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('products', 'product_images', 'product_variants')
GROUP BY tablename;

\echo '=== EMERGENCY ROLLBACK COMPLETE ==='
\echo 'System is now in emergency access mode.'
\echo 'All authenticated users have full access to core tables.'
\echo 'Please fix the underlying issues and re-apply proper RLS policies.'