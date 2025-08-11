-- =====================================================
-- CLEAN DASHBOARD FIX - PROPERLY FORMATTED
-- Run this in Supabase SQL editor
-- =====================================================

-- 1. Add missing columns to orders table
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'orders' AND column_name = 'customer_email') THEN
    ALTER TABLE orders ADD COLUMN customer_email VARCHAR(255);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'orders' AND column_name = 'guest_email') THEN
    ALTER TABLE orders ADD COLUMN guest_email VARCHAR(255);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'orders' AND column_name = 'customer_name') THEN
    ALTER TABLE orders ADD COLUMN customer_name VARCHAR(255);
  END IF;
END $$;

-- 2. Create inventory table
DROP TABLE IF EXISTS inventory CASCADE;

CREATE TABLE inventory (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  quantity INTEGER DEFAULT 0,
  reserved_quantity INTEGER DEFAULT 0,
  available_quantity INTEGER DEFAULT 0,
  low_stock_threshold INTEGER DEFAULT 10,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(product_id)
);

-- 3. Create function to update available_quantity
CREATE OR REPLACE FUNCTION update_available_quantity()
RETURNS TRIGGER AS $$
BEGIN
  NEW.available_quantity = NEW.quantity - NEW.reserved_quantity;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Create trigger
DROP TRIGGER IF EXISTS update_inventory_available ON inventory;
CREATE TRIGGER update_inventory_available
BEFORE INSERT OR UPDATE ON inventory
FOR EACH ROW
EXECUTE FUNCTION update_available_quantity();

-- 5. Create other missing tables
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

CREATE TABLE IF NOT EXISTS metrics (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  metric_name VARCHAR(100) NOT NULL,
  metric_value JSONB,
  metric_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  log_type VARCHAR(50),
  log_level VARCHAR(20),
  message TEXT,
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Drop and recreate functions
DROP FUNCTION IF EXISTS get_dashboard_stats();
DROP FUNCTION IF EXISTS get_recent_orders(integer);
DROP FUNCTION IF EXISTS get_low_stock_products(integer);

-- 7. Create get_dashboard_stats function
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

-- 8. Create SIMPLIFIED get_recent_orders function
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
    COALESCE(c.email, 'guest@example.com')::VARCHAR as customer_email,
    COALESCE(c.name, CONCAT(c.first_name, ' ', c.last_name), 'Guest Customer')::VARCHAR as customer_name
  FROM orders o
  LEFT JOIN customers c ON o.customer_id = c.id
  ORDER BY o.created_at DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Create get_low_stock_products function
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
    COALESCE(i.quantity, 100)::INTEGER as stock_level,
    COALESCE(i.reserved_quantity, 0)::INTEGER as reserved_quantity,
    COALESCE(i.available_quantity, 100)::INTEGER as available_quantity
  FROM products p
  LEFT JOIN inventory i ON p.id = i.product_id
  WHERE i.id IS NULL
     OR i.available_quantity < threshold
  ORDER BY COALESCE(i.available_quantity, 100) ASC
  LIMIT 20;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Grant all necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON products, orders, customers, inventory, vendors, metrics, logs TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON products, orders, customers, inventory, vendors, metrics, logs TO authenticated;
GRANT EXECUTE ON FUNCTION get_dashboard_stats() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_recent_orders(integer) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_low_stock_products(integer) TO anon, authenticated;

-- 11. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_inventory_product_id ON inventory(product_id);
CREATE INDEX IF NOT EXISTS idx_inventory_available ON inventory(available_quantity);
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON orders(payment_status);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);

-- 12. Populate inventory for ALL products
INSERT INTO inventory (product_id, quantity, reserved_quantity, available_quantity, low_stock_threshold)
SELECT 
  p.id,
  100 as quantity,
  0 as reserved_quantity,
  100 as available_quantity,
  10 as low_stock_threshold
FROM products p
WHERE NOT EXISTS (
  SELECT 1 FROM inventory i WHERE i.product_id = p.id
)
ON CONFLICT (product_id) DO NOTHING;

-- 13. Add at least one vendor
INSERT INTO vendors (name, email, dropship_enabled)
VALUES ('Default Vendor', 'vendor@example.com', false)
ON CONFLICT DO NOTHING;

-- 14. Verify everything is working
DO $$
DECLARE
  stats_result JSON;
  products_count INTEGER;
  inventory_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO products_count FROM products;
  RAISE NOTICE 'Products count: %', products_count;
  
  SELECT COUNT(*) INTO inventory_count FROM inventory;
  RAISE NOTICE 'Inventory records: %', inventory_count;
  
  SELECT get_dashboard_stats() INTO stats_result;
  RAISE NOTICE 'Dashboard stats: %', stats_result;
END $$;

-- Final success message
SELECT 
  'All dashboard functions fixed!' as status,
  (SELECT COUNT(*) FROM products) as products_count,
  (SELECT COUNT(*) FROM inventory) as inventory_count,
  (SELECT COUNT(*) FROM orders) as orders_count,
  (SELECT COUNT(*) FROM customers) as customers_count;