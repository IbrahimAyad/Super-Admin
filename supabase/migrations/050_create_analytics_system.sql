-- =======================================================
-- KCT Menswear Real-Time Analytics System
-- =======================================================
-- This migration creates a comprehensive analytics system for tracking:
-- - Page views and user sessions
-- - E-commerce events (views, add to cart, purchases)
-- - Admin actions and system events
-- - Customer behavior patterns
-- - Performance metrics

-- =======================================================
-- 1. ANALYTICS EVENTS TABLE
-- =======================================================

-- Main events table for all analytics tracking
CREATE TABLE IF NOT EXISTS public.analytics_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  
  -- Event identification
  event_type TEXT NOT NULL CHECK (event_type IN (
    -- Website events
    'page_view', 'session_start', 'session_end',
    -- E-commerce events
    'product_view', 'add_to_cart', 'remove_from_cart', 'checkout_start', 
    'checkout_complete', 'purchase_complete',
    -- Admin events
    'admin_login', 'admin_action', 'admin_export', 'admin_bulk_action',
    -- Customer events
    'user_register', 'user_login', 'user_logout', 'profile_update',
    -- Search and navigation
    'search', 'filter_applied', 'category_view',
    -- Marketing
    'email_open', 'email_click', 'campaign_view'
  )),
  event_category TEXT NOT NULL CHECK (event_category IN (
    'website', 'ecommerce', 'admin', 'customer', 'marketing', 'system'
  )),
  
  -- Session and user tracking
  session_id UUID NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  customer_id UUID,
  
  -- Event data
  properties JSONB DEFAULT '{}',
  
  -- Page/referrer information
  page_url TEXT,
  page_title TEXT,
  referrer TEXT,
  utm_source TEXT,
  utm_medium TEXT,
  utm_campaign TEXT,
  
  -- Device/browser information
  user_agent TEXT,
  ip_address INET,
  device_type TEXT CHECK (device_type IN ('desktop', 'mobile', 'tablet')),
  browser TEXT,
  os TEXT,
  country TEXT,
  city TEXT,
  
  -- E-commerce specific fields
  product_id UUID,
  variant_id UUID,
  order_id UUID,
  revenue DECIMAL(10,2),
  currency TEXT DEFAULT 'GBP',
  quantity INTEGER,
  
  -- Admin specific fields
  admin_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  admin_action_type TEXT,
  affected_resource TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Performance tracking
  page_load_time INTEGER, -- milliseconds
  time_on_page INTEGER     -- seconds
);

-- =======================================================
-- 2. USER SESSIONS TABLE
-- =======================================================

-- Track user sessions for better analytics
CREATE TABLE IF NOT EXISTS public.user_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id UUID UNIQUE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  customer_id UUID,
  
  -- Session details
  started_at TIMESTAMPTZ DEFAULT NOW(),
  ended_at TIMESTAMPTZ,
  duration_seconds INTEGER,
  page_views INTEGER DEFAULT 0,
  
  -- First page information
  landing_page TEXT,
  referrer TEXT,
  utm_source TEXT,
  utm_medium TEXT,
  utm_campaign TEXT,
  
  -- Device information
  device_type TEXT CHECK (device_type IN ('desktop', 'mobile', 'tablet')),
  browser TEXT,
  os TEXT,
  country TEXT,
  city TEXT,
  ip_address INET,
  
  -- Conversion tracking
  converted BOOLEAN DEFAULT FALSE,
  conversion_value DECIMAL(10,2),
  
  -- Behavioral metrics
  bounce_rate BOOLEAN DEFAULT FALSE, -- true if only viewed one page
  pages_per_session INTEGER DEFAULT 0,
  avg_time_per_page DECIMAL(8,2),
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =======================================================
-- 3. DAILY ANALYTICS SUMMARY TABLE
-- =======================================================

-- Pre-aggregated daily metrics for faster dashboard queries
CREATE TABLE IF NOT EXISTS public.daily_analytics_summary (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  date DATE NOT NULL,
  
  -- Traffic metrics
  unique_visitors INTEGER DEFAULT 0,
  total_sessions INTEGER DEFAULT 0,
  total_page_views INTEGER DEFAULT 0,
  avg_session_duration DECIMAL(8,2) DEFAULT 0,
  bounce_rate DECIMAL(5,4) DEFAULT 0,
  
  -- E-commerce metrics
  total_orders INTEGER DEFAULT 0,
  total_revenue DECIMAL(12,2) DEFAULT 0,
  avg_order_value DECIMAL(10,2) DEFAULT 0,
  conversion_rate DECIMAL(5,4) DEFAULT 0,
  
  -- Product metrics
  products_viewed INTEGER DEFAULT 0,
  products_added_to_cart INTEGER DEFAULT 0,
  
  -- Customer metrics
  new_customers INTEGER DEFAULT 0,
  returning_customers INTEGER DEFAULT 0,
  
  -- Top performers (stored as JSONB for flexibility)
  top_products JSONB DEFAULT '[]',
  top_pages JSONB DEFAULT '[]',
  top_referrers JSONB DEFAULT '[]',
  top_countries JSONB DEFAULT '[]',
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Ensure one record per date
  UNIQUE(date)
);

-- =======================================================
-- 4. PRODUCT ANALYTICS TABLE
-- =======================================================

-- Track product-specific analytics
CREATE TABLE IF NOT EXISTS public.product_analytics (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID NOT NULL,
  date DATE NOT NULL,
  
  -- View metrics
  views INTEGER DEFAULT 0,
  unique_viewers INTEGER DEFAULT 0,
  
  -- Engagement metrics
  add_to_cart_count INTEGER DEFAULT 0,
  remove_from_cart_count INTEGER DEFAULT 0,
  wishlist_adds INTEGER DEFAULT 0,
  
  -- Conversion metrics
  orders INTEGER DEFAULT 0,
  revenue DECIMAL(12,2) DEFAULT 0,
  units_sold INTEGER DEFAULT 0,
  conversion_rate DECIMAL(5,4) DEFAULT 0,
  
  -- Performance metrics
  avg_time_on_page DECIMAL(8,2) DEFAULT 0,
  bounce_rate DECIMAL(5,4) DEFAULT 0,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Ensure one record per product per date
  UNIQUE(product_id, date)
);

-- =======================================================
-- 5. INDEXES FOR OPTIMAL PERFORMANCE
-- =======================================================

-- Analytics events indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_analytics_events_created_at 
  ON public.analytics_events(created_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_analytics_events_session_id 
  ON public.analytics_events(session_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_analytics_events_user_id 
  ON public.analytics_events(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_analytics_events_event_type_created_at 
  ON public.analytics_events(event_type, created_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_analytics_events_category_created_at 
  ON public.analytics_events(event_category, created_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_analytics_events_product_id 
  ON public.analytics_events(product_id) WHERE product_id IS NOT NULL;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_analytics_events_order_id 
  ON public.analytics_events(order_id) WHERE order_id IS NOT NULL;

-- User sessions indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_sessions_started_at 
  ON public.user_sessions(started_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_sessions_user_id 
  ON public.user_sessions(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_sessions_session_id 
  ON public.user_sessions(session_id);

-- Daily summary indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_daily_analytics_summary_date 
  ON public.daily_analytics_summary(date DESC);

-- Product analytics indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_product_analytics_product_date 
  ON public.product_analytics(product_id, date DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_product_analytics_date 
  ON public.product_analytics(date DESC);

-- Composite indexes for common queries
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_analytics_events_ecommerce 
  ON public.analytics_events(event_category, created_at DESC, revenue) 
  WHERE event_category = 'ecommerce';
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_analytics_events_revenue 
  ON public.analytics_events(created_at DESC, revenue) 
  WHERE revenue IS NOT NULL AND revenue > 0;

-- =======================================================
-- 6. TRIGGERS AND FUNCTIONS
-- =======================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_user_sessions_updated_at
  BEFORE UPDATE ON public.user_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daily_analytics_summary_updated_at
  BEFORE UPDATE ON public.daily_analytics_summary
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_product_analytics_updated_at
  BEFORE UPDATE ON public.product_analytics
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to automatically end sessions
CREATE OR REPLACE FUNCTION end_user_session()
RETURNS TRIGGER AS $$
BEGIN
  -- Calculate duration when session ends
  IF NEW.ended_at IS NOT NULL AND OLD.ended_at IS NULL THEN
    NEW.duration_seconds = EXTRACT(EPOCH FROM (NEW.ended_at - NEW.started_at))::INTEGER;
    
    -- Calculate average time per page
    IF NEW.page_views > 0 THEN
      NEW.avg_time_per_page = NEW.duration_seconds::DECIMAL / NEW.page_views;
    END IF;
    
    -- Determine bounce rate
    NEW.bounce_rate = (NEW.page_views <= 1);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_session_metrics
  BEFORE UPDATE ON public.user_sessions
  FOR EACH ROW
  EXECUTE FUNCTION end_user_session();

-- =======================================================
-- 7. ROW LEVEL SECURITY
-- =======================================================

-- Enable RLS on all tables
ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_analytics_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_analytics ENABLE ROW LEVEL SECURITY;

-- Policies for analytics_events
CREATE POLICY "Admins can view all analytics events" ON public.analytics_events
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE user_id = auth.uid()
      AND is_active = true
    )
  );

CREATE POLICY "System can insert analytics events" ON public.analytics_events
  FOR INSERT
  WITH CHECK (true); -- Allow all inserts for event tracking

-- Policies for user_sessions  
CREATE POLICY "Admins can view all user sessions" ON public.user_sessions
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE user_id = auth.uid()
      AND is_active = true
    )
  );

CREATE POLICY "System can manage user sessions" ON public.user_sessions
  FOR ALL
  WITH CHECK (true);

-- Policies for daily_analytics_summary
CREATE POLICY "Admins can view daily analytics" ON public.daily_analytics_summary
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE user_id = auth.uid()
      AND is_active = true
    )
  );

-- Policies for product_analytics
CREATE POLICY "Admins can view product analytics" ON public.product_analytics
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE user_id = auth.uid()
      AND is_active = true
    )
  );

-- =======================================================
-- 8. GRANTS
-- =======================================================

-- Grant permissions
GRANT ALL ON public.analytics_events TO authenticated;
GRANT ALL ON public.analytics_events TO service_role;
GRANT ALL ON public.analytics_events TO anon; -- For website tracking

GRANT ALL ON public.user_sessions TO authenticated;
GRANT ALL ON public.user_sessions TO service_role;
GRANT ALL ON public.user_sessions TO anon;

GRANT ALL ON public.daily_analytics_summary TO authenticated;
GRANT ALL ON public.daily_analytics_summary TO service_role;

GRANT ALL ON public.product_analytics TO authenticated;
GRANT ALL ON public.product_analytics TO service_role;

-- =======================================================
-- ANALYTICS SYSTEM CREATED SUCCESSFULLY
-- =======================================================
-- Next steps:
-- 1. Run migration 051 for materialized views
-- 2. Run migration 052 for analytics functions
-- 3. Implement frontend tracking
-- =======================================================