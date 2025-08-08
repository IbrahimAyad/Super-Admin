-- ============================================
-- FIX ALL MISSING FUNCTIONS AND TABLES
-- ============================================

-- ============================================
-- 1. STRIPE SYNC TABLES & FUNCTIONS
-- ============================================

-- Stripe sync log table
CREATE TABLE IF NOT EXISTS stripe_sync_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID REFERENCES products(id),
  action VARCHAR(50),
  status VARCHAR(50),
  stripe_product_id TEXT,
  stripe_price_ids JSONB,
  error_message TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Stripe sync summary table
CREATE TABLE IF NOT EXISTS stripe_sync_summary (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  total_products INTEGER DEFAULT 0,
  synced_products INTEGER DEFAULT 0,
  failed_products INTEGER DEFAULT 0,
  last_sync_at TIMESTAMPTZ,
  sync_duration_seconds INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Get sync progress by category function
CREATE OR REPLACE FUNCTION get_sync_progress_by_category()
RETURNS TABLE (
  category TEXT,
  total INTEGER,
  synced INTEGER,
  percentage DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.category,
    COUNT(*)::INTEGER as total,
    COUNT(p.stripe_product_id)::INTEGER as synced,
    CASE 
      WHEN COUNT(*) > 0 
      THEN (COUNT(p.stripe_product_id)::DECIMAL / COUNT(*)::DECIMAL * 100)
      ELSE 0
    END as percentage
  FROM products p
  GROUP BY p.category
  ORDER BY p.category;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 2. BUNDLE MANAGEMENT TABLES
-- ============================================

CREATE TABLE IF NOT EXISTS product_bundles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  discount_type VARCHAR(50) DEFAULT 'percentage', -- 'percentage' or 'fixed'
  discount_value DECIMAL(10,2) DEFAULT 0,
  active BOOLEAN DEFAULT true,
  valid_from TIMESTAMPTZ,
  valid_until TIMESTAMPTZ,
  min_items INTEGER DEFAULT 2,
  max_items INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS bundle_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  bundle_id UUID REFERENCES product_bundles(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  quantity INTEGER DEFAULT 1,
  position INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Calculate bundle price function
CREATE OR REPLACE FUNCTION calculate_bundle_price(p_bundle_id UUID)
RETURNS DECIMAL AS $$
DECLARE
  v_total DECIMAL := 0;
  v_discount_type VARCHAR(50);
  v_discount_value DECIMAL;
BEGIN
  -- Get bundle discount info
  SELECT discount_type, discount_value 
  INTO v_discount_type, v_discount_value
  FROM product_bundles 
  WHERE id = p_bundle_id;
  
  -- Calculate total price of items
  SELECT SUM(p.base_price * bi.quantity)
  INTO v_total
  FROM bundle_items bi
  JOIN products p ON p.id = bi.product_id
  WHERE bi.bundle_id = p_bundle_id;
  
  -- Apply discount
  IF v_discount_type = 'percentage' THEN
    v_total := v_total * (1 - v_discount_value / 100);
  ELSIF v_discount_type = 'fixed' THEN
    v_total := v_total - v_discount_value;
  END IF;
  
  RETURN GREATEST(0, v_total);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 3. MARKETING & CAMPAIGNS
-- ============================================

CREATE TABLE IF NOT EXISTS marketing_campaigns (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50), -- 'email', 'sms', 'push', 'social'
  status VARCHAR(50) DEFAULT 'draft', -- 'draft', 'scheduled', 'active', 'completed'
  target_audience JSONB DEFAULT '{}',
  content JSONB DEFAULT '{}',
  scheduled_at TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  metrics JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS email_campaigns (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  campaign_id UUID REFERENCES marketing_campaigns(id) ON DELETE CASCADE,
  subject VARCHAR(255),
  html_content TEXT,
  text_content TEXT,
  from_email VARCHAR(255),
  reply_to VARCHAR(255),
  sent_count INTEGER DEFAULT 0,
  open_count INTEGER DEFAULT 0,
  click_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 4. PRODUCT REVIEWS
-- ============================================

CREATE TABLE IF NOT EXISTS product_reviews (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES customers(id),
  order_id UUID REFERENCES orders(id),
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  title VARCHAR(255),
  comment TEXT,
  verified_purchase BOOLEAN DEFAULT false,
  helpful_count INTEGER DEFAULT 0,
  status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
  moderated_at TIMESTAMPTZ,
  moderated_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 5. COLLECTIONS
-- ============================================

CREATE TABLE IF NOT EXISTS collections (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) UNIQUE NOT NULL,
  description TEXT,
  image_url TEXT,
  sort_order INTEGER DEFAULT 0,
  active BOOLEAN DEFAULT true,
  meta_title VARCHAR(255),
  meta_description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS collection_products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  collection_id UUID REFERENCES collections(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  position INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(collection_id, product_id)
);

-- ============================================
-- 6. CUSTOMER SERVICE
-- ============================================

CREATE TABLE IF NOT EXISTS support_tickets (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  ticket_number VARCHAR(50) UNIQUE NOT NULL DEFAULT 'TKT-' || SUBSTRING(gen_random_uuid()::TEXT, 1, 8),
  customer_id UUID REFERENCES customers(id),
  order_id UUID REFERENCES orders(id),
  subject VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(50) DEFAULT 'open', -- 'open', 'in_progress', 'resolved', 'closed'
  priority VARCHAR(50) DEFAULT 'medium', -- 'low', 'medium', 'high', 'urgent'
  category VARCHAR(100),
  assigned_to UUID REFERENCES auth.users(id),
  resolved_at TIMESTAMPTZ,
  satisfaction_rating INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 7. ORDER HELPER FUNCTIONS
-- ============================================

-- Calculate order totals
CREATE OR REPLACE FUNCTION calculate_order_totals(p_order_id UUID)
RETURNS TABLE (
  subtotal DECIMAL,
  tax DECIMAL,
  shipping DECIMAL,
  discount DECIMAL,
  total DECIMAL
) AS $$
DECLARE
  v_subtotal DECIMAL := 0;
  v_tax DECIMAL := 0;
  v_shipping DECIMAL := 0;
  v_discount DECIMAL := 0;
BEGIN
  -- Get order details
  SELECT 
    COALESCE(subtotal_amount, 0) / 100.0,
    COALESCE(tax_amount, 0) / 100.0,
    COALESCE(shipping_amount, 0) / 100.0,
    COALESCE(discount_amount, 0) / 100.0
  INTO v_subtotal, v_tax, v_shipping, v_discount
  FROM orders
  WHERE id = p_order_id;
  
  RETURN QUERY
  SELECT 
    v_subtotal,
    v_tax,
    v_shipping,
    v_discount,
    v_subtotal + v_tax + v_shipping - v_discount;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 8. CUSTOMER ANALYTICS FUNCTIONS
-- ============================================

-- Get customer lifetime value
CREATE OR REPLACE FUNCTION get_customer_lifetime_value(p_customer_id UUID)
RETURNS TABLE (
  total_orders INTEGER,
  total_spent DECIMAL,
  average_order_value DECIMAL,
  first_order_date DATE,
  last_order_date DATE,
  days_as_customer INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::INTEGER as total_orders,
    COALESCE(SUM(total_amount) / 100.0, 0) as total_spent,
    COALESCE(AVG(total_amount) / 100.0, 0) as average_order_value,
    MIN(created_at)::DATE as first_order_date,
    MAX(created_at)::DATE as last_order_date,
    COALESCE(EXTRACT(DAY FROM MAX(created_at) - MIN(created_at))::INTEGER, 0) as days_as_customer
  FROM orders
  WHERE customer_id = p_customer_id
    AND financial_status = 'paid';
END;
$$ LANGUAGE plpgsql;

-- Get customer stats
CREATE OR REPLACE FUNCTION get_customer_stats()
RETURNS TABLE (
  total_customers INTEGER,
  new_customers_30d INTEGER,
  returning_customers INTEGER,
  average_ltv DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(DISTINCT id)::INTEGER as total_customers,
    COUNT(DISTINCT CASE WHEN created_at > NOW() - INTERVAL '30 days' THEN id END)::INTEGER as new_customers_30d,
    COUNT(DISTINCT CASE WHEN EXISTS (
      SELECT 1 FROM orders o WHERE o.customer_id = customers.id
    ) THEN id END)::INTEGER as returning_customers,
    (
      SELECT AVG(total_spent) FROM (
        SELECT SUM(total_amount) / 100.0 as total_spent
        FROM orders
        WHERE financial_status = 'paid'
        GROUP BY customer_id
      ) customer_totals
    ) as average_ltv
  FROM customers;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 9. PRODUCT PERFORMANCE
-- ============================================

CREATE OR REPLACE FUNCTION get_product_performance(p_days INTEGER DEFAULT 30)
RETURNS TABLE (
  product_id UUID,
  product_name TEXT,
  units_sold INTEGER,
  revenue DECIMAL,
  order_count INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id as product_id,
    p.name as product_name,
    COALESCE(SUM((item->>'quantity')::INTEGER), 0)::INTEGER as units_sold,
    COALESCE(SUM((item->>'total_price')::DECIMAL / 100), 0) as revenue,
    COUNT(DISTINCT o.id)::INTEGER as order_count
  FROM products p
  LEFT JOIN orders o ON o.created_at > NOW() - (p_days || ' days')::INTERVAL
    AND o.financial_status = 'paid'
  LEFT JOIN LATERAL jsonb_array_elements(o.items) AS item ON (item->>'product_id')::UUID = p.id
  GROUP BY p.id, p.name
  ORDER BY revenue DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 10. GRANTS
-- ============================================

-- Grant permissions to authenticated users
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- ============================================
-- VERIFICATION
-- ============================================

SELECT 
  'Functions Created' as status,
  COUNT(*) as count
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'get_sync_progress_by_category',
    'calculate_bundle_price',
    'calculate_order_totals',
    'get_customer_lifetime_value',
    'get_customer_stats',
    'get_product_performance'
  );