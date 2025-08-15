-- ================================================================
-- COMPLETE ADMIN PANEL FIX - Functions and Missing Tables
-- Run this AFTER fixing the orders table columns
-- ================================================================

-- 1. CREATE REVIEWS TABLE (for reviews endpoint)
CREATE TABLE IF NOT EXISTS reviews (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  title TEXT,
  comment TEXT,
  verified_purchase BOOLEAN DEFAULT false,
  helpful_count INTEGER DEFAULT 0,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'published', 'flagged', 'archived')),
  images TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for reviews
CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_customer_id ON reviews(customer_id);
CREATE INDEX IF NOT EXISTS idx_reviews_status ON reviews(status);

-- 2. CREATE CART_ITEMS TABLE (for cart functionality)
CREATE TABLE IF NOT EXISTS cart_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  session_id TEXT,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  variant_id UUID REFERENCES product_variants(id) ON DELETE CASCADE,
  quantity INTEGER DEFAULT 1 CHECK (quantity > 0),
  price DECIMAL(10,2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for cart_items
CREATE INDEX IF NOT EXISTS idx_cart_items_customer_id ON cart_items(customer_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_session_id ON cart_items(session_id);

-- 3. CREATE CUSTOMERS TABLE IF MISSING
CREATE TABLE IF NOT EXISTS customers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);

-- 4. DROP AND RECREATE FUNCTIONS
DROP FUNCTION IF EXISTS get_recent_orders(integer);
DROP FUNCTION IF EXISTS get_recent_orders(int);
DROP FUNCTION IF EXISTS transfer_guest_cart(uuid, text);
DROP FUNCTION IF EXISTS get_dashboard_stats();

-- 5. CREATE GET_RECENT_ORDERS FUNCTION
CREATE OR REPLACE FUNCTION get_recent_orders(limit_count INT DEFAULT 10)
RETURNS TABLE (
  id UUID,
  order_number TEXT,
  customer_name TEXT,
  customer_email TEXT,
  total_amount DECIMAL,
  status TEXT,
  payment_status TEXT,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    o.id,
    COALESCE(o.order_number, 'ORD-' || SUBSTRING(o.id::text, 1, 8))::TEXT,
    COALESCE(c.name, 'Guest Customer')::TEXT as customer_name,
    COALESCE(c.email, o.email, 'No Email')::TEXT as customer_email,
    COALESCE(o.total_amount, 0::decimal),
    COALESCE(o.status, 'pending')::TEXT,
    COALESCE(o.payment_status, 'pending')::TEXT,
    o.created_at
  FROM orders o
  LEFT JOIN customers c ON c.id = o.customer_id
  ORDER BY o.created_at DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- 6. CREATE TRANSFER_GUEST_CART FUNCTION
CREATE OR REPLACE FUNCTION transfer_guest_cart(
  p_customer_id UUID,
  p_session_id TEXT
) RETURNS VOID AS $$
BEGIN
  UPDATE cart_items
  SET 
    customer_id = p_customer_id,
    session_id = NULL,
    updated_at = NOW()
  WHERE session_id = p_session_id
    AND customer_id IS NULL;
END;
$$ LANGUAGE plpgsql;

-- 7. CREATE DASHBOARD STATS FUNCTION
CREATE OR REPLACE FUNCTION get_dashboard_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_customers', (SELECT COUNT(*) FROM customers),
    'total_orders', (SELECT COUNT(*) FROM orders),
    'total_products', (SELECT COUNT(*) FROM products WHERE status = 'active'),
    'total_revenue', (SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE payment_status = 'paid'),
    'pending_orders', (SELECT COUNT(*) FROM orders WHERE status = 'pending'),
    'low_stock_products', (SELECT COUNT(*) FROM products WHERE inventory_quantity < 10 AND status = 'active'),
    'orders_today', (SELECT COUNT(*) FROM orders WHERE DATE(created_at) = CURRENT_DATE),
    'revenue_today', (SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE DATE(created_at) = CURRENT_DATE AND payment_status = 'paid')
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 8. SET UP RLS POLICIES
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;

-- Reviews policies
DROP POLICY IF EXISTS "Anyone can read published reviews" ON reviews;
CREATE POLICY "Anyone can read published reviews" ON reviews
  FOR SELECT
  USING (status = 'published');

DROP POLICY IF EXISTS "Authenticated users can create reviews" ON reviews;
CREATE POLICY "Authenticated users can create reviews" ON reviews
  FOR INSERT TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Admin users can manage all reviews" ON reviews;
CREATE POLICY "Admin users can manage all reviews" ON reviews
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users 
      WHERE admin_users.id = auth.uid()
    )
  );

-- Cart items policies
DROP POLICY IF EXISTS "Users can manage their own cart" ON cart_items;
CREATE POLICY "Users can manage their own cart" ON cart_items
  FOR ALL TO authenticated
  USING (customer_id = auth.uid())
  WITH CHECK (customer_id = auth.uid());

DROP POLICY IF EXISTS "Anonymous users can manage cart by session" ON cart_items;
CREATE POLICY "Anonymous users can manage cart by session" ON cart_items
  FOR ALL TO anon
  USING (session_id IS NOT NULL)
  WITH CHECK (session_id IS NOT NULL);

-- 9. GRANT PERMISSIONS
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON reviews TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON cart_items TO anon, authenticated;
GRANT EXECUTE ON FUNCTION transfer_guest_cart TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_recent_orders TO authenticated;
GRANT EXECUTE ON FUNCTION get_dashboard_stats TO authenticated;

-- 10. ADD PERFORMANCE INDEXES
CREATE INDEX IF NOT EXISTS idx_products_status ON products(status);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON products(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON orders(payment_status);

-- 11. VERIFY EVERYTHING IS SET UP
DO $$
DECLARE
  missing_items TEXT := '';
BEGIN
  -- Check tables
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'reviews') THEN
    missing_items := missing_items || 'reviews table, ';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'cart_items') THEN
    missing_items := missing_items || 'cart_items table, ';
  END IF;
  
  -- Check functions
  IF NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'get_recent_orders') THEN
    missing_items := missing_items || 'get_recent_orders function, ';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'transfer_guest_cart') THEN
    missing_items := missing_items || 'transfer_guest_cart function, ';
  END IF;
  
  -- Report
  IF missing_items = '' THEN
    RAISE NOTICE '✅ SUCCESS: All admin panel components are properly configured!';
  ELSE
    RAISE WARNING '⚠️ Missing: %', missing_items;
  END IF;
END $$;

-- Success message
SELECT '✅ Admin panel functions and tables created successfully!' as status;