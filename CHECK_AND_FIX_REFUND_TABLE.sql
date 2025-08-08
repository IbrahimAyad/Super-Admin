-- ============================================
-- CHECK AND FIX REFUND_REQUESTS TABLE
-- ============================================

-- 1. First, see what columns actually exist in refund_requests
SELECT 
    'CURRENT REFUND_REQUESTS COLUMNS' as info,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'refund_requests'
ORDER BY ordinal_position;

-- 2. Add missing columns to refund_requests
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'refund_requests') THEN
        -- Add refund_amount if missing
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'refund_requests' AND column_name = 'refund_amount') THEN
            ALTER TABLE public.refund_requests 
            ADD COLUMN refund_amount INTEGER NOT NULL DEFAULT 0;
            RAISE NOTICE '✅ Added refund_amount to refund_requests';
        END IF;
        
        -- Add order_id if missing
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'refund_requests' AND column_name = 'order_id') THEN
            ALTER TABLE public.refund_requests 
            ADD COLUMN order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE;
            RAISE NOTICE '✅ Added order_id to refund_requests';
        END IF;
        
        -- Add customer_id if missing
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'refund_requests' AND column_name = 'customer_id') THEN
            ALTER TABLE public.refund_requests 
            ADD COLUMN customer_id UUID REFERENCES public.customers(id);
            RAISE NOTICE '✅ Added customer_id to refund_requests';
        END IF;
        
        -- Add reason if missing
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'refund_requests' AND column_name = 'reason') THEN
            ALTER TABLE public.refund_requests 
            ADD COLUMN reason TEXT;
            RAISE NOTICE '✅ Added reason to refund_requests';
        END IF;
        
        -- Add status if missing
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'refund_requests' AND column_name = 'status') THEN
            ALTER TABLE public.refund_requests 
            ADD COLUMN status VARCHAR(20) DEFAULT 'pending';
            RAISE NOTICE '✅ Added status to refund_requests';
        END IF;
        
        -- Add stripe_refund_id if missing
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'refund_requests' AND column_name = 'stripe_refund_id') THEN
            ALTER TABLE public.refund_requests 
            ADD COLUMN stripe_refund_id VARCHAR(255);
            RAISE NOTICE '✅ Added stripe_refund_id to refund_requests';
        END IF;
        
        -- Add processed_amount if missing
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'refund_requests' AND column_name = 'processed_amount') THEN
            ALTER TABLE public.refund_requests 
            ADD COLUMN processed_amount INTEGER;
            RAISE NOTICE '✅ Added processed_amount to refund_requests';
        END IF;
        
        -- Add processed_at if missing
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'refund_requests' AND column_name = 'processed_at') THEN
            ALTER TABLE public.refund_requests 
            ADD COLUMN processed_at TIMESTAMPTZ;
            RAISE NOTICE '✅ Added processed_at to refund_requests';
        END IF;
        
        -- Add processed_by if missing
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'refund_requests' AND column_name = 'processed_by') THEN
            ALTER TABLE public.refund_requests 
            ADD COLUMN processed_by UUID;
            RAISE NOTICE '✅ Added processed_by to refund_requests';
        END IF;
        
        -- Add processing_notes if missing
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'refund_requests' AND column_name = 'processing_notes') THEN
            ALTER TABLE public.refund_requests 
            ADD COLUMN processing_notes TEXT;
            RAISE NOTICE '✅ Added processing_notes to refund_requests';
        END IF;
        
        -- Add internal_notes if missing
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'refund_requests' AND column_name = 'internal_notes') THEN
            ALTER TABLE public.refund_requests 
            ADD COLUMN internal_notes TEXT;
            RAISE NOTICE '✅ Added internal_notes to refund_requests';
        END IF;
        
        -- Add created_at if missing
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'refund_requests' AND column_name = 'created_at') THEN
            ALTER TABLE public.refund_requests 
            ADD COLUMN created_at TIMESTAMPTZ DEFAULT NOW();
            RAISE NOTICE '✅ Added created_at to refund_requests';
        END IF;
        
        -- Add updated_at if missing
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'refund_requests' AND column_name = 'updated_at') THEN
            ALTER TABLE public.refund_requests 
            ADD COLUMN updated_at TIMESTAMPTZ DEFAULT NOW();
            RAISE NOTICE '✅ Added updated_at to refund_requests';
        END IF;
    ELSE
        -- Create the table if it doesn't exist at all
        CREATE TABLE public.refund_requests (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
            customer_id UUID REFERENCES public.customers(id),
            refund_amount INTEGER NOT NULL DEFAULT 0,
            reason TEXT,
            status VARCHAR(20) DEFAULT 'pending',
            stripe_refund_id VARCHAR(255),
            processed_amount INTEGER,
            processed_at TIMESTAMPTZ,
            processed_by UUID,
            processing_notes TEXT,
            internal_notes TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );
        
        CREATE INDEX idx_refund_requests_status ON public.refund_requests(status);
        CREATE INDEX idx_refund_requests_order ON public.refund_requests(order_id);
        
        RAISE NOTICE '✅ Created refund_requests table with all columns';
    END IF;
END $$;

-- 3. Show updated structure
SELECT 
    'UPDATED REFUND_REQUESTS STRUCTURE' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'refund_requests'
ORDER BY ordinal_position;

-- 4. Check if we have any data
SELECT 
    'REFUND DATA CHECK' as info,
    COUNT(*) as total_refunds,
    COUNT(*) FILTER (WHERE status = 'pending') as pending_refunds
FROM public.refund_requests;

-- 5. Create a test refund if none exist
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
        AND (o.payment_status = 'paid' OR o.payment_status IS NOT NULL)
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
                'Customer requested refund - product not as described',
                'pending',
                'Test refund for UI testing'
            );
            
            RAISE NOTICE '✅ Created test refund request';
        END IF;
    END IF;
END $$;

-- 6. Now show what RefundProcessor will see (with proper column names)
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

-- 7. Final status
SELECT 
    '✅ REFUND TABLE FIXED' as status,
    'All required columns added' as message,
    'RefundProcessor should now work' as next_step;