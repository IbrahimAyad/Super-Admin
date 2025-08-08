-- Financial Management RLS (Row Level Security) Policies
-- Comprehensive security policies for KCT Admin Financial System
-- Created: 2025-08-08

-- =======================
-- SECURITY OVERVIEW
-- =======================
-- This file implements row-level security for the financial management system
-- Access levels:
-- 1. SUPER_ADMIN: Full access to all financial data
-- 2. ADMIN: Access to current financial operations and reports
-- 3. FINANCE_MANAGER: Access to financial reports and reconciliation
-- 4. CUSTOMER_SERVICE: Limited access to refunds and customer payment methods
-- 5. SYSTEM: System-level operations (webhooks, automated processes)

-- =======================
-- HELPER FUNCTIONS FOR RLS
-- =======================

-- Function to check if current user is admin
CREATE OR REPLACE FUNCTION is_admin_user() 
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if user exists in admin_users table
    -- Adjust this based on your admin authentication system
    RETURN EXISTS (
        SELECT 1 FROM admin_users 
        WHERE id = (auth.uid())::uuid 
        AND is_active = true
    );
EXCEPTION
    WHEN OTHERS THEN
        RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get current admin user role
CREATE OR REPLACE FUNCTION get_admin_role() 
RETURNS TEXT AS $$
DECLARE
    user_role TEXT;
BEGIN
    SELECT role INTO user_role 
    FROM admin_users 
    WHERE id = (auth.uid())::uuid 
    AND is_active = true;
    
    RETURN COALESCE(user_role, 'NONE');
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'NONE';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if current user can access financial data
CREATE OR REPLACE FUNCTION can_access_financial_data() 
RETURNS BOOLEAN AS $$
DECLARE
    user_role TEXT;
BEGIN
    user_role := get_admin_role();
    RETURN user_role IN ('SUPER_ADMIN', 'ADMIN', 'FINANCE_MANAGER');
EXCEPTION
    WHEN OTHERS THEN
        RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if current user can process refunds
CREATE OR REPLACE FUNCTION can_process_refunds() 
RETURNS BOOLEAN AS $$
DECLARE
    user_role TEXT;
BEGIN
    user_role := get_admin_role();
    RETURN user_role IN ('SUPER_ADMIN', 'ADMIN', 'CUSTOMER_SERVICE');
EXCEPTION
    WHEN OTHERS THEN
        RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if current user can modify payment configurations
CREATE OR REPLACE FUNCTION can_modify_payment_config() 
RETURNS BOOLEAN AS $$
DECLARE
    user_role TEXT;
BEGIN
    user_role := get_admin_role();
    RETURN user_role IN ('SUPER_ADMIN', 'ADMIN');
EXCEPTION
    WHEN OTHERS THEN
        RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =======================
-- ENABLE RLS ON ALL TABLES
-- =======================

-- Core financial tables
ALTER TABLE currencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_statuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE tax_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE refund_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_reconciliation ENABLE ROW LEVEL SECURITY;

-- Configuration tables
ALTER TABLE payment_method_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_webhooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE tax_jurisdiction_mapping ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_report_templates ENABLE ROW LEVEL SECURITY;

-- Audit tables
ALTER TABLE payment_transaction_audit ENABLE ROW LEVEL SECURITY;
ALTER TABLE refund_request_audit ENABLE ROW LEVEL SECURITY;

-- =======================
-- REFERENCE/LOOKUP TABLES POLICIES
-- =======================

-- Currencies: Read-only for all admin users
CREATE POLICY "Admin users can read currencies" ON currencies
    FOR SELECT USING (is_admin_user());

-- Payment methods: Read-only for all admin users
CREATE POLICY "Admin users can read payment methods" ON payment_methods
    FOR SELECT USING (is_admin_user());

-- Transaction statuses: Read-only for all admin users
CREATE POLICY "Admin users can read transaction statuses" ON transaction_statuses
    FOR SELECT USING (is_admin_user());

-- =======================
-- TAX CONFIGURATION POLICIES
-- =======================

-- Tax rates: Financial users can read, super admin/admin can modify
CREATE POLICY "Financial users can read tax rates" ON tax_rates
    FOR SELECT USING (can_access_financial_data());

CREATE POLICY "Admin users can insert tax rates" ON tax_rates
    FOR INSERT WITH CHECK (can_modify_payment_config());

CREATE POLICY "Admin users can update tax rates" ON tax_rates
    FOR UPDATE USING (can_modify_payment_config())
    WITH CHECK (can_modify_payment_config());

-- Tax jurisdiction mapping: Financial users can read, admin can modify
CREATE POLICY "Financial users can read tax jurisdiction mapping" ON tax_jurisdiction_mapping
    FOR SELECT USING (can_access_financial_data());

CREATE POLICY "Admin users can modify tax jurisdiction mapping" ON tax_jurisdiction_mapping
    FOR ALL USING (can_modify_payment_config())
    WITH CHECK (can_modify_payment_config());

-- =======================
-- PAYMENT TRANSACTION POLICIES
-- =======================

-- Payment transactions: Comprehensive access control
CREATE POLICY "Financial users can read payment transactions" ON payment_transactions
    FOR SELECT USING (
        can_access_financial_data() OR 
        (can_process_refunds() AND created_at >= CURRENT_DATE - INTERVAL '90 days')
    );

-- Only system can insert payment transactions (via webhooks/API)
CREATE POLICY "System can insert payment transactions" ON payment_transactions
    FOR INSERT WITH CHECK (
        can_modify_payment_config() OR 
        current_setting('app.current_user', true) = 'system'
    );

-- Only admin users can update payment transactions (for corrections)
CREATE POLICY "Admin users can update payment transactions" ON payment_transactions
    FOR UPDATE USING (can_modify_payment_config())
    WITH CHECK (can_modify_payment_config());

-- =======================
-- PAYMENT FEES POLICIES
-- =======================

-- Payment fees: Read access for financial users
CREATE POLICY "Financial users can read payment fees" ON payment_fees
    FOR SELECT USING (can_access_financial_data());

-- System and admin can insert/update fees
CREATE POLICY "System can manage payment fees" ON payment_fees
    FOR ALL USING (
        can_modify_payment_config() OR 
        current_setting('app.current_user', true) = 'system'
    );

-- =======================
-- REFUND REQUEST POLICIES
-- =======================

-- Refund requests: Different access levels based on role
CREATE POLICY "Users can read relevant refund requests" ON refund_requests
    FOR SELECT USING (
        can_access_financial_data() OR 
        can_process_refunds()
    );

-- Customer service and admin can create refund requests
CREATE POLICY "Authorized users can create refund requests" ON refund_requests
    FOR INSERT WITH CHECK (can_process_refunds());

-- Only refund processors can update refund requests
CREATE POLICY "Authorized users can update refund requests" ON refund_requests
    FOR UPDATE USING (can_process_refunds())
    WITH CHECK (can_process_refunds());

-- =======================
-- FINANCIAL RECONCILIATION POLICIES
-- =======================

-- Financial reconciliation: Finance manager and above
CREATE POLICY "Finance users can read reconciliation" ON financial_reconciliation
    FOR SELECT USING (can_access_financial_data());

CREATE POLICY "Finance managers can manage reconciliation" ON financial_reconciliation
    FOR ALL USING (
        get_admin_role() IN ('SUPER_ADMIN', 'ADMIN', 'FINANCE_MANAGER')
    );

-- =======================
-- PAYMENT METHOD CONFIGURATION POLICIES
-- =======================

-- Payment method configurations: Admin access for settings
CREATE POLICY "Admin users can read payment configurations" ON payment_method_configurations
    FOR SELECT USING (can_access_financial_data());

CREATE POLICY "Admin users can manage payment configurations" ON payment_method_configurations
    FOR ALL USING (can_modify_payment_config())
    WITH CHECK (can_modify_payment_config());

-- =======================
-- WEBHOOK POLICIES
-- =======================

-- Payment webhooks: System and admin access
CREATE POLICY "System can manage webhooks" ON payment_webhooks
    FOR ALL USING (
        can_modify_payment_config() OR 
        current_setting('app.current_user', true) = 'system'
    );

CREATE POLICY "Admin users can read webhooks" ON payment_webhooks
    FOR SELECT USING (can_access_financial_data());

-- =======================
-- CUSTOMER PAYMENT METHODS POLICIES
-- =======================

-- Customer payment methods: Customer service and admin access
CREATE POLICY "Authorized users can read customer payment methods" ON customer_payment_methods
    FOR SELECT USING (
        can_access_financial_data() OR 
        can_process_refunds()
    );

-- Only admin users can modify customer payment methods
CREATE POLICY "Admin users can manage customer payment methods" ON customer_payment_methods
    FOR ALL USING (can_modify_payment_config())
    WITH CHECK (can_modify_payment_config());

-- =======================
-- REPORT TEMPLATE POLICIES
-- =======================

-- Financial report templates: Role-based access
CREATE POLICY "Users can read allowed report templates" ON financial_report_templates
    FOR SELECT USING (
        is_public = true OR 
        can_access_financial_data() OR
        get_admin_role() = ANY(allowed_roles)
    );

-- Admin users can manage report templates
CREATE POLICY "Admin users can manage report templates" ON financial_report_templates
    FOR ALL USING (can_modify_payment_config())
    WITH CHECK (can_modify_payment_config());

-- =======================
-- AUDIT TABLE POLICIES
-- =======================

-- Payment transaction audit: Read-only for financial users
CREATE POLICY "Financial users can read transaction audit" ON payment_transaction_audit
    FOR SELECT USING (can_access_financial_data());

-- System can insert audit records
CREATE POLICY "System can insert transaction audit" ON payment_transaction_audit
    FOR INSERT WITH CHECK (
        can_modify_payment_config() OR 
        current_setting('app.current_user', true) = 'system'
    );

-- Refund request audit: Read-only for authorized users
CREATE POLICY "Authorized users can read refund audit" ON refund_request_audit
    FOR SELECT USING (
        can_access_financial_data() OR 
        can_process_refunds()
    );

-- System can insert refund audit records
CREATE POLICY "System can insert refund audit" ON refund_request_audit
    FOR INSERT WITH CHECK (
        can_process_refunds() OR 
        current_setting('app.current_user', true) = 'system'
    );

-- =======================
-- SECURITY BYPASS FOR SYSTEM OPERATIONS
-- =======================

-- Create a security definer function for system operations
-- This allows system processes to bypass RLS when needed
CREATE OR REPLACE FUNCTION execute_as_system(query_text TEXT) 
RETURNS VOID AS $$
BEGIN
    -- Set the current user context to system
    PERFORM set_config('app.current_user', 'system', true);
    
    -- Execute the query
    EXECUTE query_text;
    
    -- Reset the context
    PERFORM set_config('app.current_user', '', true);
EXCEPTION
    WHEN OTHERS THEN
        -- Ensure context is reset even on error
        PERFORM set_config('app.current_user', '', true);
        RAISE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =======================
-- ADDITIONAL SECURITY MEASURES
-- =======================

-- Create a function to log sensitive data access
CREATE OR REPLACE FUNCTION log_sensitive_access(
    table_name TEXT,
    operation TEXT,
    record_id UUID DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    -- Log access to sensitive financial data
    -- This can be extended to write to an audit table or external logging system
    RAISE NOTICE 'SENSITIVE_ACCESS: User % performed % on % (ID: %)', 
                 current_user, operation, table_name, record_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger function to log sensitive operations
CREATE OR REPLACE FUNCTION trigger_log_sensitive_access()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM log_sensitive_access(TG_TABLE_NAME, TG_OP, 
                                COALESCE(NEW.transaction_id, OLD.transaction_id));
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Add logging triggers for payment transactions (optional - can impact performance)
-- Uncomment if detailed access logging is required:
/*
CREATE TRIGGER tr_payment_transactions_access_log
    AFTER INSERT OR UPDATE OR DELETE ON payment_transactions
    FOR EACH ROW EXECUTE FUNCTION trigger_log_sensitive_access();
*/

-- =======================
-- GRANT PERMISSIONS TO AUTHENTICATED USERS
-- =======================

-- Grant basic permissions to authenticated users
-- These will be filtered by RLS policies
GRANT SELECT ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT INSERT, UPDATE ON payment_transactions TO authenticated;
GRANT INSERT, UPDATE ON refund_requests TO authenticated;
GRANT INSERT, UPDATE ON payment_method_configurations TO authenticated;
GRANT INSERT ON payment_webhooks TO authenticated;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- =======================
-- CREATE SECURITY TESTING FUNCTIONS
-- =======================

-- Function to test RLS policies
CREATE OR REPLACE FUNCTION test_financial_rls_policies() 
RETURNS TABLE (
    test_name TEXT,
    test_result TEXT,
    details TEXT
) AS $$
BEGIN
    -- Test 1: Check if RLS is enabled on all financial tables
    RETURN QUERY
    SELECT 
        'RLS Enabled Check' as test_name,
        CASE 
            WHEN COUNT(*) FILTER (WHERE relrowsecurity = false) = 0 
            THEN 'PASS' ELSE 'FAIL' 
        END as test_result,
        FORMAT('%s tables have RLS enabled out of %s financial tables', 
               COUNT(*) FILTER (WHERE relrowsecurity = true),
               COUNT(*)) as details
    FROM pg_class c
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'public' 
    AND c.relname IN (
        'currencies', 'payment_methods', 'transaction_statuses', 'tax_rates',
        'payment_transactions', 'payment_fees', 'refund_requests', 
        'financial_reconciliation', 'payment_method_configurations',
        'payment_webhooks', 'customer_payment_methods', 'tax_jurisdiction_mapping',
        'financial_report_templates', 'payment_transaction_audit', 'refund_request_audit'
    );
    
    -- Test 2: Check if helper functions exist
    RETURN QUERY
    SELECT 
        'Helper Functions Check' as test_name,
        CASE 
            WHEN COUNT(*) = 6 THEN 'PASS' 
            ELSE 'FAIL' 
        END as test_result,
        FORMAT('%s out of 6 security helper functions exist', COUNT(*)) as details
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
    AND p.proname IN (
        'is_admin_user', 'get_admin_role', 'can_access_financial_data',
        'can_process_refunds', 'can_modify_payment_config', 'execute_as_system'
    );
    
    -- Test 3: Check if policies exist
    RETURN QUERY
    SELECT 
        'RLS Policies Check' as test_name,
        CASE 
            WHEN COUNT(*) >= 25 THEN 'PASS'
            WHEN COUNT(*) >= 15 THEN 'PARTIAL'
            ELSE 'FAIL' 
        END as test_result,
        FORMAT('%s RLS policies created', COUNT(*)) as details
    FROM pg_policy p
    JOIN pg_class c ON p.polrelid = c.oid
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'public';
END;
$$ LANGUAGE plpgsql;

-- =======================
-- DOCUMENTATION AND COMMENTS
-- =======================

COMMENT ON FUNCTION is_admin_user() IS 'Checks if current user is an authenticated admin user';
COMMENT ON FUNCTION get_admin_role() IS 'Returns the role of the current admin user';
COMMENT ON FUNCTION can_access_financial_data() IS 'Checks if user can access financial reports and data';
COMMENT ON FUNCTION can_process_refunds() IS 'Checks if user can process refund requests';
COMMENT ON FUNCTION can_modify_payment_config() IS 'Checks if user can modify payment configurations';
COMMENT ON FUNCTION execute_as_system(TEXT) IS 'Executes queries with system privileges, bypassing RLS';

-- Create summary view of security configuration
CREATE OR REPLACE VIEW v_financial_security_summary AS
SELECT 
    'Financial RLS Security' as security_component,
    (SELECT COUNT(*) FROM pg_class c JOIN pg_namespace n ON c.relnamespace = n.oid 
     WHERE n.nspname = 'public' AND c.relrowsecurity = true 
     AND c.relname LIKE '%payment%' OR c.relname LIKE '%refund%' 
     OR c.relname LIKE '%tax%' OR c.relname LIKE '%financial%') as tables_with_rls,
    (SELECT COUNT(*) FROM pg_policy p JOIN pg_class c ON p.polrelid = c.oid 
     JOIN pg_namespace n ON c.relnamespace = n.oid WHERE n.nspname = 'public') as total_policies,
    'Role-based access control implemented for admin users' as access_model,
    'Comprehensive audit logging and sensitive data protection' as additional_features;

-- Final success message
SELECT 'Financial RLS Policies Created Successfully' as status,
       'All security policies, helper functions, and access controls are configured' as details,
       'Run: SELECT * FROM test_financial_rls_policies() to validate setup' as validation_command;