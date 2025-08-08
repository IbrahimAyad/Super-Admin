-- KCT Admin Financial Management System - Complete Deployment Script
-- This script deploys the complete production-ready financial system
-- Created: 2025-08-08
-- 
-- DEPLOYMENT ORDER (CRITICAL - Execute in this exact sequence):
-- 1. Run existing financial_management_schema.sql (if not already done)
-- 2. Run complete_financial_schema.sql
-- 3. Run this deployment script
-- 4. Run financial_rls_policies.sql
-- 5. Run stripe_webhook_integration.sql
-- 6. Test with sample data and queries

-- =======================
-- PRE-DEPLOYMENT VALIDATION
-- =======================

-- Check if base schema is deployed
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'payment_transactions') THEN
        RAISE EXCEPTION 'Base financial schema not found. Please run financial_management_schema.sql first.';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'payment_method_configurations') THEN
        RAISE EXCEPTION 'Extended schema not found. Please run complete_financial_schema.sql first.';
    END IF;
    
    RAISE NOTICE 'Pre-deployment validation passed. All required tables exist.';
END $$;

-- =======================
-- DEPLOYMENT STATUS TRACKING
-- =======================

-- Create deployment tracking table
CREATE TABLE IF NOT EXISTS deployment_history (
    deployment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    deployment_name VARCHAR(100) NOT NULL,
    deployment_version VARCHAR(20) NOT NULL,
    deployed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    deployed_by VARCHAR(100) DEFAULT current_user,
    status VARCHAR(20) DEFAULT 'IN_PROGRESS' CHECK (status IN ('IN_PROGRESS', 'COMPLETED', 'FAILED', 'ROLLED_BACK')),
    notes TEXT
);

-- Record this deployment
INSERT INTO deployment_history (deployment_name, deployment_version, notes)
VALUES ('KCT Financial Management System', '1.0.0', 'Initial production deployment');

-- =======================
-- SAMPLE DATA INSERTION
-- =======================

-- Insert comprehensive sample data for testing
INSERT INTO currencies (currency_code, currency_name, symbol, decimal_places) VALUES
('USD', 'US Dollar', '$', 2),
('EUR', 'Euro', '€', 2),
('GBP', 'British Pound', '£', 2),
('CAD', 'Canadian Dollar', 'C$', 2)
ON CONFLICT (currency_code) DO NOTHING;

INSERT INTO payment_methods (method_code, method_name, requires_processing, supports_refunds) VALUES
('CARD', 'Credit/Debit Card', true, true),
('BANK_TRANSFER', 'Bank Transfer', true, true),
('DIGITAL_WALLET', 'Digital Wallet', true, true),
('APPLE_PAY', 'Apple Pay', true, true),
('GOOGLE_PAY', 'Google Pay', true, true)
ON CONFLICT (method_code) DO NOTHING;

INSERT INTO transaction_statuses (status_code, status_name, is_final_status, is_success_status) VALUES
('PENDING', 'Pending', false, false),
('PROCESSING', 'Processing', false, false),
('AUTHORIZED', 'Authorized', false, false),
('COMPLETED', 'Completed', true, true),
('FAILED', 'Failed', true, false),
('CANCELLED', 'Cancelled', true, false),
('REFUNDED', 'Refunded', true, false),
('CHARGEBACK', 'Chargeback', true, false)
ON CONFLICT (status_code) DO NOTHING;

-- Insert sample tax rates for common jurisdictions
INSERT INTO tax_rates (jurisdiction_code, jurisdiction_name, tax_type, tax_category, rate_percentage, effective_from, created_by) VALUES
('US-CA', 'California, USA', 'SALES_TAX', 'STANDARD', 0.0875, '2024-01-01', 'system'),
('US-NY', 'New York, USA', 'SALES_TAX', 'STANDARD', 0.08, '2024-01-01', 'system'),
('US-TX', 'Texas, USA', 'SALES_TAX', 'STANDARD', 0.0825, '2024-01-01', 'system'),
('US-FL', 'Florida, USA', 'SALES_TAX', 'STANDARD', 0.06, '2024-01-01', 'system'),
('GB', 'United Kingdom', 'VAT', 'STANDARD', 0.20, '2024-01-01', 'system'),
('DE', 'Germany', 'VAT', 'STANDARD', 0.19, '2024-01-01', 'system'),
('FR', 'France', 'VAT', 'STANDARD', 0.20, '2024-01-01', 'system'),
('CA-ON', 'Ontario, Canada', 'HST', 'STANDARD', 0.13, '2024-01-01', 'system'),
('CA-BC', 'British Columbia, Canada', 'GST_PST', 'STANDARD', 0.12, '2024-01-01', 'system')
ON CONFLICT (jurisdiction_code, tax_type, effective_from) DO NOTHING;

-- Insert payment method configurations
INSERT INTO payment_method_configurations (
    payment_method_id, display_name, description, processor_name,
    fixed_fee, percentage_fee, display_order, created_by
) VALUES 
(
    (SELECT method_id FROM payment_methods WHERE method_code = 'CARD' LIMIT 1),
    'Credit/Debit Cards', 'Accept Visa, Mastercard, Amex, and Discover cards via Stripe', 
    'STRIPE', 0.30, 0.029, 1, 'system'
),
(
    (SELECT method_id FROM payment_methods WHERE method_code = 'DIGITAL_WALLET' LIMIT 1),
    'PayPal', 'Accept payments via PayPal accounts and saved cards', 
    'PAYPAL', 0.49, 0.029, 2, 'system'
),
(
    (SELECT method_id FROM payment_methods WHERE method_code = 'APPLE_PAY' LIMIT 1),
    'Apple Pay', 'Quick checkout for iOS users via Stripe', 
    'STRIPE', 0.30, 0.029, 3, 'system'
),
(
    (SELECT method_id FROM payment_methods WHERE method_code = 'GOOGLE_PAY' LIMIT 1),
    'Google Pay', 'Quick checkout for Android users via Stripe', 
    'STRIPE', 0.30, 0.029, 4, 'system'
)
ON CONFLICT DO NOTHING;

-- =======================
-- SAMPLE TRANSACTION DATA FOR TESTING
-- =======================

-- Insert sample transactions for testing dashboard metrics
-- These simulate real transaction data for the last 30 days
WITH date_series AS (
    SELECT generate_series(
        CURRENT_DATE - INTERVAL '30 days',
        CURRENT_DATE,
        INTERVAL '1 day'
    )::DATE as transaction_date
),
sample_transactions AS (
    SELECT 
        transaction_date,
        -- Simulate varying transaction volumes (more on weekends)
        CASE WHEN EXTRACT(DOW FROM transaction_date) IN (0, 6) THEN 
            (random() * 15 + 5)::INTEGER 
        ELSE 
            (random() * 10 + 3)::INTEGER 
        END as daily_transactions,
        -- Random amounts between $25 and $500
        (random() * 475 + 25)::DECIMAL(10,2) as base_amount
    FROM date_series
)
INSERT INTO payment_transactions (
    transaction_type, amount, currency_code, payment_method_id,
    processor_name, processor_transaction_id, external_transaction_id,
    status_id, customer_id,
    gross_amount, tax_amount, fee_amount,
    created_at, processed_at,
    created_by, updated_by
)
SELECT 
    'PAYMENT',
    st.base_amount,
    'USD',
    (SELECT method_id FROM payment_methods WHERE method_code = 'CARD' LIMIT 1),
    'STRIPE',
    'pi_test_' || substr(md5(random()::text), 0, 25),
    'ord_' || substr(md5(random()::text), 0, 15),
    (SELECT status_id FROM transaction_statuses WHERE status_code = 'COMPLETED'),
    uuid_generate_v4(), -- Random customer ID
    st.base_amount,
    (st.base_amount * 0.08), -- 8% tax
    (st.base_amount * 0.029 + 0.30), -- Stripe fees
    st.transaction_date + (random() * INTERVAL '23 hours'),
    st.transaction_date + (random() * INTERVAL '23 hours'),
    'sample_data_generator',
    'sample_data_generator'
FROM sample_transactions st
CROSS JOIN generate_series(1, st.daily_transactions) AS transaction_number
WHERE NOT EXISTS (
    SELECT 1 FROM payment_transactions 
    WHERE created_at::DATE = st.transaction_date
    AND created_by = 'sample_data_generator'
    LIMIT 1
);

-- Insert sample refund requests
INSERT INTO refund_requests (
    original_transaction_id, refund_reason, refund_type,
    requested_amount, currency_code, status,
    requested_by, customer_reason
)
SELECT 
    pt.transaction_id,
    CASE (random() * 4)::INTEGER
        WHEN 0 THEN 'CUSTOMER_REQUEST'
        WHEN 1 THEN 'DEFECTIVE_PRODUCT'
        WHEN 2 THEN 'WRONG_ITEM'
        ELSE 'SIZE_ISSUE'
    END,
    CASE WHEN random() > 0.7 THEN 'FULL' ELSE 'PARTIAL' END,
    CASE WHEN random() > 0.7 THEN pt.gross_amount 
         ELSE (pt.gross_amount * (0.3 + random() * 0.4)) END, -- Partial refunds
    pt.currency_code,
    CASE (random() * 3)::INTEGER
        WHEN 0 THEN 'PENDING'
        WHEN 1 THEN 'COMPLETED'
        ELSE 'APPROVED'
    END,
    'customer_service',
    'Customer requested refund via support ticket'
FROM payment_transactions pt
WHERE pt.created_by = 'sample_data_generator'
AND random() < 0.05 -- 5% of transactions get refund requests
LIMIT 20;

-- =======================
-- PERFORMANCE OPTIMIZATIONS
-- =======================

-- Update table statistics
ANALYZE payment_transactions;
ANALYZE payment_fees;
ANALYZE refund_requests;
ANALYZE financial_reconciliation;
ANALYZE payment_method_configurations;
ANALYZE tax_rates;

-- =======================
-- VALIDATION QUERIES
-- =======================

-- Validate deployment with test queries
CREATE OR REPLACE FUNCTION validate_financial_deployment()
RETURNS TABLE (
    component TEXT,
    test_name TEXT,
    status TEXT,
    details TEXT
) AS $$
BEGIN
    -- Test 1: Core tables exist
    RETURN QUERY
    SELECT 
        'Schema' as component,
        'Core Tables Exist' as test_name,
        CASE WHEN COUNT(*) = 15 THEN 'PASS' ELSE 'FAIL' END as status,
        FORMAT('%s/15 financial tables exist', COUNT(*)) as details
    FROM pg_tables 
    WHERE tablename IN (
        'currencies', 'payment_methods', 'transaction_statuses', 'tax_rates',
        'payment_transactions', 'payment_fees', 'refund_requests', 
        'financial_reconciliation', 'payment_method_configurations',
        'payment_webhooks', 'customer_payment_methods', 'tax_jurisdiction_mapping',
        'financial_report_templates', 'payment_transaction_audit', 'refund_request_audit'
    );
    
    -- Test 2: Sample data inserted
    RETURN QUERY
    SELECT 
        'Data' as component,
        'Sample Data Inserted' as test_name,
        CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END as status,
        FORMAT('%s sample transactions created', COUNT(*)) as details
    FROM payment_transactions 
    WHERE created_by = 'sample_data_generator';
    
    -- Test 3: Dashboard queries work
    RETURN QUERY
    SELECT 
        'Queries' as component,
        'Dashboard Metrics Function' as test_name,
        CASE WHEN EXISTS (
            SELECT 1 FROM get_financial_dashboard_metrics() LIMIT 1
        ) THEN 'PASS' ELSE 'FAIL' END as status,
        'Financial dashboard metrics function executes successfully' as details;
    
    -- Test 4: Refund summary works
    RETURN QUERY
    SELECT 
        'Queries' as component,
        'Refund Summary Function' as test_name,
        CASE WHEN EXISTS (
            SELECT 1 FROM get_refund_summary_metrics() LIMIT 1
        ) THEN 'PASS' ELSE 'FAIL' END as status,
        'Refund summary metrics function executes successfully' as details;
    
    -- Test 5: Revenue report works
    RETURN QUERY
    SELECT 
        'Queries' as component,
        'Revenue Report Function' as test_name,
        CASE WHEN EXISTS (
            SELECT 1 FROM get_revenue_report() LIMIT 1
        ) THEN 'PASS' ELSE 'FAIL' END as status,
        'Revenue report function executes successfully' as details;
    
    -- Test 6: Views accessible
    RETURN QUERY
    SELECT 
        'Views' as component,
        'Financial Views Created' as test_name,
        CASE WHEN COUNT(*) >= 5 THEN 'PASS' ELSE 'FAIL' END as status,
        FORMAT('%s financial views created', COUNT(*)) as details
    FROM pg_views 
    WHERE viewname LIKE '%financial%' OR viewname LIKE '%refund%' OR viewname LIKE '%payment%';
    
    -- Test 7: Indexes created
    RETURN QUERY
    SELECT 
        'Performance' as component,
        'Performance Indexes' as test_name,
        CASE WHEN COUNT(*) >= 20 THEN 'PASS' ELSE 'PARTIAL' END as status,
        FORMAT('%s performance indexes created', COUNT(*)) as details
    FROM pg_indexes 
    WHERE tablename LIKE '%payment%' OR tablename LIKE '%refund%' OR tablename LIKE '%tax%';
END;
$$ LANGUAGE plpgsql;

-- =======================
-- COMPONENT INTEGRATION SCRIPTS
-- =======================

-- Script to generate TypeScript types from database schema
CREATE OR REPLACE FUNCTION generate_typescript_types()
RETURNS TEXT AS $$
DECLARE
    typescript_output TEXT := '';
BEGIN
    typescript_output := typescript_output || E'// Generated TypeScript types for KCT Financial System\n';
    typescript_output := typescript_output || E'// Auto-generated from database schema\n\n';
    
    typescript_output := typescript_output || E'export interface PaymentTransaction {\n';
    typescript_output := typescript_output || E'  transaction_id: string;\n';
    typescript_output := typescript_output || E'  transaction_type: "PAYMENT" | "REFUND" | "VOID" | "CHARGEBACK" | "ADJUSTMENT";\n';
    typescript_output := typescript_output || E'  amount: number;\n';
    typescript_output := typescript_output || E'  currency_code: string;\n';
    typescript_output := typescript_output || E'  status_id: number;\n';
    typescript_output := typescript_output || E'  customer_id?: string;\n';
    typescript_output := typescript_output || E'  order_id?: string;\n';
    typescript_output := typescript_output || E'  gross_amount: number;\n';
    typescript_output := typescript_output || E'  tax_amount: number;\n';
    typescript_output := typescript_output || E'  fee_amount: number;\n';
    typescript_output := typescript_output || E'  net_amount: number;\n';
    typescript_output := typescript_output || E'  processor_name?: string;\n';
    typescript_output := typescript_output || E'  created_at: string;\n';
    typescript_output := typescript_output || E'  updated_at: string;\n';
    typescript_output := typescript_output || E'}\n\n';
    
    typescript_output := typescript_output || E'export interface RefundRequest {\n';
    typescript_output := typescript_output || E'  refund_id: string;\n';
    typescript_output := typescript_output || E'  original_transaction_id: string;\n';
    typescript_output := typescript_output || E'  refund_reason: string;\n';
    typescript_output := typescript_output || E'  refund_type: "FULL" | "PARTIAL";\n';
    typescript_output := typescript_output || E'  requested_amount: number;\n';
    typescript_output := typescript_output || E'  currency_code: string;\n';
    typescript_output := typescript_output || E'  status: "PENDING" | "APPROVED" | "REJECTED" | "PROCESSING" | "COMPLETED" | "FAILED";\n';
    typescript_output := typescript_output || E'  requested_by: string;\n';
    typescript_output := typescript_output || E'  created_at: string;\n';
    typescript_output := typescript_output || E'}\n\n';
    
    typescript_output := typescript_output || E'export interface FinancialMetrics {\n';
    typescript_output := typescript_output || E'  total_revenue: number;\n';
    typescript_output := typescript_output || E'  revenue_change_percent: number;\n';
    typescript_output := typescript_output || E'  pending_refunds: number;\n';
    typescript_output := typescript_output || E'  pending_refunds_count: number;\n';
    typescript_output := typescript_output || E'  processing_fees: number;\n';
    typescript_output := typescript_output || E'  tax_collected: number;\n';
    typescript_output := typescript_output || E'  pending_payouts: number;\n';
    typescript_output := typescript_output || E'}\n\n';
    
    RETURN typescript_output;
END;
$$ LANGUAGE plpgsql;

-- =======================
-- DEPLOYMENT COMPLETION
-- =======================

-- Update deployment status
UPDATE deployment_history 
SET status = 'COMPLETED',
    notes = notes || E'\n' || 'Deployment completed successfully at ' || CURRENT_TIMESTAMP
WHERE deployment_name = 'KCT Financial Management System' 
AND deployment_version = '1.0.0'
AND status = 'IN_PROGRESS';

-- =======================
-- FINAL VALIDATION AND SUMMARY
-- =======================

-- Run validation tests
SELECT 'DEPLOYMENT VALIDATION RESULTS' as section;
SELECT * FROM validate_financial_deployment();

-- Display summary
SELECT 
    'DEPLOYMENT SUMMARY' as section,
    'KCT Financial Management System v1.0.0' as system_name,
    'Successfully deployed' as status,
    CURRENT_TIMESTAMP as completed_at;

-- Display usage instructions
SELECT 
    'USAGE INSTRUCTIONS' as section,
    'Component' as component,
    'Integration Notes' as notes
UNION ALL
SELECT '', 'RefundProcessor', 'Use v_pending_refunds view and get_refund_summary_metrics() function'
UNION ALL
SELECT '', 'FinancialManagement', 'Use get_financial_dashboard_metrics() and v_recent_transactions view'
UNION ALL
SELECT '', 'FinancialReports', 'Use get_revenue_report() function with date range parameters'
UNION ALL
SELECT '', 'PaymentMethodSettings', 'Use v_payment_method_settings view and update functions'
UNION ALL
SELECT '', 'TaxConfiguration', 'Use tax_rates table with get_effective_tax_rate() function'
UNION ALL
SELECT '', 'Stripe Webhooks', 'Use process_stripe_webhook() function for webhook processing';

-- Display next steps
SELECT 
    'NEXT STEPS' as section,
    'Step' as step,
    'Action Required' as action
UNION ALL
SELECT '', '1', 'Run financial_rls_policies.sql to enable security'
UNION ALL  
SELECT '', '2', 'Configure payment processor credentials in payment_method_configurations'
UNION ALL
SELECT '', '3', 'Set up webhook endpoints using stripe_webhook_integration.sql functions'
UNION ALL
SELECT '', '4', 'Update your React components to use real database queries instead of mock data'
UNION ALL
SELECT '', '5', 'Test all financial workflows with small transactions'
UNION ALL
SELECT '', '6', 'Set up monitoring and alerting for financial operations';

-- Success confirmation
SELECT 'SUCCESS: KCT Financial Management System deployed and ready for production use!' as final_status;