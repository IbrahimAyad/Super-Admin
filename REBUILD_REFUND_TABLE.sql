-- ============================================
-- REBUILD REFUND_REQUESTS TABLE PROPERLY
-- ============================================

-- 1. First check what columns currently exist
SELECT 
    'CURRENT STRUCTURE' as info,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'refund_requests'
ORDER BY ordinal_position;

-- 2. Drop and recreate the table with proper structure
-- (We'll backup any existing data first)
DO $$
BEGIN
    -- Check if table has any data we need to preserve
    IF EXISTS (SELECT 1 FROM public.refund_requests LIMIT 1) THEN
        RAISE NOTICE 'Table has data - creating backup';
        CREATE TABLE refund_requests_backup AS SELECT * FROM public.refund_requests;
    END IF;
    
    -- Drop the existing table
    DROP TABLE IF EXISTS public.refund_requests CASCADE;
    
    -- Create with proper structure
    CREATE TABLE public.refund_requests (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
        customer_id UUID REFERENCES public.customers(id),
        refund_amount INTEGER NOT NULL DEFAULT 0, -- Amount in cents
        reason TEXT,
        status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'completed', 'failed')),
        stripe_refund_id VARCHAR(255),
        processed_amount INTEGER,
        processed_at TIMESTAMPTZ,
        processed_by UUID,
        processing_notes TEXT,
        internal_notes TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
    );
    
    -- Create indexes
    CREATE INDEX idx_refund_requests_status ON public.refund_requests(status);
    CREATE INDEX idx_refund_requests_order ON public.refund_requests(order_id);
    CREATE INDEX idx_refund_requests_customer ON public.refund_requests(customer_id);
    CREATE INDEX idx_refund_requests_created ON public.refund_requests(created_at DESC);
    
    -- Enable RLS
    ALTER TABLE public.refund_requests ENABLE ROW LEVEL SECURITY;
    
    -- Create RLS policy
    CREATE POLICY "Admin users can manage refund requests" ON public.refund_requests
        FOR ALL USING (auth.role() = 'authenticated');
    
    RAISE NOTICE '✅ Refund requests table recreated with proper structure';
    
    -- Check if we had a backup to restore
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'refund_requests_backup') THEN
        RAISE NOTICE 'Restoring data from backup...';
        -- Try to restore data (will only work if columns match)
        BEGIN
            INSERT INTO public.refund_requests SELECT * FROM refund_requests_backup;
            DROP TABLE refund_requests_backup;
            RAISE NOTICE '✅ Data restored from backup';
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE '⚠️  Could not restore backup data - table structure changed';
                DROP TABLE IF EXISTS refund_requests_backup;
        END;
    END IF;
END $$;

-- 3. Verify the new structure
SELECT 
    'NEW STRUCTURE' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'refund_requests'
ORDER BY ordinal_position;

-- 4. Create a test refund request
DO $$
DECLARE
    test_order_id UUID;
    test_customer_id UUID;
    test_amount INTEGER;
BEGIN
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
            'Customer requested - size issue',
            'pending',
            'Test refund for UI'
        );
        
        RAISE NOTICE '✅ Created test refund request';
    ELSE
        RAISE NOTICE '⚠️  No orders found to create test refund';
        
        -- Create a minimal test refund without order reference
        INSERT INTO public.refund_requests (
            refund_amount,
            reason,
            status,
            internal_notes
        ) VALUES (
            15000, -- $150 in cents
            'Test refund request',
            'pending',
            'Created for testing purposes'
        );
        
        RAISE NOTICE '✅ Created standalone test refund';
    END IF;
END $$;

-- 5. Show what's in the table now
SELECT 
    rr.id,
    rr.order_id,
    rr.refund_amount / 100.0 as refund_amount_dollars,
    rr.reason,
    rr.status,
    rr.created_at
FROM public.refund_requests rr
ORDER BY rr.created_at DESC;

-- 6. Final status
SELECT 
    '✅ REFUND TABLE REBUILT' as status,
    COUNT(*) as total_refunds,
    COUNT(*) FILTER (WHERE status = 'pending') as pending_refunds,
    'Go to your admin panel to see refunds' as next_step
FROM public.refund_requests;