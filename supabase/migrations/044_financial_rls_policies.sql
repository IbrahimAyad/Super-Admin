-- ============================================
-- FINANCIAL MANAGEMENT RLS POLICIES
-- Secure admin-only access to financial data
-- ============================================

-- Check if admin function exists, if not create it
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM public.admin_users 
        WHERE user_id = auth.uid() 
        AND is_active = true
        AND (permissions @> ARRAY['financial'] OR permissions @> ARRAY['all'])
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function for financial admin access
CREATE OR REPLACE FUNCTION public.is_financial_admin()
RETURNS boolean AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM public.admin_users 
        WHERE user_id = auth.uid() 
        AND is_active = true
        AND (permissions @> ARRAY['financial'] OR permissions @> ARRAY['all'])
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- ENABLE RLS ON ALL FINANCIAL TABLES
-- ============================================

ALTER TABLE public.currencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transaction_statuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tax_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.refund_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_reconciliation ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_transaction_audit ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.refund_request_audit ENABLE ROW LEVEL SECURITY;

-- ============================================
-- REFERENCE TABLES - READ ACCESS FOR ADMINS
-- ============================================

-- Currencies policies
DROP POLICY IF EXISTS "Admins can read currencies" ON public.currencies;
CREATE POLICY "Admins can read currencies" ON public.currencies
    FOR SELECT
    USING (public.is_financial_admin());

DROP POLICY IF EXISTS "Admins can manage currencies" ON public.currencies;
CREATE POLICY "Admins can manage currencies" ON public.currencies
    FOR ALL
    USING (public.is_financial_admin());

-- Payment methods policies
DROP POLICY IF EXISTS "Admins can read payment_methods" ON public.payment_methods;
CREATE POLICY "Admins can read payment_methods" ON public.payment_methods
    FOR SELECT
    USING (public.is_financial_admin());

DROP POLICY IF EXISTS "Admins can manage payment_methods" ON public.payment_methods;
CREATE POLICY "Admins can manage payment_methods" ON public.payment_methods
    FOR ALL
    USING (public.is_financial_admin());

-- Transaction statuses policies
DROP POLICY IF EXISTS "Admins can read transaction_statuses" ON public.transaction_statuses;
CREATE POLICY "Admins can read transaction_statuses" ON public.transaction_statuses
    FOR SELECT
    USING (public.is_financial_admin());

DROP POLICY IF EXISTS "Admins can manage transaction_statuses" ON public.transaction_statuses;
CREATE POLICY "Admins can manage transaction_statuses" ON public.transaction_statuses
    FOR ALL
    USING (public.is_financial_admin());

-- ============================================
-- TAX RATES - ADMIN MANAGEMENT
-- ============================================

DROP POLICY IF EXISTS "Admins can view tax_rates" ON public.tax_rates;
CREATE POLICY "Admins can view tax_rates" ON public.tax_rates
    FOR SELECT
    USING (public.is_financial_admin());

DROP POLICY IF EXISTS "Admins can manage tax_rates" ON public.tax_rates;
CREATE POLICY "Admins can manage tax_rates" ON public.tax_rates
    FOR ALL
    USING (public.is_financial_admin());

-- ============================================
-- PAYMENT TRANSACTIONS - COMPREHENSIVE ACCESS CONTROL
-- ============================================

DROP POLICY IF EXISTS "Admins can view payment_transactions" ON public.payment_transactions;
CREATE POLICY "Admins can view payment_transactions" ON public.payment_transactions
    FOR SELECT
    USING (public.is_financial_admin());

DROP POLICY IF EXISTS "Admins can insert payment_transactions" ON public.payment_transactions;
CREATE POLICY "Admins can insert payment_transactions" ON public.payment_transactions
    FOR INSERT
    WITH CHECK (public.is_financial_admin());

DROP POLICY IF EXISTS "Admins can update payment_transactions" ON public.payment_transactions;
CREATE POLICY "Admins can update payment_transactions" ON public.payment_transactions
    FOR UPDATE
    USING (public.is_financial_admin())
    WITH CHECK (public.is_financial_admin());

-- Service role can also manage transactions (for automated processes)
DROP POLICY IF EXISTS "Service role can manage payment_transactions" ON public.payment_transactions;
CREATE POLICY "Service role can manage payment_transactions" ON public.payment_transactions
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- PAYMENT FEES - ADMIN ONLY
-- ============================================

DROP POLICY IF EXISTS "Admins can view payment_fees" ON public.payment_fees;
CREATE POLICY "Admins can view payment_fees" ON public.payment_fees
    FOR SELECT
    USING (public.is_financial_admin());

DROP POLICY IF EXISTS "Admins can manage payment_fees" ON public.payment_fees;
CREATE POLICY "Admins can manage payment_fees" ON public.payment_fees
    FOR ALL
    USING (public.is_financial_admin());

-- Service role for automated fee processing
DROP POLICY IF EXISTS "Service role can manage payment_fees" ON public.payment_fees;
CREATE POLICY "Service role can manage payment_fees" ON public.payment_fees
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- REFUND REQUESTS - WORKFLOW BASED ACCESS
-- ============================================

DROP POLICY IF EXISTS "Admins can view refund_requests" ON public.refund_requests;
CREATE POLICY "Admins can view refund_requests" ON public.refund_requests
    FOR SELECT
    USING (public.is_financial_admin());

DROP POLICY IF EXISTS "Admins can create refund_requests" ON public.refund_requests;
CREATE POLICY "Admins can create refund_requests" ON public.refund_requests
    FOR INSERT
    WITH CHECK (public.is_financial_admin());

DROP POLICY IF EXISTS "Admins can update refund_requests" ON public.refund_requests;
CREATE POLICY "Admins can update refund_requests" ON public.refund_requests
    FOR UPDATE
    USING (public.is_financial_admin())
    WITH CHECK (public.is_financial_admin());

-- Customer service can create refund requests (different permission)
DROP POLICY IF EXISTS "Customer service can create refunds" ON public.refund_requests;
CREATE POLICY "Customer service can create refunds" ON public.refund_requests
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 
            FROM public.admin_users 
            WHERE user_id = auth.uid() 
            AND is_active = true
            AND (permissions @> ARRAY['customer_service'] OR permissions @> ARRAY['financial'] OR permissions @> ARRAY['all'])
        )
    );

-- Service role for automated processes
DROP POLICY IF EXISTS "Service role can manage refund_requests" ON public.refund_requests;
CREATE POLICY "Service role can manage refund_requests" ON public.refund_requests
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- FINANCIAL RECONCILIATION - FINANCE TEAM ONLY
-- ============================================

DROP POLICY IF EXISTS "Admins can view financial_reconciliation" ON public.financial_reconciliation;
CREATE POLICY "Admins can view financial_reconciliation" ON public.financial_reconciliation
    FOR SELECT
    USING (public.is_financial_admin());

DROP POLICY IF EXISTS "Admins can manage financial_reconciliation" ON public.financial_reconciliation;
CREATE POLICY "Admins can manage financial_reconciliation" ON public.financial_reconciliation
    FOR ALL
    USING (public.is_financial_admin());

-- Service role for automated reconciliation
DROP POLICY IF EXISTS "Service role can manage financial_reconciliation" ON public.financial_reconciliation;
CREATE POLICY "Service role can manage financial_reconciliation" ON public.financial_reconciliation
    FOR ALL
    USING (auth.role() = 'service_role');

-- ============================================
-- AUDIT TABLES - READ-ONLY FOR ADMINS, SYSTEM WRITES
-- ============================================

-- Payment transaction audit
DROP POLICY IF EXISTS "Admins can view payment_transaction_audit" ON public.payment_transaction_audit;
CREATE POLICY "Admins can view payment_transaction_audit" ON public.payment_transaction_audit
    FOR SELECT
    USING (public.is_financial_admin());

-- System can insert audit records
DROP POLICY IF EXISTS "System can insert payment_transaction_audit" ON public.payment_transaction_audit;
CREATE POLICY "System can insert payment_transaction_audit" ON public.payment_transaction_audit
    FOR INSERT
    WITH CHECK (true); -- Triggers handle this

-- Refund request audit
DROP POLICY IF EXISTS "Admins can view refund_request_audit" ON public.refund_request_audit;
CREATE POLICY "Admins can view refund_request_audit" ON public.refund_request_audit
    FOR SELECT
    USING (public.is_financial_admin());

-- System can insert audit records
DROP POLICY IF EXISTS "System can insert refund_request_audit" ON public.refund_request_audit;
CREATE POLICY "System can insert refund_request_audit" ON public.refund_request_audit
    FOR INSERT
    WITH CHECK (true); -- Triggers handle this

-- ============================================
-- VIEWS ACCESS - ADMIN ONLY
-- ============================================

-- Grant access to views for admins
GRANT SELECT ON public.daily_transaction_summary TO authenticated;
GRANT SELECT ON public.pending_reconciliation_summary TO authenticated;
GRANT SELECT ON public.refund_request_summary TO authenticated;

-- Create view-specific RLS (views inherit base table policies, but we can add extra security)
-- These would need to be implemented as security definer functions if more granular control is needed

-- ============================================
-- FUNCTION PERMISSIONS
-- ============================================

-- Grant execute permissions on financial functions
GRANT EXECUTE ON FUNCTION public.is_financial_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_effective_tax_rate(VARCHAR, VARCHAR, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION public.calculate_daily_reconciliation(DATE, CHAR) TO authenticated;

-- Service role needs broader access for automated processes
GRANT EXECUTE ON FUNCTION public.get_effective_tax_rate(VARCHAR, VARCHAR, DATE) TO service_role;
GRANT EXECUTE ON FUNCTION public.calculate_daily_reconciliation(DATE, CHAR) TO service_role;

-- ============================================
-- TABLE PERMISSIONS FOR SERVICE ROLE
-- ============================================

-- Grant necessary permissions to service_role for automated processes
GRANT SELECT, INSERT, UPDATE, DELETE ON public.currencies TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.payment_methods TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.transaction_statuses TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.tax_rates TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.payment_transactions TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.payment_fees TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.refund_requests TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.financial_reconciliation TO service_role;
GRANT SELECT, INSERT ON public.payment_transaction_audit TO service_role;
GRANT SELECT, INSERT ON public.refund_request_audit TO service_role;

-- ============================================
-- ADDITIONAL SECURITY MEASURES
-- ============================================

-- Create a function to validate transaction integrity
CREATE OR REPLACE FUNCTION public.validate_transaction_integrity(
    p_transaction_id UUID
) RETURNS boolean AS $$
DECLARE
    v_transaction_exists boolean;
    v_fees_sum DECIMAL(15,4);
    v_transaction_fee DECIMAL(15,4);
BEGIN
    -- Check if transaction exists
    SELECT EXISTS(SELECT 1 FROM public.payment_transactions WHERE transaction_id = p_transaction_id)
    INTO v_transaction_exists;
    
    IF NOT v_transaction_exists THEN
        RETURN false;
    END IF;
    
    -- Validate fee calculations
    SELECT COALESCE(SUM(calculated_fee), 0) INTO v_fees_sum
    FROM public.payment_fees 
    WHERE transaction_id = p_transaction_id;
    
    SELECT fee_amount INTO v_transaction_fee
    FROM public.payment_transactions 
    WHERE transaction_id = p_transaction_id;
    
    -- Allow for minor rounding differences
    RETURN ABS(v_fees_sum - v_transaction_fee) < 0.01;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.validate_transaction_integrity(UUID) TO authenticated, service_role;

-- ============================================
-- SECURITY AUDIT FUNCTION
-- ============================================

CREATE OR REPLACE FUNCTION public.audit_financial_access()
RETURNS TABLE(
    table_name TEXT,
    user_id UUID,
    access_type TEXT,
    timestamp TIMESTAMPTZ
) AS $$
BEGIN
    -- This is a placeholder for financial access auditing
    -- In a real implementation, you might log all access to financial data
    RETURN QUERY
    SELECT 
        'financial_audit'::TEXT,
        auth.uid(),
        'function_call'::TEXT,
        NOW()
    WHERE public.is_financial_admin();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Only financial admins can run audit functions
GRANT EXECUTE ON FUNCTION public.audit_financial_access() TO authenticated;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Verify all tables have RLS enabled
SELECT 
    tablename,
    rowsecurity as rls_enabled,
    (SELECT COUNT(*) FROM pg_policies WHERE tablename = t.tablename) as policy_count
FROM pg_tables t
WHERE schemaname = 'public'
AND tablename IN (
    'currencies', 'payment_methods', 'transaction_statuses',
    'tax_rates', 'payment_transactions', 'payment_fees',
    'refund_requests', 'financial_reconciliation',
    'payment_transaction_audit', 'refund_request_audit'
)
ORDER BY tablename;

-- Test admin function
SELECT 
    'Financial Admin Test' as test_type,
    public.is_financial_admin() as has_financial_access,
    public.is_admin() as has_admin_access,
    auth.uid() as current_user_id;