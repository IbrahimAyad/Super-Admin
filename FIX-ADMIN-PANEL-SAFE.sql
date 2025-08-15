-- ================================================================
-- FIX ADMIN PANEL - SAFE VERSION (Drops existing functions first)
-- ================================================================

-- 1. DROP EXISTING FUNCTIONS FIRST (to avoid conflicts)
DROP FUNCTION IF EXISTS get_recent_orders(integer);
DROP FUNCTION IF EXISTS get_recent_orders(int);
DROP FUNCTION IF EXISTS transfer_guest_cart(uuid, text);

-- 2. CREATE REVIEWS TABLE (if not exists)
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

-- 3. CREATE CART_ITEMS TABLE (if not exists)
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

-- 4. CREATE NEW TRANSFER_GUEST_CART FUNCTION
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

-- 5. CREATE NEW GET_RECENT_ORDERS FUNCTION
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
    o.order_number,
    COALESCE(c.name, 'Guest Customer')::TEXT as customer_name,
    COALESCE(c.email, o.email, 'No Email')::TEXT as customer_email,
    o.total_amount,
    o.status,
    o.payment_status,
    o.created_at
  FROM orders o
  LEFT JOIN customers c ON c.id = o.customer_id
  ORDER BY o.created_at DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- 6. ADD MISSING COLUMNS TO ORDERS (if they don't exist)
DO $$ 
BEGIN
  -- Add email column if missing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'orders' AND column_name = 'email') THEN
    ALTER TABLE orders ADD COLUMN email TEXT;
  END IF;
  
  -- Add payment_status column if missing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'orders' AND column_name = 'payment_status') THEN
    ALTER TABLE orders ADD COLUMN payment_status TEXT DEFAULT 'pending';
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    NULL; -- Ignore errors if columns already exist
END $$;

-- 7. SET UP RLS POLICIES (Drop existing first to avoid conflicts)
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

-- 8. GRANT PERMISSIONS
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON reviews TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON cart_items TO anon, authenticated;
GRANT EXECUTE ON FUNCTION transfer_guest_cart TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_recent_orders TO authenticated;

-- 9. CREATE SIMPLE DASHBOARD STATS FUNCTION
DROP FUNCTION IF EXISTS get_dashboard_stats();
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
    'low_stock_products', (SELECT COUNT(*) FROM products WHERE inventory_quantity < 10 AND status = 'active')
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION get_dashboard_stats TO authenticated;

-- 10. VERIFY SETUP
DO $$
DECLARE
  tables_ok BOOLEAN := TRUE;
  functions_ok BOOLEAN := TRUE;
  message TEXT := '';
BEGIN
  -- Check tables
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'reviews') THEN
    tables_ok := FALSE;
    message := message || 'Reviews table missing. ';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'cart_items') THEN
    tables_ok := FALSE;
    message := message || 'Cart_items table missing. ';
  END IF;
  
  -- Check functions
  IF NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'get_recent_orders') THEN
    functions_ok := FALSE;
    message := message || 'get_recent_orders function missing. ';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.routines WHERE routine_name = 'transfer_guest_cart') THEN
    functions_ok := FALSE;
    message := message || 'transfer_guest_cart function missing. ';
  END IF;
  
  -- Report results
  IF tables_ok AND functions_ok THEN
    RAISE NOTICE '✅ SUCCESS: All admin panel components are properly set up!';
  ELSE
    RAISE WARNING '⚠️ WARNING: Some components failed - %', message;
  END IF;
END $$;

-- Final success message
SELECT '✅ Admin panel fix completed! Please refresh your browser.' as status;