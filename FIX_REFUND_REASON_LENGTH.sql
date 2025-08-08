-- ============================================
-- FIX REFUND REASON FIELD LENGTH
-- ============================================

-- 1. Check current column type
SELECT 
    column_name,
    data_type,
    character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'refund_requests'
AND column_name = 'reason';

-- 2. Fix the reason column to accept longer text
DO $$
BEGIN
    -- Change reason to TEXT type (unlimited length)
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'refund_requests' 
               AND column_name = 'reason'
               AND data_type != 'text') THEN
        ALTER TABLE public.refund_requests 
        ALTER COLUMN reason TYPE TEXT;
        RAISE NOTICE '✅ Changed reason column to TEXT type';
    ELSE
        RAISE NOTICE '⏭️  reason column is already TEXT type';
    END IF;
END $$;

-- 3. Now create a test refund with proper data
DO $$
DECLARE
    test_order_id UUID;
    test_customer_id UUID;
    test_amount INTEGER;
BEGIN
    -- Only create if no pending refunds exist
    IF NOT EXISTS (SELECT 1 FROM public.refund_requests WHERE status = 'pending') THEN
        -- Get a suitable order
        SELECT o.id, o.customer_id, o.total_amount
        INTO test_order_id, test_customer_id, test_amount
        FROM public.orders o
        WHERE o.total_amount > 0
        LIMIT 1;
        
        IF test_order_id IS NOT NULL THEN
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
                COALESCE(test_amount, 10000), -- Default to $100 if no amount
                'Size issue', -- Shorter reason
                'pending',
                'Test refund'
            );
            
            RAISE NOTICE '✅ Created test refund request';
        ELSE
            RAISE NOTICE '⚠️  No orders found to create test refund';
        END IF;
    ELSE
        RAISE NOTICE '✅ Pending refunds already exist';
    END IF;
END $$;

-- 4. Show pending refunds
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
ORDER BY rr.created_at DESC;

-- 5. Summary
SELECT 
    '✅ REFUND SYSTEM READY' as status,
    COUNT(*) as pending_refunds_count,
    SUM(refund_amount) / 100.0 as total_pending_amount
FROM public.refund_requests
WHERE status = 'pending';