-- COMPREHENSIVE ADMIN AUTHENTICATION FIX
-- Fixes circular RLS dependency and authentication issues
-- Run this in Supabase SQL editor

-- Step 1: Temporarily disable RLS to fix everything
ALTER TABLE public.admin_users DISABLE ROW LEVEL SECURITY;

-- Step 2: Show current admin users
SELECT 'Current admin users before fix:' as status;
SELECT 
    au.id,
    au.user_id,
    au.role,
    au.is_active,
    u.email as user_email
FROM admin_users au
LEFT JOIN auth.users u ON au.user_id = u.id
ORDER BY au.created_at;

-- Step 3: Re-enable RLS
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

-- Step 4: Drop ALL existing policies to prevent conflicts
DO $$ 
DECLARE
    pol record;
BEGIN
    FOR pol IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'admin_users' 
        AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.admin_users', pol.policyname);
        RAISE NOTICE 'Dropped policy: %', pol.policyname;
    END LOOP;
END $$;

-- Step 5: Create simple, non-circular policies

-- Policy 1: Service role can do everything (admin operations)
CREATE POLICY "service_role_full_access" ON public.admin_users
    FOR ALL
    USING (auth.jwt() ->> 'role' = 'service_role')
    WITH CHECK (auth.jwt() ->> 'role' = 'service_role');

-- Policy 2: Allow reading admin status for authentication checks
-- This breaks the circular dependency by allowing basic reads
CREATE POLICY "allow_admin_status_check" ON public.admin_users
    FOR SELECT
    USING (
        -- Allow if service role
        auth.jwt() ->> 'role' = 'service_role'
        OR
        -- Allow authenticated users to read their own admin record
        (auth.uid() IS NOT NULL AND user_id = auth.uid())
        OR
        -- Allow basic admin status checks (this prevents circular dependency)
        (auth.uid() IS NOT NULL AND is_active = true)
    );

-- Policy 3: Authenticated users can view their own admin record
CREATE POLICY "users_own_admin_record" ON public.admin_users
    FOR SELECT
    USING (auth.uid() = user_id);

-- Step 6: Grant proper permissions
GRANT ALL ON public.admin_users TO service_role;
GRANT SELECT ON public.admin_users TO authenticated;
GRANT SELECT ON public.admin_users TO anon; -- Minimal read access for auth checks

-- Step 7: Test the fix
SELECT 'Testing admin_users access after fix:' as test_status;

-- Test 1: Can we count admin users?
SELECT COUNT(*) as total_admin_users FROM admin_users;

-- Test 2: Can we see admin users with details?
SELECT 
    id,
    role,
    is_active,
    created_at
FROM admin_users 
WHERE is_active = true;

-- Step 8: Show final policies
SELECT 'Final RLS policies:' as policy_status;
SELECT 
    policyname, 
    cmd as policy_type,
    CASE 
        WHEN cmd = 'SELECT' THEN 'Read operations'
        WHEN cmd = 'INSERT' THEN 'Create operations'
        WHEN cmd = 'UPDATE' THEN 'Update operations'
        WHEN cmd = 'DELETE' THEN 'Delete operations'
        WHEN cmd = 'ALL' THEN 'All operations'
    END as description
FROM pg_policies 
WHERE tablename = 'admin_users' 
AND schemaname = 'public'
ORDER BY cmd;

-- Step 9: Verify service role access
SELECT 'Service role verification:' as verification;
SELECT 
    rolname,
    rolsuper,
    rolcreaterole,
    rolcreatedb
FROM pg_roles 
WHERE rolname IN ('service_role', 'authenticated', 'anon');

-- Step 10: Create admin user if needed
-- First, check if admin exists
SELECT 'Checking for existing admin users:' as admin_check;
SELECT 
    u.email,
    u.id as auth_user_id,
    au.role,
    au.is_active
FROM auth.users u
LEFT JOIN admin_users au ON u.id = au.user_id
WHERE u.email LIKE '%admin%' OR au.role = 'super_admin';

-- Step 11: Instructions for creating admin user
SELECT '
=== ADMIN USER CREATION ===
If no admin user exists, run this script locally:
npx tsx create-admin-directly.ts

Or manually create one:
1. Find your user ID from auth.users
2. Insert into admin_users table using service role

=== AUTHENTICATION ARCHITECTURE ===
✅ Public client (anon key): User auth, public data
✅ Admin client (service key): Admin operations, bypasses RLS
✅ Non-circular RLS: Basic reads allowed, admin ops use service role

=== TROUBLESHOOTING ===
- 401 errors: Check if using correct client (admin vs public)
- Permission denied: Verify admin record exists and is_active=true
- Circular dependency: Fixed by allowing basic reads to all authenticated users
' as instructions;