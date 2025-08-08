-- ============================================
-- ORDERS MANAGEMENT SCHEMA OPTIMIZATION
-- For KCT Menswear Admin Panel
-- Created: 2025-08-08
-- ============================================

-- ============================================
-- 1. OPTIMIZE EXISTING ORDERS TABLE
-- ============================================

-- Add missing columns to orders table if they don't exist
DO $$ 
BEGIN
    -- Order identification and tracking
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'order_number') THEN
        ALTER TABLE public.orders ADD COLUMN order_number TEXT GENERATED ALWAYS AS ('KCT-' || LPAD(id::text, 8, '0')) STORED;
    END IF;
    
    -- Order workflow fields
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'priority') THEN
        ALTER TABLE public.orders ADD COLUMN priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent'));
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'fulfillment_status') THEN
        ALTER TABLE public.orders ADD COLUMN fulfillment_status TEXT DEFAULT 'unfulfilled' CHECK (fulfillment_status IN ('unfulfilled', 'partial', 'fulfilled', 'cancelled'));
    END IF;
    
    -- Enhanced tracking
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'source_channel') THEN
        ALTER TABLE public.orders ADD COLUMN source_channel TEXT DEFAULT 'website' CHECK (source_channel IN ('website', 'admin', 'phone', 'email', 'marketplace'));
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'assigned_to') THEN
        ALTER TABLE public.orders ADD COLUMN assigned_to UUID REFERENCES auth.users(id);
    END IF;
    
    -- Customer service
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'customer_notes') THEN
        ALTER TABLE public.orders ADD COLUMN customer_notes TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'admin_notes') THEN
        ALTER TABLE public.orders ADD COLUMN admin_notes TEXT;
    END IF;
    
    -- Risk assessment
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'risk_level') THEN
        ALTER TABLE public.orders ADD COLUMN risk_level TEXT DEFAULT 'low' CHECK (risk_level IN ('low', 'medium', 'high'));
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'flags') THEN
        ALTER TABLE public.orders ADD COLUMN flags TEXT[] DEFAULT '{}';
    END IF;
END $$;

-- ============================================
-- 2. ENHANCE ORDER_ITEMS TABLE  
-- ============================================

DO $$ 
BEGIN
    -- Item fulfillment tracking
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'order_items' AND column_name = 'fulfillment_status') THEN
        ALTER TABLE public.order_items ADD COLUMN fulfillment_status TEXT DEFAULT 'pending' CHECK (fulfillment_status IN ('pending', 'reserved', 'picked', 'packed', 'shipped', 'delivered', 'cancelled'));
    END IF;
    
    -- Inventory tracking
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'order_items' AND column_name = 'reserved_at') THEN
        ALTER TABLE public.order_items ADD COLUMN reserved_at TIMESTAMPTZ;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'order_items' AND column_name = 'picked_at') THEN
        ALTER TABLE public.order_items ADD COLUMN picked_at TIMESTAMPTZ;
    END IF;
    
    -- Production tracking (for custom items)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'order_items' AND column_name = 'production_status') THEN
        ALTER TABLE public.order_items ADD COLUMN production_status TEXT CHECK (production_status IN ('not_required', 'pending', 'in_progress', 'completed', 'delayed'));
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'order_items' AND column_name = 'estimated_production_time') THEN
        ALTER TABLE public.order_items ADD COLUMN estimated_production_time INTERVAL;
    END IF;
END $$;

-- ============================================
-- 3. CREATE ORDER TRACKING TABLES
-- ============================================

-- Order events for detailed tracking
CREATE TABLE IF NOT EXISTS public.order_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL CHECK (event_type IN ('status_change', 'payment', 'fulfillment', 'shipping', 'customer_contact', 'internal_note', 'system')),
    event_category TEXT, -- For grouping similar events
    title TEXT NOT NULL,
    description TEXT,
    metadata JSONB DEFAULT '{}',
    -- Event relationships
    related_item_id UUID, -- References order_items(id) when applicable
    -- Tracking
    created_by UUID REFERENCES auth.users(id), -- NULL for system events
    is_customer_visible BOOLEAN DEFAULT false,
    is_automated BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Shipment tracking
CREATE TABLE IF NOT EXISTS public.order_shipments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    shipment_number TEXT UNIQUE NOT NULL DEFAULT ('SHIP-' || extract(epoch from now())::bigint),
    -- Carrier information
    carrier TEXT NOT NULL, -- 'USPS', 'UPS', 'FedEx', etc.
    service_type TEXT, -- 'Ground', 'Express', '2-Day', etc.
    tracking_number TEXT,
    tracking_url TEXT,
    -- Shipment details
    weight_lbs DECIMAL(6,2),
    dimensions_length DECIMAL(6,2),
    dimensions_width DECIMAL(6,2),
    dimensions_height DECIMAL(6,2),
    -- Status tracking
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'picked_up', 'in_transit', 'out_for_delivery', 'delivered', 'exception', 'returned')),
    estimated_delivery_date DATE,
    actual_delivery_date DATE,
    -- Cost tracking
    shipping_cost DECIMAL(10,2),
    insurance_cost DECIMAL(10,2),
    -- Addresses (denormalized for history)
    from_address JSONB,
    to_address JSONB,
    -- Timestamps
    shipped_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

-- Shipment items (what's in each shipment)
CREATE TABLE IF NOT EXISTS public.order_shipment_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    shipment_id UUID NOT NULL REFERENCES public.order_shipments(id) ON DELETE CASCADE,
    order_item_id UUID NOT NULL REFERENCES public.order_items(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(shipment_id, order_item_id)
);

-- Return/Exchange tracking
CREATE TABLE IF NOT EXISTS public.order_returns (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    return_number TEXT UNIQUE NOT NULL DEFAULT ('RET-' || extract(epoch from now())::bigint),
    -- Return details
    return_type TEXT NOT NULL CHECK (return_type IN ('return', 'exchange', 'warranty')),
    reason_code TEXT NOT NULL CHECK (reason_code IN ('defective', 'wrong_size', 'wrong_item', 'not_as_described', 'damaged_shipping', 'changed_mind', 'other')),
    reason_description TEXT,
    -- Status tracking
    status TEXT NOT NULL DEFAULT 'requested' CHECK (status IN ('requested', 'approved', 'rejected', 'received', 'inspected', 'processed', 'completed')),
    -- Financial
    refund_amount DECIMAL(10,2),
    restocking_fee DECIMAL(10,2) DEFAULT 0,
    return_shipping_cost DECIMAL(10,2),
    -- Processing
    approved_by UUID REFERENCES auth.users(id),
    approved_at TIMESTAMPTZ,
    processed_by UUID REFERENCES auth.users(id),
    processed_at TIMESTAMPTZ,
    -- Customer communication
    customer_notified_at TIMESTAMPTZ,
    -- Notes
    customer_notes TEXT,
    internal_notes TEXT,
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Return items
CREATE TABLE IF NOT EXISTS public.order_return_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    return_id UUID NOT NULL REFERENCES public.order_returns(id) ON DELETE CASCADE,
    order_item_id UUID NOT NULL REFERENCES public.order_items(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    condition_received TEXT CHECK (condition_received IN ('new', 'like_new', 'good', 'fair', 'poor', 'damaged')),
    disposition TEXT CHECK (disposition IN ('restock', 'discount', 'damage_out', 'return_to_vendor')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(return_id, order_item_id)
);

-- ============================================
-- 4. PERFORMANCE INDEXES
-- ============================================

-- Orders table indexes (query optimization)
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status) WHERE status IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_orders_fulfillment_status ON public.orders(fulfillment_status);
CREATE INDEX IF NOT EXISTS idx_orders_created_date ON public.orders(created_at);
CREATE INDEX IF NOT EXISTS idx_orders_updated_date ON public.orders(updated_at);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON public.orders(customer_id) WHERE customer_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_orders_guest_email ON public.orders(guest_email) WHERE guest_email IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_orders_assigned_to ON public.orders(assigned_to) WHERE assigned_to IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_orders_priority ON public.orders(priority);
CREATE INDEX IF NOT EXISTS idx_orders_risk_level ON public.orders(risk_level);
CREATE INDEX IF NOT EXISTS idx_orders_source_channel ON public.orders(source_channel);

-- Multi-column indexes for common queries
CREATE INDEX IF NOT EXISTS idx_orders_status_created ON public.orders(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_fulfillment_priority ON public.orders(fulfillment_status, priority) WHERE status NOT IN ('cancelled', 'refunded');
CREATE INDEX IF NOT EXISTS idx_orders_stripe_session ON public.orders(stripe_checkout_session_id) WHERE stripe_checkout_session_id IS NOT NULL;

-- Order items indexes
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_fulfillment ON public.order_items(fulfillment_status);
CREATE INDEX IF NOT EXISTS idx_order_items_production ON public.order_items(production_status) WHERE production_status IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_order_items_variant_id ON public.order_items(variant_id) WHERE variant_id IS NOT NULL;

-- Order events indexes
CREATE INDEX IF NOT EXISTS idx_order_events_order_id ON public.order_events(order_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_events_type ON public.order_events(event_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_events_created_by ON public.order_events(created_by) WHERE created_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_order_events_customer_visible ON public.order_events(is_customer_visible, created_at DESC) WHERE is_customer_visible = true;

-- Shipment indexes
CREATE INDEX IF NOT EXISTS idx_order_shipments_order_id ON public.order_shipments(order_id);
CREATE INDEX IF NOT EXISTS idx_order_shipments_status ON public.order_shipments(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_shipments_tracking ON public.order_shipments(tracking_number) WHERE tracking_number IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_order_shipments_carrier ON public.order_shipments(carrier, status);
CREATE INDEX IF NOT EXISTS idx_order_shipments_delivery_date ON public.order_shipments(estimated_delivery_date) WHERE estimated_delivery_date IS NOT NULL;

-- Return indexes
CREATE INDEX IF NOT EXISTS idx_order_returns_order_id ON public.order_returns(order_id);
CREATE INDEX IF NOT EXISTS idx_order_returns_status ON public.order_returns(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_returns_type ON public.order_returns(return_type);
CREATE INDEX IF NOT EXISTS idx_order_returns_reason ON public.order_returns(reason_code);

-- ============================================
-- 5. PERFORMANCE FUNCTIONS
-- ============================================

-- Get orders with optimized query
CREATE OR REPLACE FUNCTION public.get_orders_optimized(
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0,
    p_status TEXT DEFAULT NULL,
    p_fulfillment_status TEXT DEFAULT NULL,
    p_assigned_to UUID DEFAULT NULL,
    p_priority TEXT DEFAULT NULL,
    p_date_from DATE DEFAULT NULL,
    p_date_to DATE DEFAULT NULL
) RETURNS TABLE (
    id UUID,
    order_number TEXT,
    customer_name TEXT,
    customer_email TEXT,
    status TEXT,
    fulfillment_status TEXT,
    priority TEXT,
    total_amount DECIMAL,
    item_count BIGINT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        o.id,
        o.order_number,
        COALESCE(c.first_name || ' ' || c.last_name, 'Guest Customer') as customer_name,
        COALESCE(c.email, o.guest_email) as customer_email,
        o.status,
        o.fulfillment_status,
        o.priority,
        o.total,
        COUNT(oi.id) as item_count,
        o.created_at,
        o.updated_at
    FROM public.orders o
    LEFT JOIN public.customers c ON o.customer_id = c.id
    LEFT JOIN public.order_items oi ON o.id = oi.order_id
    WHERE 
        (p_status IS NULL OR o.status = p_status)
        AND (p_fulfillment_status IS NULL OR o.fulfillment_status = p_fulfillment_status)
        AND (p_assigned_to IS NULL OR o.assigned_to = p_assigned_to)
        AND (p_priority IS NULL OR o.priority = p_priority)
        AND (p_date_from IS NULL OR DATE(o.created_at) >= p_date_from)
        AND (p_date_to IS NULL OR DATE(o.created_at) <= p_date_to)
    GROUP BY o.id, c.first_name, c.last_name, c.email
    ORDER BY o.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get order fulfillment metrics
CREATE OR REPLACE FUNCTION public.get_fulfillment_metrics()
RETURNS TABLE (
    total_orders BIGINT,
    pending_orders BIGINT,
    processing_orders BIGINT,
    shipped_orders BIGINT,
    avg_fulfillment_time INTERVAL,
    orders_at_risk BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_orders,
        COUNT(*) FILTER (WHERE o.status = 'pending') as pending_orders,
        COUNT(*) FILTER (WHERE o.status IN ('confirmed', 'processing')) as processing_orders,
        COUNT(*) FILTER (WHERE o.status = 'shipped') as shipped_orders,
        AVG(o.shipped_at - o.created_at) FILTER (WHERE o.shipped_at IS NOT NULL) as avg_fulfillment_time,
        COUNT(*) FILTER (WHERE o.created_at < NOW() - INTERVAL '2 days' AND o.status IN ('pending', 'confirmed')) as orders_at_risk
    FROM public.orders o
    WHERE o.created_at >= CURRENT_DATE - INTERVAL '30 days'
        AND o.status NOT IN ('cancelled', 'refunded');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 6. AUTOMATED FUNCTIONS & TRIGGERS
-- ============================================

-- Function to automatically create order events
CREATE OR REPLACE FUNCTION public.log_order_event()
RETURNS TRIGGER AS $$
BEGIN
    -- Log status changes
    IF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO public.order_events (
            order_id, event_type, event_category, title, description, 
            metadata, created_by, is_automated
        ) VALUES (
            NEW.id, 'status_change', 'workflow', 
            'Order status changed', 
            'Status changed from ' || OLD.status || ' to ' || NEW.status,
            jsonb_build_object(
                'old_status', OLD.status,
                'new_status', NEW.status,
                'changed_at', NOW()
            ),
            auth.uid(), true
        );
    END IF;
    
    -- Log fulfillment status changes
    IF TG_OP = 'UPDATE' AND OLD.fulfillment_status IS DISTINCT FROM NEW.fulfillment_status THEN
        INSERT INTO public.order_events (
            order_id, event_type, event_category, title, description,
            metadata, created_by, is_automated
        ) VALUES (
            NEW.id, 'fulfillment', 'warehouse',
            'Fulfillment status updated',
            'Fulfillment changed from ' || OLD.fulfillment_status || ' to ' || NEW.fulfillment_status,
            jsonb_build_object(
                'old_fulfillment_status', OLD.fulfillment_status,
                'new_fulfillment_status', NEW.fulfillment_status
            ),
            auth.uid(), true
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for order events
DROP TRIGGER IF EXISTS tr_order_events ON public.orders;
CREATE TRIGGER tr_order_events
    AFTER UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.log_order_event();

-- Function to update order totals when items change
CREATE OR REPLACE FUNCTION public.update_order_totals()
RETURNS TRIGGER AS $$
DECLARE
    v_order_id UUID;
    v_subtotal DECIMAL(10,2);
    v_item_count INTEGER;
BEGIN
    -- Get order ID from the operation
    IF TG_OP = 'DELETE' THEN
        v_order_id := OLD.order_id;
    ELSE
        v_order_id := NEW.order_id;
    END IF;
    
    -- Calculate new totals
    SELECT 
        COALESCE(SUM(total_price), 0),
        COALESCE(COUNT(*), 0)
    INTO v_subtotal, v_item_count
    FROM public.order_items
    WHERE order_id = v_order_id;
    
    -- Update order (keep existing tax/shipping calculations)
    UPDATE public.orders 
    SET 
        subtotal = v_subtotal,
        total = v_subtotal + COALESCE(tax_amount, 0) + COALESCE(shipping_amount, 0) - COALESCE(discount_amount, 0),
        updated_at = NOW()
    WHERE id = v_order_id;
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for order total updates
DROP TRIGGER IF EXISTS tr_update_order_totals ON public.order_items;
CREATE TRIGGER tr_update_order_totals
    AFTER INSERT OR UPDATE OR DELETE ON public.order_items
    FOR EACH ROW
    EXECUTE FUNCTION public.update_order_totals();

-- ============================================
-- 7. RLS POLICIES FOR NEW TABLES
-- ============================================

-- Enable RLS on new tables
ALTER TABLE public.order_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_shipments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_shipment_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_returns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_return_items ENABLE ROW LEVEL SECURITY;

-- Admin access policies
CREATE POLICY "Admins can manage order events" ON public.order_events
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    );

CREATE POLICY "Admins can manage shipments" ON public.order_shipments
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    );

CREATE POLICY "Admins can manage shipment items" ON public.order_shipment_items
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    );

CREATE POLICY "Admins can manage returns" ON public.order_returns
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    );

CREATE POLICY "Admins can manage return items" ON public.order_return_items
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    );

-- Customer read-only policies for their own data
CREATE POLICY "Customers can view their order events" ON public.order_events
    FOR SELECT USING (
        is_customer_visible = true 
        AND order_id IN (
            SELECT id FROM public.orders o
            WHERE o.customer_id IN (
                SELECT id FROM public.customers WHERE auth_user_id = auth.uid()
            )
            OR (o.guest_email IS NOT NULL AND o.guest_email IN (
                SELECT email FROM auth.users WHERE id = auth.uid()
            ))
        )
    );

-- ============================================
-- 8. GRANTS AND PERMISSIONS
-- ============================================

GRANT SELECT, INSERT, UPDATE ON public.order_events TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.order_shipments TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.order_shipment_items TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.order_returns TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.order_return_items TO authenticated;

GRANT EXECUTE ON FUNCTION public.get_orders_optimized TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_fulfillment_metrics TO authenticated;

-- Service role for system operations
GRANT ALL ON public.order_events TO service_role;
GRANT ALL ON public.order_shipments TO service_role;
GRANT ALL ON public.order_shipment_items TO service_role;
GRANT ALL ON public.order_returns TO service_role;
GRANT ALL ON public.order_return_items TO service_role;

-- ============================================
-- 9. VERIFICATION & COMMENTS
-- ============================================

COMMENT ON TABLE public.order_events IS 'Comprehensive event log for order lifecycle tracking and audit trail';
COMMENT ON TABLE public.order_shipments IS 'Shipment tracking with carrier integration and delivery status';
COMMENT ON TABLE public.order_returns IS 'Return and exchange management with workflow tracking';

COMMENT ON FUNCTION public.get_orders_optimized IS 'High-performance order listing with common filters and pagination';
COMMENT ON FUNCTION public.get_fulfillment_metrics IS 'Real-time fulfillment KPIs for admin dashboard';

-- Verify new tables were created
SELECT 
    tablename,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = 'public' AND tablename = t.tablename)
        THEN '✅ Created'
        ELSE '❌ Failed'
    END as status,
    (SELECT COUNT(*) FROM pg_indexes WHERE tablename = t.tablename) as index_count
FROM (VALUES 
    ('order_events'),
    ('order_shipments'),
    ('order_shipment_items'),
    ('order_returns'),
    ('order_return_items')
) AS t(tablename)
ORDER BY tablename;