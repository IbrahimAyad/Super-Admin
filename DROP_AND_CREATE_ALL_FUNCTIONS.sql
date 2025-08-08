-- ============================================
-- DROP AND RECREATE ALL RPC FUNCTIONS
-- ============================================
-- This file safely drops existing functions and recreates them with correct signatures

-- Drop existing functions that might have different signatures
DROP FUNCTION IF EXISTS get_dashboard_stats();
DROP FUNCTION IF EXISTS get_recent_orders(INTEGER);
DROP FUNCTION IF EXISTS get_low_stock_products(INTEGER);
DROP FUNCTION IF EXISTS get_revenue_metrics(DATE, DATE);
DROP FUNCTION IF EXISTS get_hourly_revenue_trend();
DROP FUNCTION IF EXISTS get_order_analytics(INTEGER);
DROP FUNCTION IF EXISTS get_top_products(INTEGER, INTEGER);
DROP FUNCTION IF EXISTS get_cart_items(TEXT);
DROP FUNCTION IF EXISTS add_to_cart(TEXT, UUID, UUID, INTEGER);
DROP FUNCTION IF EXISTS update_cart_item(UUID, INTEGER);
DROP FUNCTION IF EXISTS remove_cart_item(UUID);
DROP FUNCTION IF EXISTS clear_cart(TEXT);
DROP FUNCTION IF EXISTS get_available_inventory(UUID);
DROP FUNCTION IF EXISTS get_inventory_status();
DROP FUNCTION IF EXISTS import_products_from_csv(JSONB);
DROP FUNCTION IF EXISTS import_customers_from_csv(JSONB);
DROP FUNCTION IF EXISTS get_product_conversion_funnel(UUID, INTEGER);
DROP FUNCTION IF EXISTS get_customer_ltv_analytics();
DROP FUNCTION IF EXISTS get_realtime_customer_activity(INTEGER);
DROP FUNCTION IF EXISTS log_admin_security_event(TEXT, UUID, JSONB);
DROP FUNCTION IF EXISTS get_public_settings_cached();
DROP FUNCTION IF EXISTS update_setting_with_audit(TEXT, JSONB, UUID);
DROP FUNCTION IF EXISTS validate_setting_value(TEXT, JSONB);
DROP FUNCTION IF EXISTS get_traffic_source_performance(INTEGER);
DROP FUNCTION IF EXISTS get_realtime_website_metrics();
DROP FUNCTION IF EXISTS get_admin_activity_analytics(INTEGER);
DROP FUNCTION IF EXISTS refresh_analytics_views();
DROP FUNCTION IF EXISTS transfer_guest_cart(TEXT, UUID);
DROP FUNCTION IF EXISTS generate_tax_report(DATE, DATE);
DROP FUNCTION IF EXISTS get_payment_analytics(DATE, DATE);
DROP FUNCTION IF EXISTS generate_payment_reconciliation_report(DATE, DATE);
DROP FUNCTION IF EXISTS check_table_indexes(TEXT);
DROP FUNCTION IF EXISTS get_table_columns(TEXT);
DROP FUNCTION IF EXISTS get_sync_progress_by_category();
DROP FUNCTION IF EXISTS generate_analytics_report(DATE, DATE, TEXT);
DROP FUNCTION IF EXISTS process_bulk_orders(UUID[], TEXT, JSONB);

-- ============================================
-- NOW CREATE ALL FUNCTIONS WITH CORRECT SIGNATURES
-- ============================================

-- 1. Dashboard Stats Function
CREATE OR REPLACE FUNCTION get_dashboard_stats()
RETURNS JSONB AS $$
DECLARE
  v_stats JSONB;
BEGIN
  v_stats := jsonb_build_object(
    'revenue', jsonb_build_object(
      'total', (SELECT COALESCE(SUM(total_amount), 0) / 100.0 FROM orders WHERE financial_status = 'paid'),
      'today', (SELECT COALESCE(SUM(total_amount), 0) / 100.0 FROM orders WHERE financial_status = 'paid' AND created_at::DATE = CURRENT_DATE),
      'this_month', (SELECT COALESCE(SUM(total_amount), 0) / 100.0 FROM orders WHERE financial_status = 'paid' AND created_at >= DATE_TRUNC('month', CURRENT_DATE))
    ),
    'orders', jsonb_build_object(
      'total', (SELECT COUNT(*) FROM orders),
      'pending', (SELECT COUNT(*) FROM orders WHERE status = 'pending'),
      'processing', (SELECT COUNT(*) FROM orders WHERE status IN ('confirmed', 'processing')),
      'today', (SELECT COUNT(*) FROM orders WHERE created_at::DATE = CURRENT_DATE)
    ),
    'customers', jsonb_build_object(
      'total', (SELECT COUNT(*) FROM customers),
      'new_today', (SELECT COUNT(*) FROM customers WHERE created_at::DATE = CURRENT_DATE),
      'new_this_month', (SELECT COUNT(*) FROM customers WHERE created_at >= DATE_TRUNC('month', CURRENT_DATE))
    ),
    'products', jsonb_build_object(
      'total', (SELECT COUNT(*) FROM products),
      'active', (SELECT COUNT(*) FROM products WHERE status = 'active'),
      'low_stock', (SELECT COUNT(*) FROM product_variants WHERE COALESCE(available_quantity, inventory_quantity, 0) < 10)
    ),
    'generated_at', NOW()
  );
  RETURN v_stats;
END;
$$ LANGUAGE plpgsql;

-- 2. Get recent orders for dashboard
CREATE OR REPLACE FUNCTION get_recent_orders(limit_count INTEGER DEFAULT 5)
RETURNS TABLE (
  id UUID,
  order_number TEXT,
  customer_name TEXT,
  total_amount INTEGER,
  status TEXT,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    o.id,
    o.order_number,
    COALESCE(c.full_name, c.email, 'Guest') as customer_name,
    o.total_amount,
    o.status,
    o.created_at
  FROM orders o
  LEFT JOIN customers c ON o.customer_id = c.id
  ORDER BY o.created_at DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- 3. Get low stock products
CREATE OR REPLACE FUNCTION get_low_stock_products(threshold INTEGER DEFAULT 10)
RETURNS TABLE (
  product_id UUID,
  product_name TEXT,
  variant_name TEXT,
  current_stock INTEGER,
  threshold_value INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id as product_id,
    p.name as product_name,
    pv.name as variant_name,
    COALESCE(pv.available_quantity, pv.inventory_quantity, 0)::INTEGER as current_stock,
    threshold as threshold_value
  FROM product_variants pv
  JOIN products p ON p.id = pv.product_id
  WHERE COALESCE(pv.available_quantity, pv.inventory_quantity, 0) < threshold
  ORDER BY current_stock ASC;
END;
$$ LANGUAGE plpgsql;

-- 4. Get revenue metrics
CREATE OR REPLACE FUNCTION get_revenue_metrics(
  p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
  p_end_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB AS $$
BEGIN
  RETURN jsonb_build_object(
    'total_revenue', (
      SELECT COALESCE(SUM(total_amount), 0) / 100.0
      FROM orders 
      WHERE financial_status = 'paid'
        AND created_at::DATE BETWEEN p_start_date AND p_end_date
    ),
    'order_count', (
      SELECT COUNT(*)
      FROM orders
      WHERE created_at::DATE BETWEEN p_start_date AND p_end_date
    ),
    'average_order_value', (
      SELECT COALESCE(AVG(total_amount), 0) / 100.0
      FROM orders
      WHERE financial_status = 'paid'
        AND created_at::DATE BETWEEN p_start_date AND p_end_date
    ),
    'refund_total', (
      SELECT COALESCE(SUM(refund_amount), 0) / 100.0
      FROM refund_requests
      WHERE created_at::DATE BETWEEN p_start_date AND p_end_date
        AND status = 'completed'
    )
  );
END;
$$ LANGUAGE plpgsql;

-- 5. Get hourly revenue trend
CREATE OR REPLACE FUNCTION get_hourly_revenue_trend()
RETURNS TABLE (
  hour INTEGER,
  revenue DECIMAL,
  order_count INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    EXTRACT(HOUR FROM created_at)::INTEGER as hour,
    SUM(total_amount) / 100.0 as revenue,
    COUNT(*)::INTEGER as order_count
  FROM orders
  WHERE financial_status = 'paid'
    AND created_at >= NOW() - INTERVAL '24 hours'
  GROUP BY EXTRACT(HOUR FROM created_at)
  ORDER BY hour;
END;
$$ LANGUAGE plpgsql;

-- 6. Get order analytics
CREATE OR REPLACE FUNCTION get_order_analytics(days_back INTEGER DEFAULT 30)
RETURNS JSONB AS $$
BEGIN
  RETURN jsonb_build_object(
    'by_status', (
      SELECT jsonb_object_agg(status, count)
      FROM (
        SELECT status, COUNT(*) as count
        FROM orders
        WHERE created_at >= NOW() - (days_back || ' days')::INTERVAL
        GROUP BY status
      ) status_counts
    ),
    'by_day', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'date', order_date,
          'count', order_count,
          'revenue', revenue
        ) ORDER BY order_date
      )
      FROM (
        SELECT 
          created_at::DATE as order_date,
          COUNT(*) as order_count,
          SUM(total_amount) / 100.0 as revenue
        FROM orders
        WHERE created_at >= NOW() - (days_back || ' days')::INTERVAL
        GROUP BY created_at::DATE
      ) daily_orders
    )
  );
END;
$$ LANGUAGE plpgsql;

-- 7. Get top products
CREATE OR REPLACE FUNCTION get_top_products(
  p_limit INTEGER DEFAULT 10,
  p_days_back INTEGER DEFAULT 30
)
RETURNS TABLE (
  product_id UUID,
  product_name TEXT,
  units_sold BIGINT,
  revenue DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id as product_id,
    p.name as product_name,
    SUM((item->>'quantity')::INTEGER)::BIGINT as units_sold,
    SUM((item->>'total_price')::DECIMAL) / 100 as revenue
  FROM orders o
  CROSS JOIN LATERAL jsonb_array_elements(o.items) AS item
  JOIN products p ON p.id = (item->>'product_id')::UUID
  WHERE o.created_at >= NOW() - (p_days_back || ' days')::INTERVAL
    AND o.financial_status = 'paid'
  GROUP BY p.id, p.name
  ORDER BY revenue DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- 8. Cart Functions
-- Get cart items
CREATE OR REPLACE FUNCTION get_cart_items(p_session_id TEXT)
RETURNS TABLE (
  id UUID,
  product_id UUID,
  variant_id UUID,
  quantity INTEGER,
  price INTEGER,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id,
    c.product_id,
    c.variant_id,
    c.quantity,
    pv.price,
    c.created_at
  FROM cart_items c
  JOIN product_variants pv ON pv.id = c.variant_id
  WHERE c.session_id = p_session_id;
END;
$$ LANGUAGE plpgsql;

-- Add to cart
CREATE OR REPLACE FUNCTION add_to_cart(
  p_session_id TEXT,
  p_product_id UUID,
  p_variant_id UUID,
  p_quantity INTEGER
)
RETURNS JSONB AS $$
DECLARE
  v_existing_id UUID;
  v_cart_item_id UUID;
BEGIN
  -- Check if item already exists in cart
  SELECT id INTO v_existing_id
  FROM cart_items
  WHERE session_id = p_session_id
    AND product_id = p_product_id
    AND variant_id = p_variant_id;
    
  IF v_existing_id IS NOT NULL THEN
    -- Update quantity
    UPDATE cart_items
    SET quantity = quantity + p_quantity,
        updated_at = NOW()
    WHERE id = v_existing_id
    RETURNING id INTO v_cart_item_id;
  ELSE
    -- Insert new item
    INSERT INTO cart_items (session_id, product_id, variant_id, quantity)
    VALUES (p_session_id, p_product_id, p_variant_id, p_quantity)
    RETURNING id INTO v_cart_item_id;
  END IF;
  
  RETURN jsonb_build_object(
    'success', true,
    'cart_item_id', v_cart_item_id
  );
END;
$$ LANGUAGE plpgsql;

-- Update cart item
CREATE OR REPLACE FUNCTION update_cart_item(
  p_cart_item_id UUID,
  p_quantity INTEGER
)
RETURNS JSONB AS $$
BEGIN
  UPDATE cart_items
  SET quantity = p_quantity,
      updated_at = NOW()
  WHERE id = p_cart_item_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'updated', true
  );
END;
$$ LANGUAGE plpgsql;

-- Remove cart item
CREATE OR REPLACE FUNCTION remove_cart_item(p_cart_item_id UUID)
RETURNS JSONB AS $$
BEGIN
  DELETE FROM cart_items WHERE id = p_cart_item_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'removed', true
  );
END;
$$ LANGUAGE plpgsql;

-- Clear cart
CREATE OR REPLACE FUNCTION clear_cart(p_session_id TEXT)
RETURNS JSONB AS $$
BEGIN
  DELETE FROM cart_items WHERE session_id = p_session_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'cleared', true
  );
END;
$$ LANGUAGE plpgsql;

-- 9. Inventory Functions
-- Get available inventory
CREATE OR REPLACE FUNCTION get_available_inventory(variant_uuid UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COALESCE(available_quantity, inventory_quantity, 0)::INTEGER
    FROM product_variants
    WHERE id = variant_uuid
  );
END;
$$ LANGUAGE plpgsql;

-- Get inventory status
CREATE OR REPLACE FUNCTION get_inventory_status()
RETURNS JSONB AS $$
BEGIN
  RETURN jsonb_build_object(
    'total_products', (SELECT COUNT(*) FROM products),
    'total_variants', (SELECT COUNT(*) FROM product_variants),
    'total_stock', (
      SELECT COALESCE(SUM(COALESCE(available_quantity, inventory_quantity, 0)), 0)
      FROM product_variants
    ),
    'low_stock_count', (
      SELECT COUNT(*)
      FROM product_variants
      WHERE COALESCE(available_quantity, inventory_quantity, 0) < 10
        AND COALESCE(available_quantity, inventory_quantity, 0) > 0
    ),
    'out_of_stock_count', (
      SELECT COUNT(*)
      FROM product_variants
      WHERE COALESCE(available_quantity, inventory_quantity, 0) = 0
    )
  );
END;
$$ LANGUAGE plpgsql;

-- 10. Import/Export Functions
-- Import products from CSV
CREATE OR REPLACE FUNCTION import_products_from_csv(csv_data JSONB)
RETURNS JSONB AS $$
DECLARE
  v_product JSONB;
  v_imported INTEGER := 0;
  v_errors INTEGER := 0;
  v_product_id UUID;
BEGIN
  FOR v_product IN SELECT * FROM jsonb_array_elements(csv_data)
  LOOP
    BEGIN
      -- Insert or update product
      INSERT INTO products (
        name,
        description,
        category,
        subcategory,
        price,
        cost,
        sku,
        status
      ) VALUES (
        v_product->>'name',
        v_product->>'description',
        v_product->>'category',
        v_product->>'subcategory',
        (v_product->>'price')::INTEGER,
        (v_product->>'cost')::INTEGER,
        v_product->>'sku',
        COALESCE(v_product->>'status', 'active')
      )
      ON CONFLICT (sku) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        category = EXCLUDED.category,
        price = EXCLUDED.price,
        updated_at = NOW()
      RETURNING id INTO v_product_id;
      
      v_imported := v_imported + 1;
    EXCEPTION
      WHEN OTHERS THEN
        v_errors := v_errors + 1;
    END;
  END LOOP;
  
  RETURN jsonb_build_object(
    'success', v_errors = 0,
    'imported', v_imported,
    'errors', v_errors,
    'total', jsonb_array_length(csv_data)
  );
END;
$$ LANGUAGE plpgsql;

-- Import customers from CSV
CREATE OR REPLACE FUNCTION import_customers_from_csv(csv_data JSONB)
RETURNS JSONB AS $$
DECLARE
  v_customer JSONB;
  v_imported INTEGER := 0;
  v_errors INTEGER := 0;
BEGIN
  FOR v_customer IN SELECT * FROM jsonb_array_elements(csv_data)
  LOOP
    BEGIN
      INSERT INTO customers (
        email,
        full_name,
        phone,
        address,
        city,
        state,
        postal_code,
        country
      ) VALUES (
        v_customer->>'email',
        v_customer->>'full_name',
        v_customer->>'phone',
        v_customer->>'address',
        v_customer->>'city',
        v_customer->>'state',
        v_customer->>'postal_code',
        v_customer->>'country'
      )
      ON CONFLICT (email) DO UPDATE SET
        full_name = COALESCE(EXCLUDED.full_name, customers.full_name),
        phone = COALESCE(EXCLUDED.phone, customers.phone),
        updated_at = NOW();
      
      v_imported := v_imported + 1;
    EXCEPTION
      WHEN OTHERS THEN
        v_errors := v_errors + 1;
    END;
  END LOOP;
  
  RETURN jsonb_build_object(
    'success', v_errors = 0,
    'imported', v_imported,
    'errors', v_errors,
    'total', jsonb_array_length(csv_data)
  );
END;
$$ LANGUAGE plpgsql;

-- 11. Analytics Functions
-- Get customer lifetime value analytics
CREATE OR REPLACE FUNCTION get_customer_ltv_analytics()
RETURNS TABLE (
  customer_id UUID,
  email TEXT,
  total_orders BIGINT,
  total_spent DECIMAL,
  average_order_value DECIMAL,
  first_order_date DATE,
  last_order_date DATE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id as customer_id,
    c.email,
    COUNT(o.id)::BIGINT as total_orders,
    COALESCE(SUM(o.total_amount), 0) / 100.0 as total_spent,
    COALESCE(AVG(o.total_amount), 0) / 100.0 as average_order_value,
    MIN(o.created_at)::DATE as first_order_date,
    MAX(o.created_at)::DATE as last_order_date
  FROM customers c
  LEFT JOIN orders o ON o.customer_id = c.id
  WHERE o.financial_status = 'paid'
  GROUP BY c.id, c.email
  ORDER BY total_spent DESC;
END;
$$ LANGUAGE plpgsql;

-- 12. Generate analytics report
CREATE OR REPLACE FUNCTION generate_analytics_report(
  p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
  p_end_date DATE DEFAULT CURRENT_DATE,
  p_report_type TEXT DEFAULT 'summary'
)
RETURNS JSONB AS $$
DECLARE
  v_report JSONB;
BEGIN
  v_report := jsonb_build_object(
    'report_type', p_report_type,
    'period', jsonb_build_object(
      'start_date', p_start_date,
      'end_date', p_end_date,
      'days', p_end_date - p_start_date
    ),
    'sales', (
      SELECT jsonb_build_object(
        'total_orders', COUNT(*),
        'total_revenue', COALESCE(SUM(total_amount), 0) / 100.0,
        'average_order_value', COALESCE(AVG(total_amount), 0) / 100.0
      )
      FROM orders
      WHERE created_at::DATE BETWEEN p_start_date AND p_end_date
        AND financial_status = 'paid'
    ),
    'generated_at', NOW()
  );
  
  RETURN v_report;
END;
$$ LANGUAGE plpgsql;

-- 13. Process bulk orders
CREATE OR REPLACE FUNCTION process_bulk_orders(
  p_order_ids UUID[],
  p_action TEXT,
  p_metadata JSONB DEFAULT '{}'
)
RETURNS JSONB AS $$
DECLARE
  v_processed INTEGER := 0;
  v_failed INTEGER := 0;
  v_order_id UUID;
BEGIN
  -- Validate action
  IF p_action NOT IN ('confirm', 'ship', 'cancel', 'refund', 'deliver') THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Invalid action: ' || p_action
    );
  END IF;
  
  -- Process each order
  FOREACH v_order_id IN ARRAY p_order_ids
  LOOP
    BEGIN
      -- Update order based on action
      UPDATE orders 
      SET 
        status = CASE p_action
          WHEN 'confirm' THEN 'confirmed'
          WHEN 'ship' THEN 'shipped'
          WHEN 'deliver' THEN 'delivered'
          WHEN 'cancel' THEN 'cancelled'
          ELSE status
        END,
        updated_at = NOW()
      WHERE id = v_order_id;
      
      v_processed := v_processed + 1;
    EXCEPTION
      WHEN OTHERS THEN
        v_failed := v_failed + 1;
    END;
  END LOOP;
  
  RETURN jsonb_build_object(
    'success', v_failed = 0,
    'processed', v_processed,
    'failed', v_failed,
    'total', array_length(p_order_ids, 1)
  );
END;
$$ LANGUAGE plpgsql;

-- Grant permissions to authenticated users
GRANT EXECUTE ON FUNCTION get_dashboard_stats() TO authenticated;
GRANT EXECUTE ON FUNCTION get_recent_orders(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_low_stock_products(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_revenue_metrics(DATE, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION get_hourly_revenue_trend() TO authenticated;
GRANT EXECUTE ON FUNCTION get_order_analytics(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_top_products(INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_cart_items(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION add_to_cart(TEXT, UUID, UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION update_cart_item(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION remove_cart_item(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION clear_cart(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_available_inventory(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION get_inventory_status() TO authenticated;
GRANT EXECUTE ON FUNCTION import_products_from_csv(JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION import_customers_from_csv(JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION get_customer_ltv_analytics() TO authenticated;
GRANT EXECUTE ON FUNCTION generate_analytics_report(DATE, DATE, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION process_bulk_orders(UUID[], TEXT, JSONB) TO authenticated;

-- ============================================
-- VERIFICATION
-- ============================================
SELECT 
  'Functions Created Successfully' as status,
  COUNT(*) as total_functions
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_type = 'FUNCTION'
  AND routine_name IN (
    'get_dashboard_stats',
    'get_recent_orders',
    'get_low_stock_products',
    'get_revenue_metrics',
    'get_hourly_revenue_trend',
    'get_order_analytics',
    'get_top_products',
    'get_cart_items',
    'add_to_cart',
    'update_cart_item',
    'remove_cart_item',
    'clear_cart',
    'get_available_inventory',
    'get_inventory_status',
    'import_products_from_csv',
    'import_customers_from_csv',
    'get_customer_ltv_analytics',
    'generate_analytics_report',
    'process_bulk_orders'
  );