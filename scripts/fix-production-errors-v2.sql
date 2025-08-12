-- Fix Production Errors v2
-- Run this in Supabase SQL Editor to fix the 400/404 errors

-- 1. Drop and recreate get_recent_orders function
DROP FUNCTION IF EXISTS get_recent_orders(integer);

CREATE OR REPLACE FUNCTION get_recent_orders(limit_count INT DEFAULT 10)
RETURNS TABLE (
  id UUID,
  order_number TEXT,
  customer_name TEXT,
  total_amount DECIMAL,
  status TEXT,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    o.id,
    o.order_number,
    COALESCE(c.name, c.email, 'Guest Customer') as customer_name,
    o.total_amount,
    o.status,
    o.created_at
  FROM orders o
  LEFT JOIN customers c ON c.id = o.customer_id
  ORDER BY o.created_at DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- 2. Create metrics table (404 error)
CREATE TABLE IF NOT EXISTS metrics (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  metric_name TEXT NOT NULL,
  metric_value DECIMAL,
  metric_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create logs table (404 error)  
CREATE TABLE IF NOT EXISTS logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  level TEXT,
  message TEXT,
  context JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Create product_variants table if missing (400 error)
CREATE TABLE IF NOT EXISTS product_variants (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  size TEXT,
  color TEXT,
  sku TEXT UNIQUE,
  price DECIMAL(10,2),
  inventory_quantity INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Create refund_requests table (401 error)
CREATE TABLE IF NOT EXISTS refund_requests (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID REFERENCES orders(id),
  amount DECIMAL(10,2),
  reason TEXT,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Add RLS policies for new tables (check if they exist first)
DO $$ 
BEGIN
  -- Enable RLS if not already enabled
  ALTER TABLE metrics ENABLE ROW LEVEL SECURITY;
  ALTER TABLE logs ENABLE ROW LEVEL SECURITY;
  ALTER TABLE refund_requests ENABLE ROW LEVEL SECURITY;
EXCEPTION
  WHEN OTHERS THEN NULL;
END $$;

-- 7. Create policies if they don't exist
DO $$
BEGIN
  -- Metrics policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'metrics' AND policyname = 'Users can read metrics'
  ) THEN
    CREATE POLICY "Users can read metrics" ON metrics
      FOR SELECT TO authenticated
      USING (true);
  END IF;

  -- Logs policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'logs' AND policyname = 'Users can read logs'
  ) THEN
    CREATE POLICY "Users can read logs" ON logs
      FOR SELECT TO authenticated
      USING (true);
  END IF;

  -- Refund requests policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'refund_requests' AND policyname = 'Users can read refund requests'
  ) THEN
    CREATE POLICY "Users can read refund requests" ON refund_requests
      FOR SELECT TO authenticated
      USING (true);
  END IF;
END $$;

-- 8. Grant necessary permissions
GRANT SELECT ON metrics TO authenticated;
GRANT SELECT ON logs TO authenticated;
GRANT SELECT ON refund_requests TO authenticated;
GRANT EXECUTE ON FUNCTION get_recent_orders TO authenticated;

-- 9. Insert some sample data to avoid empty tables
INSERT INTO metrics (metric_name, metric_value) 
VALUES ('total_orders', 0), ('total_revenue', 0)
ON CONFLICT DO NOTHING;

-- Success message
SELECT 'Production errors fixed!' as status;