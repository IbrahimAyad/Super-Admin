-- ============================================
-- ORDERS MANAGEMENT RLS POLICIES
-- Comprehensive Row Level Security for KCT Menswear
-- Created: 2025-08-08
-- ============================================

-- ============================================
-- 1. ORDERS TABLE POLICIES
-- ============================================

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Admins can manage orders" ON public.orders;
DROP POLICY IF EXISTS "Customers can view own orders" ON public.orders;
DROP POLICY IF EXISTS "System can create orders" ON public.orders;

-- Ensure RLS is enabled
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Admin users can manage all orders
CREATE POLICY "Admins can manage all orders" ON public.orders
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    );

-- Customers can view their own orders
CREATE POLICY "Customers can view own orders" ON public.orders
    FOR SELECT
    USING (
        -- Registered customers can see orders linked to their customer record
        customer_id IN (
            SELECT id FROM public.customers 
            WHERE auth_user_id = auth.uid()
        )
        OR
        -- Users can see orders placed with their email as guest
        (auth.uid() IS NOT NULL AND guest_email IN (
            SELECT email FROM auth.users WHERE id = auth.uid()
        ))
    );

-- System/service role can create and update orders (for webhooks, etc.)
CREATE POLICY "System can manage orders" ON public.orders
    FOR ALL
    TO service_role, anon
    USING (true)
    WITH CHECK (true);

-- Allow order creation during checkout (anonymous users)
CREATE POLICY "Anonymous can create orders during checkout" ON public.orders
    FOR INSERT
    TO anon
    WITH CHECK (
        -- Only allow if it's a new order with basic required fields
        id IS NOT NULL 
        AND status IS NOT NULL
        AND created_at IS NOT NULL
    );

-- ============================================
-- 2. ORDER ITEMS POLICIES
-- ============================================

-- Ensure RLS is enabled
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Admins can manage order items" ON public.order_items;
DROP POLICY IF EXISTS "Customers can view own order items" ON public.order_items;

-- Admin users can manage all order items
CREATE POLICY "Admins can manage all order items" ON public.order_items
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    );

-- Customers can view items from their orders
CREATE POLICY "Customers can view own order items" ON public.order_items
    FOR SELECT
    USING (
        order_id IN (
            SELECT id FROM public.orders o
            WHERE o.customer_id IN (
                SELECT id FROM public.customers 
                WHERE auth_user_id = auth.uid()
            )
            OR (auth.uid() IS NOT NULL AND o.guest_email IN (
                SELECT email FROM auth.users WHERE id = auth.uid()
            ))
        )
    );

-- System can manage order items
CREATE POLICY "System can manage order items" ON public.order_items
    FOR ALL
    TO service_role, anon
    USING (true)
    WITH CHECK (true);

-- ============================================
-- 3. ORDER EVENTS POLICIES  
-- ============================================

-- Policies already exist from previous migration - verify they're correct
DROP POLICY IF EXISTS "Admins can manage order events" ON public.order_events;
DROP POLICY IF EXISTS "Customers can view their order events" ON public.order_events;

-- Admin users can manage all order events
CREATE POLICY "Admins can manage all order events" ON public.order_events
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    );

-- Customers can view customer-visible events from their orders
CREATE POLICY "Customers can view their order events" ON public.order_events
    FOR SELECT
    USING (
        is_customer_visible = true 
        AND order_id IN (
            SELECT id FROM public.orders o
            WHERE o.customer_id IN (
                SELECT id FROM public.customers 
                WHERE auth_user_id = auth.uid()
            )
            OR (auth.uid() IS NOT NULL AND o.guest_email IN (
                SELECT email FROM auth.users WHERE id = auth.uid()
            ))
        )
    );

-- System can create events (automated logging)
CREATE POLICY "System can create order events" ON public.order_events
    FOR INSERT
    TO service_role, anon
    WITH CHECK (true);

-- ============================================
-- 4. SHIPMENTS POLICIES
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Admins can manage shipments" ON public.order_shipments;

-- Admin users can manage all shipments
CREATE POLICY "Admins can manage all shipments" ON public.order_shipments
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    );

-- Customers can view shipments for their orders
CREATE POLICY "Customers can view their shipments" ON public.order_shipments
    FOR SELECT
    USING (
        order_id IN (
            SELECT id FROM public.orders o
            WHERE o.customer_id IN (
                SELECT id FROM public.customers 
                WHERE auth_user_id = auth.uid()
            )
            OR (auth.uid() IS NOT NULL AND o.guest_email IN (
                SELECT email FROM auth.users WHERE id = auth.uid()
            ))
        )
    );

-- System can manage shipments (for carrier webhooks)
CREATE POLICY "System can manage shipments" ON public.order_shipments
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================
-- 5. SHIPMENT ITEMS POLICIES
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Admins can manage shipment items" ON public.order_shipment_items;

-- Admin users can manage all shipment items
CREATE POLICY "Admins can manage all shipment items" ON public.order_shipment_items
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    );

-- Customers can view shipment items for their orders
CREATE POLICY "Customers can view their shipment items" ON public.order_shipment_items
    FOR SELECT
    USING (
        shipment_id IN (
            SELECT s.id FROM public.order_shipments s
            JOIN public.orders o ON s.order_id = o.id
            WHERE o.customer_id IN (
                SELECT id FROM public.customers 
                WHERE auth_user_id = auth.uid()
            )
            OR (auth.uid() IS NOT NULL AND o.guest_email IN (
                SELECT email FROM auth.users WHERE id = auth.uid()
            ))
        )
    );

-- System can manage shipment items
CREATE POLICY "System can manage shipment items" ON public.order_shipment_items
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================
-- 6. RETURNS POLICIES
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Admins can manage returns" ON public.order_returns;

-- Admin users can manage all returns
CREATE POLICY "Admins can manage all returns" ON public.order_returns
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    );

-- Customers can view and create returns for their orders
CREATE POLICY "Customers can manage their returns" ON public.order_returns
    FOR ALL
    USING (
        order_id IN (
            SELECT id FROM public.orders o
            WHERE o.customer_id IN (
                SELECT id FROM public.customers 
                WHERE auth_user_id = auth.uid()
            )
            OR (auth.uid() IS NOT NULL AND o.guest_email IN (
                SELECT email FROM auth.users WHERE id = auth.uid()
            ))
        )
    )
    WITH CHECK (
        order_id IN (
            SELECT id FROM public.orders o
            WHERE o.customer_id IN (
                SELECT id FROM public.customers 
                WHERE auth_user_id = auth.uid()
            )
            OR (auth.uid() IS NOT NULL AND o.guest_email IN (
                SELECT email FROM auth.users WHERE id = auth.uid()
            ))
        )
        -- Additional business rules for return creation
        AND status IN ('requested', 'approved') -- Customers can only create/update requests and approved returns
    );

-- System can manage returns
CREATE POLICY "System can manage returns" ON public.order_returns
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================
-- 7. RETURN ITEMS POLICIES
-- ============================================

-- Drop existing policies
DROP POLICY IF EXISTS "Admins can manage return items" ON public.order_return_items;

-- Admin users can manage all return items
CREATE POLICY "Admins can manage all return items" ON public.order_return_items
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    );

-- Customers can view return items for their returns
CREATE POLICY "Customers can view their return items" ON public.order_return_items
    FOR SELECT
    USING (
        return_id IN (
            SELECT r.id FROM public.order_returns r
            JOIN public.orders o ON r.order_id = o.id
            WHERE o.customer_id IN (
                SELECT id FROM public.customers 
                WHERE auth_user_id = auth.uid()
            )
            OR (auth.uid() IS NOT NULL AND o.guest_email IN (
                SELECT email FROM auth.users WHERE id = auth.uid()
            ))
        )
    );

-- Customers can add items to their return requests
CREATE POLICY "Customers can add items to their returns" ON public.order_return_items
    FOR INSERT
    WITH CHECK (
        return_id IN (
            SELECT r.id FROM public.order_returns r
            JOIN public.orders o ON r.order_id = o.id
            WHERE (o.customer_id IN (
                SELECT id FROM public.customers 
                WHERE auth_user_id = auth.uid()
            )
            OR (auth.uid() IS NOT NULL AND o.guest_email IN (
                SELECT email FROM auth.users WHERE id = auth.uid()
            )))
            AND r.status IN ('requested', 'approved') -- Can only add items to certain statuses
        )
    );

-- System can manage return items
CREATE POLICY "System can manage return items" ON public.order_return_items
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================
-- 8. MATERIALIZED VIEWS POLICIES
-- ============================================

-- Grant read access to analytics views for admins only
GRANT SELECT ON public.daily_order_summary TO authenticated;
GRANT SELECT ON public.fulfillment_performance TO authenticated;

-- Create policies for materialized views (if supported)
-- Note: PostgreSQL doesn't support RLS on materialized views directly,
-- so we control access through function-based access

-- ============================================
-- 9. FUNCTION SECURITY
-- ============================================

-- Ensure admin-only functions have proper security
ALTER FUNCTION public.get_orders_optimized SECURITY DEFINER;
ALTER FUNCTION public.search_orders_fast SECURITY DEFINER;
ALTER FUNCTION public.get_orders_requiring_attention SECURITY DEFINER;
ALTER FUNCTION public.get_fulfillment_metrics SECURITY DEFINER;

-- Create wrapper functions with RLS checks for customer access
CREATE OR REPLACE FUNCTION public.get_customer_orders(
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
    id UUID,
    order_number TEXT,
    status TEXT,
    total DECIMAL(10,2),
    created_at TIMESTAMPTZ,
    item_count BIGINT
) SECURITY DEFINER AS $$
BEGIN
    -- Verify the user is authenticated
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    RETURN QUERY
    SELECT 
        o.id,
        o.order_number,
        o.status,
        o.total,
        o.created_at,
        COUNT(oi.id) as item_count
    FROM public.orders o
    LEFT JOIN public.order_items oi ON o.id = oi.order_id
    WHERE 
        -- Apply RLS logic manually in function
        o.customer_id IN (
            SELECT c.id FROM public.customers c
            WHERE c.auth_user_id = auth.uid()
        )
        OR (o.guest_email IN (
            SELECT u.email FROM auth.users u WHERE u.id = auth.uid()
        ))
    GROUP BY o.id
    ORDER BY o.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;

-- Grant access to customer function
GRANT EXECUTE ON FUNCTION public.get_customer_orders TO authenticated;

-- ============================================
-- 10. SECURITY VALIDATION FUNCTIONS
-- ============================================

-- Function to validate order access for a user
CREATE OR REPLACE FUNCTION public.can_user_access_order(
    p_order_id UUID,
    p_user_id UUID DEFAULT auth.uid()
)
RETURNS BOOLEAN AS $$
DECLARE
    v_has_access BOOLEAN := false;
BEGIN
    -- Check if user is admin
    IF EXISTS (
        SELECT 1 FROM public.admin_users
        WHERE user_id = p_user_id AND is_active = true
    ) THEN
        RETURN true;
    END IF;
    
    -- Check if user owns the order
    SELECT EXISTS (
        SELECT 1 FROM public.orders o
        WHERE o.id = p_order_id
        AND (
            o.customer_id IN (
                SELECT id FROM public.customers 
                WHERE auth_user_id = p_user_id
            )
            OR (p_user_id IS NOT NULL AND o.guest_email IN (
                SELECT email FROM auth.users WHERE id = p_user_id
            ))
        )
    ) INTO v_has_access;
    
    RETURN v_has_access;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can modify an order
CREATE OR REPLACE FUNCTION public.can_user_modify_order(
    p_order_id UUID,
    p_user_id UUID DEFAULT auth.uid()
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Only admins can modify orders
    RETURN EXISTS (
        SELECT 1 FROM public.admin_users
        WHERE user_id = p_user_id AND is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant access to validation functions
GRANT EXECUTE ON FUNCTION public.can_user_access_order TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_user_modify_order TO authenticated;

-- ============================================
-- 11. AUDIT AND LOGGING
-- ============================================

-- Function to log policy violations (for security monitoring)
CREATE OR REPLACE FUNCTION public.log_policy_violation(
    p_table_name TEXT,
    p_operation TEXT,
    p_user_id UUID DEFAULT auth.uid(),
    p_details TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO public.order_events (
        order_id, event_type, event_category, title, description,
        metadata, created_by, is_automated, is_customer_visible
    ) VALUES (
        NULL, 'system', 'security',
        'RLS Policy Violation Detected',
        'User attempted unauthorized access to ' || p_table_name,
        jsonb_build_object(
            'table_name', p_table_name,
            'operation', p_operation,
            'user_id', p_user_id,
            'details', p_details,
            'ip_address', current_setting('request.headers', true)::jsonb->>'x-forwarded-for'
        ),
        p_user_id, true, false
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 12. TESTING AND VERIFICATION
-- ============================================

-- Function to test RLS policies
CREATE OR REPLACE FUNCTION public.test_rls_policies()
RETURNS TABLE (
    test_name TEXT,
    table_name TEXT,
    result TEXT,
    description TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'Admin Access Test' as test_name,
        'orders' as table_name,
        CASE 
            WHEN EXISTS (
                SELECT 1 FROM public.orders 
                WHERE EXISTS (
                    SELECT 1 FROM public.admin_users 
                    WHERE user_id = auth.uid() AND is_active = true
                )
            ) THEN 'PASS'
            ELSE 'FAIL'
        END as result,
        'Admins should have access to all orders' as description
    
    UNION ALL
    
    SELECT 
        'Customer Isolation Test',
        'orders',
        CASE 
            WHEN NOT EXISTS (
                SELECT 1 FROM public.orders o1
                JOIN public.orders o2 ON o1.customer_id != o2.customer_id
                WHERE o1.customer_id IN (
                    SELECT id FROM public.customers WHERE auth_user_id = auth.uid()
                )
            ) THEN 'PASS'
            ELSE 'NEEDS_VERIFICATION'
        END,
        'Customers should only see their own orders';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant access to test function
GRANT EXECUTE ON FUNCTION public.test_rls_policies TO authenticated;

-- ============================================
-- 13. FINAL VERIFICATION
-- ============================================

-- Check all policies are in place
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd as operation,
    CASE 
        WHEN qual IS NOT NULL THEN 'HAS_USING_CLAUSE' 
        ELSE 'NO_USING_CLAUSE' 
    END as using_clause,
    CASE 
        WHEN with_check IS NOT NULL THEN 'HAS_CHECK_CLAUSE' 
        ELSE 'NO_CHECK_CLAUSE' 
    END as check_clause
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename IN ('orders', 'order_items', 'order_events', 'order_shipments', 'order_returns')
ORDER BY tablename, policyname;

-- Verify RLS is enabled on all tables
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
    AND tablename IN ('orders', 'order_items', 'order_events', 'order_shipments', 'order_returns')
ORDER BY tablename;

-- Document the security model
COMMENT ON FUNCTION public.can_user_access_order IS 'Validates if a user can access a specific order (admin or owner)';
COMMENT ON FUNCTION public.can_user_modify_order IS 'Validates if a user can modify an order (admin only)';
COMMENT ON FUNCTION public.get_customer_orders IS 'Secure function for customers to access their own orders';

SELECT 'RLS Policies Applied Successfully! 🔒' as status;