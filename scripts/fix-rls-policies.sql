-- Fix RLS Policies for Admin Users Table
-- Run this in Supabase SQL Editor

-- First, let's check if RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename = 'admin_users';

-- Temporarily disable RLS to allow anon access for reading
ALTER TABLE public.admin_users DISABLE ROW LEVEL SECURITY;

-- Or if you want to keep RLS but make it readable:
-- ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Admin users can view their own record" ON public.admin_users;
DROP POLICY IF EXISTS "Service role can manage all admin users" ON public.admin_users;

-- Create new policies that allow reading
CREATE POLICY "Anyone can read admin users" ON public.admin_users
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can update their own record" ON public.admin_users
  FOR UPDATE USING (auth.uid() = user_id);

-- Verify your admin user exists
SELECT 
  id,
  email,
  role,
  permissions,
  is_active,
  user_id
FROM public.admin_users;

-- Also check stripe_sync_log
ALTER TABLE public.stripe_sync_log DISABLE ROW LEVEL SECURITY;