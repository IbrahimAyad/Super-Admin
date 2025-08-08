-- =======================================================
-- KCT Menswear Analytics Functions
-- =======================================================
-- Optimized SQL functions for real-time dashboard queries
-- These functions provide fast access to analytics data

-- =======================================================
-- 1. REVENUE ANALYTICS FUNCTIONS
-- =======================================================

-- Get revenue metrics for any time period
CREATE OR REPLACE FUNCTION get_revenue_metrics(
  period_type TEXT DEFAULT 'today', -- 'today', 'week', 'month', 'year', 'custom'
  start_date DATE DEFAULT NULL,
  end_date DATE DEFAULT NULL
)
RETURNS TABLE(
  total_revenue DECIMAL(12,2),
  order_count INTEGER,
  avg_order_value DECIMAL(10,2),
  conversion_rate DECIMAL(5,2),
  sessions INTEGER,
  revenue_growth DECIMAL(5,2)
) AS $$
DECLARE
  current_start_date DATE;
  current_end_date DATE;
  prev_start_date DATE;
  prev_end_date DATE;
  prev_revenue DECIMAL(12,2);
BEGIN
  -- Set date ranges based on period_type
  CASE period_type
    WHEN 'today' THEN
      current_start_date := CURRENT_DATE;
      current_end_date := CURRENT_DATE + INTERVAL '1 day';
      prev_start_date := CURRENT_DATE - INTERVAL '1 day';
      prev_end_date := CURRENT_DATE;
      
    WHEN 'week' THEN
      current_start_date := DATE_TRUNC('week', CURRENT_DATE);
      current_end_date := DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 week';
      prev_start_date := DATE_TRUNC('week', CURRENT_DATE) - INTERVAL '1 week';
      prev_end_date := DATE_TRUNC('week', CURRENT_DATE);
      
    WHEN 'month' THEN
      current_start_date := DATE_TRUNC('month', CURRENT_DATE);
      current_end_date := DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month';
      prev_start_date := DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '1 month';
      prev_end_date := DATE_TRUNC('month', CURRENT_DATE);
      
    WHEN 'year' THEN
      current_start_date := DATE_TRUNC('year', CURRENT_DATE);
      current_end_date := DATE_TRUNC('year', CURRENT_DATE) + INTERVAL '1 year';
      prev_start_date := DATE_TRUNC('year', CURRENT_DATE) - INTERVAL '1 year';
      prev_end_date := DATE_TRUNC('year', CURRENT_DATE);
      
    WHEN 'custom' THEN
      current_start_date := COALESCE(start_date, CURRENT_DATE - INTERVAL '30 days');
      current_end_date := COALESCE(end_date, CURRENT_DATE + INTERVAL '1 day');
      prev_start_date := current_start_date - (current_end_date - current_start_date);
      prev_end_date := current_start_date;
      
    ELSE
      current_start_date := CURRENT_DATE;
      current_end_date := CURRENT_DATE + INTERVAL '1 day';
      prev_start_date := CURRENT_DATE - INTERVAL '1 day';
      prev_end_date := CURRENT_DATE;
  END CASE;
  
  -- Get previous period revenue for growth calculation
  SELECT COALESCE(SUM(ae.revenue), 0)
  INTO prev_revenue
  FROM public.analytics_events ae
  WHERE ae.created_at >= prev_start_date 
    AND ae.created_at < prev_end_date
    AND ae.event_type = 'purchase_complete'
    AND ae.revenue > 0;
  
  -- Return current period metrics
  RETURN QUERY
  SELECT 
    COALESCE(SUM(ae.revenue), 0) as total_revenue,
    COUNT(DISTINCT ae.order_id)::INTEGER as order_count,
    COALESCE(AVG(ae.revenue), 0) as avg_order_value,
    CASE 
      WHEN COUNT(DISTINCT ae.session_id) > 0 
      THEN ROUND((COUNT(DISTINCT ae.order_id)::DECIMAL / COUNT(DISTINCT ae.session_id) * 100), 2)
      ELSE 0::DECIMAL(5,2)
    END as conversion_rate,
    COUNT(DISTINCT ae.session_id)::INTEGER as sessions,
    CASE 
      WHEN prev_revenue > 0 
      THEN ROUND(((COALESCE(SUM(ae.revenue), 0) - prev_revenue) / prev_revenue * 100), 2)
      ELSE 0::DECIMAL(5,2)
    END as revenue_growth
  FROM public.analytics_events ae
  WHERE ae.created_at >= current_start_date 
    AND ae.created_at < current_end_date
    AND ae.event_category = 'ecommerce';
END;
$$ LANGUAGE plpgsql;

-- Get hourly revenue trend for today
CREATE OR REPLACE FUNCTION get_hourly_revenue_trend()
RETURNS TABLE(
  hour TIMESTAMPTZ,
  revenue DECIMAL(10,2),
  orders INTEGER,
  sessions INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    DATE_TRUNC('hour', ae.created_at) as hour,
    COALESCE(SUM(ae.revenue), 0) as revenue,
    COUNT(DISTINCT ae.order_id)::INTEGER as orders,
    COUNT(DISTINCT ae.session_id)::INTEGER as sessions
  FROM public.analytics_events ae
  WHERE ae.created_at >= CURRENT_DATE
    AND ae.created_at < CURRENT_DATE + INTERVAL '1 day'
    AND ae.event_category = 'ecommerce'
  GROUP BY DATE_TRUNC('hour', ae.created_at)
  ORDER BY hour;
END;
$$ LANGUAGE plpgsql;

-- =======================================================
-- 2. ORDER ANALYTICS FUNCTIONS
-- =======================================================

-- Get detailed order analytics
CREATE OR REPLACE FUNCTION get_order_analytics(
  days_back INTEGER DEFAULT 30
)
RETURNS TABLE(
  total_orders INTEGER,
  completed_orders INTEGER,
  pending_orders INTEGER,
  cancelled_orders INTEGER,
  avg_order_value DECIMAL(10,2),
  avg_items_per_order DECIMAL(5,2),
  top_payment_methods JSONB,
  order_status_distribution JSONB,
  daily_order_trend JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(DISTINCT ae.order_id)::INTEGER as total_orders,
    COUNT(DISTINCT CASE WHEN ae.event_type = 'purchase_complete' THEN ae.order_id END)::INTEGER as completed_orders,
    COUNT(DISTINCT CASE WHEN ae.event_type = 'checkout_complete' AND NOT EXISTS(
      SELECT 1 FROM public.analytics_events ae2 
      WHERE ae2.order_id = ae.order_id AND ae2.event_type = 'purchase_complete'
    ) THEN ae.order_id END)::INTEGER as pending_orders,
    0::INTEGER as cancelled_orders, -- This would come from order status in your orders table
    COALESCE(AVG(ae.revenue), 0) as avg_order_value,
    COALESCE(AVG(ae.quantity), 0) as avg_items_per_order,
    
    -- Top payment methods (from properties)
    COALESCE(
      (SELECT jsonb_agg(payment_method_stats ORDER BY order_count DESC)
       FROM (
         SELECT 
           ae.properties->>'payment_method' as payment_method,
           COUNT(*) as order_count
         FROM public.analytics_events ae
         WHERE ae.event_type = 'purchase_complete'
           AND ae.created_at >= CURRENT_DATE - INTERVAL '%s days'
           AND ae.properties->>'payment_method' IS NOT NULL
         GROUP BY ae.properties->>'payment_method'
         ORDER BY order_count DESC
         LIMIT 5
       ) payment_method_stats), 
      '[]'::jsonb
    ) as top_payment_methods,
    
    -- Order status distribution
    jsonb_build_object(
      'completed', COUNT(DISTINCT CASE WHEN ae.event_type = 'purchase_complete' THEN ae.order_id END),
      'pending', COUNT(DISTINCT CASE WHEN ae.event_type = 'checkout_complete' AND NOT EXISTS(
        SELECT 1 FROM public.analytics_events ae2 
        WHERE ae2.order_id = ae.order_id AND ae2.event_type = 'purchase_complete'
      ) THEN ae.order_id END),
      'cancelled', 0
    ) as order_status_distribution,
    
    -- Daily order trend
    COALESCE(
      (SELECT jsonb_agg(daily_stats ORDER BY day)
       FROM (
         SELECT 
           DATE_TRUNC('day', ae.created_at) as day,
           COUNT(DISTINCT ae.order_id) as orders,
           COALESCE(SUM(ae.revenue), 0) as revenue
         FROM public.analytics_events ae
         WHERE ae.event_type = 'purchase_complete'
           AND ae.created_at >= CURRENT_DATE - INTERVAL '%s days'
         GROUP BY DATE_TRUNC('day', ae.created_at)
         ORDER BY day
       ) daily_stats), 
      '[]'::jsonb
    ) as daily_order_trend
    
  FROM public.analytics_events ae
  WHERE ae.created_at >= CURRENT_DATE - (days_back || ' days')::INTERVAL
    AND ae.event_category = 'ecommerce'
    AND ae.order_id IS NOT NULL;
END;
$$ LANGUAGE plpgsql;

-- =======================================================
-- 3. PRODUCT PERFORMANCE FUNCTIONS
-- =======================================================

-- Get top performing products
CREATE OR REPLACE FUNCTION get_top_products(
  metric_type TEXT DEFAULT 'revenue', -- 'revenue', 'views', 'conversions', 'units_sold'
  limit_count INTEGER DEFAULT 10,
  days_back INTEGER DEFAULT 30
)
RETURNS TABLE(
  product_id UUID,
  product_name TEXT,
  category TEXT,
  price DECIMAL(10,2),
  metric_value DECIMAL(12,2),
  views INTEGER,
  add_to_cart_count INTEGER,
  orders INTEGER,
  revenue DECIMAL(12,2),
  units_sold INTEGER,
  conversion_rate DECIMAL(5,2)
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ae.product_id,
    p.name as product_name,
    p.category,
    p.price,
    CASE metric_type
      WHEN 'revenue' THEN COALESCE(SUM(ae.revenue), 0)
      WHEN 'views' THEN COUNT(CASE WHEN ae.event_type = 'product_view' THEN 1 END)::DECIMAL
      WHEN 'conversions' THEN COUNT(DISTINCT ae.order_id)::DECIMAL
      WHEN 'units_sold' THEN SUM(CASE WHEN ae.event_type = 'purchase_complete' THEN ae.quantity ELSE 0 END)::DECIMAL
      ELSE COALESCE(SUM(ae.revenue), 0)
    END as metric_value,
    COUNT(CASE WHEN ae.event_type = 'product_view' THEN 1 END)::INTEGER as views,
    COUNT(CASE WHEN ae.event_type = 'add_to_cart' THEN 1 END)::INTEGER as add_to_cart_count,
    COUNT(DISTINCT CASE WHEN ae.event_type = 'purchase_complete' THEN ae.order_id END)::INTEGER as orders,
    COALESCE(SUM(CASE WHEN ae.event_type = 'purchase_complete' THEN ae.revenue ELSE 0 END), 0) as revenue,
    COALESCE(SUM(CASE WHEN ae.event_type = 'purchase_complete' THEN ae.quantity ELSE 0 END), 0)::INTEGER as units_sold,
    CASE 
      WHEN COUNT(CASE WHEN ae.event_type = 'product_view' THEN 1 END) > 0
      THEN ROUND((COUNT(DISTINCT CASE WHEN ae.event_type = 'purchase_complete' THEN ae.order_id END)::DECIMAL / 
                  COUNT(CASE WHEN ae.event_type = 'product_view' THEN 1 END) * 100), 2)
      ELSE 0::DECIMAL(5,2)
    END as conversion_rate
  FROM public.analytics_events ae
  LEFT JOIN public.products p ON ae.product_id = p.id
  WHERE ae.product_id IS NOT NULL
    AND ae.created_at >= CURRENT_DATE - (days_back || ' days')::INTERVAL
  GROUP BY ae.product_id, p.name, p.category, p.price
  ORDER BY metric_value DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Get product conversion funnel
CREATE OR REPLACE FUNCTION get_product_conversion_funnel(
  input_product_id UUID,
  days_back INTEGER DEFAULT 30
)
RETURNS TABLE(
  product_id UUID,
  product_name TEXT,
  views INTEGER,
  add_to_cart INTEGER,
  checkout_starts INTEGER,
  purchases INTEGER,
  view_to_cart_rate DECIMAL(5,2),
  cart_to_checkout_rate DECIMAL(5,2),
  checkout_to_purchase_rate DECIMAL(5,2),
  overall_conversion_rate DECIMAL(5,2)
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ae.product_id,
    p.name as product_name,
    COUNT(CASE WHEN ae.event_type = 'product_view' THEN 1 END)::INTEGER as views,
    COUNT(CASE WHEN ae.event_type = 'add_to_cart' THEN 1 END)::INTEGER as add_to_cart,
    COUNT(CASE WHEN ae.event_type = 'checkout_start' THEN 1 END)::INTEGER as checkout_starts,
    COUNT(CASE WHEN ae.event_type = 'purchase_complete' THEN 1 END)::INTEGER as purchases,
    
    CASE 
      WHEN COUNT(CASE WHEN ae.event_type = 'product_view' THEN 1 END) > 0
      THEN ROUND((COUNT(CASE WHEN ae.event_type = 'add_to_cart' THEN 1 END)::DECIMAL / 
                  COUNT(CASE WHEN ae.event_type = 'product_view' THEN 1 END) * 100), 2)
      ELSE 0::DECIMAL(5,2)
    END as view_to_cart_rate,
    
    CASE 
      WHEN COUNT(CASE WHEN ae.event_type = 'add_to_cart' THEN 1 END) > 0
      THEN ROUND((COUNT(CASE WHEN ae.event_type = 'checkout_start' THEN 1 END)::DECIMAL / 
                  COUNT(CASE WHEN ae.event_type = 'add_to_cart' THEN 1 END) * 100), 2)
      ELSE 0::DECIMAL(5,2)
    END as cart_to_checkout_rate,
    
    CASE 
      WHEN COUNT(CASE WHEN ae.event_type = 'checkout_start' THEN 1 END) > 0
      THEN ROUND((COUNT(CASE WHEN ae.event_type = 'purchase_complete' THEN 1 END)::DECIMAL / 
                  COUNT(CASE WHEN ae.event_type = 'checkout_start' THEN 1 END) * 100), 2)
      ELSE 0::DECIMAL(5,2)
    END as checkout_to_purchase_rate,
    
    CASE 
      WHEN COUNT(CASE WHEN ae.event_type = 'product_view' THEN 1 END) > 0
      THEN ROUND((COUNT(CASE WHEN ae.event_type = 'purchase_complete' THEN 1 END)::DECIMAL / 
                  COUNT(CASE WHEN ae.event_type = 'product_view' THEN 1 END) * 100), 2)
      ELSE 0::DECIMAL(5,2)
    END as overall_conversion_rate
    
  FROM public.analytics_events ae
  LEFT JOIN public.products p ON ae.product_id = p.id
  WHERE ae.product_id = input_product_id
    AND ae.created_at >= CURRENT_DATE - (days_back || ' days')::INTERVAL
  GROUP BY ae.product_id, p.name;
END;
$$ LANGUAGE plpgsql;

-- =======================================================
-- 4. CUSTOMER BEHAVIOR FUNCTIONS
-- =======================================================

-- Get customer lifetime value analytics
CREATE OR REPLACE FUNCTION get_customer_ltv_analytics()
RETURNS TABLE(
  total_customers INTEGER,
  avg_ltv DECIMAL(10,2),
  ltv_segments JSONB,
  top_customers JSONB,
  customer_retention JSONB
) AS $$
BEGIN
  RETURN QUERY
  WITH customer_ltv AS (
    SELECT 
      ae.customer_id,
      SUM(ae.revenue) as lifetime_value,
      COUNT(DISTINCT ae.order_id) as total_orders,
      MIN(ae.created_at) as first_purchase,
      MAX(ae.created_at) as last_purchase,
      EXTRACT(DAYS FROM (MAX(ae.created_at) - MIN(ae.created_at)))::INTEGER as customer_lifespan_days
    FROM public.analytics_events ae
    WHERE ae.event_type = 'purchase_complete' 
      AND ae.customer_id IS NOT NULL
      AND ae.revenue > 0
    GROUP BY ae.customer_id
  )
  SELECT 
    COUNT(*)::INTEGER as total_customers,
    ROUND(AVG(lifetime_value), 2) as avg_ltv,
    
    -- LTV segments
    jsonb_build_object(
      'high_value', COUNT(*) FILTER (WHERE lifetime_value >= 500),
      'medium_value', COUNT(*) FILTER (WHERE lifetime_value BETWEEN 100 AND 499),
      'low_value', COUNT(*) FILTER (WHERE lifetime_value < 100)
    ) as ltv_segments,
    
    -- Top 10 customers by LTV
    (SELECT jsonb_agg(customer_data ORDER BY lifetime_value DESC)
     FROM (
       SELECT customer_id, lifetime_value, total_orders
       FROM customer_ltv
       ORDER BY lifetime_value DESC
       LIMIT 10
     ) customer_data
    ) as top_customers,
    
    -- Customer retention metrics
    jsonb_build_object(
      'repeat_customers', COUNT(*) FILTER (WHERE total_orders > 1),
      'one_time_customers', COUNT(*) FILTER (WHERE total_orders = 1),
      'avg_orders_per_customer', ROUND(AVG(total_orders), 2),
      'avg_customer_lifespan_days', ROUND(AVG(customer_lifespan_days), 0)
    ) as customer_retention
    
  FROM customer_ltv;
END;
$$ LANGUAGE plpgsql;

-- Get real-time customer activity
CREATE OR REPLACE FUNCTION get_realtime_customer_activity(
  minutes_back INTEGER DEFAULT 60
)
RETURNS TABLE(
  active_sessions INTEGER,
  active_customers INTEGER,
  recent_events JSONB,
  current_cart_value DECIMAL(10,2),
  conversion_events INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(DISTINCT ae.session_id)::INTEGER as active_sessions,
    COUNT(DISTINCT ae.customer_id) FILTER (WHERE ae.customer_id IS NOT NULL)::INTEGER as active_customers,
    
    -- Recent events (last 10)
    (SELECT jsonb_agg(event_data ORDER BY created_at DESC)
     FROM (
       SELECT 
         event_type,
         event_category,
         created_at,
         properties,
         CASE WHEN product_id IS NOT NULL THEN
           (SELECT name FROM public.products WHERE id = product_id)
         END as product_name
       FROM public.analytics_events
       WHERE created_at >= NOW() - (minutes_back || ' minutes')::INTERVAL
       ORDER BY created_at DESC
       LIMIT 10
     ) event_data
    ) as recent_events,
    
    -- Current cart value (items in cart)
    COALESCE(SUM(CASE WHEN ae.event_type = 'add_to_cart' THEN ae.revenue ELSE 0 END), 0) as current_cart_value,
    
    -- Recent conversions
    COUNT(CASE WHEN ae.event_type = 'purchase_complete' THEN 1 END)::INTEGER as conversion_events
    
  FROM public.analytics_events ae
  WHERE ae.created_at >= NOW() - (minutes_back || ' minutes')::INTERVAL;
END;
$$ LANGUAGE plpgsql;

-- =======================================================
-- 5. TRAFFIC AND SOURCE ANALYTICS
-- =======================================================

-- Get traffic source performance
CREATE OR REPLACE FUNCTION get_traffic_source_performance(
  days_back INTEGER DEFAULT 30
)
RETURNS TABLE(
  source TEXT,
  sessions INTEGER,
  users INTEGER,
  page_views INTEGER,
  avg_session_duration DECIMAL(8,2),
  bounce_rate DECIMAL(5,2),
  conversions INTEGER,
  revenue DECIMAL(12,2),
  conversion_rate DECIMAL(5,2)
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(ae.utm_source, 'direct') as source,
    COUNT(DISTINCT ae.session_id)::INTEGER as sessions,
    COUNT(DISTINCT ae.user_id) FILTER (WHERE ae.user_id IS NOT NULL)::INTEGER as users,
    COUNT(CASE WHEN ae.event_type = 'page_view' THEN 1 END)::INTEGER as page_views,
    
    ROUND(AVG(ae.time_on_page) FILTER (WHERE ae.time_on_page IS NOT NULL), 2) as avg_session_duration,
    
    -- Bounce rate calculation
    ROUND((COUNT(DISTINCT bounced_sessions.session_id)::DECIMAL / 
           NULLIF(COUNT(DISTINCT ae.session_id), 0) * 100), 2) as bounce_rate,
    
    COUNT(DISTINCT CASE WHEN ae.event_type = 'purchase_complete' THEN ae.order_id END)::INTEGER as conversions,
    COALESCE(SUM(CASE WHEN ae.event_type = 'purchase_complete' THEN ae.revenue ELSE 0 END), 0) as revenue,
    
    ROUND((COUNT(DISTINCT CASE WHEN ae.event_type = 'purchase_complete' THEN ae.order_id END)::DECIMAL / 
           NULLIF(COUNT(DISTINCT ae.session_id), 0) * 100), 2) as conversion_rate
    
  FROM public.analytics_events ae
  LEFT JOIN (
    -- Sessions with only one page view (bounced)
    SELECT session_id
    FROM public.analytics_events
    WHERE event_type = 'page_view'
      AND created_at >= CURRENT_DATE - (days_back || ' days')::INTERVAL
    GROUP BY session_id
    HAVING COUNT(*) = 1
  ) bounced_sessions ON ae.session_id = bounced_sessions.session_id
  
  WHERE ae.created_at >= CURRENT_DATE - (days_back || ' days')::INTERVAL
  GROUP BY COALESCE(ae.utm_source, 'direct')
  ORDER BY sessions DESC;
END;
$$ LANGUAGE plpgsql;

-- Get real-time website metrics
CREATE OR REPLACE FUNCTION get_realtime_website_metrics()
RETURNS TABLE(
  current_online_users INTEGER,
  page_views_last_hour INTEGER,
  sessions_last_hour INTEGER,
  top_pages_now JSONB,
  active_countries JSONB,
  device_breakdown JSONB,
  recent_conversions JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    -- Users active in last 5 minutes
    COUNT(DISTINCT CASE 
      WHEN ae.created_at >= NOW() - INTERVAL '5 minutes' 
      THEN ae.session_id 
    END)::INTEGER as current_online_users,
    
    -- Page views in last hour
    COUNT(CASE 
      WHEN ae.event_type = 'page_view' 
      AND ae.created_at >= NOW() - INTERVAL '1 hour'
      THEN 1 
    END)::INTEGER as page_views_last_hour,
    
    -- Sessions in last hour
    COUNT(DISTINCT CASE 
      WHEN ae.created_at >= NOW() - INTERVAL '1 hour'
      THEN ae.session_id 
    END)::INTEGER as sessions_last_hour,
    
    -- Top pages being viewed now
    (SELECT jsonb_agg(page_stats ORDER BY views DESC)
     FROM (
       SELECT 
         page_url,
         COUNT(*) as views
       FROM public.analytics_events
       WHERE event_type = 'page_view'
         AND created_at >= NOW() - INTERVAL '1 hour'
         AND page_url IS NOT NULL
       GROUP BY page_url
       ORDER BY views DESC
       LIMIT 5
     ) page_stats
    ) as top_pages_now,
    
    -- Active countries
    (SELECT jsonb_agg(country_stats ORDER BY sessions DESC)
     FROM (
       SELECT 
         country,
         COUNT(DISTINCT session_id) as sessions
       FROM public.analytics_events
       WHERE created_at >= NOW() - INTERVAL '1 hour'
         AND country IS NOT NULL
       GROUP BY country
       ORDER BY sessions DESC
       LIMIT 5
     ) country_stats
    ) as active_countries,
    
    -- Device breakdown
    jsonb_build_object(
      'desktop', COUNT(DISTINCT CASE WHEN ae.device_type = 'desktop' AND ae.created_at >= NOW() - INTERVAL '1 hour' THEN ae.session_id END),
      'mobile', COUNT(DISTINCT CASE WHEN ae.device_type = 'mobile' AND ae.created_at >= NOW() - INTERVAL '1 hour' THEN ae.session_id END),
      'tablet', COUNT(DISTINCT CASE WHEN ae.device_type = 'tablet' AND ae.created_at >= NOW() - INTERVAL '1 hour' THEN ae.session_id END)
    ) as device_breakdown,
    
    -- Recent conversions
    (SELECT jsonb_agg(conversion_data ORDER BY created_at DESC)
     FROM (
       SELECT 
         created_at,
         revenue,
         properties->>'customer_email' as customer_email,
         (SELECT name FROM public.products WHERE id = ae.product_id) as product_name
       FROM public.analytics_events ae
       WHERE event_type = 'purchase_complete'
         AND created_at >= NOW() - INTERVAL '24 hours'
       ORDER BY created_at DESC
       LIMIT 10
     ) conversion_data
    ) as recent_conversions
    
  FROM public.analytics_events ae
  WHERE ae.created_at >= NOW() - INTERVAL '1 day';
END;
$$ LANGUAGE plpgsql;

-- =======================================================
-- 6. ADMIN ACTIVITY TRACKING FUNCTIONS
-- =======================================================

-- Get admin activity analytics
CREATE OR REPLACE FUNCTION get_admin_activity_analytics(
  days_back INTEGER DEFAULT 7
)
RETURNS TABLE(
  total_admin_actions INTEGER,
  active_admins INTEGER,
  top_actions JSONB,
  hourly_activity JSONB,
  admin_performance JSONB
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::INTEGER as total_admin_actions,
    COUNT(DISTINCT ae.admin_user_id)::INTEGER as active_admins,
    
    -- Top admin actions
    (SELECT jsonb_agg(action_stats ORDER BY action_count DESC)
     FROM (
       SELECT 
         admin_action_type,
         COUNT(*) as action_count
       FROM public.analytics_events
       WHERE event_category = 'admin'
         AND created_at >= CURRENT_DATE - (days_back || ' days')::INTERVAL
         AND admin_action_type IS NOT NULL
       GROUP BY admin_action_type
       ORDER BY action_count DESC
       LIMIT 10
     ) action_stats
    ) as top_actions,
    
    -- Hourly activity pattern
    (SELECT jsonb_agg(hourly_stats ORDER BY hour)
     FROM (
       SELECT 
         EXTRACT(HOUR FROM created_at) as hour,
         COUNT(*) as actions
       FROM public.analytics_events
       WHERE event_category = 'admin'
         AND created_at >= CURRENT_DATE - (days_back || ' days')::INTERVAL
       GROUP BY EXTRACT(HOUR FROM created_at)
       ORDER BY hour
     ) hourly_stats
    ) as hourly_activity,
    
    -- Individual admin performance
    (SELECT jsonb_agg(admin_stats ORDER BY action_count DESC)
     FROM (
       SELECT 
         admin_user_id,
         COUNT(*) as action_count,
         COUNT(DISTINCT admin_action_type) as unique_actions,
         MAX(created_at) as last_active
       FROM public.analytics_events
       WHERE event_category = 'admin'
         AND created_at >= CURRENT_DATE - (days_back || ' days')::INTERVAL
         AND admin_user_id IS NOT NULL
       GROUP BY admin_user_id
       ORDER BY action_count DESC
     ) admin_stats
    ) as admin_performance
    
  FROM public.analytics_events ae
  WHERE ae.event_category = 'admin'
    AND ae.created_at >= CURRENT_DATE - (days_back || ' days')::INTERVAL;
END;
$$ LANGUAGE plpgsql;

-- =======================================================
-- 7. GRANTS AND PERMISSIONS
-- =======================================================

-- Grant execute permissions to authenticated users (admins)
GRANT EXECUTE ON FUNCTION get_revenue_metrics(TEXT, DATE, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION get_hourly_revenue_trend() TO authenticated;
GRANT EXECUTE ON FUNCTION get_order_analytics(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_top_products(TEXT, INTEGER, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_product_conversion_funnel(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_customer_ltv_analytics() TO authenticated;
GRANT EXECUTE ON FUNCTION get_realtime_customer_activity(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_traffic_source_performance(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION get_realtime_website_metrics() TO authenticated;
GRANT EXECUTE ON FUNCTION get_admin_activity_analytics(INTEGER) TO authenticated;

-- Grant to service_role for server-side operations
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO service_role;

-- =======================================================
-- ANALYTICS FUNCTIONS CREATED SUCCESSFULLY
-- =======================================================
-- These functions provide optimized queries for:
-- - Revenue metrics with growth calculations
-- - Order analytics and trends
-- - Product performance and conversion funnels
-- - Customer lifetime value and behavior
-- - Traffic source analysis
-- - Real-time website metrics
-- - Admin activity tracking
-- =======================================================