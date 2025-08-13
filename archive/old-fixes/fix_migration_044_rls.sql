-- =====================================================
-- FIX FOR MIGRATION 044: Financial RLS Policies
-- This fixes the RLS policies to use the correct column structure
-- =====================================================

-- First, let's check what columns exist in admin_users
DO $$
DECLARE
    v_has_email BOOLEAN;
    v_has_user_id BOOLEAN;
    v_column_name TEXT;
BEGIN
    -- Check which identifier column exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'admin_users' AND column_name = 'email'
    ) INTO v_has_email;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'admin_users' AND column_name = 'user_id'
    ) INTO v_has_user_id;
    
    -- Report findings
    RAISE NOTICE 'Checking admin_users structure...';
    RAISE NOTICE 'Has email column: %', v_has_email;
    RAISE NOTICE 'Has user_id column: %', v_has_user_id;
    
    -- List all columns for debugging
    RAISE NOTICE 'Columns in admin_users table:';
    FOR v_column_name IN 
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'admin_users'
        ORDER BY ordinal_position
    LOOP
        RAISE NOTICE '  - %', v_column_name;
    END LOOP;
END $$;

-- =====================================================
-- Apply correct RLS policies based on actual structure
-- =====================================================

-- Enable RLS on financial tables
ALTER TABLE public.tax_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.refund_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_reconciliation ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (safe to run)
DROP POLICY IF EXISTS "Admin users can manage tax rates" ON public.tax_rates;
DROP POLICY IF EXISTS "Admin users can view payment transactions" ON public.payment_transactions;
DROP POLICY IF EXISTS "Admin users can manage refund requests" ON public.refund_requests;
DROP POLICY IF EXISTS "Admin users can manage financial reconciliation" ON public.financial_reconciliation;

-- Create simplified RLS policies that work with Supabase auth
DO $$
BEGIN
    RAISE NOTICE 'Creating simplified RLS policies...';
    
    -- Option 1: If admin_users has user_id column linking to auth.users
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'admin_users' AND column_name = 'user_id') THEN
        RAISE NOTICE 'Using user_id based policies...';
        
        -- Tax rates policy
        CREATE POLICY "Admin users can manage tax rates" ON public.tax_rates
        FOR ALL USING (
            auth.uid() IN (
                SELECT user_id FROM public.admin_users 
                WHERE role IN ('admin', 'super_admin')
            )
        );

        -- Payment transactions policy
        CREATE POLICY "Admin users can view payment transactions" ON public.payment_transactions
        FOR SELECT USING (
            auth.uid() IN (
                SELECT user_id FROM public.admin_users 
                WHERE role IN ('admin', 'super_admin')
            )
        );

        -- Refund requests policy
        CREATE POLICY "Admin users can manage refund requests" ON public.refund_requests
        FOR ALL USING (
            auth.uid() IN (
                SELECT user_id FROM public.admin_users 
                WHERE role IN ('admin', 'super_admin')
            )
        );

        -- Financial reconciliation policy
        CREATE POLICY "Admin users can manage financial reconciliation" ON public.financial_reconciliation
        FOR ALL USING (
            auth.uid() IN (
                SELECT user_id FROM public.admin_users 
                WHERE role IN ('admin', 'super_admin')
            )
        );
        
    -- Option 2: Fallback to checking if user exists in admin_users at all
    ELSE
        RAISE NOTICE 'Using simplified admin check policies...';
        
        -- Tax rates policy
        CREATE POLICY "Admin users can manage tax rates" ON public.tax_rates
        FOR ALL USING (
            EXISTS (
                SELECT 1 FROM public.admin_users 
                WHERE id = auth.uid() 
                   OR (auth.jwt() ->> 'sub')::uuid = id
            )
        );

        -- Payment transactions policy
        CREATE POLICY "Admin users can view payment transactions" ON public.payment_transactions
        FOR SELECT USING (
            EXISTS (
                SELECT 1 FROM public.admin_users 
                WHERE id = auth.uid() 
                   OR (auth.jwt() ->> 'sub')::uuid = id
            )
        );

        -- Refund requests policy
        CREATE POLICY "Admin users can manage refund requests" ON public.refund_requests
        FOR ALL USING (
            EXISTS (
                SELECT 1 FROM public.admin_users 
                WHERE id = auth.uid() 
                   OR (auth.jwt() ->> 'sub')::uuid = id
            )
        );

        -- Financial reconciliation policy
        CREATE POLICY "Admin users can manage financial reconciliation" ON public.financial_reconciliation
        FOR ALL USING (
            EXISTS (
                SELECT 1 FROM public.admin_users 
                WHERE id = auth.uid() 
                   OR (auth.jwt() ->> 'sub')::uuid = id
            )
        );
    END IF;

    -- Also create service role policies for Edge Functions
    CREATE POLICY "Service role has full access to tax_rates" ON public.tax_rates
    FOR ALL USING (auth.role() = 'service_role');
    
    CREATE POLICY "Service role has full access to payment_transactions" ON public.payment_transactions
    FOR ALL USING (auth.role() = 'service_role');
    
    CREATE POLICY "Service role has full access to refund_requests" ON public.refund_requests
    FOR ALL USING (auth.role() = 'service_role');
    
    CREATE POLICY "Service role has full access to financial_reconciliation" ON public.financial_reconciliation
    FOR ALL USING (auth.role() = 'service_role');

    RAISE NOTICE '✓ RLS policies created successfully';
END $$;

-- =====================================================
-- Continue with Migration 045: Stripe Fields
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'products' AND column_name = 'stripe_product_id') THEN
        RAISE NOTICE 'Applying Migration 045: Stripe Fields...';
        
        -- Add Stripe fields to products
        ALTER TABLE public.products 
        ADD COLUMN IF NOT EXISTS stripe_product_id TEXT,
        ADD COLUMN IF NOT EXISTS stripe_sync_status TEXT DEFAULT 'pending' 
            CHECK (stripe_sync_status IN ('pending', 'synced', 'failed', 'skip')),
        ADD COLUMN IF NOT EXISTS stripe_sync_error TEXT,
        ADD COLUMN IF NOT EXISTS stripe_synced_at TIMESTAMPTZ;

        -- Add Stripe fields to variants
        ALTER TABLE public.product_variants 
        ADD COLUMN IF NOT EXISTS stripe_price_id TEXT;

        -- Create sync log table
        CREATE TABLE IF NOT EXISTS public.stripe_sync_log (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            sync_type TEXT NOT NULL,
            entity_id UUID,
            entity_type TEXT,
            stripe_id TEXT,
            action TEXT,
            status TEXT,
            error_message TEXT,
            metadata JSONB,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            created_by TEXT DEFAULT CURRENT_USER
        );

        -- Create indexes
        CREATE INDEX IF NOT EXISTS idx_products_stripe_id 
        ON public.products(stripe_product_id) 
        WHERE stripe_product_id IS NOT NULL;

        CREATE INDEX IF NOT EXISTS idx_variants_stripe_price_id 
        ON public.product_variants(stripe_price_id) 
        WHERE stripe_price_id IS NOT NULL;

        -- Create helper view
        CREATE OR REPLACE VIEW public.stripe_sync_summary AS
        SELECT 
            COUNT(*) FILTER (WHERE stripe_product_id IS NOT NULL) as products_synced,
            COUNT(*) FILTER (WHERE stripe_product_id IS NULL) as products_pending,
            COUNT(*) FILTER (WHERE stripe_sync_status = 'failed') as products_failed,
            (SELECT COUNT(*) FROM product_variants WHERE stripe_price_id IS NOT NULL) as variants_synced,
            (SELECT COUNT(*) FROM product_variants WHERE stripe_price_id IS NULL) as variants_pending,
            (SELECT MAX(stripe_synced_at) FROM products) as last_sync_at
        FROM public.products;

        RAISE NOTICE '✓ Migration 045 completed';
    ELSE
        RAISE NOTICE '⊘ Migration 045 already applied (Stripe fields exist)';
    END IF;
END $$;

-- =====================================================
-- FINAL CHECK
-- =====================================================
DO $$
DECLARE
    v_policies_count INTEGER;
    v_stripe_fields BOOLEAN;
BEGIN
    -- Count RLS policies
    SELECT COUNT(*) INTO v_policies_count
    FROM pg_policies 
    WHERE tablename IN ('tax_rates', 'payment_transactions', 'refund_requests', 'financial_reconciliation');
    
    -- Check Stripe fields
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' AND column_name = 'stripe_product_id'
    ) INTO v_stripe_fields;
    
    RAISE NOTICE '';
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'MIGRATION FIX COMPLETE';
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'Financial RLS Policies: % created', v_policies_count;
    RAISE NOTICE 'Stripe Fields: %', CASE WHEN v_stripe_fields THEN '✓ Added' ELSE '✗ Missing' END;
    RAISE NOTICE '===========================================';
    
    IF v_policies_count >= 4 AND v_stripe_fields THEN
        RAISE NOTICE 'SUCCESS: Financial system ready! 🎉';
    END IF;
END $$;