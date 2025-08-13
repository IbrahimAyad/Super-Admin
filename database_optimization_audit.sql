-- ============================================
-- DATABASE OPTIMIZATION AUDIT FOR KCT MENSWEAR
-- Comprehensive performance optimization for PostgreSQL on Supabase
-- Target: 1000+ concurrent users with 300+ products and variants
-- ============================================

-- SECTION 1: CRITICAL PERFORMANCE INDEXES
-- ============================================

-- Product search and filtering indexes (highest priority)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_search_vector 
ON products USING gin(to_tsvector('english', coalesce(name, '') || ' ' || coalesce(description, '') || ' ' || coalesce(category, '')));

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_category_status_active 
ON products (category, status) WHERE status = 'active';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_status_created_desc 
ON products (status, created_at DESC) WHERE status = 'active';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_base_price_active 
ON products (base_price) WHERE status = 'active';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_sale_price_active 
ON products (sale_price) WHERE status = 'active' AND sale_price IS NOT NULL;

-- Product variant indexes for inventory and sizing
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_product_variants_product_size_color 
ON product_variants (product_id, size, color) WHERE status = 'active';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_product_variants_inventory_available 
ON product_variants (inventory_quantity DESC) WHERE status = 'active' AND inventory_quantity > 0;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_product_variants_low_stock_alert 
ON product_variants (product_id, inventory_quantity) WHERE status = 'active' AND inventory_quantity <= 5;

-- Product images performance indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_product_images_product_position 
ON product_images (product_id, position) WHERE image_url IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_product_images_primary 
ON product_images (product_id) WHERE image_type = 'primary';

-- Order processing indexes (critical for checkout performance)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_status_priority_created 
ON orders (status, priority, created_at DESC) WHERE status IN ('pending', 'confirmed', 'processing');

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_customer_created_desc 
ON orders (customer_id, created_at DESC) WHERE customer_id IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_guest_email_created 
ON orders (guest_email, created_at DESC) WHERE guest_email IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_stripe_session 
ON orders (stripe_checkout_session_id) WHERE stripe_checkout_session_id IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_fulfillment_status 
ON orders (fulfillment_status, created_at DESC) WHERE fulfillment_status != 'delivered';

-- Order items for order details and fulfillment
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_order_items_order_fulfillment 
ON order_items (order_id, fulfillment_status);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_order_items_variant_tracking 
ON order_items (variant_id) WHERE variant_id IS NOT NULL;

-- Customer and user profile indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_customers_email_active 
ON customers (email) WHERE email IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_customers_stripe_customer 
ON customers (stripe_customer_id) WHERE stripe_customer_id IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_profiles_auth_user 
ON user_profiles (auth_user_id) WHERE auth_user_id IS NOT NULL;

-- Admin and session management
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_admin_users_active_permissions 
ON admin_users (is_active, permissions) WHERE is_active = true;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_admin_sessions_user_active 
ON admin_sessions (user_id, expires_at) WHERE expires_at > NOW();

-- Stripe sync and payment tracking
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stripe_sync_log_timestamp 
ON stripe_sync_log (created_at DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_stripe_sync_log_operation_status 
ON stripe_sync_log (operation_type, status, created_at DESC);

-- Analytics and reporting indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_analytics_events_timestamp 
ON analytics_events (created_at DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_analytics_events_type_date 
ON analytics_events (event_type, DATE(created_at));

-- Cart performance indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cart_items_user_session 
ON cart_items (user_id, session_id, created_at DESC) WHERE user_id IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_cart_items_session_only 
ON cart_items (session_id, created_at DESC) WHERE user_id IS NULL;

-- SECTION 2: COMPOSITE INDEXES FOR COMPLEX QUERIES
-- ============================================

-- Product filtering with multiple criteria
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_category_price_status 
ON products (category, base_price, status) WHERE status = 'active';

-- Order management dashboard queries
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_status_date_customer 
ON orders (status, created_at DESC, customer_id);

-- Inventory management
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_variants_product_inventory_status 
ON product_variants (product_id, inventory_quantity, status) WHERE status = 'active';

-- SECTION 3: PARTIAL INDEXES FOR PERFORMANCE
-- ============================================

-- Active products only (most common queries)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_active_only_name 
ON products (name) WHERE status = 'active';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_active_only_slug 
ON products (slug) WHERE status = 'active';

-- In-stock variants only
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_variants_in_stock_only 
ON product_variants (product_id, size, color, price) 
WHERE status = 'active' AND inventory_quantity > 0;

-- Recent orders for dashboard
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_recent_active 
ON orders (created_at DESC, status) 
WHERE created_at >= NOW() - INTERVAL '30 days' AND status != 'cancelled';

-- SECTION 4: COVERING INDEXES FOR QUERY OPTIMIZATION
-- ============================================

-- Product listing with basic info (covering index)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_listing_cover 
ON products (status, category, created_at DESC) 
INCLUDE (id, name, slug, base_price, sale_price);

-- Variant availability checking (covering index)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_variants_availability_cover 
ON product_variants (product_id, status) 
INCLUDE (size, color, price, inventory_quantity) 
WHERE status = 'active';

-- Order summary for admin (covering index)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_admin_summary_cover 
ON orders (status, created_at DESC) 
INCLUDE (id, order_number, total, customer_id, guest_email, fulfillment_status);

-- SECTION 5: MATERIALIZED VIEWS FOR COMPLEX ANALYTICS
-- ============================================

-- Product performance summary
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_product_performance AS
SELECT 
    p.id,
    p.name,
    p.category,
    p.status,
    COUNT(DISTINCT pv.id) as variant_count,
    COALESCE(SUM(pv.inventory_quantity), 0) as total_inventory,
    COALESCE(MIN(pv.price), p.base_price) as min_price,
    COALESCE(MAX(pv.price), p.base_price) as max_price,
    COUNT(DISTINCT pi.id) as image_count,
    p.created_at,
    p.updated_at
FROM products p
LEFT JOIN product_variants pv ON p.id = pv.product_id AND pv.status = 'active'
LEFT JOIN product_images pi ON p.id = pi.product_id
WHERE p.status = 'active'
GROUP BY p.id, p.name, p.category, p.status, p.base_price, p.created_at, p.updated_at;

-- Create index on materialized view
CREATE INDEX IF NOT EXISTS idx_mv_product_performance_category 
ON mv_product_performance (category, total_inventory DESC);

-- Order fulfillment metrics
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_order_metrics AS
SELECT 
    DATE(o.created_at) as order_date,
    o.status,
    o.fulfillment_status,
    COUNT(*) as order_count,
    SUM(o.total) as total_revenue,
    AVG(o.total) as avg_order_value,
    COUNT(DISTINCT o.customer_id) as unique_customers,
    COUNT(*) FILTER (WHERE o.guest_email IS NOT NULL) as guest_orders
FROM orders o
WHERE o.created_at >= NOW() - INTERVAL '90 days'
GROUP BY DATE(o.created_at), o.status, o.fulfillment_status;

-- Create index on order metrics view
CREATE INDEX IF NOT EXISTS idx_mv_order_metrics_date_status 
ON mv_order_metrics (order_date DESC, status);

-- SECTION 6: QUERY OPTIMIZATION FUNCTIONS
-- ============================================

-- Optimized product search function
CREATE OR REPLACE FUNCTION search_products_optimized(
    search_term TEXT DEFAULT NULL,
    category_filter TEXT DEFAULT NULL,
    min_price DECIMAL DEFAULT NULL,
    max_price DECIMAL DEFAULT NULL,
    in_stock_only BOOLEAN DEFAULT FALSE,
    limit_count INTEGER DEFAULT 50,
    offset_count INTEGER DEFAULT 0
) RETURNS TABLE (
    id UUID,
    name TEXT,
    slug TEXT,
    category TEXT,
    base_price DECIMAL,
    sale_price DECIMAL,
    status TEXT,
    total_inventory BIGINT,
    image_url TEXT,
    relevance REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.name,
        p.slug,
        p.category,
        p.base_price,
        p.sale_price,
        p.status,
        COALESCE(mv.total_inventory, 0) as total_inventory,
        pi.image_url,
        CASE 
            WHEN search_term IS NULL THEN 1.0
            ELSE ts_rank(to_tsvector('english', coalesce(p.name, '') || ' ' || coalesce(p.description, '')), 
                         plainto_tsquery('english', search_term))
        END as relevance
    FROM products p
    LEFT JOIN mv_product_performance mv ON p.id = mv.id
    LEFT JOIN LATERAL (
        SELECT image_url 
        FROM product_images 
        WHERE product_id = p.id 
        ORDER BY position, image_type = 'primary' DESC 
        LIMIT 1
    ) pi ON true
    WHERE 
        p.status = 'active'
        AND (category_filter IS NULL OR p.category = category_filter)
        AND (min_price IS NULL OR COALESCE(p.sale_price, p.base_price) >= min_price)
        AND (max_price IS NULL OR COALESCE(p.sale_price, p.base_price) <= max_price)
        AND (NOT in_stock_only OR COALESCE(mv.total_inventory, 0) > 0)
        AND (search_term IS NULL OR to_tsvector('english', coalesce(p.name, '') || ' ' || coalesce(p.description, '')) @@ plainto_tsquery('english', search_term))
    ORDER BY 
        CASE WHEN search_term IS NOT NULL THEN relevance END DESC,
        p.created_at DESC
    LIMIT limit_count OFFSET offset_count;
END;
$$ LANGUAGE plpgsql STABLE;

-- Fast order lookup function
CREATE OR REPLACE FUNCTION get_order_summary_optimized(
    status_filter TEXT DEFAULT NULL,
    days_back INTEGER DEFAULT 30,
    limit_count INTEGER DEFAULT 100
) RETURNS TABLE (
    id UUID,
    order_number TEXT,
    customer_name TEXT,
    customer_email TEXT,
    status TEXT,
    fulfillment_status TEXT,
    total_amount DECIMAL,
    item_count BIGINT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        o.id,
        o.order_number,
        COALESCE(c.first_name || ' ' || c.last_name, 'Guest') as customer_name,
        COALESCE(c.email, o.guest_email) as customer_email,
        o.status,
        o.fulfillment_status,
        o.total,
        COUNT(oi.id) as item_count,
        o.created_at
    FROM orders o
    LEFT JOIN customers c ON o.customer_id = c.id
    LEFT JOIN order_items oi ON o.id = oi.order_id
    WHERE 
        o.created_at >= NOW() - INTERVAL '%s days'::text % days_back::text
        AND (status_filter IS NULL OR o.status = status_filter)
    GROUP BY o.id, c.first_name, c.last_name, c.email
    ORDER BY o.created_at DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql STABLE;

-- SECTION 7: MAINTENANCE AND OPTIMIZATION PROCEDURES
-- ============================================

-- Refresh materialized views procedure
CREATE OR REPLACE FUNCTION refresh_analytics_views()
RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_product_performance;
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_order_metrics;
    
    -- Update table statistics
    ANALYZE products;
    ANALYZE product_variants;
    ANALYZE orders;
    ANALYZE order_items;
    
    RAISE NOTICE 'Analytics views refreshed and statistics updated';
END;
$$ LANGUAGE plpgsql;

-- Database maintenance procedure
CREATE OR REPLACE FUNCTION optimize_database_performance()
RETURNS TABLE (
    operation TEXT,
    status TEXT,
    details TEXT
) AS $$
DECLARE
    rec RECORD;
    unused_indexes INTEGER;
BEGIN
    -- Check for unused indexes
    SELECT COUNT(*) INTO unused_indexes
    FROM pg_stat_user_indexes 
    WHERE schemaname = 'public' AND idx_scan = 0;
    
    RETURN QUERY SELECT 'Unused Indexes Check'::TEXT, 'INFO'::TEXT, 
                       ('Found ' || unused_indexes || ' unused indexes')::TEXT;
    
    -- Check for tables that need vacuuming
    FOR rec IN 
        SELECT schemaname, tablename, n_dead_tup
        FROM pg_stat_user_tables 
        WHERE schemaname = 'public' 
        AND n_dead_tup > 1000
    LOOP
        RETURN QUERY SELECT 'Table Maintenance'::TEXT, 'WARNING'::TEXT,
                           ('Table ' || rec.tablename || ' has ' || rec.n_dead_tup || ' dead tuples')::TEXT;
    END LOOP;
    
    -- Update statistics on main tables
    ANALYZE products;
    ANALYZE product_variants;
    ANALYZE orders;
    
    RETURN QUERY SELECT 'Statistics Update'::TEXT, 'SUCCESS'::TEXT, 'Updated table statistics'::TEXT;
END;
$$ LANGUAGE plpgsql;

-- SECTION 8: PERFORMANCE MONITORING SETUP
-- ============================================

-- Enable query stats if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Function to identify slow queries
CREATE OR REPLACE FUNCTION identify_slow_queries(min_exec_time_ms REAL DEFAULT 100.0)
RETURNS TABLE (
    query_text TEXT,
    avg_time_ms REAL,
    total_time_ms REAL,
    call_count BIGINT,
    rows_avg REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        LEFT(pss.query, 100) as query_text,
        ROUND(pss.mean_exec_time::NUMERIC, 2)::REAL as avg_time_ms,
        ROUND(pss.total_exec_time::NUMERIC, 2)::REAL as total_time_ms,
        pss.calls as call_count,
        ROUND((pss.rows::NUMERIC / GREATEST(pss.calls, 1)), 2)::REAL as rows_avg
    FROM pg_stat_statements pss
    WHERE pss.mean_exec_time >= min_exec_time_ms
    AND pss.calls >= 5  -- Only frequently called queries
    ORDER BY pss.mean_exec_time DESC
    LIMIT 20;
END;
$$ LANGUAGE plpgsql;

-- Function to check index effectiveness
CREATE OR REPLACE FUNCTION check_index_effectiveness()
RETURNS TABLE (
    table_name TEXT,
    index_name TEXT,
    index_size TEXT,
    scans BIGINT,
    tuples_read BIGINT,
    effectiveness TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        psi.relname::TEXT as table_name,
        psi.indexrelname::TEXT as index_name,
        pg_size_pretty(pg_relation_size(psi.indexrelid)) as index_size,
        psi.idx_scan as scans,
        psi.idx_tup_read as tuples_read,
        CASE 
            WHEN psi.idx_scan = 0 THEN 'UNUSED'
            WHEN psi.idx_scan < 10 THEN 'LOW_USAGE'
            WHEN psi.idx_scan < 100 THEN 'MODERATE_USAGE'
            ELSE 'HIGH_USAGE'
        END as effectiveness
    FROM pg_stat_user_indexes psi
    WHERE psi.schemaname = 'public'
    ORDER BY psi.idx_scan DESC;
END;
$$ LANGUAGE plpgsql;

-- SECTION 9: AUTOMATED MAINTENANCE SCHEDULING
-- ============================================

-- Note: These would be scheduled using pg_cron extension if available
-- Example scheduling commands (uncomment if pg_cron is installed):

-- Refresh analytics views every hour
-- SELECT cron.schedule('refresh-analytics', '0 * * * *', 'SELECT refresh_analytics_views();');

-- Run performance optimization checks daily
-- SELECT cron.schedule('performance-check', '0 2 * * *', 'SELECT optimize_database_performance();');

-- SECTION 10: VALIDATION AND VERIFICATION
-- ============================================

-- Check if all critical indexes exist
SELECT 
    'Index Status Check' as operation,
    CASE 
        WHEN COUNT(*) >= 25 THEN 'SUCCESS'
        ELSE 'WARNING'
    END as status,
    'Created ' || COUNT(*) || ' performance indexes' as details
FROM pg_indexes 
WHERE schemaname = 'public' 
AND indexname LIKE 'idx_%'
AND indexname NOT LIKE 'idx_mv_%';

-- Verify materialized views
SELECT 
    'Materialized Views Check' as operation,
    CASE 
        WHEN COUNT(*) >= 2 THEN 'SUCCESS'
        ELSE 'ERROR'
    END as status,
    'Found ' || COUNT(*) || ' materialized views' as details
FROM pg_matviews 
WHERE schemaname = 'public';

-- Performance summary
SELECT 
    'Performance Audit' as operation,
    'COMPLETED' as status,
    'Database optimization audit completed successfully' as details;

-- Display optimization summary
SELECT 
    'OPTIMIZATION SUMMARY' as title,
    '=====================================' as separator;

SELECT 
    'Indexes Created' as metric,
    COUNT(*)::TEXT as value
FROM pg_indexes 
WHERE schemaname = 'public' 
AND indexname LIKE 'idx_%'
AND indexname NOT LIKE 'idx_mv_%';

SELECT 
    'Materialized Views' as metric,
    COUNT(*)::TEXT as value
FROM pg_matviews 
WHERE schemaname = 'public';

SELECT 
    'Optimization Functions' as metric,
    COUNT(*)::TEXT as value
FROM pg_proc 
WHERE proname IN ('search_products_optimized', 'get_order_summary_optimized', 'refresh_analytics_views');