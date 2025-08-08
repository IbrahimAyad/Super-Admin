-- ============================================
-- COMPLETE MIGRATION SCRIPT FOR ALL MISSING COMPONENTS
-- Run this entire script to add all missing tables and functions
-- ============================================

-- ============================================
-- PART 1: SYNC PROGRESS FUNCTION (046)
-- ============================================

CREATE OR REPLACE FUNCTION update_sync_progress(
    p_entity_type TEXT,
    p_entity_id UUID,
    p_status TEXT,
    p_message TEXT DEFAULT NULL,
    p_progress INTEGER DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    -- Log sync progress (you can create a sync_logs table if needed)
    RAISE NOTICE 'Sync Progress: % - % - % - %', p_entity_type, p_entity_id, p_status, COALESCE(p_message, 'No message');
    
    -- Update the sync status on the entity if applicable
    IF p_entity_type = 'product' THEN
        UPDATE products 
        SET 
            stripe_sync_status = p_status,
            updated_at = NOW()
        WHERE id = p_entity_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- PART 2: ORDER EVENTS & SHIPMENTS TABLES (048 partial)
-- ============================================

-- Order Events Table (for detailed order history)
CREATE TABLE IF NOT EXISTS order_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    event_data JSONB DEFAULT '{}',
    description TEXT,
    created_by UUID REFERENCES auth.users(id),
    is_customer_visible BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_events_order_id ON order_events(order_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_events_type ON order_events(event_type, created_at DESC);

-- Order Shipments Table
CREATE TABLE IF NOT EXISTS order_shipments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    tracking_number VARCHAR(255),
    carrier VARCHAR(100),
    service_type VARCHAR(100),
    status VARCHAR(50) DEFAULT 'pending',
    shipped_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    estimated_delivery DATE,
    shipping_label_url TEXT,
    tracking_url TEXT,
    weight DECIMAL(10,3),
    dimensions JSONB,
    cost DECIMAL(10,2),
    items JSONB, -- Which items are in this shipment
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_shipments_order_id ON order_shipments(order_id);
CREATE INDEX IF NOT EXISTS idx_order_shipments_tracking ON order_shipments(tracking_number);
CREATE INDEX IF NOT EXISTS idx_order_shipments_status ON order_shipments(status, created_at DESC);

-- Order Returns Table (if not exists)
CREATE TABLE IF NOT EXISTS order_returns (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    reason VARCHAR(255),
    status VARCHAR(50) DEFAULT 'requested',
    items JSONB NOT NULL,
    refund_amount DECIMAL(10,2),
    return_shipping_label_url TEXT,
    notes TEXT,
    approved_by UUID REFERENCES auth.users(id),
    approved_at TIMESTAMPTZ,
    received_at TIMESTAMPTZ,
    refunded_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_returns_order_id ON order_returns(order_id);
CREATE INDEX IF NOT EXISTS idx_order_returns_status ON order_returns(status, created_at DESC);

-- ============================================
-- PART 3: ANALYTICS TABLES (050 & 052 partial)
-- ============================================

-- Analytics Sessions Table
CREATE TABLE IF NOT EXISTS analytics_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id),
    started_at TIMESTAMPTZ DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    duration_seconds INTEGER,
    page_views INTEGER DEFAULT 0,
    events_count INTEGER DEFAULT 0,
    user_agent TEXT,
    ip_address INET,
    referrer TEXT,
    utm_source TEXT,
    utm_medium TEXT,
    utm_campaign TEXT,
    device_type TEXT,
    browser TEXT,
    os TEXT,
    country TEXT,
    city TEXT,
    metadata JSONB DEFAULT '{}'
);

CREATE INDEX IF NOT EXISTS idx_analytics_sessions_session_id ON analytics_sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_analytics_sessions_user_id ON analytics_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_sessions_started_at ON analytics_sessions(started_at DESC);

-- Analytics Page Views Table
CREATE TABLE IF NOT EXISTS analytics_page_views (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id TEXT,
    user_id UUID REFERENCES auth.users(id),
    page_path TEXT NOT NULL,
    page_title TEXT,
    referrer TEXT,
    duration_seconds INTEGER,
    exit_page BOOLEAN DEFAULT false,
    bounce BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_page_views_session ON analytics_page_views(session_id);
CREATE INDEX IF NOT EXISTS idx_page_views_path ON analytics_page_views(page_path, created_at DESC);

-- Analytics Conversions Table
CREATE TABLE IF NOT EXISTS analytics_conversions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id TEXT,
    user_id UUID REFERENCES auth.users(id),
    conversion_type VARCHAR(50) NOT NULL, -- 'purchase', 'signup', 'newsletter', etc.
    conversion_value DECIMAL(10,2),
    order_id UUID REFERENCES orders(id),
    attribution_source TEXT,
    attribution_medium TEXT,
    attribution_campaign TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_conversions_type ON analytics_conversions(conversion_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversions_session ON analytics_conversions(session_id);

-- Analytics Daily Summary Table
CREATE TABLE IF NOT EXISTS analytics_daily_summary (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    total_visitors INTEGER DEFAULT 0,
    unique_visitors INTEGER DEFAULT 0,
    total_page_views INTEGER DEFAULT 0,
    total_sessions INTEGER DEFAULT 0,
    avg_session_duration INTEGER DEFAULT 0,
    bounce_rate DECIMAL(5,2) DEFAULT 0,
    total_conversions INTEGER DEFAULT 0,
    conversion_value DECIMAL(10,2) DEFAULT 0,
    top_pages JSONB DEFAULT '[]',
    top_referrers JSONB DEFAULT '[]',
    device_breakdown JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_daily_summary_date ON analytics_daily_summary(date DESC);

-- Analytics Product Performance Table
CREATE TABLE IF NOT EXISTS analytics_product_performance (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    views INTEGER DEFAULT 0,
    add_to_cart INTEGER DEFAULT 0,
    purchases INTEGER DEFAULT 0,
    revenue DECIMAL(10,2) DEFAULT 0,
    conversion_rate DECIMAL(5,2) DEFAULT 0,
    avg_time_on_page INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(product_id, date)
);

CREATE INDEX IF NOT EXISTS idx_product_performance_product ON analytics_product_performance(product_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_product_performance_date ON analytics_product_performance(date DESC);

-- ============================================
-- PART 4: ANALYTICS FUNCTIONS (052)
-- ============================================

-- Track Analytics Event Function
CREATE OR REPLACE FUNCTION track_analytics_event(
    p_event_type VARCHAR(100),
    p_session_id TEXT DEFAULT NULL,
    p_user_id UUID DEFAULT NULL,
    p_event_data JSONB DEFAULT '{}'
) RETURNS UUID AS $$
DECLARE
    v_event_id UUID;
BEGIN
    INSERT INTO analytics_events (
        event_type,
        session_id,
        user_id,
        event_data,
        created_at
    ) VALUES (
        p_event_type,
        p_session_id,
        p_user_id,
        p_event_data,
        NOW()
    ) RETURNING id INTO v_event_id;
    
    RETURN v_event_id;
END;
$$ LANGUAGE plpgsql;

-- Get Analytics Summary Function
CREATE OR REPLACE FUNCTION get_analytics_summary(
    p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
    p_end_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE (
    total_visitors BIGINT,
    total_page_views BIGINT,
    total_orders BIGINT,
    total_revenue DECIMAL,
    avg_order_value DECIMAL,
    conversion_rate DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(DISTINCT ae.user_id) AS total_visitors,
        COUNT(DISTINCT ae.id) FILTER (WHERE ae.event_type = 'page_view') AS total_page_views,
        COUNT(DISTINCT o.id) AS total_orders,
        COALESCE(SUM(o.total_amount), 0)::DECIMAL AS total_revenue,
        CASE 
            WHEN COUNT(DISTINCT o.id) > 0 
            THEN (SUM(o.total_amount) / COUNT(DISTINCT o.id))::DECIMAL
            ELSE 0::DECIMAL
        END AS avg_order_value,
        CASE 
            WHEN COUNT(DISTINCT ae.user_id) > 0 
            THEN (COUNT(DISTINCT o.customer_id)::DECIMAL / COUNT(DISTINCT ae.user_id) * 100)
            ELSE 0::DECIMAL
        END AS conversion_rate
    FROM analytics_events ae
    LEFT JOIN orders o ON o.created_at::DATE BETWEEN p_start_date AND p_end_date
    WHERE ae.created_at::DATE BETWEEN p_start_date AND p_end_date;
END;
$$ LANGUAGE plpgsql;

-- Process Refund Function (if missing)
CREATE OR REPLACE FUNCTION process_refund(
    p_refund_id UUID,
    p_approved_by UUID DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_order_id UUID;
    v_refund_amount DECIMAL;
BEGIN
    -- Get refund details
    SELECT order_id, refund_amount 
    INTO v_order_id, v_refund_amount
    FROM refund_requests
    WHERE id = p_refund_id AND status = 'pending';
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Update refund status
    UPDATE refund_requests
    SET 
        status = 'approved',
        approved_by = p_approved_by,
        approved_at = NOW(),
        updated_at = NOW()
    WHERE id = p_refund_id;
    
    -- Update order status
    UPDATE orders
    SET 
        financial_status = 'refunded',
        updated_at = NOW()
    WHERE id = v_order_id;
    
    -- Trigger inventory restore (handled by trigger)
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- PART 5: ENABLE RLS AND GRANTS
-- ============================================

-- Enable RLS on new tables
ALTER TABLE order_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_shipments ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_returns ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_page_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_conversions ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_daily_summary ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_product_performance ENABLE ROW LEVEL SECURITY;

-- Create basic admin policies
CREATE POLICY "Admin full access" ON order_events FOR ALL USING (true);
CREATE POLICY "Admin full access" ON order_shipments FOR ALL USING (true);
CREATE POLICY "Admin full access" ON order_returns FOR ALL USING (true);
CREATE POLICY "Admin full access" ON analytics_sessions FOR ALL USING (true);
CREATE POLICY "Admin full access" ON analytics_page_views FOR ALL USING (true);
CREATE POLICY "Admin full access" ON analytics_conversions FOR ALL USING (true);
CREATE POLICY "Admin full access" ON analytics_daily_summary FOR ALL USING (true);
CREATE POLICY "Admin full access" ON analytics_product_performance FOR ALL USING (true);

-- Grants
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- ============================================
-- VERIFICATION
-- ============================================

-- Run this after to verify everything was created:
SELECT 
  'Tables Created' as status,
  COUNT(*) as count
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'order_events', 'order_shipments', 'order_returns',
    'analytics_sessions', 'analytics_page_views', 'analytics_conversions',
    'analytics_daily_summary', 'analytics_product_performance'
  );
  
-- Should return count = 8