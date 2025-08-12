-- ============================================
-- ORDER FULFILLMENT SYSTEM MIGRATION
-- Complete order processing workflow for KCT Menswear
-- Created: 2025-08-12
-- ============================================

BEGIN;

-- ============================================
-- 1. ORDER FULFILLMENT TRACKING TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.order_fulfillment (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' 
        CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
    
    -- Tracking information
    tracking_number TEXT,
    carrier TEXT CHECK (carrier IN ('usps', 'ups', 'fedex', 'dhl', 'other')),
    tracking_url TEXT,
    
    -- Fulfillment details
    warehouse_location TEXT,
    pick_list_id TEXT,
    packing_slip_id TEXT,
    
    -- Timestamps
    processing_started_at TIMESTAMPTZ,
    shipped_at TIMESTAMPTZ,
    estimated_delivery_date DATE,
    actual_delivery_date DATE,
    
    -- Staff assignments
    assigned_picker UUID REFERENCES auth.users(id),
    assigned_packer UUID REFERENCES auth.users(id),
    
    -- Notes and metadata
    internal_notes TEXT,
    shipping_method TEXT,
    shipping_cost DECIMAL(10,2),
    
    -- Audit fields
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

-- ============================================
-- 2. SHIPPING LABELS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.shipping_labels (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    fulfillment_id UUID REFERENCES public.order_fulfillment(id) ON DELETE SET NULL,
    
    -- Label details
    label_url TEXT NOT NULL,
    tracking_number TEXT NOT NULL,
    carrier TEXT NOT NULL,
    service_type TEXT,
    
    -- Package information
    weight_lbs DECIMAL(6,2),
    length_inches DECIMAL(6,2),
    width_inches DECIMAL(6,2),
    height_inches DECIMAL(6,2),
    
    -- Cost information
    shipping_cost DECIMAL(10,2),
    insurance_cost DECIMAL(10,2),
    
    -- Status
    status TEXT DEFAULT 'generated' 
        CHECK (status IN ('generated', 'printed', 'shipped', 'delivered', 'voided')),
    
    -- Addresses (stored for audit trail)
    from_address JSONB NOT NULL,
    to_address JSONB NOT NULL,
    
    -- Metadata
    label_format TEXT DEFAULT 'pdf',
    external_label_id TEXT, -- ID from shipping carrier
    
    -- Audit fields
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

-- ============================================
-- 3. ORDER NOTIFICATIONS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.order_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    
    -- Notification details
    notification_type TEXT NOT NULL 
        CHECK (notification_type IN ('order_confirmation', 'order_processing', 'order_shipped', 'order_delivered', 'order_cancelled', 'order_delayed', 'custom')),
    
    -- Delivery method
    delivery_method TEXT NOT NULL 
        CHECK (delivery_method IN ('email', 'sms', 'push', 'webhook')),
    
    -- Recipients
    recipient_email TEXT,
    recipient_phone TEXT,
    recipient_user_id UUID REFERENCES auth.users(id),
    
    -- Content
    subject TEXT,
    message TEXT,
    template_id TEXT,
    template_data JSONB DEFAULT '{}',
    
    -- Status tracking
    status TEXT NOT NULL DEFAULT 'pending' 
        CHECK (status IN ('pending', 'sent', 'delivered', 'failed', 'bounced')),
    
    -- Delivery tracking
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    opened_at TIMESTAMPTZ,
    clicked_at TIMESTAMPTZ,
    
    -- Error handling
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    
    -- Metadata
    external_message_id TEXT, -- ID from email/SMS provider
    
    -- Audit fields
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id)
);

-- ============================================
-- 4. ORDER NOTES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.order_notes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    
    -- Note details
    note_type TEXT NOT NULL DEFAULT 'internal' 
        CHECK (note_type IN ('internal', 'customer_service', 'fulfillment', 'shipping', 'accounting')),
    
    content TEXT NOT NULL,
    is_customer_visible BOOLEAN DEFAULT FALSE,
    is_urgent BOOLEAN DEFAULT FALSE,
    
    -- File attachments
    attachments JSONB DEFAULT '[]',
    
    -- Staff information
    created_by UUID NOT NULL REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 5. REFUNDS AND RETURNS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.order_refunds (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    
    -- Refund details
    refund_type TEXT NOT NULL 
        CHECK (refund_type IN ('full_refund', 'partial_refund', 'return', 'exchange', 'store_credit')),
    
    reason TEXT NOT NULL,
    reason_category TEXT 
        CHECK (reason_category IN ('defective', 'wrong_item', 'customer_request', 'damaged_shipping', 'quality_issue', 'other')),
    
    -- Financial details
    original_amount DECIMAL(10,2) NOT NULL,
    refund_amount DECIMAL(10,2) NOT NULL,
    processing_fee DECIMAL(10,2) DEFAULT 0,
    
    -- Status tracking
    status TEXT NOT NULL DEFAULT 'requested' 
        CHECK (status IN ('requested', 'approved', 'processing', 'completed', 'failed', 'cancelled')),
    
    -- Payment information
    refund_method TEXT 
        CHECK (refund_method IN ('original_payment', 'store_credit', 'check', 'bank_transfer')),
    
    stripe_refund_id TEXT,
    external_transaction_id TEXT,
    
    -- Return shipping
    return_tracking_number TEXT,
    return_label_url TEXT,
    
    -- Staff processing
    requested_by UUID REFERENCES auth.users(id),
    approved_by UUID REFERENCES auth.users(id),
    processed_by UUID REFERENCES auth.users(id),
    
    -- Timestamps
    requested_at TIMESTAMPTZ DEFAULT NOW(),
    approved_at TIMESTAMPTZ,
    processed_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    
    -- Notes
    customer_notes TEXT,
    internal_notes TEXT,
    
    -- Audit fields
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 6. NOTIFICATION PREFERENCES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.notification_preferences (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE,
    auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Email preferences
    email_order_confirmation BOOLEAN DEFAULT TRUE,
    email_order_shipped BOOLEAN DEFAULT TRUE,
    email_order_delivered BOOLEAN DEFAULT TRUE,
    email_marketing BOOLEAN DEFAULT FALSE,
    
    -- SMS preferences
    sms_order_shipped BOOLEAN DEFAULT FALSE,
    sms_order_delivered BOOLEAN DEFAULT FALSE,
    sms_marketing BOOLEAN DEFAULT FALSE,
    
    -- Push notification preferences
    push_order_updates BOOLEAN DEFAULT TRUE,
    push_marketing BOOLEAN DEFAULT FALSE,
    
    -- Contact information
    preferred_email TEXT,
    preferred_phone TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(customer_id),
    UNIQUE(auth_user_id)
);

-- ============================================
-- 7. INDEXES FOR PERFORMANCE
-- ============================================

-- Order fulfillment indexes
CREATE INDEX IF NOT EXISTS idx_order_fulfillment_order_id ON public.order_fulfillment(order_id);
CREATE INDEX IF NOT EXISTS idx_order_fulfillment_status ON public.order_fulfillment(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_fulfillment_tracking ON public.order_fulfillment(tracking_number) WHERE tracking_number IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_order_fulfillment_carrier ON public.order_fulfillment(carrier, status);
CREATE INDEX IF NOT EXISTS idx_order_fulfillment_assigned ON public.order_fulfillment(assigned_picker) WHERE assigned_picker IS NOT NULL;

-- Shipping labels indexes
CREATE INDEX IF NOT EXISTS idx_shipping_labels_order_id ON public.shipping_labels(order_id);
CREATE INDEX IF NOT EXISTS idx_shipping_labels_tracking ON public.shipping_labels(tracking_number);
CREATE INDEX IF NOT EXISTS idx_shipping_labels_status ON public.shipping_labels(status, created_at DESC);

-- Notifications indexes
CREATE INDEX IF NOT EXISTS idx_order_notifications_order_id ON public.order_notifications(order_id);
CREATE INDEX IF NOT EXISTS idx_order_notifications_status ON public.order_notifications(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_notifications_type ON public.order_notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_order_notifications_delivery_method ON public.order_notifications(delivery_method);
CREATE INDEX IF NOT EXISTS idx_order_notifications_recipient_email ON public.order_notifications(recipient_email) WHERE recipient_email IS NOT NULL;

-- Order notes indexes
CREATE INDEX IF NOT EXISTS idx_order_notes_order_id ON public.order_notes(order_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_notes_type ON public.order_notes(note_type);
CREATE INDEX IF NOT EXISTS idx_order_notes_created_by ON public.order_notes(created_by);

-- Refunds indexes
CREATE INDEX IF NOT EXISTS idx_order_refunds_order_id ON public.order_refunds(order_id);
CREATE INDEX IF NOT EXISTS idx_order_refunds_status ON public.order_refunds(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_refunds_type ON public.order_refunds(refund_type);

-- ============================================
-- 8. TRIGGER FUNCTIONS
-- ============================================

-- Function to update order status based on fulfillment status
CREATE OR REPLACE FUNCTION public.update_order_from_fulfillment()
RETURNS TRIGGER AS $$
BEGIN
    -- Update order status based on fulfillment status
    IF NEW.status = 'shipped' AND OLD.status != 'shipped' THEN
        UPDATE public.orders 
        SET 
            status = 'shipped',
            shipped_at = NEW.shipped_at,
            tracking_number = NEW.tracking_number,
            carrier_name = NEW.carrier,
            updated_at = NOW()
        WHERE id = NEW.order_id;
        
        -- Create notification for shipping
        INSERT INTO public.order_notifications (
            order_id, notification_type, delivery_method, 
            template_id, template_data, created_by
        ) VALUES (
            NEW.order_id, 'order_shipped', 'email',
            'order_shipped_template',
            jsonb_build_object(
                'tracking_number', NEW.tracking_number,
                'carrier', NEW.carrier,
                'estimated_delivery', NEW.estimated_delivery_date
            ),
            NEW.created_by
        );
    END IF;
    
    IF NEW.status = 'delivered' AND OLD.status != 'delivered' THEN
        UPDATE public.orders 
        SET 
            status = 'delivered',
            delivered_at = NEW.actual_delivery_date,
            updated_at = NOW()
        WHERE id = NEW.order_id;
        
        -- Create notification for delivery
        INSERT INTO public.order_notifications (
            order_id, notification_type, delivery_method, 
            template_id, created_by
        ) VALUES (
            NEW.order_id, 'order_delivered', 'email',
            'order_delivered_template',
            NEW.created_by
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to automatically update timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to handle inventory updates on fulfillment
CREATE OR REPLACE FUNCTION public.update_inventory_on_fulfillment()
RETURNS TRIGGER AS $$
DECLARE
    item RECORD;
BEGIN
    -- Only process when status changes to shipped
    IF NEW.status = 'shipped' AND (OLD.status IS NULL OR OLD.status != 'shipped') THEN
        -- Update inventory for each order item
        FOR item IN 
            SELECT oi.variant_id, oi.quantity 
            FROM public.order_items oi 
            WHERE oi.order_id = NEW.order_id 
            AND oi.variant_id IS NOT NULL
        LOOP
            -- Reduce inventory quantity
            UPDATE public.product_variants 
            SET 
                quantity_in_stock = GREATEST(0, quantity_in_stock - item.quantity),
                updated_at = NOW()
            WHERE id = item.variant_id;
            
            -- Log inventory change
            INSERT INTO public.order_events (
                order_id, event_type, event_category, title, description,
                metadata, created_by, is_automated
            ) VALUES (
                NEW.order_id, 'fulfillment', 'inventory',
                'Inventory updated',
                'Reduced inventory by ' || item.quantity || ' units',
                jsonb_build_object(
                    'variant_id', item.variant_id,
                    'quantity_change', -item.quantity,
                    'action', 'fulfillment'
                ),
                NEW.created_by, true
            );
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 9. CREATE TRIGGERS
-- ============================================

-- Trigger for order fulfillment updates
DROP TRIGGER IF EXISTS tr_update_order_from_fulfillment ON public.order_fulfillment;
CREATE TRIGGER tr_update_order_from_fulfillment
    AFTER UPDATE ON public.order_fulfillment
    FOR EACH ROW
    EXECUTE FUNCTION public.update_order_from_fulfillment();

-- Triggers for updating timestamps
DROP TRIGGER IF EXISTS tr_order_fulfillment_updated_at ON public.order_fulfillment;
CREATE TRIGGER tr_order_fulfillment_updated_at
    BEFORE UPDATE ON public.order_fulfillment
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS tr_shipping_labels_updated_at ON public.shipping_labels;
CREATE TRIGGER tr_shipping_labels_updated_at
    BEFORE UPDATE ON public.shipping_labels
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS tr_order_notifications_updated_at ON public.order_notifications;
CREATE TRIGGER tr_order_notifications_updated_at
    BEFORE UPDATE ON public.order_notifications
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS tr_order_notes_updated_at ON public.order_notes;
CREATE TRIGGER tr_order_notes_updated_at
    BEFORE UPDATE ON public.order_notes
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS tr_order_refunds_updated_at ON public.order_refunds;
CREATE TRIGGER tr_order_refunds_updated_at
    BEFORE UPDATE ON public.order_refunds
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Trigger for inventory updates
DROP TRIGGER IF EXISTS tr_update_inventory_on_fulfillment ON public.order_fulfillment;
CREATE TRIGGER tr_update_inventory_on_fulfillment
    AFTER UPDATE ON public.order_fulfillment
    FOR EACH ROW
    EXECUTE FUNCTION public.update_inventory_on_fulfillment();

-- ============================================
-- 10. RLS POLICIES
-- ============================================

-- Enable RLS on all new tables
ALTER TABLE public.order_fulfillment ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shipping_labels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_refunds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

-- Admin access policies
CREATE POLICY "Admins can manage order fulfillment" ON public.order_fulfillment
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    );

CREATE POLICY "Admins can manage shipping labels" ON public.shipping_labels
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    );

CREATE POLICY "Admins can manage order notifications" ON public.order_notifications
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    );

CREATE POLICY "Admins can manage order notes" ON public.order_notes
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    );

CREATE POLICY "Admins can manage refunds" ON public.order_refunds
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    );

CREATE POLICY "Users can manage their notification preferences" ON public.notification_preferences
    FOR ALL USING (auth_user_id = auth.uid());

-- Customer read-only policies for their own data
CREATE POLICY "Customers can view their order fulfillment" ON public.order_fulfillment
    FOR SELECT USING (
        order_id IN (
            SELECT id FROM public.orders o
            WHERE o.customer_id IN (
                SELECT id FROM public.customers WHERE auth_user_id = auth.uid()
            )
            OR (o.guest_email IS NOT NULL AND o.guest_email IN (
                SELECT email FROM auth.users WHERE id = auth.uid()
            ))
        )
    );

CREATE POLICY "Customers can view their notifications" ON public.order_notifications
    FOR SELECT USING (
        recipient_user_id = auth.uid()
        OR recipient_email IN (
            SELECT email FROM auth.users WHERE id = auth.uid()
        )
    );

-- ============================================
-- 11. UTILITY FUNCTIONS
-- ============================================

-- Function to get order fulfillment status
CREATE OR REPLACE FUNCTION public.get_order_fulfillment_status(p_order_id UUID)
RETURNS TABLE (
    fulfillment_status TEXT,
    tracking_number TEXT,
    carrier TEXT,
    estimated_delivery DATE,
    shipping_cost DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        of.status,
        of.tracking_number,
        of.carrier,
        of.estimated_delivery_date,
        of.shipping_cost
    FROM public.order_fulfillment of
    WHERE of.order_id = p_order_id
    ORDER BY of.created_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create fulfillment record
CREATE OR REPLACE FUNCTION public.create_order_fulfillment(
    p_order_id UUID,
    p_status TEXT DEFAULT 'pending',
    p_assigned_picker UUID DEFAULT NULL,
    p_warehouse_location TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_fulfillment_id UUID;
BEGIN
    INSERT INTO public.order_fulfillment (
        order_id, status, assigned_picker, warehouse_location, created_by
    ) VALUES (
        p_order_id, p_status, p_assigned_picker, p_warehouse_location, auth.uid()
    ) RETURNING id INTO v_fulfillment_id;
    
    -- Create initial fulfillment event
    INSERT INTO public.order_events (
        order_id, event_type, event_category, title, description,
        metadata, created_by, is_automated
    ) VALUES (
        p_order_id, 'fulfillment', 'workflow',
        'Fulfillment record created',
        'Order entered fulfillment pipeline with status: ' || p_status,
        jsonb_build_object(
            'fulfillment_id', v_fulfillment_id,
            'initial_status', p_status
        ),
        auth.uid(), true
    );
    
    RETURN v_fulfillment_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 12. GRANTS AND PERMISSIONS
-- ============================================

-- Grant permissions to authenticated users
GRANT SELECT, INSERT, UPDATE ON public.order_fulfillment TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.shipping_labels TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.order_notifications TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.order_notes TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.order_refunds TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.notification_preferences TO authenticated;

-- Grant function execution permissions
GRANT EXECUTE ON FUNCTION public.get_order_fulfillment_status TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_order_fulfillment TO authenticated;

-- Service role for system operations
GRANT ALL ON public.order_fulfillment TO service_role;
GRANT ALL ON public.shipping_labels TO service_role;
GRANT ALL ON public.order_notifications TO service_role;
GRANT ALL ON public.order_notes TO service_role;
GRANT ALL ON public.order_refunds TO service_role;
GRANT ALL ON public.notification_preferences TO service_role;

-- ============================================
-- 13. COMMENTS AND DOCUMENTATION
-- ============================================

COMMENT ON TABLE public.order_fulfillment IS 'Tracks order fulfillment lifecycle from processing to delivery';
COMMENT ON TABLE public.shipping_labels IS 'Stores shipping label information and carrier integration data';
COMMENT ON TABLE public.order_notifications IS 'Manages customer notifications for order updates';
COMMENT ON TABLE public.order_notes IS 'Internal and customer-facing notes for orders';
COMMENT ON TABLE public.order_refunds IS 'Handles refunds, returns, and exchanges';
COMMENT ON TABLE public.notification_preferences IS 'Customer preferences for order notifications';

COMMENT ON FUNCTION public.update_order_from_fulfillment IS 'Automatically updates order status based on fulfillment changes';
COMMENT ON FUNCTION public.update_inventory_on_fulfillment IS 'Updates product inventory when orders are shipped';

COMMIT;

-- ============================================
-- 14. VERIFICATION
-- ============================================

-- Verify all tables were created
SELECT 
    table_name,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = t.table_name)
        THEN '✅ Created'
        ELSE '❌ Failed'
    END as status
FROM (VALUES 
    ('order_fulfillment'),
    ('shipping_labels'),
    ('order_notifications'),
    ('order_notes'),
    ('order_refunds'),
    ('notification_preferences')
) AS t(table_name)
ORDER BY table_name;

-- Display summary
SELECT 'Order Fulfillment System Migration Complete! 🚀' as message;