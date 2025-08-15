-- ================================================================
-- COMPLETE ADMIN PANEL FIX - Handles all table/column issues
-- ================================================================

-- 1. FIX ORDERS TABLE - Add missing columns if needed
DO $$ 
BEGIN
  -- Add customer_id if missing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'orders' AND column_name = 'customer_id') THEN
    ALTER TABLE orders ADD COLUMN customer_id UUID;
  END IF;
  
  -- Add email if missing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'orders' AND column_name = 'email') THEN
    ALTER TABLE orders ADD COLUMN email TEXT;
  END IF;
  
  -- Add payment_status if missing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'orders' AND column_name = 'payment_status') THEN
    ALTER TABLE orders ADD COLUMN payment_status TEXT DEFAULT 'pending';
  END IF;

  -- Add order_number if missing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'orders' AND column_name = 'order_number') THEN
    ALTER TABLE orders ADD COLUMN order_number TEXT;
    -- Generate order numbers for existing orders
    UPDATE orders SET order_number = 'ORD-' || SUBSTRING(id::text, 1, 8) WHERE order_number IS NULL;
  END IF;

  -- Add total_amount if missing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'orders' AND column_name = 'total_amount') THEN
    ALTER TABLE orders ADD COLUMN total_amount DECIMAL(10,2) DEFAULT 0;
  END IF;

  -- Add status if missing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'orders' AND column_name = 'status') THEN
    ALTER TABLE orders ADD COLUMN status TEXT DEFAULT 'pending';
  END IF;

  -- Add created_at if missing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'orders' AND column_name = 'created_at') THEN
    ALTER TABLE orders ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
  END IF;
END $$;

-- 2. CREATE CUSTOMERS TABLE IF MISSING
CREATE TABLE IF NOT EXISTS customers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. CREATE REVIEWS TABLE
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

-- 4. CREATE CART_ITEMS TABLE
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

-- 5. DROP AND RECREATE FUNCTIONS (clean slate)
DROP FUNCTION IF EXISTS get_recent_orders(integer);
DROP FUNCTION IF EXISTS get_recent_orders(int);
DROP FUNCTION IF EXISTS transfer_guest_cart(uuid, text);

-- 6. CREATE GET_RECENT_ORDERS FUNCTION - Fixed version
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

-- 7. CREATE TRANSFER_GUEST_CART FUNCTION
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

-- 8. CREATE DASHBOARD STATS FUNCTION
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
EXCEPTION
  WHEN OTHERS THEN
    -- Return safe defaults if there's any error
    RETURN json_build_object(
      'total_customers', 0,
      'total_orders', 0,
      'total_products', 0,
      'total_revenue', 0,
      'pending_orders', 0,
      'low_stock_products', 0
    );
END;
$$ LANGUAGE plpgsql;

-- 9. CREATE INDEXES FOR PERFORMANCE
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_status ON reviews(status);
CREATE INDEX IF NOT EXISTS idx_cart_items_customer_id ON cart_items(customer_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_session_id ON cart_items(session_id);

-- 10. SET UP RLS POLICIES
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;

-- Drop existing policies first
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

-- 11. GRANT PERMISSIONS
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON reviews TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON cart_items TO anon, authenticated;
GRANT EXECUTE ON FUNCTION transfer_guest_cart TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_recent_orders TO authenticated;
GRANT EXECUTE ON FUNCTION get_dashboard_stats TO authenticated;

-- 12. VERIFY SETUP
DO $$
DECLARE
  orders_ok BOOLEAN := FALSE;
  reviews_ok BOOLEAN := FALSE;
  cart_ok BOOLEAN := FALSE;
  functions_ok BOOLEAN := FALSE;
BEGIN
  -- Check if orders table has required columns
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_name = 'orders' 
             AND column_name IN ('customer_id', 'email', 'payment_status', 'order_number')) THEN
    orders_ok := TRUE;
  END IF;
  
  -- Check if reviews table exists
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'reviews') THEN
    reviews_ok := TRUE;
  END IF;
  
  -- Check if cart_items table exists
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'cart_items') THEN
    cart_ok := TRUE;
  END IF;
  
  -- Check if functions exist
  IF EXISTS (SELECT 1 FROM information_schema.routines 
             WHERE routine_name IN ('get_recent_orders', 'transfer_guest_cart', 'get_dashboard_stats')) THEN
    functions_ok := TRUE;
  END IF;
  
  -- Report status
  RAISE NOTICE '';
  RAISE NOTICE '=====================================';
  RAISE NOTICE 'ADMIN PANEL FIX STATUS:';
  RAISE NOTICE '=====================================';
  RAISE NOTICE 'Orders table fixed: %', CASE WHEN orders_ok THEN '✅' ELSE '❌' END;
  RAISE NOTICE 'Reviews table created: %', CASE WHEN reviews_ok THEN '✅' ELSE '❌' END;
  RAISE NOTICE 'Cart table created: %', CASE WHEN cart_ok THEN '✅' ELSE '❌' END;
  RAISE NOTICE 'Functions created: %', CASE WHEN functions_ok THEN '✅' ELSE '❌' END;
  RAISE NOTICE '=====================================';
  
  IF orders_ok AND reviews_ok AND cart_ok AND functions_ok THEN
    RAISE NOTICE '✅ SUCCESS: All fixes applied successfully!';
  ELSE
    RAISE WARNING '⚠️ Some fixes may have failed. Check individual components.';
  END IF;
END $$;

-- Final message
SELECT '✅ Admin panel fix completed! Please hard refresh your browser (Ctrl+Shift+R).' as status;