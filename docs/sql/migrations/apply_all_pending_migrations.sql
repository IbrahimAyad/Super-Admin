-- =====================================================
-- CONSOLIDATED MIGRATION SCRIPT
-- Applies all pending migrations (037-045) in order
-- Run this ONCE in Supabase SQL Editor
-- =====================================================

-- Check if migrations already applied
DO $$
BEGIN
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'Starting consolidated migration...';
    RAISE NOTICE 'This will apply migrations 037-045';
    RAISE NOTICE '===========================================';
END $$;

-- =====================================================
-- MIGRATION 037: Create Settings Tables
-- =====================================================
-- Check if settings tables exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'settings_categories') THEN
        RAISE NOTICE 'Applying Migration 037: Settings Tables...';
        
        -- Create settings categories table
        CREATE TABLE public.settings_categories (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name TEXT NOT NULL UNIQUE,
            display_name TEXT NOT NULL,
            description TEXT,
            icon TEXT,
            sort_order INTEGER DEFAULT 0,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );

        -- Create settings table
        CREATE TABLE public.settings (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            category_id UUID REFERENCES public.settings_categories(id) ON DELETE CASCADE,
            key TEXT NOT NULL UNIQUE,
            value JSONB,
            display_name TEXT NOT NULL,
            description TEXT,
            data_type TEXT CHECK (data_type IN ('string', 'number', 'boolean', 'json', 'array', 'select', 'multiselect')),
            validation_rules JSONB,
            options JSONB,
            default_value JSONB,
            is_required BOOLEAN DEFAULT false,
            is_sensitive BOOLEAN DEFAULT false,
            is_public BOOLEAN DEFAULT false,
            sort_order INTEGER DEFAULT 0,
            metadata JSONB DEFAULT '{}',
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),
            updated_by UUID
        );

        -- Create settings history table
        CREATE TABLE public.settings_history (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            setting_id UUID REFERENCES public.settings(id) ON DELETE CASCADE,
            old_value JSONB,
            new_value JSONB,
            changed_by UUID,
            change_reason TEXT,
            changed_at TIMESTAMPTZ DEFAULT NOW()
        );

        -- Create indexes
        CREATE INDEX idx_settings_category ON public.settings(category_id);
        CREATE INDEX idx_settings_key ON public.settings(key);
        CREATE INDEX idx_settings_history_setting ON public.settings_history(setting_id);

        RAISE NOTICE '✓ Migration 037 completed';
    ELSE
        RAISE NOTICE '⊘ Migration 037 already applied (settings tables exist)';
    END IF;
END $$;

-- =====================================================
-- MIGRATION 040: Create Settings System (Enhancement)
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'settings' AND column_name = 'environment') THEN
        RAISE NOTICE 'Applying Migration 040: Settings System Enhancement...';
        
        -- Add environment column if not exists
        ALTER TABLE public.settings 
        ADD COLUMN IF NOT EXISTS environment TEXT DEFAULT 'production';

        -- Add settings groups table if not exists
        CREATE TABLE IF NOT EXISTS public.settings_groups (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name TEXT NOT NULL UNIQUE,
            display_name TEXT NOT NULL,
            description TEXT,
            parent_group_id UUID REFERENCES public.settings_groups(id),
            sort_order INTEGER DEFAULT 0,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );

        RAISE NOTICE '✓ Migration 040 completed';
    ELSE
        RAISE NOTICE '⊘ Migration 040 already applied';
    END IF;
END $$;

-- =====================================================
-- MIGRATION 041: Add 2FA Session Management
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_2fa_settings') THEN
        RAISE NOTICE 'Applying Migration 041: 2FA Session Management...';
        
        -- Create 2FA settings table
        CREATE TABLE public.admin_2fa_settings (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            admin_user_id UUID NOT NULL REFERENCES public.admin_users(id) ON DELETE CASCADE,
            secret_encrypted TEXT NOT NULL,
            backup_codes TEXT[],
            is_enabled BOOLEAN DEFAULT false,
            enabled_at TIMESTAMPTZ,
            last_used_at TIMESTAMPTZ,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),
            UNIQUE(admin_user_id)
        );

        -- Create session management table
        CREATE TABLE public.admin_sessions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            admin_user_id UUID NOT NULL REFERENCES public.admin_users(id) ON DELETE CASCADE,
            session_token TEXT NOT NULL UNIQUE,
            ip_address INET,
            user_agent TEXT,
            device_fingerprint TEXT,
            last_activity TIMESTAMPTZ DEFAULT NOW(),
            expires_at TIMESTAMPTZ NOT NULL,
            is_active BOOLEAN DEFAULT true,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );

        -- Create indexes
        CREATE INDEX idx_admin_2fa_user ON public.admin_2fa_settings(admin_user_id);
        CREATE INDEX idx_admin_sessions_user ON public.admin_sessions(admin_user_id);
        CREATE INDEX idx_admin_sessions_token ON public.admin_sessions(session_token);
        CREATE INDEX idx_admin_sessions_active ON public.admin_sessions(is_active, expires_at);

        RAISE NOTICE '✓ Migration 041 completed';
    ELSE
        RAISE NOTICE '⊘ Migration 041 already applied (2FA tables exist)';
    END IF;
END $$;

-- =====================================================
-- MIGRATION 042: Security Audit System
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'security_audit_logs') THEN
        RAISE NOTICE 'Applying Migration 042: Security Audit System...';
        
        -- Create audit logs table
        CREATE TABLE public.security_audit_logs (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            event_type TEXT NOT NULL,
            event_category TEXT NOT NULL,
            severity TEXT CHECK (severity IN ('info', 'warning', 'error', 'critical')),
            user_id UUID,
            admin_user_id UUID REFERENCES public.admin_users(id),
            ip_address INET,
            user_agent TEXT,
            resource_type TEXT,
            resource_id TEXT,
            action TEXT,
            result TEXT,
            metadata JSONB DEFAULT '{}',
            error_details TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );

        -- Create indexes
        CREATE INDEX idx_audit_logs_event ON public.security_audit_logs(event_type, created_at);
        CREATE INDEX idx_audit_logs_user ON public.security_audit_logs(admin_user_id);
        CREATE INDEX idx_audit_logs_severity ON public.security_audit_logs(severity);
        CREATE INDEX idx_audit_logs_created ON public.security_audit_logs(created_at DESC);

        RAISE NOTICE '✓ Migration 042 completed';
    ELSE
        RAISE NOTICE '⊘ Migration 042 already applied (audit tables exist)';
    END IF;
END $$;

-- =====================================================
-- MIGRATION 043: Financial Management System
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tax_rates') THEN
        RAISE NOTICE 'Applying Migration 043: Financial Management System...';
        
        -- Create currencies table
        CREATE TABLE IF NOT EXISTS public.currencies (
            currency_code CHAR(3) PRIMARY KEY,
            currency_name VARCHAR(50) NOT NULL,
            symbol VARCHAR(5) NOT NULL,
            decimal_places SMALLINT DEFAULT 2 NOT NULL,
            is_active BOOLEAN DEFAULT true NOT NULL,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );

        -- Create payment methods table
        CREATE TABLE IF NOT EXISTS public.payment_methods (
            method_id SERIAL PRIMARY KEY,
            method_code VARCHAR(20) UNIQUE NOT NULL,
            method_name VARCHAR(50) NOT NULL,
            requires_processing BOOLEAN DEFAULT true NOT NULL,
            supports_refunds BOOLEAN DEFAULT true NOT NULL,
            is_active BOOLEAN DEFAULT true NOT NULL,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );

        -- Create transaction statuses table
        CREATE TABLE IF NOT EXISTS public.transaction_statuses (
            status_id SERIAL PRIMARY KEY,
            status_code VARCHAR(20) UNIQUE NOT NULL,
            status_name VARCHAR(50) NOT NULL,
            is_final_status BOOLEAN DEFAULT false NOT NULL,
            is_success_status BOOLEAN DEFAULT false NOT NULL,
            created_at TIMESTAMPTZ DEFAULT NOW()
        );

        -- Create tax rates table
        CREATE TABLE IF NOT EXISTS public.tax_rates (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            jurisdiction VARCHAR(100) NOT NULL,
            tax_type VARCHAR(30) NOT NULL,
            rate DECIMAL(5,4) NOT NULL CHECK (rate >= 0 AND rate <= 1),
            effective_date DATE NOT NULL,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            created_by VARCHAR(100) NOT NULL,
            updated_at TIMESTAMPTZ DEFAULT NOW(),
            updated_by VARCHAR(100)
        );

        -- Create payment transactions table
        CREATE TABLE IF NOT EXISTS public.payment_transactions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            order_id UUID,
            customer_id UUID,
            amount DECIMAL(15,4) NOT NULL CHECK (amount > 0),
            currency_code CHAR(3) NOT NULL,
            payment_method_id INTEGER,
            processor_transaction_id VARCHAR(100),
            status VARCHAR(20) NOT NULL,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            created_by VARCHAR(100) NOT NULL,
            updated_at TIMESTAMPTZ DEFAULT NOW(),
            updated_by VARCHAR(100)
        );

        -- Create refund requests table
        CREATE TABLE IF NOT EXISTS public.refund_requests (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            order_id UUID,
            customer_id UUID,
            amount DECIMAL(15,4) NOT NULL CHECK (amount > 0),
            reason VARCHAR(50) NOT NULL,
            status VARCHAR(20) NOT NULL DEFAULT 'pending',
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );

        -- Create financial reconciliation table
        CREATE TABLE IF NOT EXISTS public.financial_reconciliation (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            reconciliation_date DATE NOT NULL,
            currency_code CHAR(3) NOT NULL,
            total_transactions INTEGER NOT NULL DEFAULT 0,
            gross_sales_amount DECIMAL(15,4) NOT NULL DEFAULT 0,
            total_refunds_amount DECIMAL(15,4) NOT NULL DEFAULT 0,
            total_fees_amount DECIMAL(15,4) NOT NULL DEFAULT 0,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW()
        );

        -- Insert sample data
        INSERT INTO currencies (currency_code, currency_name, symbol) VALUES
        ('USD', 'US Dollar', '$'),
        ('EUR', 'Euro', '€'),
        ('GBP', 'British Pound', '£')
        ON CONFLICT DO NOTHING;

        INSERT INTO payment_methods (method_code, method_name) VALUES
        ('CARD', 'Credit/Debit Card'),
        ('BANK_TRANSFER', 'Bank Transfer'),
        ('DIGITAL_WALLET', 'Digital Wallet')
        ON CONFLICT DO NOTHING;

        INSERT INTO transaction_statuses (status_code, status_name, is_final_status, is_success_status) VALUES
        ('PENDING', 'Pending', false, false),
        ('COMPLETED', 'Completed', true, true),
        ('FAILED', 'Failed', true, false)
        ON CONFLICT DO NOTHING;

        RAISE NOTICE '✓ Migration 043 completed';
    ELSE
        RAISE NOTICE '⊘ Migration 043 already applied (financial tables exist)';
    END IF;
END $$;

-- =====================================================
-- MIGRATION 044: Financial RLS Policies
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE 'Applying Migration 044: Financial RLS Policies...';
    
    -- Enable RLS on financial tables (safe to run multiple times)
    ALTER TABLE public.tax_rates ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.refund_requests ENABLE ROW LEVEL SECURITY;
    ALTER TABLE public.financial_reconciliation ENABLE ROW LEVEL SECURITY;

    -- Create policies (IF NOT EXISTS equivalent)
    DO $policy$
    BEGIN
        -- Tax rates policies
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'tax_rates' AND policyname = 'Admin users can manage tax rates') THEN
            CREATE POLICY "Admin users can manage tax rates" ON public.tax_rates
            FOR ALL USING (
                auth.jwt() ->> 'email' IN (
                    SELECT email FROM public.admin_users 
                    WHERE role IN ('admin', 'super_admin')
                    AND permissions ? ANY(ARRAY['financial', 'all'])
                )
            );
        END IF;

        -- Payment transactions policies
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payment_transactions' AND policyname = 'Admin users can view payment transactions') THEN
            CREATE POLICY "Admin users can view payment transactions" ON public.payment_transactions
            FOR SELECT USING (
                auth.jwt() ->> 'email' IN (
                    SELECT email FROM public.admin_users 
                    WHERE role IN ('admin', 'super_admin')
                    AND permissions ? ANY(ARRAY['financial', 'all'])
                )
            );
        END IF;

        -- Refund requests policies
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'refund_requests' AND policyname = 'Admin users can manage refund requests') THEN
            CREATE POLICY "Admin users can manage refund requests" ON public.refund_requests
            FOR ALL USING (
                auth.jwt() ->> 'email' IN (
                    SELECT email FROM public.admin_users 
                    WHERE role IN ('admin', 'super_admin')
                    AND permissions ? ANY(ARRAY['financial', 'all'])
                )
            );
        END IF;
    END $policy$;

    RAISE NOTICE '✓ Migration 044 completed';
END $$;

-- =====================================================
-- MIGRATION 045: Add Stripe Fields Safely
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
-- FINAL STATUS REPORT
-- =====================================================
DO $$
DECLARE
    v_settings_exists BOOLEAN;
    v_2fa_exists BOOLEAN;
    v_audit_exists BOOLEAN;
    v_financial_exists BOOLEAN;
    v_stripe_fields_exists BOOLEAN;
BEGIN
    -- Check what exists
    SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'settings') INTO v_settings_exists;
    SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_2fa_settings') INTO v_2fa_exists;
    SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'security_audit_logs') INTO v_audit_exists;
    SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tax_rates') INTO v_financial_exists;
    SELECT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'stripe_product_id') INTO v_stripe_fields_exists;

    RAISE NOTICE '';
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'MIGRATION COMPLETE - STATUS REPORT';
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'Settings System (037, 040): %', CASE WHEN v_settings_exists THEN '✓ ACTIVE' ELSE '✗ MISSING' END;
    RAISE NOTICE '2FA Security (041): %', CASE WHEN v_2fa_exists THEN '✓ ACTIVE' ELSE '✗ MISSING' END;
    RAISE NOTICE 'Audit System (042): %', CASE WHEN v_audit_exists THEN '✓ ACTIVE' ELSE '✗ MISSING' END;
    RAISE NOTICE 'Financial System (043, 044): %', CASE WHEN v_financial_exists THEN '✓ ACTIVE' ELSE '✗ MISSING' END;
    RAISE NOTICE 'Stripe Integration (045): %', CASE WHEN v_stripe_fields_exists THEN '✓ ACTIVE' ELSE '✗ MISSING' END;
    RAISE NOTICE '===========================================';
    
    IF v_settings_exists AND v_2fa_exists AND v_audit_exists AND v_financial_exists AND v_stripe_fields_exists THEN
        RAISE NOTICE 'SUCCESS: All systems operational! 🎉';
    ELSE
        RAISE NOTICE 'ACTION NEEDED: Some systems need attention';
    END IF;
    
    RAISE NOTICE '===========================================';
END $$;