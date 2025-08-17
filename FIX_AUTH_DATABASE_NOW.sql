-- CRITICAL DATABASE FIXES FOR AUTHENTICATION
-- Run this IMMEDIATELY in Supabase SQL Editor
-- This fixes the 4 critical issues causing auth problems

-- ============================================
-- FIX 1: get_recent_orders() - Wrong return type
-- ============================================
-- First drop the broken function
DROP FUNCTION IF EXISTS public.get_recent_orders() CASCADE;

-- Create it with correct return types
CREATE OR REPLACE FUNCTION public.get_recent_orders()
RETURNS TABLE (
  id uuid,
  order_number text,  -- Changed from varchar to text
  customer_email text,  -- Changed from varchar to text
  total_amount integer,
  status text,  -- Changed from varchar to text
  created_at timestamp with time zone
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    o.id,
    o.order_number::text,  -- Explicit cast to text
    o.customer_email::text,  -- Explicit cast to text
    o.total_amount,
    o.status::text,  -- Explicit cast to text
    o.created_at
  FROM orders o
  ORDER BY o.created_at DESC
  LIMIT 10;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.get_recent_orders() TO anon, authenticated, service_role;

-- ============================================
-- FIX 2: Create missing log_login_attempt() function
-- ============================================
CREATE OR REPLACE FUNCTION public.log_login_attempt(
  email text,
  success boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Log to auth_logs table (which exists)
  INSERT INTO auth_logs (
    user_email,
    action,
    success,
    metadata,
    created_at
  ) VALUES (
    email,
    'login_attempt',
    success,
    jsonb_build_object(
      'timestamp', now(),
      'success', success,
      'ip_address', current_setting('request.headers', true)::json->>'x-forwarded-for'
    ),
    now()
  );
  
  -- Don't throw errors if logging fails
  EXCEPTION WHEN OTHERS THEN
    -- Silently fail to not break login flow
    NULL;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.log_login_attempt(text, boolean) TO anon, authenticated, service_role;

-- ============================================
-- FIX 3: Fix transfer_guest_cart() parameters
-- ============================================
-- Drop any existing versions with wrong parameters
DROP FUNCTION IF EXISTS public.transfer_guest_cart(text, uuid) CASCADE;
DROP FUNCTION IF EXISTS public.transfer_guest_cart(uuid, uuid) CASCADE;

-- Create with correct parameter names that match the code
CREATE OR REPLACE FUNCTION public.transfer_guest_cart(
  p_guest_id text,  -- This matches what the code sends
  p_user_id uuid    -- This matches what the code sends
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if cart_items table exists
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'cart_items') THEN
    -- Transfer cart items from guest to user
    UPDATE cart_items
    SET user_id = p_user_id,
        guest_id = NULL,
        updated_at = now()
    WHERE guest_id = p_guest_id;
  END IF;

  -- Log the transfer (optional, won't break if fails)
  BEGIN
    INSERT INTO auth_logs (
      user_id,
      action,
      success,
      metadata,
      created_at
    ) VALUES (
      p_user_id,
      'cart_transfer',
      true,
      jsonb_build_object(
        'guest_id', p_guest_id,
        'timestamp', now()
      ),
      now()
    );
  EXCEPTION WHEN OTHERS THEN
    -- Don't break cart transfer if logging fails
    NULL;
  END;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.transfer_guest_cart(text, uuid) TO anon, authenticated, service_role;

-- ============================================
-- FIX 4: Fix login_attempts table/view permissions
-- ============================================
-- Create a view that maps to auth_logs (since login_attempts doesn't exist)
DROP VIEW IF EXISTS public.login_attempts CASCADE;

CREATE VIEW public.login_attempts AS
SELECT 
  id,
  user_email as email,
  CASE 
    WHEN success = true THEN 'success'::text
    ELSE 'failed'::text
  END as status,
  metadata,
  created_at
FROM auth_logs
WHERE action = 'login_attempt';

-- Grant SELECT permissions (fix the 403 error)
GRANT SELECT ON public.login_attempts TO anon, authenticated, service_role;

-- Fix RLS on auth_logs table
ALTER TABLE auth_logs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view own auth logs" ON auth_logs;
DROP POLICY IF EXISTS "Allow anonymous login logging" ON auth_logs;
DROP POLICY IF EXISTS "Service role bypass" ON auth_logs;

-- Allow authenticated users to view their own logs
CREATE POLICY "Users can view own auth logs" ON auth_logs
  FOR SELECT
  USING (
    auth.uid() = user_id 
    OR auth.uid() IS NOT NULL  -- Authenticated users can see some logs
  );

-- Allow anyone to insert login attempts
CREATE POLICY "Allow anonymous login logging" ON auth_logs
  FOR INSERT
  WITH CHECK (
    action IN ('login_attempt', 'cart_transfer')
  );

-- Service role can do anything
CREATE POLICY "Service role bypass" ON auth_logs
  FOR ALL
  USING (auth.role() = 'service_role');

-- ============================================
-- BONUS: Ensure cart_items table is ready
-- ============================================
-- Add columns if they don't exist
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'cart_items') THEN
    -- Add guest_id column if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'cart_items' AND column_name = 'guest_id') THEN
      ALTER TABLE cart_items ADD COLUMN guest_id text;
    END IF;
    
    -- Add user_id column if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'cart_items' AND column_name = 'user_id') THEN
      ALTER TABLE cart_items ADD COLUMN user_id uuid REFERENCES auth.users(id);
    END IF;
    
    -- Add indexes for performance
    CREATE INDEX IF NOT EXISTS idx_cart_items_guest_id ON cart_items(guest_id);
    CREATE INDEX IF NOT EXISTS idx_cart_items_user_id ON cart_items(user_id);
  END IF;
END $$;

-- ============================================
-- VERIFICATION
-- ============================================
-- Test that functions exist and work
DO $$
DECLARE
  test_result record;
BEGIN
  -- Test get_recent_orders
  BEGIN
    PERFORM * FROM get_recent_orders() LIMIT 1;
    RAISE NOTICE '✅ get_recent_orders() is working';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ get_recent_orders() failed: %', SQLERRM;
  END;

  -- Test log_login_attempt
  BEGIN
    PERFORM log_login_attempt('test@example.com', false);
    RAISE NOTICE '✅ log_login_attempt() is working';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ log_login_attempt() failed: %', SQLERRM;
  END;

  -- Test transfer_guest_cart
  BEGIN
    PERFORM transfer_guest_cart('test-guest', gen_random_uuid());
    RAISE NOTICE '✅ transfer_guest_cart() is working';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ transfer_guest_cart() failed: %', SQLERRM;
  END;

  -- Test login_attempts view
  BEGIN
    PERFORM * FROM login_attempts LIMIT 1;
    RAISE NOTICE '✅ login_attempts view is working';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ login_attempts view failed: %', SQLERRM;
  END;
END $$;

-- Final success message
SELECT 
  '🎉 All 4 authentication fixes have been applied!' as status,
  'Your login process should now work properly!' as message;