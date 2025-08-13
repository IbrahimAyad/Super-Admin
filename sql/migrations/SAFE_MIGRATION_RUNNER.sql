-- ============================================
-- SAFE MIGRATION RUNNER
-- Run this to apply only the migrations you need
-- It checks what exists before creating anything
-- ============================================

-- STEP 1: Show current status
DO $$
BEGIN
    RAISE NOTICE '=== CHECKING CURRENT DATABASE STATUS ===';
END $$;

SELECT 
    'Current Tables' as info,
    COUNT(*) as total_tables,
    array_to_string(
        array_agg(table_name ORDER BY table_name), 
        ', '
    ) as table_list
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE';

-- STEP 2: Create refund tables if they don't exist (Migration 051)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'refund_requests') THEN
        RAISE NOTICE 'Creating refund_requests table...';
        
        CREATE TABLE public.refund_requests (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
            customer_id UUID REFERENCES public.customers(id),
            refund_amount INTEGER NOT NULL,
            reason TEXT NOT NULL,
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
        
        RAISE NOTICE '✅ refund_requests table created';
    ELSE
        RAISE NOTICE '⏭️  refund_requests table already exists';
    END IF;
END $$;

-- STEP 3: Create payment_transactions if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payment_transactions') THEN
        RAISE NOTICE 'Creating payment_transactions table...';
        
        CREATE TABLE public.payment_transactions (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
            transaction_type VARCHAR(20) NOT NULL,
            amount INTEGER NOT NULL,
            currency VARCHAR(3) DEFAULT 'usd',
            status VARCHAR(20) DEFAULT 'pending',
            gateway VARCHAR(50) DEFAULT 'stripe',
            gateway_transaction_id VARCHAR(255),
            gateway_response JSONB,
            metadata JSONB DEFAULT '{}',
            created_at TIMESTAMPTZ DEFAULT NOW()
        );
        
        CREATE INDEX idx_payment_transactions_order ON public.payment_transactions(order_id);
        
        RAISE NOTICE '✅ payment_transactions table created';
    ELSE
        RAISE NOTICE '⏭️  payment_transactions table already exists';
    END IF;
END $$;

-- STEP 4: Create analytics_events if it doesn't exist (Migration 050)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'analytics_events') THEN
        RAISE NOTICE 'Creating analytics_events table...';
        
        CREATE TABLE public.analytics_events (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            session_id VARCHAR(100) NOT NULL,
            user_id UUID,
            event_type VARCHAR(50) NOT NULL,
            event_category VARCHAR(50),
            event_action VARCHAR(100),
            event_label VARCHAR(255),
            event_value NUMERIC,
            page_path VARCHAR(500),
            page_title VARCHAR(255),
            referrer VARCHAR(500),
            user_agent TEXT,
            ip_address INET,
            country VARCHAR(2),
            device_type VARCHAR(20),
            browser VARCHAR(50),
            os VARCHAR(50),
            utm_source VARCHAR(100),
            utm_medium VARCHAR(100),
            utm_campaign VARCHAR(100),
            metadata JSONB DEFAULT '{}',
            created_at TIMESTAMPTZ DEFAULT NOW()
        );
        
        CREATE INDEX idx_analytics_events_session ON public.analytics_events(session_id);
        CREATE INDEX idx_analytics_events_type ON public.analytics_events(event_type);
        CREATE INDEX idx_analytics_events_created ON public.analytics_events(created_at DESC);
        
        RAISE NOTICE '✅ analytics_events table created';
    ELSE
        RAISE NOTICE '⏭️  analytics_events table already exists';
    END IF;
END $$;

-- STEP 5: Add missing columns to orders table
DO $$
BEGIN
    -- Add refund_status if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'refund_status') THEN
        ALTER TABLE public.orders 
        ADD COLUMN refund_status VARCHAR(20) DEFAULT 'none';
        RAISE NOTICE '✅ Added refund_status to orders';
    END IF;
    
    -- Add total_refunded if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'total_refunded') THEN
        ALTER TABLE public.orders 
        ADD COLUMN total_refunded INTEGER DEFAULT 0;
        RAISE NOTICE '✅ Added total_refunded to orders';
    END IF;
END $$;

-- STEP 6: Create daily_analytics_summary if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'daily_analytics_summary') THEN
        RAISE NOTICE 'Creating daily_analytics_summary table...';
        
        CREATE TABLE public.daily_analytics_summary (
            date DATE PRIMARY KEY,
            total_revenue INTEGER DEFAULT 0,
            total_orders INTEGER DEFAULT 0,
            total_customers INTEGER DEFAULT 0,
            new_customers INTEGER DEFAULT 0,
            total_page_views INTEGER DEFAULT 0,
            unique_visitors INTEGER DEFAULT 0,
            avg_order_value NUMERIC(10,2),
            conversion_rate NUMERIC(5,4),
            top_products JSONB DEFAULT '[]',
            top_referrers JSONB DEFAULT '[]',
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );
        
        RAISE NOTICE '✅ daily_analytics_summary table created';
    ELSE
        RAISE NOTICE '⏭️  daily_analytics_summary table already exists';
    END IF;
END $$;

-- STEP 7: Enable RLS on new tables
DO $$
BEGIN
    -- Enable RLS on refund_requests
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'refund_requests') THEN
        ALTER TABLE public.refund_requests ENABLE ROW LEVEL SECURITY;
        
        -- Create policy if it doesn't exist
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'refund_requests' AND policyname = 'Admin users can manage refund requests') THEN
            CREATE POLICY "Admin users can manage refund requests" ON public.refund_requests
                FOR ALL USING (auth.role() = 'authenticated');
        END IF;
    END IF;
    
    -- Enable RLS on payment_transactions
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payment_transactions') THEN
        ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;
        
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payment_transactions' AND policyname = 'Admin users can manage payment transactions') THEN
            CREATE POLICY "Admin users can manage payment transactions" ON public.payment_transactions
                FOR ALL USING (auth.role() = 'authenticated');
        END IF;
    END IF;
    
    -- Enable RLS on analytics_events
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'analytics_events') THEN
        ALTER TABLE public.analytics_events ENABLE ROW LEVEL SECURITY;
        
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'analytics_events' AND policyname = 'Admin users can manage analytics') THEN
            CREATE POLICY "Admin users can manage analytics" ON public.analytics_events
                FOR ALL USING (auth.role() = 'authenticated');
        END IF;
    END IF;
    
    RAISE NOTICE '✅ RLS policies applied';
END $$;

-- STEP 8: Final status report
SELECT 
    'MIGRATION COMPLETE' as status,
    json_build_object(
        'refund_requests', EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'refund_requests'),
        'payment_transactions', EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'payment_transactions'),
        'analytics_events', EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'analytics_events'),
        'daily_analytics_summary', EXISTS(SELECT 1 FROM information_schema.tables WHERE table_name = 'daily_analytics_summary'),
        'orders_has_refund_columns', EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'refund_status')
    ) as tables_created;

-- Show what's ready to use
SELECT 
    '🎉 READY TO USE' as info,
    'RefundProcessor will now show real data' as refunds,
    'Analytics tracking is ready to collect events' as analytics,
    'Financial dashboard can connect to real data' as financial;