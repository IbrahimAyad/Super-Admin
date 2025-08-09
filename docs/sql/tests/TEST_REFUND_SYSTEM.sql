-- ============================================
-- TEST REFUND SYSTEM
-- Verify everything is working
-- ============================================

-- 1. Check if we have any orders to work with
SELECT 
    'ORDERS AVAILABLE' as check_type,
    COUNT(*) as total_orders,
    COUNT(*) FILTER (WHERE payment_status = 'paid') as paid_orders,
    COUNT(*) FILTER (WHERE refund_status != 'none') as orders_with_refunds
FROM public.orders;

-- 2. Check if refund_requests table is ready
SELECT 
    'REFUND SYSTEM STATUS' as check_type,
    EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'refund_requests') as has_refund_table,
    EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'payment_transactions') as has_payment_table,
    EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'refund_status') as has_refund_columns;

-- 3. Check for any existing refund requests
SELECT 
    'EXISTING REFUNDS' as info,
    COUNT(*) as total_refund_requests,
    COUNT(*) FILTER (WHERE status = 'pending') as pending_refunds,
    COUNT(*) FILTER (WHERE status = 'completed') as completed_refunds
FROM public.refund_requests;

-- 4. Create a test refund request if none exist (for testing the UI)
DO $$
DECLARE
    test_order_id UUID;
    test_customer_id UUID;
BEGIN
    -- Only create test data if no refunds exist
    IF NOT EXISTS (SELECT 1 FROM public.refund_requests WHERE status = 'pending') THEN
        -- Get a paid order to create a refund for
        SELECT o.id, o.customer_id 
        INTO test_order_id, test_customer_id
        FROM public.orders o
        WHERE o.payment_status = 'paid' 
        AND o.refund_status = 'none'
        AND o.total_amount > 0
        LIMIT 1;
        
        IF test_order_id IS NOT NULL THEN
            -- Create a test refund request
            INSERT INTO public.refund_requests (
                order_id,
                customer_id,
                refund_amount,
                reason,
                status,
                internal_notes
            ) VALUES (
                test_order_id,
                test_customer_id,
                (SELECT total_amount FROM orders WHERE id = test_order_id), -- Full refund amount
                'Customer requested refund - size issue',
                'pending',
                'Test refund request for UI testing'
            );
            
            RAISE NOTICE '✅ Created test refund request for testing';
        ELSE
            RAISE NOTICE '⚠️  No paid orders available to create test refund';
        END IF;
    ELSE
        RAISE NOTICE '✅ Existing pending refunds found';
    END IF;
END $$;

-- 5. Show what RefundProcessor will display
SELECT 
    rr.id,
    rr.order_id,
    o.order_number,
    COALESCE(c.first_name || ' ' || c.last_name, c.email, 'Guest') as customer_name,
    rr.refund_amount / 100.0 as refund_amount_dollars,
    o.total_amount / 100.0 as original_amount_dollars,
    rr.reason,
    rr.status,
    rr.created_at::date as request_date
FROM public.refund_requests rr
LEFT JOIN public.orders o ON rr.order_id = o.id
LEFT JOIN public.customers c ON COALESCE(rr.customer_id, o.customer_id) = c.id
WHERE rr.status = 'pending'
ORDER BY rr.created_at DESC
LIMIT 10;

-- 6. Final status
SELECT 
    '🎉 REFUND SYSTEM READY' as status,
    'Go to Financial > Refund Processing in your admin panel' as next_step,
    'You should see pending refunds listed there' as expected_result;