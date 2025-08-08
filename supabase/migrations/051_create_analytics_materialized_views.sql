-- =======================================================
-- KCT Menswear Analytics Materialized Views
-- =======================================================
-- Optimized materialized views for sub-second dashboard performance
-- These views pre-calculate complex analytics for real-time dashboards

-- =======================================================
-- 1. REAL-TIME REVENUE METRICS VIEW
-- =======================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS public.mv_revenue_metrics AS
WITH revenue_periods AS (
  -- Today's revenue
  SELECT 
    'today' as period,
    COALESCE(SUM(revenue), 0) as total_revenue,
    COUNT(DISTINCT CASE WHEN revenue > 0 THEN order_id END) as order_count,
    COALESCE(AVG(CASE WHEN revenue > 0 THEN revenue END), 0) as avg_order_value,
    COUNT(DISTINCT session_id) as sessions,
    ROUND(
      (COUNT(DISTINCT CASE WHEN revenue > 0 THEN order_id END)::DECIMAL / 
       NULLIF(COUNT(DISTINCT session_id), 0) * 100), 2
    ) as conversion_rate
  FROM public.analytics_events 
  WHERE created_at >= CURRENT_DATE
    AND event_category = 'ecommerce'
  
  UNION ALL
  
  -- This week's revenue
  SELECT 
    'week' as period,
    COALESCE(SUM(revenue), 0) as total_revenue,
    COUNT(DISTINCT CASE WHEN revenue > 0 THEN order_id END) as order_count,
    COALESCE(AVG(CASE WHEN revenue > 0 THEN revenue END), 0) as avg_order_value,
    COUNT(DISTINCT session_id) as sessions,
    ROUND(
      (COUNT(DISTINCT CASE WHEN revenue > 0 THEN order_id END)::DECIMAL / 
       NULLIF(COUNT(DISTINCT session_id), 0) * 100), 2
    ) as conversion_rate
  FROM public.analytics_events 
  WHERE created_at >= DATE_TRUNC('week', CURRENT_DATE)
    AND event_category = 'ecommerce'
  
  UNION ALL
  
  -- This month's revenue
  SELECT 
    'month' as period,
    COALESCE(SUM(revenue), 0) as total_revenue,
    COUNT(DISTINCT CASE WHEN revenue > 0 THEN order_id END) as order_count,
    COALESCE(AVG(CASE WHEN revenue > 0 THEN revenue END), 0) as avg_order_value,
    COUNT(DISTINCT session_id) as sessions,
    ROUND(
      (COUNT(DISTINCT CASE WHEN revenue > 0 THEN order_id END)::DECIMAL / 
       NULLIF(COUNT(DISTINCT session_id), 0) * 100), 2
    ) as conversion_rate
  FROM public.analytics_events 
  WHERE created_at >= DATE_TRUNC('month', CURRENT_DATE)
    AND event_category = 'ecommerce'
  
  UNION ALL
  
  -- This year's revenue
  SELECT 
    'year' as period,
    COALESCE(SUM(revenue), 0) as total_revenue,
    COUNT(DISTINCT CASE WHEN revenue > 0 THEN order_id END) as order_count,
    COALESCE(AVG(CASE WHEN revenue > 0 THEN revenue END), 0) as avg_order_value,
    COUNT(DISTINCT session_id) as sessions,
    ROUND(
      (COUNT(DISTINCT CASE WHEN revenue > 0 THEN order_id END)::DECIMAL / 
       NULLIF(COUNT(DISTINCT session_id), 0) * 100), 2
    ) as conversion_rate
  FROM public.analytics_events 
  WHERE created_at >= DATE_TRUNC('year', CURRENT_DATE)
    AND event_category = 'ecommerce'
)
SELECT * FROM revenue_periods;

-- Index for fast lookups
CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_revenue_metrics_period 
  ON public.mv_revenue_metrics(period);

-- =======================================================
-- 2. PRODUCT PERFORMANCE VIEW
-- =======================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS public.mv_product_performance AS
WITH product_metrics AS (
  SELECT 
    ae.product_id,
    p.name as product_name,
    p.price,
    p.category,
    
    -- View metrics
    COUNT(CASE WHEN ae.event_type = 'product_view' THEN 1 END) as views_total,
    COUNT(DISTINCT CASE WHEN ae.event_type = 'product_view' THEN ae.session_id END) as unique_views,
    
    -- Engagement metrics  
    COUNT(CASE WHEN ae.event_type = 'add_to_cart' THEN 1 END) as add_to_cart_count,
    SUM(CASE WHEN ae.event_type = 'add_to_cart' THEN ae.quantity END) as units_added_to_cart,
    
    -- Conversion metrics
    COUNT(DISTINCT CASE WHEN ae.event_type = 'purchase_complete' THEN ae.order_id END) as orders,
    COALESCE(SUM(CASE WHEN ae.event_type = 'purchase_complete' THEN ae.revenue END), 0) as revenue,
    SUM(CASE WHEN ae.event_type = 'purchase_complete' THEN ae.quantity END) as units_sold,
    
    -- Conversion rates
    CASE 
      WHEN COUNT(CASE WHEN ae.event_type = 'product_view' THEN 1 END) > 0 
      THEN ROUND(
        (COUNT(CASE WHEN ae.event_type = 'add_to_cart' THEN 1 END)::DECIMAL / 
         COUNT(CASE WHEN ae.event_type = 'product_view' THEN 1 END) * 100), 2
      )
      ELSE 0 
    END as view_to_cart_rate,
    
    CASE 
      WHEN COUNT(CASE WHEN ae.event_type = 'add_to_cart' THEN 1 END) > 0 
      THEN ROUND(
        (COUNT(DISTINCT CASE WHEN ae.event_type = 'purchase_complete' THEN ae.order_id END)::DECIMAL / 
         COUNT(CASE WHEN ae.event_type = 'add_to_cart' THEN 1 END) * 100), 2
      )
      ELSE 0 
    END as cart_to_purchase_rate,
    
    -- Time-based metrics (last 30 days)
    COUNT(CASE WHEN ae.event_type = 'product_view' AND ae.created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as views_30d,
    COALESCE(SUM(CASE WHEN ae.event_type = 'purchase_complete' AND ae.created_at >= CURRENT_DATE - INTERVAL '30 days' THEN ae.revenue END), 0) as revenue_30d,
    
    -- Performance score (weighted combination of metrics)
    (
      (COUNT(CASE WHEN ae.event_type = 'product_view' THEN 1 END) * 0.3) +
      (COUNT(CASE WHEN ae.event_type = 'add_to_cart' THEN 1 END) * 0.4) +
      (COUNT(DISTINCT CASE WHEN ae.event_type = 'purchase_complete' THEN ae.order_id END) * 0.3)
    ) as performance_score
    
  FROM public.analytics_events ae
  LEFT JOIN public.products p ON ae.product_id = p.id
  WHERE ae.product_id IS NOT NULL
    AND ae.created_at >= CURRENT_DATE - INTERVAL '90 days' -- Last 90 days
  GROUP BY ae.product_id, p.name, p.price, p.category
)
SELECT 
  *,
  RANK() OVER (ORDER BY performance_score DESC) as performance_rank,
  RANK() OVER (ORDER BY views_total DESC) as views_rank,
  RANK() OVER (ORDER BY revenue DESC) as revenue_rank
FROM product_metrics;

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_mv_product_performance_product_id 
  ON public.mv_product_performance(product_id);
CREATE INDEX IF NOT EXISTS idx_mv_product_performance_score 
  ON public.mv_product_performance(performance_score DESC);
CREATE INDEX IF NOT EXISTS idx_mv_product_performance_revenue 
  ON public.mv_product_performance(revenue DESC);

-- =======================================================
-- 3. CUSTOMER BEHAVIOR ANALYTICS VIEW
-- =======================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS public.mv_customer_behavior AS
WITH customer_segments AS (
  -- New vs Returning customers
  SELECT 
    'customer_type' as metric_type,
    
    COUNT(DISTINCT CASE 
      WHEN first_session.session_id IS NOT NULL 
      THEN ae.session_id 
    END) as new_customers,
    
    COUNT(DISTINCT CASE 
      WHEN first_session.session_id IS NULL 
      THEN ae.session_id 
    END) as returning_customers,
    
    -- Customer Lifetime Value segments
    COUNT(DISTINCT CASE 
      WHEN customer_ltv.total_revenue >= 500 
      THEN ae.customer_id 
    END) as high_value_customers,
    
    COUNT(DISTINCT CASE 
      WHEN customer_ltv.total_revenue BETWEEN 100 AND 499 
      THEN ae.customer_id 
    END) as medium_value_customers,
    
    COUNT(DISTINCT CASE 
      WHEN customer_ltv.total_revenue < 100 
      THEN ae.customer_id 
    END) as low_value_customers,
    
    -- Engagement levels
    AVG(session_metrics.avg_session_duration) as avg_session_duration,
    AVG(session_metrics.pages_per_session) as avg_pages_per_session,
    AVG(session_metrics.bounce_rate) as overall_bounce_rate
    
  FROM public.analytics_events ae
  
  -- Identify first sessions (new customers)
  LEFT JOIN (
    SELECT DISTINCT ON (customer_id) 
      customer_id, session_id, created_at
    FROM public.analytics_events 
    WHERE customer_id IS NOT NULL 
      AND event_type = 'session_start'
    ORDER BY customer_id, created_at ASC
  ) first_session ON ae.customer_id = first_session.customer_id 
    AND ae.session_id = first_session.session_id
  
  -- Customer LTV calculation
  LEFT JOIN (
    SELECT 
      customer_id,
      SUM(revenue) as total_revenue,
      COUNT(DISTINCT order_id) as total_orders,
      MAX(created_at) as last_purchase_date
    FROM public.analytics_events 
    WHERE event_type = 'purchase_complete' 
      AND customer_id IS NOT NULL
    GROUP BY customer_id
  ) customer_ltv ON ae.customer_id = customer_ltv.customer_id
  
  -- Session-level metrics
  LEFT JOIN (
    SELECT 
      session_id,
      AVG(time_on_page) as avg_session_duration,
      COUNT(CASE WHEN event_type = 'page_view' THEN 1 END) as pages_per_session,
      CASE WHEN COUNT(CASE WHEN event_type = 'page_view' THEN 1 END) <= 1 THEN 1 ELSE 0 END as bounce_rate
    FROM public.analytics_events 
    GROUP BY session_id
  ) session_metrics ON ae.session_id = session_metrics.session_id
  
  WHERE ae.created_at >= CURRENT_DATE - INTERVAL '30 days'
),

-- Geographic and device insights
geographic_insights AS (
  SELECT 
    'geographic' as metric_type,
    
    -- Top countries by sessions
    array_agg(
      json_build_object(
        'country', country_stats.country,
        'sessions', country_stats.session_count,
        'revenue', country_stats.revenue
      ) ORDER BY country_stats.session_count DESC
    ) FILTER (WHERE country_stats.country IS NOT NULL) as top_countries,
    
    -- Top cities by sessions  
    array_agg(
      json_build_object(
        'city', city_stats.city,
        'sessions', city_stats.session_count
      ) ORDER BY city_stats.session_count DESC
    ) FILTER (WHERE city_stats.city IS NOT NULL) as top_cities,
    
    -- Device type distribution
    SUM(CASE WHEN device_type = 'desktop' THEN 1 ELSE 0 END) as desktop_sessions,
    SUM(CASE WHEN device_type = 'mobile' THEN 1 ELSE 0 END) as mobile_sessions,
    SUM(CASE WHEN device_type = 'tablet' THEN 1 ELSE 0 END) as tablet_sessions
    
  FROM public.analytics_events ae
  LEFT JOIN (
    SELECT 
      country,
      COUNT(DISTINCT session_id) as session_count,
      SUM(revenue) as revenue
    FROM public.analytics_events 
    WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
      AND country IS NOT NULL
    GROUP BY country
    ORDER BY session_count DESC
    LIMIT 10
  ) country_stats ON ae.country = country_stats.country
  
  LEFT JOIN (
    SELECT 
      city,
      COUNT(DISTINCT session_id) as session_count
    FROM public.analytics_events 
    WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
      AND city IS NOT NULL
    GROUP BY city
    ORDER BY session_count DESC
    LIMIT 10
  ) city_stats ON ae.city = city_stats.city
  
  WHERE ae.created_at >= CURRENT_DATE - INTERVAL '30 days'
)

-- Combine all customer behavior metrics
SELECT 
  'behavior_summary' as metric_name,
  json_build_object(
    'new_customers', cs.new_customers,
    'returning_customers', cs.returning_customers,
    'high_value_customers', cs.high_value_customers,
    'medium_value_customers', cs.medium_value_customers,
    'low_value_customers', cs.low_value_customers,
    'avg_session_duration', ROUND(cs.avg_session_duration, 2),
    'avg_pages_per_session', ROUND(cs.avg_pages_per_session, 2),
    'bounce_rate', ROUND(cs.overall_bounce_rate * 100, 2),
    'geographic_data', row_to_json(gi),
    'device_distribution', json_build_object(
      'desktop', gi.desktop_sessions,
      'mobile', gi.mobile_sessions,
      'tablet', gi.tablet_sessions
    )
  ) as metrics
FROM customer_segments cs, geographic_insights gi;

-- =======================================================
-- 4. TRAFFIC METRICS VIEW
-- =======================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS public.mv_traffic_metrics AS
WITH hourly_traffic AS (
  SELECT 
    DATE_TRUNC('hour', created_at) as hour,
    COUNT(DISTINCT session_id) as unique_sessions,
    COUNT(CASE WHEN event_type = 'page_view' THEN 1 END) as page_views,
    COUNT(DISTINCT user_id) FILTER (WHERE user_id IS NOT NULL) as unique_users
  FROM public.analytics_events
  WHERE created_at >= CURRENT_DATE - INTERVAL '24 hours'
  GROUP BY DATE_TRUNC('hour', created_at)
),

daily_traffic AS (
  SELECT 
    DATE_TRUNC('day', created_at) as day,
    COUNT(DISTINCT session_id) as unique_sessions,
    COUNT(CASE WHEN event_type = 'page_view' THEN 1 END) as page_views,
    COUNT(DISTINCT user_id) FILTER (WHERE user_id IS NOT NULL) as unique_users,
    AVG(time_on_page) FILTER (WHERE time_on_page IS NOT NULL) as avg_time_on_page
  FROM public.analytics_events
  WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
  GROUP BY DATE_TRUNC('day', created_at)
),

traffic_sources AS (
  SELECT 
    COALESCE(utm_source, 'direct') as source,
    COUNT(DISTINCT session_id) as sessions,
    COUNT(CASE WHEN event_type = 'page_view' THEN 1 END) as page_views,
    SUM(revenue) FILTER (WHERE revenue IS NOT NULL) as revenue,
    COUNT(DISTINCT CASE WHEN revenue > 0 THEN order_id END) as conversions
  FROM public.analytics_events
  WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
  GROUP BY COALESCE(utm_source, 'direct')
),

top_pages AS (
  SELECT 
    page_url,
    COUNT(*) as page_views,
    COUNT(DISTINCT session_id) as unique_sessions,
    AVG(time_on_page) FILTER (WHERE time_on_page IS NOT NULL) as avg_time_on_page
  FROM public.analytics_events
  WHERE event_type = 'page_view'
    AND created_at >= CURRENT_DATE - INTERVAL '7 days'
    AND page_url IS NOT NULL
  GROUP BY page_url
  ORDER BY page_views DESC
  LIMIT 20
)

SELECT 
  json_build_object(
    'hourly_traffic', (SELECT json_agg(row_to_json(ht)) FROM hourly_traffic ht),
    'daily_traffic', (SELECT json_agg(row_to_json(dt)) FROM daily_traffic dt),
    'traffic_sources', (SELECT json_agg(row_to_json(ts)) FROM traffic_sources ts ORDER BY ts.sessions DESC),
    'top_pages', (SELECT json_agg(row_to_json(tp)) FROM top_pages tp),
    'current_online_users', (
      SELECT COUNT(DISTINCT session_id) 
      FROM public.analytics_events 
      WHERE created_at >= NOW() - INTERVAL '5 minutes'
    ),
    'realtime_stats', json_build_object(
      'sessions_last_hour', (
        SELECT COUNT(DISTINCT session_id) 
        FROM public.analytics_events 
        WHERE created_at >= NOW() - INTERVAL '1 hour'
      ),
      'page_views_last_hour', (
        SELECT COUNT(*) 
        FROM public.analytics_events 
        WHERE event_type = 'page_view' 
        AND created_at >= NOW() - INTERVAL '1 hour'
      ),
      'revenue_last_hour', (
        SELECT COALESCE(SUM(revenue), 0) 
        FROM public.analytics_events 
        WHERE created_at >= NOW() - INTERVAL '1 hour'
        AND revenue > 0
      )
    )
  ) as traffic_data;

-- =======================================================
-- 5. REFRESH FUNCTIONS
-- =======================================================

-- Function to refresh all materialized views
CREATE OR REPLACE FUNCTION refresh_analytics_views()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_revenue_metrics;
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_product_performance;
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_customer_behavior;
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_traffic_metrics;
  
  -- Update the daily summary as well
  PERFORM update_daily_analytics_summary();
END;
$$ LANGUAGE plpgsql;

-- Function to update daily analytics summary
CREATE OR REPLACE FUNCTION update_daily_analytics_summary()
RETURNS void AS $$
BEGIN
  INSERT INTO public.daily_analytics_summary (
    date,
    unique_visitors,
    total_sessions,
    total_page_views,
    avg_session_duration,
    bounce_rate,
    total_orders,
    total_revenue,
    avg_order_value,
    conversion_rate,
    products_viewed,
    products_added_to_cart,
    new_customers,
    returning_customers,
    top_products,
    top_pages,
    top_referrers,
    top_countries
  )
  SELECT 
    CURRENT_DATE,
    COUNT(DISTINCT user_id) FILTER (WHERE user_id IS NOT NULL),
    COUNT(DISTINCT session_id),
    COUNT(CASE WHEN event_type = 'page_view' THEN 1 END),
    AVG(time_on_page) FILTER (WHERE time_on_page IS NOT NULL),
    AVG(CASE WHEN bounce_session.is_bounce THEN 1 ELSE 0 END),
    COUNT(DISTINCT CASE WHEN event_type = 'purchase_complete' THEN order_id END),
    COALESCE(SUM(CASE WHEN event_type = 'purchase_complete' THEN revenue END), 0),
    AVG(CASE WHEN event_type = 'purchase_complete' THEN revenue END),
    CASE 
      WHEN COUNT(DISTINCT session_id) > 0 
      THEN (COUNT(DISTINCT CASE WHEN event_type = 'purchase_complete' THEN order_id END)::DECIMAL / COUNT(DISTINCT session_id) * 100)
      ELSE 0 
    END,
    COUNT(CASE WHEN event_type = 'product_view' THEN 1 END),
    COUNT(CASE WHEN event_type = 'add_to_cart' THEN 1 END),
    0, -- Will be updated by separate query
    0, -- Will be updated by separate query
    '[]'::jsonb, -- Will be updated by separate queries
    '[]'::jsonb,
    '[]'::jsonb,
    '[]'::jsonb
  FROM public.analytics_events ae
  LEFT JOIN (
    SELECT 
      session_id,
      COUNT(CASE WHEN event_type = 'page_view' THEN 1 END) <= 1 as is_bounce
    FROM public.analytics_events 
    WHERE created_at >= CURRENT_DATE
    GROUP BY session_id
  ) bounce_session ON ae.session_id = bounce_session.session_id
  WHERE ae.created_at >= CURRENT_DATE
  
  ON CONFLICT (date) 
  DO UPDATE SET
    unique_visitors = EXCLUDED.unique_visitors,
    total_sessions = EXCLUDED.total_sessions,
    total_page_views = EXCLUDED.total_page_views,
    avg_session_duration = EXCLUDED.avg_session_duration,
    bounce_rate = EXCLUDED.bounce_rate,
    total_orders = EXCLUDED.total_orders,
    total_revenue = EXCLUDED.total_revenue,
    avg_order_value = EXCLUDED.avg_order_value,
    conversion_rate = EXCLUDED.conversion_rate,
    products_viewed = EXCLUDED.products_viewed,
    products_added_to_cart = EXCLUDED.products_added_to_cart,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- =======================================================
-- 6. AUTOMATED REFRESH SCHEDULE
-- =======================================================

-- Note: In Supabase, you would set up pg_cron extension for scheduled refreshes
-- For now, we'll create a function that can be called by the application

CREATE OR REPLACE FUNCTION schedule_analytics_refresh()
RETURNS void AS $$
BEGIN
  -- This would be called periodically (every 15 minutes) by the application
  -- or by a cron job if pg_cron is available
  PERFORM refresh_analytics_views();
END;
$$ LANGUAGE plpgsql;

-- =======================================================
-- MATERIALIZED VIEWS CREATED SUCCESSFULLY
-- =======================================================
-- These views will provide sub-second query performance for:
-- - Revenue metrics (today, week, month, year)
-- - Product performance rankings
-- - Customer behavior insights
-- - Traffic analytics and sources
-- =======================================================