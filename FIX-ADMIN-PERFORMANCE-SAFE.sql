-- ================================================================
-- FIX ADMIN PANEL PERFORMANCE - SAFE VERSION
-- Run this AFTER the FIX-ADMIN-PANEL-SAFE.sql
-- ================================================================

-- 1. ADD INDEXES FOR PRODUCTS (only if they don't exist)
CREATE INDEX IF NOT EXISTS idx_products_status ON products(status);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON products(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_price ON products(price);
CREATE INDEX IF NOT EXISTS idx_products_inventory ON products(inventory_quantity);
CREATE INDEX IF NOT EXISTS idx_products_status_created ON products(status, created_at DESC);

-- 2. ADD INDEXES FOR ORDERS
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON orders(payment_status);

-- 3. ADD INDEXES FOR CUSTOMERS
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_customers_created_at ON customers(created_at DESC);

-- 4. DROP AND RECREATE MATERIALIZED VIEW (to ensure clean state)
DROP MATERIALIZED VIEW IF EXISTS admin_products_summary CASCADE;

CREATE MATERIALIZED VIEW admin_products_summary AS
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

-- Create indexes on materialized view
CREATE UNIQUE INDEX idx_admin_products_summary_id ON admin_products_summary(id);
CREATE INDEX idx_admin_products_summary_status ON admin_products_summary(status);
CREATE INDEX idx_admin_products_summary_category ON admin_products_summary(category);

-- 5. CREATE REFRESH FUNCTION
CREATE OR REPLACE FUNCTION refresh_admin_products_summary()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY admin_products_summary;
END;
$$ LANGUAGE plpgsql;

-- 6. CREATE FAST PAGINATED PRODUCTS FUNCTION
DROP FUNCTION IF EXISTS get_admin_products_paginated(int, int, text, text, text);

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
  total_count_value BIGINT;
BEGIN
  -- Calculate offset
  offset_value := (page_number - 1) * page_size;
  
  -- Get total count
  SELECT COUNT(*) INTO total_count_value
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
    total_count_value
  FROM products p
  WHERE (search_term IS NULL OR p.name ILIKE '%' || search_term || '%')
    AND (filter_category IS NULL OR p.category = filter_category)
    AND (filter_status IS NULL OR p.status = filter_status)
  ORDER BY p.created_at DESC
  LIMIT page_size
  OFFSET offset_value;
END;
$$ LANGUAGE plpgsql;

-- 7. CREATE LIGHTWEIGHT PRODUCT COUNT FUNCTION
CREATE OR REPLACE FUNCTION get_product_counts()
RETURNS JSON AS $$
BEGIN
  RETURN json_build_object(
    'total', (SELECT COUNT(*) FROM products),
    'active', (SELECT COUNT(*) FROM products WHERE status = 'active'),
    'draft', (SELECT COUNT(*) FROM products WHERE status = 'draft'),
    'archived', (SELECT COUNT(*) FROM products WHERE status = 'archived'),
    'low_stock', (SELECT COUNT(*) FROM products WHERE inventory_quantity < 10 AND status = 'active'),
    'out_of_stock', (SELECT COUNT(*) FROM products WHERE inventory_quantity = 0 AND status = 'active')
  );
END;
$$ LANGUAGE plpgsql;

-- 8. CREATE OPTIMIZED RECENT ACTIVITY FUNCTION
CREATE OR REPLACE FUNCTION get_recent_activity(limit_count INT DEFAULT 10)
RETURNS JSON AS $$
DECLARE
  recent_orders JSON;
  recent_customers JSON;
BEGIN
  -- Get recent orders
  SELECT json_agg(row_to_json(t))
  INTO recent_orders
  FROM (
    SELECT id, order_number, total_amount, status, created_at
    FROM orders
    ORDER BY created_at DESC
    LIMIT limit_count
  ) t;
  
  -- Get recent customers
  SELECT json_agg(row_to_json(t))
  INTO recent_customers
  FROM (
    SELECT id, email, name, created_at
    FROM customers
    ORDER BY created_at DESC
    LIMIT limit_count
  ) t;
  
  RETURN json_build_object(
    'recent_orders', COALESCE(recent_orders, '[]'::json),
    'recent_customers', COALESCE(recent_customers, '[]'::json)
  );
END;
$$ LANGUAGE plpgsql;

-- 9. GRANT PERMISSIONS
GRANT SELECT ON admin_products_summary TO authenticated;
GRANT EXECUTE ON FUNCTION refresh_admin_products_summary TO authenticated;
GRANT EXECUTE ON FUNCTION get_admin_products_paginated TO authenticated;
GRANT EXECUTE ON FUNCTION get_product_counts TO authenticated;
GRANT EXECUTE ON FUNCTION get_recent_activity TO authenticated;

-- 10. REFRESH MATERIALIZED VIEW
REFRESH MATERIALIZED VIEW admin_products_summary;

-- 11. UPDATE TABLE STATISTICS FOR QUERY PLANNER
ANALYZE products;
ANALYZE orders;
ANALYZE customers;
ANALYZE product_variants;
ANALYZE reviews;
ANALYZE cart_items;

-- 12. VERIFY PERFORMANCE SETUP
DO $$
DECLARE
  index_count INT;
  view_exists BOOLEAN;
  function_count INT;
BEGIN
  -- Count indexes on products table
  SELECT COUNT(*) INTO index_count
  FROM pg_indexes
  WHERE tablename = 'products';
  
  -- Check if materialized view exists
  SELECT EXISTS (
    SELECT 1 FROM pg_matviews 
    WHERE matviewname = 'admin_products_summary'
  ) INTO view_exists;
  
  -- Count our custom functions
  SELECT COUNT(*) INTO function_count
  FROM information_schema.routines 
  WHERE routine_schema = 'public' 
    AND routine_name IN (
      'get_admin_products_paginated',
      'get_product_counts',
      'get_recent_activity',
      'refresh_admin_products_summary'
    );
  
  -- Report results
  RAISE NOTICE '📊 Performance Setup Status:';
  RAISE NOTICE '  - Product indexes: %', index_count;
  RAISE NOTICE '  - Materialized view: %', CASE WHEN view_exists THEN 'Created' ELSE 'Missing' END;
  RAISE NOTICE '  - Performance functions: %/4', function_count;
  
  IF index_count >= 7 AND view_exists AND function_count = 4 THEN
    RAISE NOTICE '✅ SUCCESS: All performance optimizations applied!';
  ELSE
    RAISE WARNING '⚠️ Some optimizations may have failed. Check individual components.';
  END IF;
END $$;

-- Success message
SELECT '✅ Performance optimizations completed! Admin panel should now load much faster.' as status;