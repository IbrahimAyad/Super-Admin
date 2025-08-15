-- ================================================================
-- FIX ADMIN PANEL PERFORMANCE ISSUES
-- Run this AFTER the FIX-ADMIN-PANEL-ERRORS-CLEAN.sql
-- ================================================================

-- 1. ADD CRITICAL INDEXES FOR PRODUCT QUERIES
CREATE INDEX IF NOT EXISTS idx_products_status ON products(status);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON products(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_price ON products(price);
CREATE INDEX IF NOT EXISTS idx_products_inventory ON products(inventory_quantity);

-- Composite index for common admin queries
CREATE INDEX IF NOT EXISTS idx_products_status_created ON products(status, created_at DESC);

-- 2. ADD INDEXES FOR ORDERS
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON orders(payment_status);

-- 3. ADD INDEXES FOR CUSTOMERS
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_created_at ON customers(created_at DESC);

-- 4. OPTIMIZE PRODUCT QUERIES WITH MATERIALIZED VIEW
CREATE MATERIALIZED VIEW IF NOT EXISTS admin_products_summary AS
SELECT 
  p.id,
  p.name,
  p.slug,
  p.category,
  p.price,
  p.status,
  p.inventory_quantity,
  p.primary_image,
  p.created_at,
  p.updated_at,
  COUNT(DISTINCT pv.id) as variant_count,
  COALESCE(SUM(pv.inventory_quantity), p.inventory_quantity) as total_inventory
FROM products p
LEFT JOIN product_variants pv ON pv.product_id = p.id
GROUP BY p.id;

-- Create index on materialized view
CREATE UNIQUE INDEX IF NOT EXISTS idx_admin_products_summary_id ON admin_products_summary(id);
CREATE INDEX IF NOT EXISTS idx_admin_products_summary_status ON admin_products_summary(status);
CREATE INDEX IF NOT EXISTS idx_admin_products_summary_category ON admin_products_summary(category);

-- 5. CREATE FUNCTION FOR REFRESHING MATERIALIZED VIEW
CREATE OR REPLACE FUNCTION refresh_admin_products_summary()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY admin_products_summary;
END;
$$ LANGUAGE plpgsql;

-- 6. CREATE OPTIMIZED DASHBOARD STATS FUNCTION
CREATE OR REPLACE FUNCTION get_dashboard_stats_optimized()
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_customers', (SELECT COUNT(*) FROM customers),
    'total_orders', (SELECT COUNT(*) FROM orders),
    'total_products', (SELECT COUNT(*) FROM products WHERE status = 'active'),
    'total_revenue', (SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE payment_status = 'paid'),
    'orders_today', (SELECT COUNT(*) FROM orders WHERE DATE(created_at) = CURRENT_DATE),
    'revenue_today', (SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE DATE(created_at) = CURRENT_DATE AND payment_status = 'paid'),
    'pending_orders', (SELECT COUNT(*) FROM orders WHERE status = 'pending'),
    'low_stock_products', (SELECT COUNT(*) FROM products WHERE inventory_quantity < 10 AND status = 'active')
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 7. CREATE PAGINATED PRODUCTS FUNCTION FOR ADMIN
CREATE OR REPLACE FUNCTION get_admin_products_paginated(
  page_size INT DEFAULT 50,
  page_number INT DEFAULT 1,
  search_term TEXT DEFAULT NULL,
  filter_category TEXT DEFAULT NULL,
  filter_status TEXT DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  slug TEXT,
  category TEXT,
  price DECIMAL,
  status TEXT,
  inventory_quantity INTEGER,
  primary_image TEXT,
  created_at TIMESTAMPTZ,
  total_count BIGINT
) AS $$
DECLARE
  offset_value INT;
  total_count BIGINT;
BEGIN
  offset_value := (page_number - 1) * page_size;
  
  -- Get total count
  SELECT COUNT(*) INTO total_count
  FROM products p
  WHERE (search_term IS NULL OR p.name ILIKE '%' || search_term || '%')
    AND (filter_category IS NULL OR p.category = filter_category)
    AND (filter_status IS NULL OR p.status = filter_status);
  
  -- Return paginated results
  RETURN QUERY
  SELECT 
    p.id,
    p.name,
    p.slug,
    p.category,
    p.price,
    p.status,
    p.inventory_quantity,
    p.primary_image,
    p.created_at,
    total_count
  FROM products p
  WHERE (search_term IS NULL OR p.name ILIKE '%' || search_term || '%')
    AND (filter_category IS NULL OR p.category = filter_category)
    AND (filter_status IS NULL OR p.status = filter_status)
  ORDER BY p.created_at DESC
  LIMIT page_size
  OFFSET offset_value;
END;
$$ LANGUAGE plpgsql;

-- 8. GRANT PERMISSIONS
GRANT SELECT ON admin_products_summary TO authenticated;
GRANT EXECUTE ON FUNCTION refresh_admin_products_summary TO authenticated;
GRANT EXECUTE ON FUNCTION get_dashboard_stats_optimized TO authenticated;
GRANT EXECUTE ON FUNCTION get_admin_products_paginated TO authenticated;

-- 9. REFRESH THE MATERIALIZED VIEW
REFRESH MATERIALIZED VIEW admin_products_summary;

-- 10. ANALYZE TABLES FOR QUERY PLANNER
ANALYZE products;
ANALYZE orders;
ANALYZE customers;
ANALYZE product_variants;

-- Success
SELECT 'Performance optimizations applied!' as status;