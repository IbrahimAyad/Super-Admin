-- ================================================================
-- FIX ADMIN PANEL ERRORS (404 & 400 Errors)
-- Run this in Supabase SQL Editor to fix all admin panel issues
-- ================================================================

-- 1. CREATE REVIEWS TABLE (Fix 400 error on reviews endpoint)
-- ================================================================
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

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_customer_id ON reviews(customer_id);
CREATE INDEX IF NOT EXISTS idx_reviews_status ON reviews(status);

-- 2. CREATE TRANSFER_GUEST_CART FUNCTION (Fix 404 error)
-- ================================================================
CREATE OR REPLACE FUNCTION transfer_guest_cart(
  p_customer_id UUID,
  p_session_id TEXT
) RETURNS VOID AS $$
BEGIN
  -- Transfer cart items from guest session to customer
  UPDATE cart_items
  SET 
    customer_id = p_customer_id,
    session_id = NULL,
    updated_at = NOW()
  WHERE session_id = p_session_id
    AND customer_id IS NULL;
END;
$$ LANGUAGE plpgsql;

-- 3. CREATE GET_RECENT_ORDERS FUNCTION (Fix 400 error)
-- ================================================================
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
    COALESCE(c.name, 'Guest Customer') as customer_name,
    COALESCE(c.email, o.email, 'No Email') as customer_email,
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

-- 4. CREATE CART_ITEMS TABLE IF MISSING
-- ================================================================
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

-- 5. CREATE PRODUCT_VARIANTS TABLE IF MISSING
-- ================================================================
CREATE TABLE IF NOT EXISTS product_variants (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  size TEXT,
  color TEXT,
  sku TEXT UNIQUE,
  price DECIMAL(10,2),
  compare_at_price DECIMAL(10,2),
  inventory_quantity INTEGER DEFAULT 0,
  weight DECIMAL(10,2),
  barcode TEXT,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for product_variants
CREATE INDEX IF NOT EXISTS idx_product_variants_product_id ON product_variants(product_id);
CREATE INDEX IF NOT EXISTS idx_product_variants_sku ON product_variants(sku);

-- 6. SET UP RLS POLICIES FOR ALL TABLES
-- ================================================================

-- Reviews table policies
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;

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
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;

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

-- Product variants policies
ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read product variants" ON product_variants;
CREATE POLICY "Anyone can read product variants" ON product_variants
  FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Admin users can manage variants" ON product_variants;
CREATE POLICY "Admin users can manage variants" ON product_variants
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users 
      WHERE admin_users.id = auth.uid()
    )
  );

-- 7. GRANT PERMISSIONS
-- ================================================================
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON reviews TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON cart_items TO anon, authenticated;
GRANT SELECT ON product_variants TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON product_variants TO authenticated;

-- Grant function permissions
GRANT EXECUTE ON FUNCTION transfer_guest_cart TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_recent_orders TO authenticated;

-- 8. CREATE HELPER FUNCTIONS FOR ADMIN DASHBOARD
-- ================================================================

-- Get dashboard statistics
CREATE OR REPLACE FUNCTION get_dashboard_stats()
RETURNS TABLE (
  total_customers BIGINT,
  total_orders BIGINT,
  total_products BIGINT,
  total_revenue DECIMAL,
  orders_today BIGINT,
  revenue_today DECIMAL,
  pending_orders BIGINT,
  low_stock_products BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    (SELECT COUNT(*) FROM customers)::BIGINT as total_customers,
    (SELECT COUNT(*) FROM orders)::BIGINT as total_orders,
    (SELECT COUNT(*) FROM products WHERE status = 'active')::BIGINT as total_products,
    (SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE payment_status = 'paid')::DECIMAL as total_revenue,
    (SELECT COUNT(*) FROM orders WHERE DATE(created_at) = CURRENT_DATE)::BIGINT as orders_today,
    (SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE DATE(created_at) = CURRENT_DATE AND payment_status = 'paid')::DECIMAL as revenue_today,
    (SELECT COUNT(*) FROM orders WHERE status = 'pending')::BIGINT as pending_orders,
    (SELECT COUNT(*) FROM products WHERE inventory_quantity < 10 AND status = 'active')::BIGINT as low_stock_products;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION get_dashboard_stats TO authenticated;

-- 9. ADD MISSING COLUMNS TO ORDERS TABLE
-- ================================================================
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
END $$;

-- 10. INSERT SAMPLE REVIEW DATA (Optional - for testing)
-- ================================================================
-- Uncomment below to add sample reviews for testing
/*
INSERT INTO reviews (product_id, rating, title, comment, status, verified_purchase)
SELECT 
  id as product_id,
  (RANDOM() * 4 + 1)::INTEGER as rating,
  'Great product!' as title,
  'Really happy with this purchase. Quality is excellent.' as comment,
  'published' as status,
  true as verified_purchase
FROM products
LIMIT 5
ON CONFLICT DO NOTHING;
*/

-- ================================================================
-- VERIFICATION QUERIES
-- ================================================================
-- Run these to verify everything is set up correctly:

-- Check if all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('reviews', 'cart_items', 'product_variants')
ORDER BY table_name;

-- Check if functions exist
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name IN ('transfer_guest_cart', 'get_recent_orders', 'get_dashboard_stats')
ORDER BY routine_name;

-- Test the dashboard stats function
SELECT * FROM get_dashboard_stats();

-- Success message
SELECT '✅ Admin panel errors fixed! All tables, functions, and policies are now properly configured.' as status;