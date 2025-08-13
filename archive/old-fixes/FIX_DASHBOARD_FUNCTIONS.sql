-- Fix get_recent_orders to handle missing customers table
DROP FUNCTION IF EXISTS get_recent_orders(INTEGER);

CREATE OR REPLACE FUNCTION get_recent_orders(limit_count INTEGER DEFAULT 5)
RETURNS TABLE (
  id UUID,
  order_number TEXT,
  customer_name TEXT,
  total_amount INTEGER,
  status TEXT,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    o.id,
    COALESCE(o.order_number, o.id::TEXT) as order_number,
    COALESCE(
      o.customer_email, 
      o.customer_name,
      'Guest'
    ) as customer_name,
    COALESCE(o.total_amount, 0)::INTEGER as total_amount,
    COALESCE(o.status, 'pending') as status,
    o.created_at
  FROM orders o
  ORDER BY o.created_at DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Grant permission
GRANT EXECUTE ON FUNCTION get_recent_orders(INTEGER) TO authenticated;

-- Test the function
SELECT * FROM get_recent_orders(5);