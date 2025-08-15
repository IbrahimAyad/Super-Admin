-- ================================================================
-- CREATE FUNCTIONS WITHOUT CUSTOMER_ID REFERENCE
-- Use this if customer_id column won't add properly
-- ================================================================

-- 1. Drop existing functions
DROP FUNCTION IF EXISTS get_recent_orders(integer);
DROP FUNCTION IF EXISTS get_recent_orders(int);

-- 2. Create simplified get_recent_orders without customer_id
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
    'Guest Customer'::TEXT as customer_name,  -- Static value since no customer_id
    COALESCE(o.email, 'No Email')::TEXT as customer_email,
    COALESCE(o.total_amount, 0::decimal),
    COALESCE(o.status, 'pending')::TEXT,
    COALESCE(o.payment_status, 'pending')::TEXT,
    o.created_at
  FROM orders o
  ORDER BY o.created_at DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- 3. Create reviews table (doesn't depend on orders.customer_id)
CREATE TABLE IF NOT EXISTS reviews (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  customer_id UUID,  -- No foreign key since customers might not exist
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
CREATE INDEX IF NOT EXISTS idx_reviews_status ON reviews(status);

-- 4. Create cart_items table (simplified)
CREATE TABLE IF NOT EXISTS cart_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  customer_id UUID,  -- No foreign key
  session_id TEXT,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  variant_id UUID REFERENCES product_variants(id) ON DELETE CASCADE,
  quantity INTEGER DEFAULT 1 CHECK (quantity > 0),
  price DECIMAL(10,2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cart_items_session_id ON cart_items(session_id);

-- 5. Create transfer_guest_cart function
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

-- 6. Create simplified dashboard stats
CREATE OR REPLACE FUNCTION get_dashboard_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_customers', 0,  -- Hardcoded since we don't have customers table
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

-- 7. Set up RLS policies
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read published reviews" ON reviews;
CREATE POLICY "Anyone can read published reviews" ON reviews
  FOR SELECT USING (status = 'published');

DROP POLICY IF EXISTS "Authenticated users can manage reviews" ON reviews;
CREATE POLICY "Authenticated users can manage reviews" ON reviews
  FOR ALL TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Public can manage cart" ON cart_items;
CREATE POLICY "Public can manage cart" ON cart_items
  FOR ALL USING (true);

-- 8. Grant permissions
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON reviews TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON cart_items TO anon, authenticated;
GRANT EXECUTE ON FUNCTION transfer_guest_cart TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_recent_orders TO authenticated;
GRANT EXECUTE ON FUNCTION get_dashboard_stats TO authenticated;

-- 9. Verify setup
SELECT 
  'Tables created:' as check_type,
  EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'reviews') as reviews_exists,
  EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'cart_items') as cart_items_exists,
  EXISTS(SELECT 1 FROM information_schema.routines WHERE routine_name = 'get_recent_orders') as get_recent_orders_exists,
  EXISTS(SELECT 1 FROM information_schema.routines WHERE routine_name = 'transfer_guest_cart') as transfer_guest_cart_exists,
  EXISTS(SELECT 1 FROM information_schema.routines WHERE routine_name = 'get_dashboard_stats') as dashboard_stats_exists;

-- Success
SELECT '✅ Admin panel functions created WITHOUT requiring customer_id column!' as status;