-- ============================================
-- ADD MISSING COLUMNS ONLY
-- Based on your check, these columns are missing
-- ============================================

-- 1. Add 2FA columns to admin_users (if table exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_users') THEN
        -- Add two_factor_secret
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'admin_users' AND column_name = 'two_factor_secret') THEN
            ALTER TABLE public.admin_users ADD COLUMN two_factor_secret TEXT;
            RAISE NOTICE '✅ Added two_factor_secret to admin_users';
        END IF;
        
        -- Add two_factor_enabled
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'admin_users' AND column_name = 'two_factor_enabled') THEN
            ALTER TABLE public.admin_users ADD COLUMN two_factor_enabled BOOLEAN DEFAULT false;
            RAISE NOTICE '✅ Added two_factor_enabled to admin_users';
        END IF;
        
        -- Add two_factor_backup_codes
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'admin_users' AND column_name = 'two_factor_backup_codes') THEN
            ALTER TABLE public.admin_users ADD COLUMN two_factor_backup_codes TEXT[];
            RAISE NOTICE '✅ Added two_factor_backup_codes to admin_users';
        END IF;
    ELSE
        RAISE NOTICE '⚠️  admin_users table does not exist - skipping 2FA columns';
    END IF;
END $$;

-- 2. Add refund columns to orders table
DO $$
BEGIN
    -- Add refund_status
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'refund_status') THEN
        ALTER TABLE public.orders 
        ADD COLUMN refund_status VARCHAR(20) DEFAULT 'none' 
        CHECK (refund_status IN ('none', 'partial', 'full', 'pending'));
        RAISE NOTICE '✅ Added refund_status to orders';
    END IF;
    
    -- Add total_refunded
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'total_refunded') THEN
        ALTER TABLE public.orders 
        ADD COLUMN total_refunded INTEGER DEFAULT 0;
        RAISE NOTICE '✅ Added total_refunded to orders';
    END IF;
    
    -- Add refund_reason
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'refund_reason') THEN
        ALTER TABLE public.orders 
        ADD COLUMN refund_reason TEXT;
        RAISE NOTICE '✅ Added refund_reason to orders';
    END IF;
    
    -- Add refunded_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'refunded_at') THEN
        ALTER TABLE public.orders 
        ADD COLUMN refunded_at TIMESTAMPTZ;
        RAISE NOTICE '✅ Added refunded_at to orders';
    END IF;
END $$;

-- 3. Add financial status columns to orders table
DO $$
BEGIN
    -- Add financial_status
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'financial_status') THEN
        ALTER TABLE public.orders 
        ADD COLUMN financial_status VARCHAR(20) DEFAULT 'pending'
        CHECK (financial_status IN ('pending', 'paid', 'partially_paid', 'refunded', 'voided', 'failed'));
        RAISE NOTICE '✅ Added financial_status to orders';
    END IF;
    
    -- Add tax_amount
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'tax_amount') THEN
        ALTER TABLE public.orders 
        ADD COLUMN tax_amount INTEGER DEFAULT 0;
        RAISE NOTICE '✅ Added tax_amount to orders';
    END IF;
    
    -- Add discount_amount
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'discount_amount') THEN
        ALTER TABLE public.orders 
        ADD COLUMN discount_amount INTEGER DEFAULT 0;
        RAISE NOTICE '✅ Added discount_amount to orders';
    END IF;
    
    -- Add net_amount (total after tax and discounts)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'orders' AND column_name = 'net_amount') THEN
        ALTER TABLE public.orders 
        ADD COLUMN net_amount INTEGER;
        -- Set net_amount to total_amount for existing orders
        UPDATE public.orders SET net_amount = total_amount WHERE net_amount IS NULL;
        RAISE NOTICE '✅ Added net_amount to orders';
    END IF;
END $$;

-- 4. Final check - show what columns we now have
SELECT 
    'COLUMNS ADDED SUCCESSFULLY' as status,
    json_build_object(
        '2FA_columns', json_build_object(
            'two_factor_secret', EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'admin_users' AND column_name = 'two_factor_secret'),
            'two_factor_enabled', EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'admin_users' AND column_name = 'two_factor_enabled'),
            'two_factor_backup_codes', EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'admin_users' AND column_name = 'two_factor_backup_codes')
        ),
        'refund_columns', json_build_object(
            'refund_status', EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'refund_status'),
            'total_refunded', EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'total_refunded'),
            'refund_reason', EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'refund_reason'),
            'refunded_at', EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'refunded_at')
        ),
        'financial_columns', json_build_object(
            'financial_status', EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'financial_status'),
            'tax_amount', EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'tax_amount'),
            'discount_amount', EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'discount_amount'),
            'net_amount', EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'net_amount')
        )
    ) as columns_status;