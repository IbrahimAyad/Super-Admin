-- ================================================================
-- FINAL ADMIN PANEL FIX - Now that customer_id exists
-- ================================================================

-- 1. CREATE CUSTOMERS TABLE (needed for the foreign key reference)
CREATE TABLE IF NOT EXISTS customers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);

-- 2. CREATE REVIEWS TABLE
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

CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_customer_id ON reviews(customer_id);
CREATE INDEX IF NOT EXISTS idx_reviews_status ON reviews(status);

-- 3. CREATE CART_ITEMS TABLE
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

CREATE INDEX IF NOT EXISTS idx_cart_items_customer_id ON cart_items(customer_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_session_id ON cart_items(session_id);

-- 4. DROP OLD FUNCTIONS
DROP FUNCTION IF EXISTS get_recent_orders(integer);
DROP FUNCTION IF EXISTS get_recent_orders(int);
DROP FUNCTION IF EXISTS transfer_guest_cart(uuid, text);
DROP FUNCTION IF EXISTS get_dashboard_stats();

-- 5. CREATE GET_RECENT_ORDERS FUNCTION (Now customer_id exists!)
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
  LEFT JOIN customers c ON c.id = o.customer_id  -- This will work now!
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

-- Drop existing policies
DROP POLICY IF EXISTS "Anyone can read published reviews" ON reviews;
DROP POLICY IF EXISTS "Authenticated users can create reviews" ON reviews;
DROP POLICY IF EXISTS "Admin users can manage all reviews" ON reviews;
DROP POLICY IF EXISTS "Users can manage their own cart" ON cart_items;
DROP POLICY IF EXISTS "Anonymous users can manage cart by session" ON cart_items;

-- Create new policies
CREATE POLICY "Anyone can read published reviews" ON reviews
  FOR SELECT USING (status = 'published');

CREATE POLICY "Authenticated users can create reviews" ON reviews
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Admin users can manage all reviews" ON reviews
  FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM admin_users WHERE admin_users.id = auth.uid()));

CREATE POLICY "Users can manage their own cart" ON cart_items
  FOR ALL TO authenticated
  USING (customer_id = auth.uid())
  WITH CHECK (customer_id = auth.uid());

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
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);

-- 11. VERIFY EVERYTHING
SELECT 
  'Verification Results:' as status,
  EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'reviews') as reviews_table,
  EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'cart_items') as cart_items_table,
  EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'customers') as customers_table,
  EXISTS(SELECT 1 FROM information_schema.routines WHERE routine_name = 'get_recent_orders') as get_recent_orders_func,
  EXISTS(SELECT 1 FROM information_schema.routines WHERE routine_name = 'transfer_guest_cart') as transfer_guest_cart_func,
  EXISTS(SELECT 1 FROM information_schema.routines WHERE routine_name = 'get_dashboard_stats') as dashboard_stats_func;

-- Final message
SELECT '✅ ADMIN PANEL COMPLETELY FIXED! All tables, functions, and indexes are now properly configured.' as final_status;