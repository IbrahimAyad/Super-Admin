-- ============================================
-- FIX FINAL UI ISSUES - MISSING FUNCTIONS
-- ============================================

-- 1. Create get_dashboard_stats function (used by EnhancedDashboardWidgets and useDashboardData)
CREATE OR REPLACE FUNCTION get_dashboard_stats()
RETURNS JSONB AS $$
DECLARE
  v_stats JSONB;
BEGIN
  v_stats := jsonb_build_object(
    -- Revenue metrics
    'revenue', jsonb_build_object(
      'total', (
        SELECT COALESCE(SUM(total_amount), 0) / 100.0
        FROM orders 
        WHERE financial_status = 'paid'
      ),
      'today', (
        SELECT COALESCE(SUM(total_amount), 0) / 100.0
        FROM orders 
        WHERE financial_status = 'paid' 
          AND created_at::DATE = CURRENT_DATE
      ),
      'this_month', (
        SELECT COALESCE(SUM(total_amount), 0) / 100.0
        FROM orders 
        WHERE financial_status = 'paid'
          AND created_at >= DATE_TRUNC('month', CURRENT_DATE)
      ),
      'last_month', (
        SELECT COALESCE(SUM(total_amount), 0) / 100.0
        FROM orders 
        WHERE financial_status = 'paid'
          AND created_at >= DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')
          AND created_at < DATE_TRUNC('month', CURRENT_DATE)
      )
    ),
    
    -- Order metrics
    'orders', jsonb_build_object(
      'total', (SELECT COUNT(*) FROM orders),
      'pending', (SELECT COUNT(*) FROM orders WHERE status = 'pending'),
      'processing', (SELECT COUNT(*) FROM orders WHERE status IN ('confirmed', 'processing')),
      'shipped', (SELECT COUNT(*) FROM orders WHERE status = 'shipped'),
      'delivered', (SELECT COUNT(*) FROM orders WHERE status = 'delivered'),
      'cancelled', (SELECT COUNT(*) FROM orders WHERE status = 'cancelled'),
      'today', (SELECT COUNT(*) FROM orders WHERE created_at::DATE = CURRENT_DATE),
      'this_week', (
        SELECT COUNT(*) FROM orders 
        WHERE created_at >= DATE_TRUNC('week', CURRENT_DATE)
      ),
      'this_month', (
        SELECT COUNT(*) FROM orders 
        WHERE created_at >= DATE_TRUNC('month', CURRENT_DATE)
      )
    ),
    
    -- Customer metrics
    'customers', jsonb_build_object(
      'total', (SELECT COUNT(*) FROM customers),
      'new_today', (
        SELECT COUNT(*) FROM customers 
        WHERE created_at::DATE = CURRENT_DATE
      ),
      'new_this_week', (
        SELECT COUNT(*) FROM customers 
        WHERE created_at >= DATE_TRUNC('week', CURRENT_DATE)
      ),
      'new_this_month', (
        SELECT COUNT(*) FROM customers 
        WHERE created_at >= DATE_TRUNC('month', CURRENT_DATE)
      ),
      'with_orders', (
        SELECT COUNT(DISTINCT customer_id) 
        FROM orders 
        WHERE customer_id IS NOT NULL
      )
    ),
    
    -- Product metrics
    'products', jsonb_build_object(
      'total', (SELECT COUNT(*) FROM products),
      'active', (SELECT COUNT(*) FROM products WHERE status = 'active'),
      'low_stock', (
        SELECT COUNT(*) 
        FROM product_variants 
        WHERE COALESCE(available_quantity, inventory_quantity, 0) < 10
          AND COALESCE(available_quantity, inventory_quantity, 0) > 0
      ),
      'out_of_stock', (
        SELECT COUNT(*) 
        FROM product_variants 
        WHERE COALESCE(available_quantity, inventory_quantity, 0) = 0
      ),
      'categories', (
        SELECT COUNT(DISTINCT category) 
        FROM products 
        WHERE category IS NOT NULL
      )
    ),
    
    -- Inventory value
    'inventory', jsonb_build_object(
      'total_value', (
        SELECT COALESCE(SUM(
          COALESCE(available_quantity, inventory_quantity, 0) * price
        ), 0) / 100.0
        FROM product_variants
      ),
      'total_units', (
        SELECT COALESCE(SUM(
          COALESCE(available_quantity, inventory_quantity, 0)
        ), 0)
        FROM product_variants
      )
    ),
    
    -- Recent activity
    'recent_activity', jsonb_build_object(
      'last_order', (
        SELECT created_at 
        FROM orders 
        ORDER BY created_at DESC 
        LIMIT 1
      ),
      'last_customer', (
        SELECT created_at 
        FROM customers 
        ORDER BY created_at DESC 
        LIMIT 1
      ),
      'orders_last_hour', (
        SELECT COUNT(*) 
        FROM orders 
        WHERE created_at > NOW() - INTERVAL '1 hour'
      )
    ),
    
    -- Top sellers (last 30 days)
    'top_products', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'product_id', product_id,
          'product_name', product_name,
          'units_sold', units_sold,
          'revenue', revenue
        ) ORDER BY revenue DESC
      )
      FROM (
        SELECT 
          p.id as product_id,
          p.name as product_name,
          COUNT(DISTINCT o.id) as units_sold,
          SUM(o.total_amount) / 100.0 as revenue
        FROM products p
        JOIN orders o ON o.items @> jsonb_build_array(
          jsonb_build_object('product_id', p.id::text)
        )
        WHERE o.created_at > NOW() - INTERVAL '30 days'
          AND o.financial_status = 'paid'
        GROUP BY p.id, p.name
        ORDER BY revenue DESC
        LIMIT 5
      ) top_products
    ),
    
    -- Performance metrics
    'performance', jsonb_build_object(
      'conversion_rate', 0, -- Would need sessions data
      'average_order_value', (
        SELECT COALESCE(AVG(total_amount), 0) / 100.0
        FROM orders 
        WHERE financial_status = 'paid'
      ),
      'cart_abandonment_rate', 0, -- Would need cart tracking
      'refund_rate', (
        SELECT 
          CASE 
            WHEN COUNT(*) > 0 
            THEN (COUNT(*) FILTER (WHERE financial_status = 'refunded')::DECIMAL / COUNT(*) * 100)
            ELSE 0 
          END
        FROM orders
      )
    ),
    
    'generated_at', NOW()
  );
  
  RETURN v_stats;
END;
$$ LANGUAGE plpgsql;

-- Grant permission
GRANT EXECUTE ON FUNCTION get_dashboard_stats() TO authenticated;

-- ============================================
-- VERIFICATION
-- ============================================

SELECT 
  'Dashboard Stats Function' as component,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.routines 
      WHERE routine_name = 'get_dashboard_stats'
    ) THEN 'CREATED ✅'
    ELSE 'MISSING ❌'
  END as status;

-- Test the function
SELECT get_dashboard_stats() as dashboard_data;