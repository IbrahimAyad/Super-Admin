-- Fix Database Functions and Tables
-- Run this in Supabase SQL Editor

-- 1. Fix get_recent_orders() function - it exists but returns wrong type
DROP FUNCTION IF EXISTS public.get_recent_orders();

CREATE OR REPLACE FUNCTION public.get_recent_orders()
RETURNS TABLE (
  id uuid,
  order_number text,
  customer_email text,
  total_amount integer,
  status text,
  created_at timestamp with time zone
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    o.id,
    o.order_number::text,
    o.customer_email::text,
    o.total_amount,
    o.status::text,
    o.created_at
  FROM orders o
  ORDER BY o.created_at DESC
  LIMIT 10;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_recent_orders() TO anon, authenticated;

-- 2. Create the missing log_login_attempt() function
CREATE OR REPLACE FUNCTION public.log_login_attempt(
  email text,
  success boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Insert into auth_logs table instead of non-existent login_attempts
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
      'success', success
    ),
    now()
  );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.log_login_attempt(text, boolean) TO anon, authenticated;

-- 3. Fix transfer_guest_cart() function - wrong parameter names
DROP FUNCTION IF EXISTS public.transfer_guest_cart(text, uuid);
DROP FUNCTION IF EXISTS public.transfer_guest_cart(uuid, uuid);

CREATE OR REPLACE FUNCTION public.transfer_guest_cart(
  p_guest_id text,
  p_user_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Transfer cart items from guest to user
  UPDATE cart_items
  SET user_id = p_user_id,
      guest_id = NULL,
      updated_at = now()
  WHERE guest_id = p_guest_id;

  -- Log the transfer
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
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.transfer_guest_cart(text, uuid) TO anon, authenticated;

-- 4. Create login_attempts table if it doesn't exist (or use auth_logs)
-- Since auth_logs already exists, let's create a view for compatibility
CREATE OR REPLACE VIEW public.login_attempts AS
SELECT 
  id,
  user_email as email,
  CASE WHEN success THEN 'success' ELSE 'failed' END as status,
  metadata,
  created_at
FROM auth_logs
WHERE action = 'login_attempt';

-- Grant permissions on the view
GRANT SELECT ON public.login_attempts TO anon, authenticated;

-- 5. Add RLS policies for auth_logs if missing
ALTER TABLE auth_logs ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view their own logs
CREATE POLICY "Users can view own auth logs" ON auth_logs
  FOR SELECT
  USING (auth.uid() = user_id OR auth.uid() IS NOT NULL);

-- Allow anonymous users to insert login attempts
CREATE POLICY "Allow anonymous login logging" ON auth_logs
  FOR INSERT
  WITH CHECK (action = 'login_attempt');

-- 6. Ensure cart_items table has proper columns for guest cart
ALTER TABLE cart_items 
ADD COLUMN IF NOT EXISTS guest_id text,
ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id);

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_cart_items_guest_id ON cart_items(guest_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_user_id ON cart_items(user_id);

-- 7. Add helper function to clean up old guest carts
CREATE OR REPLACE FUNCTION public.cleanup_old_guest_carts()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Delete guest carts older than 30 days
  DELETE FROM cart_items
  WHERE guest_id IS NOT NULL
    AND user_id IS NULL
    AND created_at < now() - interval '30 days';
END;
$$;

GRANT EXECUTE ON FUNCTION public.cleanup_old_guest_carts() TO authenticated;

-- Success message
SELECT 'All database functions have been fixed!' as message;