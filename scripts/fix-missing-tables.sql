-- Fix Missing Tables Script
-- Run this in Supabase SQL Editor to create missing tables

-- Create admin_users table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.admin_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  role TEXT DEFAULT 'admin',
  permissions JSONB DEFAULT '["all"]'::jsonb,
  is_active BOOLEAN DEFAULT true,
  two_factor_enabled BOOLEAN DEFAULT false,
  two_factor_secret TEXT,
  last_login TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create stripe_sync_log table
CREATE TABLE IF NOT EXISTS public.stripe_sync_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sync_type TEXT NOT NULL,
  status TEXT NOT NULL,
  details JSONB,
  error_message TEXT,
  synced_count INTEGER DEFAULT 0,
  failed_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- Enable RLS on admin_users
ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for admin_users
CREATE POLICY "Admin users can view their own record" ON public.admin_users
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage all admin users" ON public.admin_users
  FOR ALL USING (auth.jwt()->>'role' = 'service_role');

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_admin_users_email ON public.admin_users(email);
CREATE INDEX IF NOT EXISTS idx_admin_users_user_id ON public.admin_users(user_id);
CREATE INDEX IF NOT EXISTS idx_stripe_sync_log_created ON public.stripe_sync_log(created_at DESC);

-- Create your first admin user (replace with your email)
-- First, make sure you have a user in auth.users
DO $$
BEGIN
  -- Check if admin_users table is empty
  IF NOT EXISTS (SELECT 1 FROM public.admin_users LIMIT 1) THEN
    -- Try to create an admin from existing auth users
    INSERT INTO public.admin_users (user_id, email, role, permissions, is_active)
    SELECT 
      id,
      email,
      'super_admin',
      '["all"]'::jsonb,
      true
    FROM auth.users
    WHERE email = 'ibrahimayad13@gmail.com'  -- Replace with your email
    ON CONFLICT (email) DO NOTHING;
    
    RAISE NOTICE 'Admin user created for ibrahimayad13@gmail.com';
  END IF;
END $$;

-- Verify the tables were created
SELECT 
  'admin_users' as table_name,
  COUNT(*) as record_count
FROM public.admin_users
UNION ALL
SELECT 
  'stripe_sync_log' as table_name,
  COUNT(*) as record_count
FROM public.stripe_sync_log;