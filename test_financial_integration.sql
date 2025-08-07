-- ============================================
-- FINANCIAL MANAGEMENT INTEGRATION TEST
-- Verification script to ensure proper setup
-- ============================================

SELECT 'Starting Financial Management Integration Test...' as test_status;

-- ============================================
-- TEST 1: Table Existence
-- ============================================

SELECT '1. Testing table existence...' as test_phase;

SELECT 
    tablename,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_tables 
            WHERE schemaname = 'public' 
            AND tablename = t.tablename
        ) THEN '✅ EXISTS'
        ELSE '❌ MISSING'
    END as status,
    (SELECT COUNT(*) FROM pg_policies WHERE tablename = t.tablename) as rls_policies
FROM (
    VALUES 
        ('currencies'),
        ('payment_methods'),
        ('transaction_statuses'),
        ('tax_rates'),
        ('payment_transactions'),
        ('payment_fees'),
        ('refund_requests'),
        ('financial_reconciliation'),
        ('payment_transaction_audit'),
        ('refund_request_audit')
) AS t(tablename)
ORDER BY tablename;

-- ============================================
-- TEST 2: Reference Data
-- ============================================

SELECT '2. Testing reference data...' as test_phase;

SELECT 
    'Reference Data Counts' as data_type,
    (SELECT COUNT(*) FROM public.currencies) as currencies_count,
    (SELECT COUNT(*) FROM public.payment_methods) as payment_methods_count,
    (SELECT COUNT(*) FROM public.transaction_statuses) as transaction_statuses_count,
    (SELECT COUNT(*) FROM public.tax_rates) as tax_rates_count;

-- Show sample data
SELECT 'Sample Currencies:' as info;
SELECT currency_code, currency_name, symbol FROM public.currencies LIMIT 3;

SELECT 'Sample Payment Methods:' as info;
SELECT method_code, method_name FROM public.payment_methods LIMIT 3;

SELECT 'Sample Transaction Statuses:' as info;
SELECT status_code, status_name, is_success_status FROM public.transaction_statuses LIMIT 3;

-- ============================================
-- TEST 3: Functions
-- ============================================

SELECT '3. Testing functions...' as test_phase;

-- Test tax rate function
SELECT 
    'Tax Rate Function Test' as test_type,
    public.get_effective_tax_rate('US-CA', 'SALES_TAX', CURRENT_DATE) as ca_tax_rate,
    CASE 
        WHEN public.get_effective_tax_rate('US-CA', 'SALES_TAX', CURRENT_DATE) > 0 
        THEN '✅ WORKING'
        ELSE '⚠️ NO TAX RATE FOUND'
    END as status;

-- Test admin functions
SELECT 
    'Admin Function Test' as test_type,
    public.is_financial_admin() as has_financial_access,
    auth.uid() as current_user_id,
    CASE 
        WHEN auth.uid() IS NOT NULL 
        THEN '✅ AUTH WORKING'
        ELSE '⚠️ NO USER'
    END as auth_status;

-- ============================================
-- TEST 4: RLS Verification
-- ============================================

SELECT '4. Testing RLS setup...' as test_phase;

SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    (SELECT COUNT(*) FROM pg_policies WHERE tablename = t.tablename) as policy_count
FROM pg_tables t
WHERE schemaname = 'public'
AND tablename LIKE '%payment%' OR tablename LIKE '%transaction%' OR tablename LIKE '%refund%' OR tablename LIKE '%reconciliation%'
ORDER BY tablename;

-- ============================================
-- TEST 5: Views
-- ============================================

SELECT '5. Testing views...' as test_phase;

-- Check if views exist and are accessible
SELECT 
    viewname,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_views 
            WHERE schemaname = 'public' 
            AND viewname = v.viewname
        ) THEN '✅ EXISTS'
        ELSE '❌ MISSING'
    END as status
FROM (
    VALUES 
        ('daily_transaction_summary'),
        ('pending_reconciliation_summary'),
        ('refund_request_summary')
) AS v(viewname);

-- ============================================
-- TEST 6: Integration Points
-- ============================================

SELECT '6. Testing integration with existing tables...' as test_phase;

-- Check if core tables exist (should be there from your existing system)
SELECT 
    table_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = t.table_name
        ) THEN '✅ EXISTS'
        ELSE '❌ MISSING - CHECK EXISTING SYSTEM'
    END as status
FROM (
    VALUES 
        ('customers'),
        ('orders'),
        ('products'),
        ('admin_users')
) AS t(table_name);

-- ============================================
-- TEST 7: Sample Transaction Test (Optional)
-- ============================================

SELECT '7. Testing sample transaction creation...' as test_phase;

-- Only run if we have the required reference data and an authenticated user
DO $$
DECLARE
    v_currency_exists boolean;
    v_payment_method_id integer;
    v_status_id integer;
    v_user_id uuid;
    v_transaction_id uuid;
BEGIN
    -- Check if we have required reference data
    SELECT EXISTS(SELECT 1 FROM public.currencies WHERE currency_code = 'USD') INTO v_currency_exists;
    
    IF v_currency_exists THEN
        -- Get required IDs
        SELECT method_id INTO v_payment_method_id 
        FROM public.payment_methods 
        WHERE method_code = 'STRIPE_CARD' LIMIT 1;
        
        SELECT status_id INTO v_status_id 
        FROM public.transaction_statuses 
        WHERE status_code = 'COMPLETED' LIMIT 1;
        
        SELECT auth.uid() INTO v_user_id;
        
        -- Only create test transaction if we have a user
        IF v_user_id IS NOT NULL AND v_payment_method_id IS NOT NULL AND v_status_id IS NOT NULL THEN
            -- Create a test transaction
            INSERT INTO public.payment_transactions (
                transaction_type,
                amount,
                currency_code,
                payment_method_id,
                processor_name,
                status_id,
                gross_amount,
                tax_amount,
                fee_amount,
                created_by,
                notes
            ) VALUES (
                'PAYMENT',
                100.00,
                'USD',
                v_payment_method_id,
                'TEST',
                v_status_id,
                100.00,
                8.00,
                3.00,
                v_user_id,
                'Integration test transaction'
            ) RETURNING transaction_id INTO v_transaction_id;
            
            RAISE NOTICE 'Test transaction created: %', v_transaction_id;
            
            -- Clean up test transaction
            DELETE FROM public.payment_transactions WHERE transaction_id = v_transaction_id;
            RAISE NOTICE 'Test transaction cleaned up';
            
        ELSE
            RAISE NOTICE 'Skipping transaction test - missing auth or reference data';
        END IF;
    ELSE
        RAISE NOTICE 'Skipping transaction test - USD currency not found';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Transaction test failed (expected if not admin): %', SQLERRM;
END $$;

-- ============================================
-- TEST RESULTS SUMMARY
-- ============================================

SELECT '✅ FINANCIAL MANAGEMENT INTEGRATION TEST COMPLETED' as final_status;

SELECT 
    'Summary' as section,
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND tablename IN ('currencies', 'payment_transactions', 'refund_requests')) = 3
        THEN '✅ CORE TABLES CREATED'
        ELSE '❌ SOME TABLES MISSING'
    END as table_status,
    CASE 
        WHEN (SELECT COUNT(*) FROM public.currencies) >= 3
        THEN '✅ REFERENCE DATA LOADED'
        ELSE '⚠️ LIMITED REFERENCE DATA'
    END as data_status,
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_policies WHERE tablename LIKE '%payment%') > 0
        THEN '✅ RLS POLICIES APPLIED'
        ELSE '❌ RLS POLICIES MISSING'
    END as security_status;

-- Final recommendations
SELECT 
    'Next Steps:' as section,
    '1. Run apply_financial_schema.sql if tables are missing' as step_1,
    '2. Run apply_financial_rls.sql if RLS policies are missing' as step_2,
    '3. Add financial permissions to admin users' as step_3,
    '4. Test with actual admin user account' as step_4;

SELECT 'Integration test completed! Check results above.' as conclusion;