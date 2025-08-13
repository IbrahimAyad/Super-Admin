-- ============================================
-- FIX PAYMENT_TRANSACTIONS TABLE
-- Check and fix the transaction_type column issue
-- ============================================

-- 1. First, check what columns exist in payment_transactions
SELECT 
    'CURRENT COLUMNS' as info,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'payment_transactions'
ORDER BY ordinal_position;

-- 2. Add missing columns if they don't exist
DO $$
BEGIN
    -- Add transaction_type if missing
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payment_transactions') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'payment_transactions' AND column_name = 'transaction_type') THEN
            ALTER TABLE public.payment_transactions 
            ADD COLUMN transaction_type VARCHAR(20) DEFAULT 'payment'
            CHECK (transaction_type IN ('payment', 'refund', 'partial_refund', 'chargeback', 'adjustment'));
            RAISE NOTICE '✅ Added transaction_type to payment_transactions';
        ELSE
            RAISE NOTICE '⏭️  transaction_type already exists';
        END IF;
        
        -- Ensure all required columns exist
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'payment_transactions' AND column_name = 'order_id') THEN
            ALTER TABLE public.payment_transactions 
            ADD COLUMN order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE;
            RAISE NOTICE '✅ Added order_id to payment_transactions';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'payment_transactions' AND column_name = 'amount') THEN
            ALTER TABLE public.payment_transactions 
            ADD COLUMN amount INTEGER NOT NULL DEFAULT 0;
            RAISE NOTICE '✅ Added amount to payment_transactions';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'payment_transactions' AND column_name = 'currency') THEN
            ALTER TABLE public.payment_transactions 
            ADD COLUMN currency VARCHAR(3) DEFAULT 'usd';
            RAISE NOTICE '✅ Added currency to payment_transactions';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'payment_transactions' AND column_name = 'status') THEN
            ALTER TABLE public.payment_transactions 
            ADD COLUMN status VARCHAR(20) DEFAULT 'pending';
            RAISE NOTICE '✅ Added status to payment_transactions';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'payment_transactions' AND column_name = 'gateway') THEN
            ALTER TABLE public.payment_transactions 
            ADD COLUMN gateway VARCHAR(50) DEFAULT 'stripe';
            RAISE NOTICE '✅ Added gateway to payment_transactions';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'payment_transactions' AND column_name = 'gateway_transaction_id') THEN
            ALTER TABLE public.payment_transactions 
            ADD COLUMN gateway_transaction_id VARCHAR(255);
            RAISE NOTICE '✅ Added gateway_transaction_id to payment_transactions';
        END IF;
        
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'payment_transactions' AND column_name = 'metadata') THEN
            ALTER TABLE public.payment_transactions 
            ADD COLUMN metadata JSONB DEFAULT '{}';
            RAISE NOTICE '✅ Added metadata to payment_transactions';
        END IF;
    ELSE
        RAISE NOTICE '❌ payment_transactions table does not exist!';
    END IF;
END $$;

-- 3. Show updated table structure
SELECT 
    'UPDATED STRUCTURE' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'payment_transactions'
ORDER BY ordinal_position;

-- 4. Test that we can now insert into payment_transactions
DO $$
DECLARE
    test_order_id UUID;
BEGIN
    -- Get a sample order ID for testing
    SELECT id INTO test_order_id FROM public.orders LIMIT 1;
    
    IF test_order_id IS NOT NULL THEN
        -- Try to insert a test transaction
        INSERT INTO public.payment_transactions (
            order_id,
            transaction_type,
            amount,
            currency,
            status,
            gateway,
            metadata
        ) VALUES (
            test_order_id,
            'payment',
            1000, -- $10.00 in cents
            'usd',
            'completed',
            'stripe',
            '{"test": true}'::jsonb
        );
        
        -- Delete the test transaction
        DELETE FROM public.payment_transactions WHERE metadata->>'test' = 'true';
        
        RAISE NOTICE '✅ payment_transactions table is working correctly';
    ELSE
        RAISE NOTICE '⚠️  No orders found for testing, but table structure is fixed';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '⚠️  Error testing insert: %', SQLERRM;
END $$;

-- 5. Final status
SELECT 
    'PAYMENT TRANSACTIONS FIXED' as status,
    EXISTS(SELECT 1 FROM information_schema.columns 
           WHERE table_name = 'payment_transactions' 
           AND column_name = 'transaction_type') as has_transaction_type,
    COUNT(*) as total_columns
FROM information_schema.columns
WHERE table_name = 'payment_transactions';