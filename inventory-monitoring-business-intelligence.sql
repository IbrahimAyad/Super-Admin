-- ============================================
-- INVENTORY MONITORING & BUSINESS INTELLIGENCE
-- Advanced inventory tracking, forecasting, and business insights
-- ============================================

-- ============================================
-- SECTION 1: INVENTORY MONITORING TABLES
-- ============================================

-- Enhanced inventory tracking
CREATE TABLE IF NOT EXISTS inventory_snapshots (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID NOT NULL REFERENCES products(id),
    variant_id UUID REFERENCES product_variants(id),
    
    -- Stock levels
    current_stock INTEGER NOT NULL,
    reserved_stock INTEGER DEFAULT 0,
    available_stock INTEGER GENERATED ALWAYS AS (current_stock - reserved_stock) STORED,
    
    -- Reorder information
    reorder_level INTEGER DEFAULT 0,
    reorder_quantity INTEGER DEFAULT 0,
    max_stock_level INTEGER,
    
    -- Cost information
    unit_cost NUMERIC(10,2),
    total_inventory_value NUMERIC(12,2) GENERATED ALWAYS AS (current_stock * unit_cost) STORED,
    
    -- Movement tracking
    last_stock_movement TIMESTAMPTZ,
    days_since_last_sale INTEGER,
    
    -- Performance metrics
    velocity_per_day NUMERIC(8,2) DEFAULT 0, -- Units sold per day
    days_of_supply NUMERIC(8,2) DEFAULT 0,   -- Current stock / velocity
    
    -- Seasonality and trends
    seasonal_factor NUMERIC(5,2) DEFAULT 1.0,
    trend_factor NUMERIC(5,2) DEFAULT 1.0,
    
    snapshot_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(product_id, variant_id, snapshot_date)
);

-- Inventory movements log
CREATE TABLE IF NOT EXISTS inventory_movements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID NOT NULL REFERENCES products(id),
    variant_id UUID REFERENCES product_variants(id),
    
    -- Movement details
    movement_type VARCHAR(50) NOT NULL, -- 'sale', 'restock', 'adjustment', 'return', 'damage'
    quantity_change INTEGER NOT NULL,   -- Positive for increases, negative for decreases
    
    -- Before/after state
    stock_before INTEGER NOT NULL,
    stock_after INTEGER NOT NULL,
    
    -- Reference information
    order_id UUID REFERENCES orders(id),
    order_item_id UUID,
    adjustment_reason TEXT,
    
    -- Cost tracking
    unit_cost NUMERIC(10,2),
    total_cost_impact NUMERIC(12,2),
    
    -- Metadata
    created_by UUID REFERENCES auth.users(id),
    notes TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    INDEX idx_inventory_movements_product (product_id, created_at),
    INDEX idx_inventory_movements_type (movement_type, created_at)
);

-- Demand forecasting
CREATE TABLE IF NOT EXISTS demand_forecasts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID NOT NULL REFERENCES products(id),
    variant_id UUID REFERENCES product_variants(id),
    
    -- Forecast period
    forecast_date DATE NOT NULL,
    forecast_horizon_days INTEGER NOT NULL, -- 7, 14, 30, 60, 90 days
    
    -- Demand predictions
    predicted_demand NUMERIC(10,2) NOT NULL,
    confidence_interval_lower NUMERIC(10,2),
    confidence_interval_upper NUMERIC(10,2),
    confidence_level NUMERIC(5,2) DEFAULT 95.0,
    
    -- Forecast model information
    model_type VARCHAR(50) NOT NULL, -- 'linear', 'seasonal', 'moving_average', 'exponential_smoothing'
    model_accuracy NUMERIC(5,2),
    
    -- Factors considered
    historical_days INTEGER,
    seasonal_adjustment BOOLEAN DEFAULT FALSE,
    trend_adjustment BOOLEAN DEFAULT FALSE,
    external_factors JSONB DEFAULT '{}',
    
    -- Results
    recommended_reorder_quantity INTEGER,
    recommended_reorder_date DATE,
    stockout_risk_percentage NUMERIC(5,2),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(product_id, variant_id, forecast_date, forecast_horizon_days)
);

-- Supplier performance tracking
CREATE TABLE IF NOT EXISTS supplier_performance (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    supplier_id UUID, -- Would reference suppliers table
    supplier_name VARCHAR(200) NOT NULL,
    
    -- Performance metrics (last 90 days)
    total_orders INTEGER DEFAULT 0,
    on_time_deliveries INTEGER DEFAULT 0,
    quality_issues INTEGER DEFAULT 0,
    
    -- Timing metrics
    avg_lead_time_days NUMERIC(8,2),
    min_lead_time_days INTEGER,
    max_lead_time_days INTEGER,
    
    -- Quality metrics
    defect_rate NUMERIC(5,2) DEFAULT 0,
    return_rate NUMERIC(5,2) DEFAULT 0,
    
    -- Cost metrics
    avg_unit_cost NUMERIC(10,2),
    price_stability_score NUMERIC(5,2) DEFAULT 100, -- 100 = very stable
    
    -- Reliability score (0-100)
    reliability_score NUMERIC(5,2) DEFAULT 100,
    
    -- Review period
    review_period_start DATE NOT NULL,
    review_period_end DATE NOT NULL,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    INDEX idx_supplier_performance_score (reliability_score DESC)
);

-- Product lifecycle analytics
CREATE TABLE IF NOT EXISTS product_lifecycle_analytics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID NOT NULL REFERENCES products(id),
    
    -- Lifecycle stage
    lifecycle_stage VARCHAR(50) NOT NULL, -- 'launch', 'growth', 'maturity', 'decline', 'discontinued'
    stage_changed_at TIMESTAMPTZ,
    
    -- Performance metrics
    total_sales_volume INTEGER DEFAULT 0,
    total_revenue NUMERIC(12,2) DEFAULT 0,
    days_since_launch INTEGER,
    
    -- Velocity metrics
    current_velocity NUMERIC(8,2) DEFAULT 0,    -- Units per day
    peak_velocity NUMERIC(8,2) DEFAULT 0,       -- Highest velocity achieved
    velocity_trend VARCHAR(20) DEFAULT 'stable', -- 'increasing', 'decreasing', 'stable'
    
    -- Financial metrics
    profit_margin NUMERIC(5,2),
    roi_percentage NUMERIC(8,2),
    
    -- Recommendations
    recommended_action VARCHAR(100),
    action_priority VARCHAR(20) DEFAULT 'medium', -- 'high', 'medium', 'low'
    
    analysis_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(product_id, analysis_date)
);

-- ============================================
-- SECTION 2: BUSINESS INTELLIGENCE FUNCTIONS
-- ============================================

-- Calculate inventory velocity for products
CREATE OR REPLACE FUNCTION calculate_inventory_velocity()
RETURNS VOID AS $$
DECLARE
    product_record RECORD;
    sales_last_30_days INTEGER;
    velocity NUMERIC(8,2);
BEGIN
    FOR product_record IN
        SELECT DISTINCT p.id as product_id, pv.id as variant_id
        FROM products p
        LEFT JOIN product_variants pv ON p.id = pv.product_id
    LOOP
        -- Calculate sales in last 30 days
        SELECT COALESCE(SUM(oi.quantity), 0)
        INTO sales_last_30_days
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.id
        WHERE oi.product_id = product_record.product_id
        AND (product_record.variant_id IS NULL OR oi.variant_id = product_record.variant_id)
        AND o.payment_status = 'paid'
        AND o.created_at >= NOW() - INTERVAL '30 days';
        
        -- Calculate daily velocity
        velocity := sales_last_30_days::NUMERIC / 30.0;
        
        -- Update or insert inventory snapshot
        INSERT INTO inventory_snapshots (
            product_id,
            variant_id,
            current_stock,
            velocity_per_day,
            days_of_supply,
            last_stock_movement
        )
        SELECT 
            product_record.product_id,
            product_record.variant_id,
            COALESCE(pv.current_stock, p.stock_quantity),
            velocity,
            CASE 
                WHEN velocity > 0 THEN COALESCE(pv.current_stock, p.stock_quantity)::NUMERIC / velocity
                ELSE 999
            END,
            COALESCE(
                (SELECT MAX(created_at) FROM inventory_movements 
                 WHERE product_id = product_record.product_id 
                 AND (variant_id = product_record.variant_id OR variant_id IS NULL)),
                NOW() - INTERVAL '1 day'
            )
        FROM products p
        LEFT JOIN product_variants pv ON p.id = pv.product_id AND pv.id = product_record.variant_id
        WHERE p.id = product_record.product_id
        
        ON CONFLICT (product_id, variant_id, snapshot_date) 
        DO UPDATE SET
            velocity_per_day = EXCLUDED.velocity_per_day,
            days_of_supply = EXCLUDED.days_of_supply,
            last_stock_movement = EXCLUDED.last_stock_movement;
    END LOOP;
    
    RAISE NOTICE 'Inventory velocity calculation completed';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Generate demand forecast for products
CREATE OR REPLACE FUNCTION generate_demand_forecast(
    target_product_id UUID DEFAULT NULL,
    forecast_days INTEGER DEFAULT 30
)
RETURNS INTEGER AS $$
DECLARE
    product_record RECORD;
    historical_sales RECORD;
    seasonal_factor NUMERIC := 1.0;
    trend_factor NUMERIC := 1.0;
    base_demand NUMERIC;
    predicted_demand NUMERIC;
    confidence_lower NUMERIC;
    confidence_upper NUMERIC;
    forecasts_created INTEGER := 0;
BEGIN
    FOR product_record IN
        SELECT p.id, p.name, pv.id as variant_id
        FROM products p
        LEFT JOIN product_variants pv ON p.id = pv.product_id
        WHERE (target_product_id IS NULL OR p.id = target_product_id)
    LOOP
        -- Get historical sales data (last 90 days)
        SELECT 
            COALESCE(AVG(daily_sales), 0) as avg_daily_sales,
            COALESCE(STDDEV(daily_sales), 0) as stddev_daily_sales,
            COUNT(*) as days_with_data
        INTO historical_sales
        FROM (
            SELECT 
                DATE(o.created_at) as sale_date,
                SUM(oi.quantity) as daily_sales
            FROM order_items oi
            JOIN orders o ON oi.order_id = o.id
            WHERE oi.product_id = product_record.id
            AND (product_record.variant_id IS NULL OR oi.variant_id = product_record.variant_id)
            AND o.payment_status = 'paid'
            AND o.created_at >= NOW() - INTERVAL '90 days'
            GROUP BY DATE(o.created_at)
        ) daily_sales_data;
        
        -- Skip if no historical data
        IF historical_sales.days_with_data < 7 THEN
            CONTINUE;
        END IF;
        
        -- Calculate seasonal factor (simplified - month-based)
        SELECT 
            CASE EXTRACT(MONTH FROM CURRENT_DATE)
                WHEN 11, 12, 1 THEN 1.3  -- Holiday season
                WHEN 6, 7, 8 THEN 0.9    -- Summer slowdown
                ELSE 1.0
            END
        INTO seasonal_factor;
        
        -- Calculate trend factor (sales growth/decline)
        WITH monthly_sales AS (
            SELECT 
                DATE_TRUNC('month', o.created_at) as month,
                SUM(oi.quantity) as monthly_total
            FROM order_items oi
            JOIN orders o ON oi.order_id = o.id
            WHERE oi.product_id = product_record.id
            AND (product_record.variant_id IS NULL OR oi.variant_id = product_record.variant_id)
            AND o.payment_status = 'paid'
            AND o.created_at >= NOW() - INTERVAL '3 months'
            GROUP BY DATE_TRUNC('month', o.created_at)
            ORDER BY month
        ),
        trend_calculation AS (
            SELECT 
                CASE 
                    WHEN LAG(monthly_total) OVER (ORDER BY month) > 0 
                    THEN monthly_total::NUMERIC / LAG(monthly_total) OVER (ORDER BY month)
                    ELSE 1.0
                END as month_over_month_growth
            FROM monthly_sales
        )
        SELECT COALESCE(AVG(month_over_month_growth), 1.0)
        INTO trend_factor
        FROM trend_calculation
        WHERE month_over_month_growth IS NOT NULL;
        
        -- Calculate base demand and apply factors
        base_demand := historical_sales.avg_daily_sales;
        predicted_demand := base_demand * seasonal_factor * trend_factor * forecast_days;
        
        -- Calculate confidence intervals (assuming normal distribution)
        confidence_lower := GREATEST(0, predicted_demand - (1.96 * historical_sales.stddev_daily_sales * SQRT(forecast_days)));
        confidence_upper := predicted_demand + (1.96 * historical_sales.stddev_daily_sales * SQRT(forecast_days));
        
        -- Insert forecast
        INSERT INTO demand_forecasts (
            product_id,
            variant_id,
            forecast_date,
            forecast_horizon_days,
            predicted_demand,
            confidence_interval_lower,
            confidence_interval_upper,
            model_type,
            model_accuracy,
            historical_days,
            seasonal_adjustment,
            trend_adjustment,
            recommended_reorder_quantity,
            stockout_risk_percentage
        ) VALUES (
            product_record.id,
            product_record.variant_id,
            CURRENT_DATE,
            forecast_days,
            predicted_demand,
            confidence_lower,
            confidence_upper,
            'seasonal_trend',
            GREATEST(70, 100 - (historical_sales.stddev_daily_sales / NULLIF(historical_sales.avg_daily_sales, 0) * 100)),
            90,
            TRUE,
            TRUE,
            CEIL(predicted_demand * 1.2), -- 20% buffer
            CASE 
                WHEN predicted_demand > COALESCE((SELECT current_stock FROM inventory_snapshots 
                                                WHERE product_id = product_record.id 
                                                AND (variant_id = product_record.variant_id OR variant_id IS NULL)
                                                ORDER BY snapshot_date DESC LIMIT 1), 0)
                THEN LEAST(95, (predicted_demand - COALESCE((SELECT current_stock FROM inventory_snapshots 
                                                           WHERE product_id = product_record.id 
                                                           AND (variant_id = product_record.variant_id OR variant_id IS NULL)
                                                           ORDER BY snapshot_date DESC LIMIT 1), 0)) / predicted_demand * 100)
                ELSE 0
            END
        )
        ON CONFLICT (product_id, variant_id, forecast_date, forecast_horizon_days)
        DO UPDATE SET
            predicted_demand = EXCLUDED.predicted_demand,
            confidence_interval_lower = EXCLUDED.confidence_interval_lower,
            confidence_interval_upper = EXCLUDED.confidence_interval_upper,
            recommended_reorder_quantity = EXCLUDED.recommended_reorder_quantity,
            stockout_risk_percentage = EXCLUDED.stockout_risk_percentage;
        
        forecasts_created := forecasts_created + 1;
    END LOOP;
    
    RETURN forecasts_created;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Analyze product lifecycle stage
CREATE OR REPLACE FUNCTION analyze_product_lifecycle()
RETURNS INTEGER AS $$
DECLARE
    product_record RECORD;
    launch_date DATE;
    days_since_launch INTEGER;
    sales_trend VARCHAR(20);
    current_velocity NUMERIC;
    peak_velocity NUMERIC;
    lifecycle_stage VARCHAR(50);
    recommended_action VARCHAR(100);
    products_analyzed INTEGER := 0;
BEGIN
    FOR product_record IN
        SELECT p.id, p.name, p.created_at
        FROM products p
        WHERE p.status = 'active'
    LOOP
        -- Calculate days since launch
        launch_date := DATE(product_record.created_at);
        days_since_launch := CURRENT_DATE - launch_date;
        
        -- Get current velocity (last 30 days)
        SELECT COALESCE(velocity_per_day, 0)
        INTO current_velocity
        FROM inventory_snapshots
        WHERE product_id = product_record.id
        AND snapshot_date = CURRENT_DATE;
        
        -- Get peak velocity (highest 30-day period)
        WITH daily_sales AS (
            SELECT 
                DATE(o.created_at) as sale_date,
                SUM(oi.quantity) as daily_quantity
            FROM order_items oi
            JOIN orders o ON oi.order_id = o.id
            WHERE oi.product_id = product_record.id
            AND o.payment_status = 'paid'
            GROUP BY DATE(o.created_at)
            ORDER BY sale_date
        ),
        rolling_30_day AS (
            SELECT 
                sale_date,
                AVG(daily_quantity) OVER (
                    ORDER BY sale_date 
                    ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
                ) as rolling_avg
            FROM daily_sales
        )
        SELECT COALESCE(MAX(rolling_avg), 0)
        INTO peak_velocity
        FROM rolling_30_day;
        
        -- Determine velocity trend
        WITH recent_periods AS (
            SELECT 
                AVG(CASE WHEN o.created_at >= NOW() - INTERVAL '15 days' THEN oi.quantity END) as last_15_days,
                AVG(CASE WHEN o.created_at >= NOW() - INTERVAL '30 days' 
                          AND o.created_at < NOW() - INTERVAL '15 days' THEN oi.quantity END) as prev_15_days
            FROM order_items oi
            JOIN orders o ON oi.order_id = o.id
            WHERE oi.product_id = product_record.id
            AND o.payment_status = 'paid'
            AND o.created_at >= NOW() - INTERVAL '30 days'
        )
        SELECT 
            CASE 
                WHEN last_15_days > prev_15_days * 1.1 THEN 'increasing'
                WHEN last_15_days < prev_15_days * 0.9 THEN 'decreasing'
                ELSE 'stable'
            END
        INTO sales_trend
        FROM recent_periods;
        
        -- Determine lifecycle stage
        lifecycle_stage := CASE
            WHEN days_since_launch <= 30 THEN 'launch'
            WHEN sales_trend = 'increasing' AND current_velocity >= peak_velocity * 0.8 THEN 'growth'
            WHEN sales_trend = 'stable' AND current_velocity >= peak_velocity * 0.5 THEN 'maturity'
            WHEN sales_trend = 'decreasing' OR current_velocity < peak_velocity * 0.3 THEN 'decline'
            ELSE 'maturity'
        END;
        
        -- Generate recommendations
        recommended_action := CASE lifecycle_stage
            WHEN 'launch' THEN 'Monitor performance, increase marketing if needed'
            WHEN 'growth' THEN 'Scale inventory, optimize pricing'
            WHEN 'maturity' THEN 'Maintain steady inventory, consider promotions'
            WHEN 'decline' THEN 'Reduce inventory, plan discontinuation or revitalization'
            ELSE 'Review and reassess'
        END;
        
        -- Insert or update analysis
        INSERT INTO product_lifecycle_analytics (
            product_id,
            lifecycle_stage,
            stage_changed_at,
            total_sales_volume,
            days_since_launch,
            current_velocity,
            peak_velocity,
            velocity_trend,
            recommended_action,
            action_priority
        )
        SELECT 
            product_record.id,
            lifecycle_stage,
            CASE 
                WHEN EXISTS (
                    SELECT 1 FROM product_lifecycle_analytics pla
                    WHERE pla.product_id = product_record.id
                    AND pla.lifecycle_stage != lifecycle_stage
                    ORDER BY analysis_date DESC LIMIT 1
                ) THEN CURRENT_TIMESTAMP
                ELSE NULL
            END,
            COALESCE((
                SELECT SUM(oi.quantity)
                FROM order_items oi
                JOIN orders o ON oi.order_id = o.id
                WHERE oi.product_id = product_record.id
                AND o.payment_status = 'paid'
            ), 0),
            days_since_launch,
            current_velocity,
            peak_velocity,
            sales_trend,
            recommended_action,
            CASE lifecycle_stage
                WHEN 'decline' THEN 'high'
                WHEN 'launch' THEN 'high'
                ELSE 'medium'
            END
        
        ON CONFLICT (product_id, analysis_date)
        DO UPDATE SET
            lifecycle_stage = EXCLUDED.lifecycle_stage,
            stage_changed_at = CASE 
                WHEN product_lifecycle_analytics.lifecycle_stage != EXCLUDED.lifecycle_stage 
                THEN CURRENT_TIMESTAMP
                ELSE product_lifecycle_analytics.stage_changed_at
            END,
            current_velocity = EXCLUDED.current_velocity,
            peak_velocity = EXCLUDED.peak_velocity,
            velocity_trend = EXCLUDED.velocity_trend,
            recommended_action = EXCLUDED.recommended_action,
            action_priority = EXCLUDED.action_priority;
        
        products_analyzed := products_analyzed + 1;
    END LOOP;
    
    RETURN products_analyzed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SECTION 3: BUSINESS INTELLIGENCE VIEWS
-- ============================================

-- Inventory health dashboard
CREATE OR REPLACE VIEW v_inventory_health_dashboard AS
SELECT 
    -- Overall inventory metrics
    COUNT(DISTINCT is_current.product_id) as total_products,
    COUNT(DISTINCT CASE WHEN is_current.available_stock <= is_current.reorder_level THEN is_current.product_id END) as low_stock_products,
    COUNT(DISTINCT CASE WHEN is_current.available_stock = 0 THEN is_current.product_id END) as out_of_stock_products,
    SUM(is_current.total_inventory_value) as total_inventory_value,
    
    -- Velocity metrics
    AVG(is_current.velocity_per_day) as avg_velocity_per_day,
    AVG(is_current.days_of_supply) as avg_days_of_supply,
    
    -- Risk metrics
    COUNT(DISTINCT CASE WHEN df.stockout_risk_percentage > 70 THEN is_current.product_id END) as high_stockout_risk_products,
    COUNT(DISTINCT CASE WHEN is_current.days_of_supply < 7 THEN is_current.product_id END) as products_with_low_supply,
    
    -- Movement activity
    COUNT(DISTINCT CASE WHEN is_current.last_stock_movement > NOW() - INTERVAL '7 days' THEN is_current.product_id END) as products_with_recent_movement,
    
    CURRENT_DATE as dashboard_date
FROM inventory_snapshots is_current
LEFT JOIN demand_forecasts df ON is_current.product_id = df.product_id 
    AND is_current.variant_id = df.variant_id 
    AND df.forecast_date = CURRENT_DATE
    AND df.forecast_horizon_days = 30
WHERE is_current.snapshot_date = CURRENT_DATE;

-- Product performance insights
CREATE OR REPLACE VIEW v_product_performance_insights AS
SELECT 
    p.id,
    p.name,
    p.category,
    p.price,
    
    -- Current status
    is_snap.current_stock,
    is_snap.available_stock,
    is_snap.velocity_per_day,
    is_snap.days_of_supply,
    
    -- Lifecycle information
    pla.lifecycle_stage,
    pla.velocity_trend,
    pla.recommended_action,
    pla.action_priority,
    
    -- Financial metrics
    is_snap.total_inventory_value,
    pla.total_revenue,
    
    -- Demand forecasting
    df.predicted_demand as forecast_30_day_demand,
    df.stockout_risk_percentage,
    df.recommended_reorder_quantity,
    
    -- Performance score (0-100)
    LEAST(100, GREATEST(0, 
        (COALESCE(is_snap.velocity_per_day, 0) * 20) + -- Velocity component
        (CASE WHEN is_snap.days_of_supply BETWEEN 7 AND 30 THEN 30 ELSE 0 END) + -- Supply component
        (CASE pla.lifecycle_stage
            WHEN 'growth' THEN 30
            WHEN 'maturity' THEN 25
            WHEN 'launch' THEN 20
            WHEN 'decline' THEN 10
            ELSE 15
        END) + -- Lifecycle component
        (CASE WHEN df.stockout_risk_percentage < 20 THEN 20 ELSE 5 END) -- Risk component
    )) as performance_score,
    
    -- Status flags
    CASE 
        WHEN is_snap.available_stock = 0 THEN 'OUT_OF_STOCK'
        WHEN is_snap.available_stock <= is_snap.reorder_level THEN 'LOW_STOCK'
        WHEN df.stockout_risk_percentage > 70 THEN 'HIGH_RISK'
        WHEN pla.lifecycle_stage = 'decline' THEN 'DECLINING'
        WHEN pla.velocity_trend = 'increasing' THEN 'TRENDING_UP'
        ELSE 'NORMAL'
    END as status_flag

FROM products p
LEFT JOIN inventory_snapshots is_snap ON p.id = is_snap.product_id 
    AND is_snap.snapshot_date = CURRENT_DATE
LEFT JOIN product_lifecycle_analytics pla ON p.id = pla.product_id 
    AND pla.analysis_date = CURRENT_DATE
LEFT JOIN demand_forecasts df ON p.id = df.product_id 
    AND df.forecast_date = CURRENT_DATE 
    AND df.forecast_horizon_days = 30
WHERE p.status = 'active'
ORDER BY performance_score DESC;

-- Inventory alerts and recommendations
CREATE OR REPLACE VIEW v_inventory_alerts AS
SELECT 
    'LOW_STOCK' as alert_type,
    'warning' as severity,
    p.name as product_name,
    'Low stock alert: ' || p.name || ' has ' || is_snap.available_stock || ' units remaining' as message,
    is_snap.available_stock as current_value,
    is_snap.reorder_level as threshold_value,
    is_snap.product_id,
    CURRENT_TIMESTAMP as created_at
FROM inventory_snapshots is_snap
JOIN products p ON is_snap.product_id = p.id
WHERE is_snap.snapshot_date = CURRENT_DATE
AND is_snap.available_stock <= is_snap.reorder_level
AND is_snap.available_stock > 0

UNION ALL

SELECT 
    'OUT_OF_STOCK' as alert_type,
    'critical' as severity,
    p.name as product_name,
    'Out of stock: ' || p.name || ' is completely out of stock' as message,
    0 as current_value,
    1 as threshold_value,
    is_snap.product_id,
    CURRENT_TIMESTAMP as created_at
FROM inventory_snapshots is_snap
JOIN products p ON is_snap.product_id = p.id
WHERE is_snap.snapshot_date = CURRENT_DATE
AND is_snap.available_stock = 0

UNION ALL

SELECT 
    'HIGH_STOCKOUT_RISK' as alert_type,
    'warning' as severity,
    p.name as product_name,
    'High stockout risk: ' || p.name || ' has ' || df.stockout_risk_percentage::INTEGER || '% chance of stockout' as message,
    df.stockout_risk_percentage as current_value,
    70 as threshold_value,
    df.product_id,
    CURRENT_TIMESTAMP as created_at
FROM demand_forecasts df
JOIN products p ON df.product_id = p.id
WHERE df.forecast_date = CURRENT_DATE
AND df.forecast_horizon_days = 30
AND df.stockout_risk_percentage > 70

UNION ALL

SELECT 
    'DECLINING_PRODUCT' as alert_type,
    'info' as severity,
    p.name as product_name,
    'Product in decline: ' || p.name || ' is in decline stage. ' || pla.recommended_action as message,
    0 as current_value,
    0 as threshold_value,
    pla.product_id,
    CURRENT_TIMESTAMP as created_at
FROM product_lifecycle_analytics pla
JOIN products p ON pla.product_id = p.id
WHERE pla.analysis_date = CURRENT_DATE
AND pla.lifecycle_stage = 'decline'
AND pla.action_priority = 'high';

-- Financial impact analysis
CREATE OR REPLACE VIEW v_inventory_financial_impact AS
SELECT 
    -- Total inventory value
    SUM(is_snap.total_inventory_value) as total_inventory_value,
    
    -- Dead stock analysis
    SUM(CASE WHEN is_snap.velocity_per_day = 0 THEN is_snap.total_inventory_value ELSE 0 END) as dead_stock_value,
    SUM(CASE WHEN is_snap.days_of_supply > 90 THEN is_snap.total_inventory_value ELSE 0 END) as slow_moving_value,
    
    -- Opportunity costs
    SUM(CASE WHEN is_snap.available_stock = 0 AND df.predicted_demand > 0 
             THEN df.predicted_demand * p.price 
             ELSE 0 END) as lost_revenue_opportunity,
    
    -- Carrying costs (estimated 20% annually)
    SUM(is_snap.total_inventory_value) * 0.20 / 365 as daily_carrying_cost,
    
    -- Reorder recommendations value
    SUM(CASE WHEN is_snap.available_stock <= is_snap.reorder_level 
             THEN df.recommended_reorder_quantity * is_snap.unit_cost 
             ELSE 0 END) as recommended_reorder_investment,
    
    -- Performance metrics
    COUNT(DISTINCT is_snap.product_id) as total_products,
    COUNT(DISTINCT CASE WHEN is_snap.velocity_per_day > 0 THEN is_snap.product_id END) as active_products,
    
    CURRENT_DATE as analysis_date
    
FROM inventory_snapshots is_snap
JOIN products p ON is_snap.product_id = p.id
LEFT JOIN demand_forecasts df ON is_snap.product_id = df.product_id 
    AND df.forecast_date = CURRENT_DATE 
    AND df.forecast_horizon_days = 30
WHERE is_snap.snapshot_date = CURRENT_DATE;

-- ============================================
-- SECTION 4: AUTOMATED SCHEDULING
-- ============================================

-- Schedule inventory velocity calculation daily
SELECT cron.schedule(
    'calculate-inventory-velocity',
    '0 1 * * *',
    'SELECT calculate_inventory_velocity();'
);

-- Schedule demand forecasting daily
SELECT cron.schedule(
    'generate-demand-forecasts',
    '0 2 * * *',
    'SELECT generate_demand_forecast();'
);

-- Schedule product lifecycle analysis daily
SELECT cron.schedule(
    'analyze-product-lifecycle',
    '0 3 * * *',
    'SELECT analyze_product_lifecycle();'
);

-- Schedule inventory snapshot cleanup (keep 90 days)
SELECT cron.schedule(
    'cleanup-inventory-snapshots',
    '0 4 * * *',
    'DELETE FROM inventory_snapshots WHERE snapshot_date < CURRENT_DATE - INTERVAL ''90 days'';'
);

-- ============================================
-- SECTION 5: INITIAL DATA SETUP
-- ============================================

-- Run initial calculations
SELECT calculate_inventory_velocity();
SELECT generate_demand_forecast();
SELECT analyze_product_lifecycle();

-- Create summary report
SELECT 
    'INVENTORY MONITORING & BI SETUP COMPLETE' as status,
    COUNT(*) || ' inventory snapshots created' as snapshots,
    (SELECT COUNT(*) FROM demand_forecasts WHERE forecast_date = CURRENT_DATE) || ' demand forecasts generated' as forecasts,
    (SELECT COUNT(*) FROM product_lifecycle_analytics WHERE analysis_date = CURRENT_DATE) || ' lifecycle analyses completed' as lifecycle_analyses
FROM inventory_snapshots WHERE snapshot_date = CURRENT_DATE;

-- Show current inventory health
SELECT * FROM v_inventory_health_dashboard;

-- Show current alerts
SELECT alert_type, severity, COUNT(*) as alert_count
FROM v_inventory_alerts
GROUP BY alert_type, severity
ORDER BY 
    CASE severity 
        WHEN 'critical' THEN 1 
        WHEN 'warning' THEN 2 
        WHEN 'info' THEN 3 
    END,
    alert_count DESC;