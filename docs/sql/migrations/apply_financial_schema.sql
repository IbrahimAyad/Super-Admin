-- ============================================
-- APPLY FINANCIAL MANAGEMENT SCHEMA
-- Combined script for immediate application
-- ============================================

-- First, let's check if the schema already exists
SELECT 'Checking existing financial tables...' as status;

SELECT 
    table_name,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = t.table_name
        ) THEN 'EXISTS'
        ELSE 'MISSING'
    END as current_status
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
) AS t(table_name)
ORDER BY table_name;

-- ============================================
-- STEP 1: Apply the main financial schema
-- ============================================

-- REFERENCE/LOOKUP TABLES
-- Currency types (optimized for Supabase)
CREATE TABLE IF NOT EXISTS public.currencies (
    currency_code CHAR(3) PRIMARY KEY,
    currency_name VARCHAR(50) NOT NULL,
    symbol VARCHAR(5) NOT NULL,
    decimal_places SMALLINT DEFAULT 2 NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payment methods
CREATE TABLE IF NOT EXISTS public.payment_methods (
    method_id SERIAL PRIMARY KEY,
    method_code VARCHAR(20) UNIQUE NOT NULL,
    method_name VARCHAR(50) NOT NULL,
    requires_processing BOOLEAN DEFAULT true NOT NULL,
    supports_refunds BOOLEAN DEFAULT true NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Transaction statuses
CREATE TABLE IF NOT EXISTS public.transaction_statuses (
    status_id SERIAL PRIMARY KEY,
    status_code VARCHAR(20) UNIQUE NOT NULL,
    status_name VARCHAR(50) NOT NULL,
    is_final_status BOOLEAN DEFAULT false NOT NULL,
    is_success_status BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tax rates
CREATE TABLE IF NOT EXISTS public.tax_rates (
    tax_rate_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    jurisdiction_code VARCHAR(10) NOT NULL,
    jurisdiction_name VARCHAR(100) NOT NULL,
    tax_type VARCHAR(30) NOT NULL,
    tax_category VARCHAR(50),
    rate_percentage DECIMAL(5,4) NOT NULL CHECK (rate_percentage >= 0 AND rate_percentage <= 1),
    effective_from DATE NOT NULL,
    effective_to DATE,
    is_compound BOOLEAN DEFAULT false NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by UUID REFERENCES auth.users(id),
    version_number INTEGER DEFAULT 1 NOT NULL,
    CONSTRAINT tax_rates_date_range_check CHECK (effective_to IS NULL OR effective_to > effective_from),
    CONSTRAINT tax_rates_rate_valid CHECK (rate_percentage >= 0)
);

-- Payment transactions (with soft references)
CREATE TABLE IF NOT EXISTS public.payment_transactions (
    transaction_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    external_transaction_id VARCHAR(100),
    parent_transaction_id UUID REFERENCES public.payment_transactions(transaction_id),
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('PAYMENT', 'REFUND', 'VOID', 'CHARGEBACK', 'ADJUSTMENT')),
    amount DECIMAL(15,4) NOT NULL CHECK (amount > 0),
    currency_code CHAR(3) NOT NULL REFERENCES public.currencies(currency_code),
    payment_method_id INTEGER REFERENCES public.payment_methods(method_id),
    processor_name VARCHAR(50),
    processor_transaction_id VARCHAR(100),
    status_id INTEGER NOT NULL REFERENCES public.transaction_statuses(status_id),
    status_changed_at TIMESTAMPTZ DEFAULT NOW(),
    -- SOFT REFERENCES - No FK constraints to existing tables
    customer_id UUID, -- References customers(id) but no FK constraint
    order_id UUID, -- References orders(id) but no FK constraint
    gross_amount DECIMAL(15,4) NOT NULL,
    tax_amount DECIMAL(15,4) DEFAULT 0 NOT NULL,
    fee_amount DECIMAL(15,4) DEFAULT 0 NOT NULL,
    net_amount DECIMAL(15,4) GENERATED ALWAYS AS (gross_amount - tax_amount - fee_amount) STORED,
    processed_at TIMESTAMPTZ,
    settled_at TIMESTAMPTZ,
    reconciled_at TIMESTAMPTZ,
    risk_score DECIMAL(3,2) CHECK (risk_score >= 0 AND risk_score <= 1),
    fraud_flags TEXT[],
    metadata JSONB,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by UUID REFERENCES auth.users(id),
    CONSTRAINT payment_transactions_amounts_positive CHECK (gross_amount > 0 AND tax_amount >= 0 AND fee_amount >= 0)
);

-- Payment fees
CREATE TABLE IF NOT EXISTS public.payment_fees (
    fee_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    transaction_id UUID NOT NULL REFERENCES public.payment_transactions(transaction_id) ON DELETE CASCADE,
    fee_type VARCHAR(30) NOT NULL,
    fee_category VARCHAR(20) NOT NULL,
    base_amount DECIMAL(15,4) NOT NULL,
    fee_rate DECIMAL(8,6),
    fixed_fee DECIMAL(10,4),
    calculated_fee DECIMAL(15,4) NOT NULL,
    processor_name VARCHAR(50),
    processor_fee_id VARCHAR(100),
    fee_description TEXT,
    settled_amount DECIMAL(15,4),
    settled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),
    CONSTRAINT payment_fees_amounts_check CHECK (base_amount >= 0 AND calculated_fee >= 0),
    CONSTRAINT payment_fees_rate_check CHECK (fee_rate IS NULL OR fee_rate >= 0)
);

-- Refund requests
CREATE TABLE IF NOT EXISTS public.refund_requests (
    refund_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    original_transaction_id UUID NOT NULL REFERENCES public.payment_transactions(transaction_id),
    refund_transaction_id UUID REFERENCES public.payment_transactions(transaction_id),
    refund_reason VARCHAR(50) NOT NULL,
    refund_type VARCHAR(20) NOT NULL CHECK (refund_type IN ('FULL', 'PARTIAL')),
    requested_amount DECIMAL(15,4) NOT NULL CHECK (requested_amount > 0),
    currency_code CHAR(3) NOT NULL REFERENCES public.currencies(currency_code),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'PROCESSING', 'COMPLETED', 'FAILED')),
    status_changed_at TIMESTAMPTZ DEFAULT NOW(),
    requested_by UUID REFERENCES auth.users(id),
    approved_by UUID REFERENCES auth.users(id),
    approved_at TIMESTAMPTZ,
    rejection_reason TEXT,
    processed_at TIMESTAMPTZ,
    processor_refund_id VARCHAR(100),
    processing_fee DECIMAL(10,4) DEFAULT 0,
    customer_notified_at TIMESTAMPTZ,
    customer_notification_method VARCHAR(20),
    internal_notes TEXT,
    customer_reason TEXT,
    supporting_documents TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by UUID REFERENCES auth.users(id)
);

-- Financial reconciliation
CREATE TABLE IF NOT EXISTS public.financial_reconciliation (
    reconciliation_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    reconciliation_date DATE NOT NULL,
    currency_code CHAR(3) NOT NULL REFERENCES public.currencies(currency_code),
    total_transactions INTEGER NOT NULL DEFAULT 0,
    gross_sales_amount DECIMAL(15,4) NOT NULL DEFAULT 0,
    total_refunds_amount DECIMAL(15,4) NOT NULL DEFAULT 0,
    total_fees_amount DECIMAL(15,4) NOT NULL DEFAULT 0,
    total_tax_amount DECIMAL(15,4) NOT NULL DEFAULT 0,
    net_settlement_amount DECIMAL(15,4) GENERATED ALWAYS AS (gross_sales_amount - total_refunds_amount - total_fees_amount) STORED,
    expected_deposit_amount DECIMAL(15,4),
    actual_deposit_amount DECIMAL(15,4),
    variance_amount DECIMAL(15,4) GENERATED ALWAYS AS (COALESCE(actual_deposit_amount, 0) - COALESCE(expected_deposit_amount, 0)) STORED,
    reconciliation_status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (reconciliation_status IN ('PENDING', 'IN_PROGRESS', 'RECONCILED', 'DISCREPANCY')),
    reconciled_by UUID REFERENCES auth.users(id),
    reconciled_at TIMESTAMPTZ,
    discrepancy_notes TEXT,
    discrepancy_resolved_at TIMESTAMPTZ,
    discrepancy_resolved_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by UUID REFERENCES auth.users(id),
    UNIQUE(reconciliation_date, currency_code)
);

-- Audit tables
CREATE TABLE IF NOT EXISTS public.payment_transaction_audit (
    audit_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    transaction_id UUID NOT NULL,
    operation VARCHAR(10) NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    changed_fields JSONB,
    old_values JSONB,
    new_values JSONB,
    changed_at TIMESTAMPTZ DEFAULT NOW(),
    changed_by UUID REFERENCES auth.users(id),
    change_reason VARCHAR(200),
    ip_address INET,
    user_agent TEXT
);

CREATE TABLE IF NOT EXISTS public.refund_request_audit (
    audit_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    refund_id UUID NOT NULL,
    operation VARCHAR(10) NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    old_status VARCHAR(20),
    new_status VARCHAR(20),
    status_change_reason TEXT,
    changed_at TIMESTAMPTZ DEFAULT NOW(),
    changed_by UUID REFERENCES auth.users(id),
    ip_address INET
);

-- ============================================
-- STEP 2: Create indexes
-- ============================================

-- Payment transactions indexes
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON public.payment_transactions(status_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_created_date ON public.payment_transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_customer ON public.payment_transactions(customer_id) WHERE customer_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_payment_transactions_order ON public.payment_transactions(order_id) WHERE order_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_payment_transactions_external_id ON public.payment_transactions(external_transaction_id) WHERE external_transaction_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_payment_transactions_processor ON public.payment_transactions(processor_name, processor_transaction_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_reconciliation ON public.payment_transactions(reconciled_at) WHERE reconciled_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_payment_transactions_settlement ON public.payment_transactions(settled_at);

-- Tax rates indexes
CREATE INDEX IF NOT EXISTS idx_tax_rates_jurisdiction ON public.tax_rates(jurisdiction_code, effective_from, effective_to);
CREATE INDEX IF NOT EXISTS idx_tax_rates_active ON public.tax_rates(effective_from, effective_to) WHERE effective_to IS NULL OR effective_to > CURRENT_DATE;
CREATE INDEX IF NOT EXISTS idx_tax_rates_type_category ON public.tax_rates(tax_type, tax_category);

-- Refund requests indexes
CREATE INDEX IF NOT EXISTS idx_refund_requests_status ON public.refund_requests(status, created_at);
CREATE INDEX IF NOT EXISTS idx_refund_requests_original_transaction ON public.refund_requests(original_transaction_id);
CREATE INDEX IF NOT EXISTS idx_refund_requests_created_date ON public.refund_requests(created_at);
CREATE INDEX IF NOT EXISTS idx_refund_requests_approval ON public.refund_requests(status, approved_at) WHERE status = 'PENDING';

-- Payment fees indexes
CREATE INDEX IF NOT EXISTS idx_payment_fees_transaction ON public.payment_fees(transaction_id);
CREATE INDEX IF NOT EXISTS idx_payment_fees_type ON public.payment_fees(fee_type, created_at);
CREATE INDEX IF NOT EXISTS idx_payment_fees_processor ON public.payment_fees(processor_name, settled_at);

-- Financial reconciliation indexes
CREATE INDEX IF NOT EXISTS idx_financial_reconciliation_date ON public.financial_reconciliation(reconciliation_date);
CREATE INDEX IF NOT EXISTS idx_financial_reconciliation_status ON public.financial_reconciliation(reconciliation_status, reconciliation_date);
CREATE INDEX IF NOT EXISTS idx_financial_reconciliation_currency ON public.financial_reconciliation(currency_code, reconciliation_date);

-- Audit table indexes
CREATE INDEX IF NOT EXISTS idx_payment_transaction_audit_transaction ON public.payment_transaction_audit(transaction_id, changed_at);
CREATE INDEX IF NOT EXISTS idx_payment_transaction_audit_date ON public.payment_transaction_audit(changed_at);
CREATE INDEX IF NOT EXISTS idx_refund_request_audit_refund ON public.refund_request_audit(refund_id, changed_at);

-- ============================================
-- STEP 3: Insert reference data
-- ============================================

-- Insert currencies
INSERT INTO public.currencies (currency_code, currency_name, symbol, decimal_places) VALUES
('USD', 'US Dollar', '$', 2),
('EUR', 'Euro', '€', 2),
('GBP', 'British Pound', '£', 2),
('CAD', 'Canadian Dollar', 'C$', 2),
('JPY', 'Japanese Yen', '¥', 0)
ON CONFLICT (currency_code) DO NOTHING;

-- Insert payment methods
INSERT INTO public.payment_methods (method_code, method_name, requires_processing, supports_refunds) VALUES
('STRIPE_CARD', 'Credit/Debit Card (Stripe)', true, true),
('STRIPE_WALLET', 'Digital Wallet (Stripe)', true, true),
('BANK_TRANSFER', 'Bank Transfer', true, true),
('CASH', 'Cash', false, false),
('CHECK', 'Check', true, true)
ON CONFLICT (method_code) DO NOTHING;

-- Insert transaction statuses
INSERT INTO public.transaction_statuses (status_code, status_name, is_final_status, is_success_status) VALUES
('PENDING', 'Pending', false, false),
('PROCESSING', 'Processing', false, false),
('AUTHORIZED', 'Authorized', false, false),
('COMPLETED', 'Completed', true, true),
('FAILED', 'Failed', true, false),
('CANCELLED', 'Cancelled', true, false),
('REFUNDED', 'Refunded', true, false),
('CHARGEBACK', 'Chargeback', true, false)
ON CONFLICT (status_code) DO NOTHING;

-- Insert sample tax rates (only if admin user exists)
INSERT INTO public.tax_rates (jurisdiction_code, jurisdiction_name, tax_type, tax_category, rate_percentage, effective_from, created_by) 
SELECT 'US-CA', 'California, USA', 'SALES_TAX', 'STANDARD', 0.0875, '2024-01-01', u.id
FROM auth.users u 
WHERE u.email = 'admin@kctmenswear.com' 
LIMIT 1
ON CONFLICT DO NOTHING;

INSERT INTO public.tax_rates (jurisdiction_code, jurisdiction_name, tax_type, tax_category, rate_percentage, effective_from, created_by) 
SELECT 'US-NY', 'New York, USA', 'SALES_TAX', 'STANDARD', 0.08, '2024-01-01', u.id
FROM auth.users u 
WHERE u.email = 'admin@kctmenswear.com' 
LIMIT 1
ON CONFLICT DO NOTHING;

INSERT INTO public.tax_rates (jurisdiction_code, jurisdiction_name, tax_type, tax_category, rate_percentage, effective_from, created_by) 
SELECT 'GB', 'United Kingdom', 'VAT', 'STANDARD', 0.20, '2024-01-01', u.id
FROM auth.users u 
WHERE u.email = 'admin@kctmenswear.com' 
LIMIT 1
ON CONFLICT DO NOTHING;

-- ============================================
-- STEP 4: Create functions and triggers
-- ============================================

-- Function to update timestamps
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to log payment transaction changes
CREATE OR REPLACE FUNCTION public.log_payment_transaction_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO public.payment_transaction_audit (
            transaction_id, operation, old_values, new_values, 
            changed_by, change_reason
        ) VALUES (
            NEW.transaction_id, 'UPDATE', 
            to_jsonb(OLD), to_jsonb(NEW),
            auth.uid(), 'Transaction updated'
        );
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO public.payment_transaction_audit (
            transaction_id, operation, new_values, 
            changed_by, change_reason
        ) VALUES (
            NEW.transaction_id, 'INSERT', 
            to_jsonb(NEW),
            auth.uid(), 'Transaction created'
        );
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to log refund request changes
CREATE OR REPLACE FUNCTION public.log_refund_request_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO public.refund_request_audit (
            refund_id, operation, old_status, new_status,
            status_change_reason, changed_by
        ) VALUES (
            NEW.refund_id, 'UPDATE', OLD.status, NEW.status,
            'Status changed', auth.uid()
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create triggers
DROP TRIGGER IF EXISTS tr_payment_transactions_audit ON public.payment_transactions;
CREATE TRIGGER tr_payment_transactions_audit
    AFTER INSERT OR UPDATE ON public.payment_transactions
    FOR EACH ROW EXECUTE FUNCTION public.log_payment_transaction_changes();

DROP TRIGGER IF EXISTS tr_refund_requests_audit ON public.refund_requests;
CREATE TRIGGER tr_refund_requests_audit
    AFTER UPDATE ON public.refund_requests
    FOR EACH ROW EXECUTE FUNCTION public.log_refund_request_changes();

-- Update timestamp triggers
DROP TRIGGER IF EXISTS tr_tax_rates_updated_at ON public.tax_rates;
CREATE TRIGGER tr_tax_rates_updated_at
    BEFORE UPDATE ON public.tax_rates
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS tr_payment_transactions_updated_at ON public.payment_transactions;
CREATE TRIGGER tr_payment_transactions_updated_at
    BEFORE UPDATE ON public.payment_transactions
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS tr_refund_requests_updated_at ON public.refund_requests;
CREATE TRIGGER tr_refund_requests_updated_at
    BEFORE UPDATE ON public.refund_requests
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS tr_financial_reconciliation_updated_at ON public.financial_reconciliation;
CREATE TRIGGER tr_financial_reconciliation_updated_at
    BEFORE UPDATE ON public.financial_reconciliation
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================
-- STEP 5: Create utility functions
-- ============================================

-- Function to get effective tax rate for jurisdiction and date
CREATE OR REPLACE FUNCTION public.get_effective_tax_rate(
    p_jurisdiction_code VARCHAR(10),
    p_tax_type VARCHAR(30),
    p_effective_date DATE DEFAULT CURRENT_DATE
) RETURNS DECIMAL(5,4) AS $$
DECLARE
    v_rate DECIMAL(5,4);
BEGIN
    SELECT rate_percentage
    INTO v_rate
    FROM public.tax_rates
    WHERE jurisdiction_code = p_jurisdiction_code
        AND tax_type = p_tax_type
        AND effective_from <= p_effective_date
        AND (effective_to IS NULL OR effective_to > p_effective_date)
    ORDER BY effective_from DESC
    LIMIT 1;
    
    RETURN COALESCE(v_rate, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate daily reconciliation
CREATE OR REPLACE FUNCTION public.calculate_daily_reconciliation(
    p_reconciliation_date DATE,
    p_currency_code CHAR(3)
) RETURNS VOID AS $$
DECLARE
    v_total_transactions INTEGER;
    v_gross_sales DECIMAL(15,4);
    v_total_refunds DECIMAL(15,4);
    v_total_fees DECIMAL(15,4);
    v_total_tax DECIMAL(15,4);
BEGIN
    -- Calculate transaction summaries for the date
    SELECT 
        COUNT(*) FILTER (WHERE transaction_type = 'PAYMENT'),
        COALESCE(SUM(gross_amount) FILTER (WHERE transaction_type = 'PAYMENT'), 0),
        COALESCE(SUM(gross_amount) FILTER (WHERE transaction_type = 'REFUND'), 0),
        COALESCE(SUM(fee_amount), 0),
        COALESCE(SUM(tax_amount), 0)
    INTO v_total_transactions, v_gross_sales, v_total_refunds, v_total_fees, v_total_tax
    FROM public.payment_transactions pt
    JOIN public.transaction_statuses ts ON pt.status_id = ts.status_id
    WHERE DATE(pt.created_at) = p_reconciliation_date
        AND pt.currency_code = p_currency_code
        AND ts.is_success_status = true;

    -- Insert or update reconciliation record
    INSERT INTO public.financial_reconciliation (
        reconciliation_date, currency_code, total_transactions,
        gross_sales_amount, total_refunds_amount, total_fees_amount,
        total_tax_amount, created_by, updated_by
    ) VALUES (
        p_reconciliation_date, p_currency_code, v_total_transactions,
        v_gross_sales, v_total_refunds, v_total_fees,
        v_total_tax, auth.uid(), auth.uid()
    )
    ON CONFLICT (reconciliation_date, currency_code)
    DO UPDATE SET
        total_transactions = EXCLUDED.total_transactions,
        gross_sales_amount = EXCLUDED.gross_sales_amount,
        total_refunds_amount = EXCLUDED.total_refunds_amount,
        total_fees_amount = EXCLUDED.total_fees_amount,
        total_tax_amount = EXCLUDED.total_tax_amount,
        updated_by = auth.uid(),
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- STEP 6: Create reporting views
-- ============================================

-- Daily transaction summary view
CREATE OR REPLACE VIEW public.daily_transaction_summary AS
SELECT 
    DATE(created_at) as transaction_date,
    currency_code,
    transaction_type,
    COUNT(*) as transaction_count,
    SUM(gross_amount) as total_gross_amount,
    SUM(tax_amount) as total_tax_amount,
    SUM(fee_amount) as total_fee_amount,
    SUM(net_amount) as total_net_amount,
    AVG(gross_amount) as avg_transaction_amount
FROM public.payment_transactions pt
WHERE status_id IN (SELECT status_id FROM public.transaction_statuses WHERE is_success_status = true)
GROUP BY DATE(created_at), currency_code, transaction_type
ORDER BY transaction_date DESC, currency_code, transaction_type;

-- Pending reconciliation view
CREATE OR REPLACE VIEW public.pending_reconciliation_summary AS
SELECT 
    currency_code,
    COUNT(*) as unreconciled_transactions,
    SUM(gross_amount) as total_unreconciled_amount,
    MIN(created_at) as oldest_transaction,
    MAX(created_at) as newest_transaction
FROM public.payment_transactions 
WHERE reconciled_at IS NULL 
    AND status_id IN (SELECT status_id FROM public.transaction_statuses WHERE is_success_status = true)
GROUP BY currency_code
ORDER BY total_unreconciled_amount DESC;

-- Refund request summary view
CREATE OR REPLACE VIEW public.refund_request_summary AS
SELECT 
    status,
    COUNT(*) as request_count,
    SUM(requested_amount) as total_requested_amount,
    AVG(requested_amount) as avg_requested_amount,
    currency_code,
    refund_reason
FROM public.refund_requests 
GROUP BY status, currency_code, refund_reason
ORDER BY status, total_requested_amount DESC;

-- ============================================
-- STEP 7: Final verification
-- ============================================

SELECT 'Financial schema application completed!' as status;

-- Check table creation
SELECT 
    tablename,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_tables 
            WHERE schemaname = 'public' 
            AND tablename = t.tablename
        ) THEN '✅ Created'
        ELSE '❌ Failed'
    END as status
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

-- Check data insertion
SELECT 'Reference data check' as info;
SELECT 
    (SELECT COUNT(*) FROM public.currencies) as currencies_count,
    (SELECT COUNT(*) FROM public.payment_methods) as payment_methods_count,
    (SELECT COUNT(*) FROM public.transaction_statuses) as transaction_statuses_count,
    (SELECT COUNT(*) FROM public.tax_rates) as tax_rates_count;

-- Test functions
SELECT 'Function test' as test_type;
SELECT public.get_effective_tax_rate('US-CA', 'SALES_TAX', CURRENT_DATE) as ca_tax_rate;

SELECT 'Schema application completed successfully! 🎉' as final_status;