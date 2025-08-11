-- =====================================================
-- FIX DASHBOARD RPC FUNCTIONS AND PERMISSIONS (V2)
-- Fixed version without generated columns
-- =====================================================

-- 1. Drop and recreate inventory table without generated column
DROP TABLE IF EXISTS inventory CASCADE;

CREATE TABLE inventory (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  quantity INTEGER DEFAULT 0,
  reserved_quantity INTEGER DEFAULT 0,
  available_quantity INTEGER DEFAULT 0, -- Regular column, not generated
  low_stock_threshold INTEGER DEFAULT 10,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create function to update available_quantity
CREATE OR REPLACE FUNCTION update_available_quantity()
RETURNS TRIGGER AS $$
BEGIN
  NEW.available_quantity = NEW.quantity - NEW.reserved_quantity;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Create trigger to auto-update available_quantity
CREATE TRIGGER update_inventory_available
BEFORE INSERT OR UPDATE ON inventory
FOR EACH ROW
EXECUTE FUNCTION update_available_quantity();

-- 4. Create vendors table if it doesn't exist
CREATE TABLE IF NOT EXISTS vendors (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  phone VARCHAR(50),
  address TEXT,
  dropship_enabled BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Create metrics table if it doesn't exist
CREATE TABLE IF NOT EXISTS metrics (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  metric_name VARCHAR(100) NOT NULL,
  metric_value JSONB,
  metric_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Create logs table if it doesn't exist
CREATE TABLE IF NOT EXISTS logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  log_type VARCHAR(50),
  log_level VARCHAR(20),
  message TEXT,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Drop existing functions to recreate them
DROP FUNCTION IF EXISTS get_dashboard_stats();
DROP FUNCTION IF EXISTS get_recent_orders(integer);
DROP FUNCTION IF EXISTS get_low_stock_products(integer);

-- 8. Create get_dashboard_stats function
CREATE OR REPLACE FUNCTION get_dashboard_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'orders', json_build_object(
      'total', (SELECT COUNT(*) FROM orders),
      'pending', (SELECT COUNT(*) FROM orders WHERE status = 'pending'),
      'processing', (SELECT COUNT(*) FROM orders WHERE status = 'processing'),
      'completed', (SELECT COUNT(*) FROM orders WHERE status = 'completed')
    ),
    'revenue', json_build_object(
      'total', COALESCE((SELECT SUM(total_amount) FROM orders WHERE payment_status = 'paid'), 0),
      'today', COALESCE((SELECT SUM(total_amount) FROM orders WHERE payment_status = 'paid' AND DATE(created_at) = CURRENT_DATE), 0),
      'month', COALESCE((SELECT SUM(total_amount) FROM orders WHERE payment_status = 'paid' AND DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE)), 0)
    ),
    'customers', json_build_object(
      'total', (SELECT COUNT(*) FROM customers),
      'new_today', (SELECT COUNT(*) FROM customers WHERE DATE(created_at) = CURRENT_DATE),
      'new_month', (SELECT COUNT(*) FROM customers WHERE DATE_TRUNC('month', created_at) = DATE_TRUNC('month', CURRENT_DATE))
    ),
    'products', json_build_object(
      'total', (SELECT COUNT(*) FROM products),
      'active', (SELECT COUNT(*) FROM products WHERE status = 'active'),
      'low_stock', (SELECT COUNT(*) FROM inventory WHERE available_quantity < low_stock_threshold)
    )
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Create get_recent_orders function
CREATE OR REPLACE FUNCTION get_recent_orders(limit_count INTEGER DEFAULT 5)
RETURNS TABLE (
  id UUID,
  order_number VARCHAR,
  total_amount DECIMAL,
  status VARCHAR,
  payment_status VARCHAR,
  created_at TIMESTAMP WITH TIME ZONE,
  customer_email VARCHAR,
  customer_name VARCHAR
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    o.id,
    o.order_number,
    o.total_amount,
    o.status,
    o.payment_status,
    o.created_at,
    COALESCE(c.email, o.customer_email, o.guest_email, 'Unknown')::VARCHAR as customer_email,
    COALESCE(c.name, CONCAT(c.first_name, ' ', c.last_name), o.customer_name, 'Unknown')::VARCHAR as customer_name
  FROM orders o
  LEFT JOIN customers c ON o.customer_id = c.id
  ORDER BY o.created_at DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Create get_low_stock_products function
CREATE OR REPLACE FUNCTION get_low_stock_products(threshold INTEGER DEFAULT 10)
RETURNS TABLE (
  id UUID,
  product_name VARCHAR,
  sku VARCHAR,
  stock_level INTEGER,
  reserved_quantity INTEGER,
  available_quantity INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.name::VARCHAR as product_name,
    p.sku::VARCHAR,
    COALESCE(i.quantity, 0)::INTEGER as stock_level,
    COALESCE(i.reserved_quantity, 0)::INTEGER as reserved_quantity,
    COALESCE(i.available_quantity, 0)::INTEGER as available_quantity
  FROM products p
  LEFT JOIN inventory i ON p.id = i.product_id
  WHERE COALESCE(i.available_quantity, 0) < threshold
     OR i.id IS NULL  -- Include products with no inventory record
  ORDER BY COALESCE(i.available_quantity, 0) ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. Grant permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON products TO authenticated;
GRANT INSERT, UPDATE, DELETE ON orders TO authenticated;
GRANT INSERT, UPDATE, DELETE ON customers TO authenticated;
GRANT INSERT, UPDATE, DELETE ON inventory TO authenticated;
GRANT INSERT, UPDATE, DELETE ON vendors TO authenticated;
GRANT INSERT, UPDATE, DELETE ON metrics TO authenticated;
GRANT INSERT, UPDATE, DELETE ON logs TO authenticated;

-- Grant EXECUTE on functions
GRANT EXECUTE ON FUNCTION get_dashboard_stats() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_recent_orders(integer) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_low_stock_products(integer) TO anon, authenticated;

-- 12. Create indexes
CREATE INDEX IF NOT EXISTS idx_inventory_product_id ON inventory(product_id);
CREATE INDEX IF NOT EXISTS idx_inventory_available ON inventory(available_quantity);
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON orders(payment_status);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);

-- 13. Populate inventory for existing products
INSERT INTO inventory (product_id, quantity, reserved_quantity, available_quantity, low_stock_threshold)
SELECT 
  p.id,
  COALESCE(p.stock_quantity, 100) as quantity,
  0 as reserved_quantity,
  COALESCE(p.stock_quantity, 100) as available_quantity,
  10 as low_stock_threshold
FROM products p
LEFT JOIN inventory i ON p.id = i.product_id
WHERE i.id IS NULL;

-- 14. Test the functions
SELECT get_dashboard_stats();

-- Success message
SELECT 'Dashboard functions and permissions fixed successfully!' as status;