-- Financial Management Database Schema
-- PostgreSQL dialect with comprehensive financial tracking, audit capabilities, and compliance features
-- Created: 2025-08-07

-- Enable UUID extension for better primary keys
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =======================
-- REFERENCE/LOOKUP TABLES
-- =======================

-- Currency types
CREATE TABLE currencies (
    currency_code CHAR(3) PRIMARY KEY, -- ISO 4217 currency codes
    currency_name VARCHAR(50) NOT NULL,
    symbol VARCHAR(5) NOT NULL,
    decimal_places SMALLINT DEFAULT 2 NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Payment methods
CREATE TABLE payment_methods (
    method_id SERIAL PRIMARY KEY,
    method_code VARCHAR(20) UNIQUE NOT NULL, -- 'CARD', 'BANK_TRANSFER', 'DIGITAL_WALLET'
    method_name VARCHAR(50) NOT NULL,
    requires_processing BOOLEAN DEFAULT true NOT NULL,
    supports_refunds BOOLEAN DEFAULT true NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Transaction statuses
CREATE TABLE transaction_statuses (
    status_id SERIAL PRIMARY KEY,
    status_code VARCHAR(20) UNIQUE NOT NULL,
    status_name VARCHAR(50) NOT NULL,
    is_final_status BOOLEAN DEFAULT false NOT NULL, -- Cannot be changed after this
    is_success_status BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =======================
-- CORE FINANCIAL TABLES
-- =======================

-- 1. TAX RATES - Jurisdiction-based tax configuration
CREATE TABLE tax_rates (
    tax_rate_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    jurisdiction_code VARCHAR(10) NOT NULL, -- Country/state/province code
    jurisdiction_name VARCHAR(100) NOT NULL,
    tax_type VARCHAR(30) NOT NULL, -- 'VAT', 'GST', 'SALES_TAX', 'EXCISE'
    tax_category VARCHAR(50), -- 'STANDARD', 'REDUCED', 'ZERO', 'EXEMPT'
    rate_percentage DECIMAL(5,4) NOT NULL CHECK (rate_percentage >= 0 AND rate_percentage <= 1), -- 0.1950 for 19.50%
    effective_from DATE NOT NULL,
    effective_to DATE,
    is_compound BOOLEAN DEFAULT false NOT NULL, -- Tax calculated on tax-inclusive amount
    description TEXT,
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by VARCHAR(100),
    version_number INTEGER DEFAULT 1 NOT NULL,
    -- Constraints
    CONSTRAINT tax_rates_date_range_check CHECK (effective_to IS NULL OR effective_to > effective_from),
    CONSTRAINT tax_rates_rate_valid CHECK (rate_percentage >= 0)
);

-- 2. PAYMENT TRANSACTIONS - Comprehensive transaction logging
CREATE TABLE payment_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- Transaction identification
    external_transaction_id VARCHAR(100), -- Payment processor reference
    parent_transaction_id UUID REFERENCES payment_transactions(transaction_id), -- For refunds/voids
    -- Transaction details
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('PAYMENT', 'REFUND', 'VOID', 'CHARGEBACK', 'ADJUSTMENT')),
    amount DECIMAL(15,4) NOT NULL CHECK (amount > 0),
    currency_code CHAR(3) NOT NULL REFERENCES currencies(currency_code),
    -- Payment processing
    payment_method_id INTEGER REFERENCES payment_methods(method_id),
    processor_name VARCHAR(50), -- 'STRIPE', 'PAYPAL', 'SQUARE'
    processor_transaction_id VARCHAR(100),
    -- Status tracking
    status_id INTEGER NOT NULL REFERENCES transaction_statuses(status_id),
    status_changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- Customer and order information
    customer_id UUID, -- Reference to customers table (external)
    order_id UUID, -- Reference to orders table (external)
    -- Financial breakdown
    gross_amount DECIMAL(15,4) NOT NULL,
    tax_amount DECIMAL(15,4) DEFAULT 0 NOT NULL,
    fee_amount DECIMAL(15,4) DEFAULT 0 NOT NULL,
    net_amount DECIMAL(15,4) GENERATED ALWAYS AS (gross_amount - tax_amount - fee_amount) STORED,
    -- Processing details
    processed_at TIMESTAMP WITH TIME ZONE,
    settled_at TIMESTAMP WITH TIME ZONE,
    reconciled_at TIMESTAMP WITH TIME ZONE,
    -- Risk and fraud
    risk_score DECIMAL(3,2) CHECK (risk_score >= 0 AND risk_score <= 1),
    fraud_flags TEXT[], -- Array of fraud indicators
    -- Metadata
    metadata JSONB, -- Additional processor-specific data
    notes TEXT,
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by VARCHAR(100),
    -- Constraints
    CONSTRAINT payment_transactions_amounts_positive CHECK (gross_amount > 0 AND tax_amount >= 0 AND fee_amount >= 0)
);

-- 3. PAYMENT FEES - Transaction fee tracking
CREATE TABLE payment_fees (
    fee_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID NOT NULL REFERENCES payment_transactions(transaction_id) ON DELETE CASCADE,
    -- Fee structure
    fee_type VARCHAR(30) NOT NULL, -- 'PROCESSING', 'GATEWAY', 'CHARGEBACK', 'INTERNATIONAL', 'CURRENCY_CONVERSION'
    fee_category VARCHAR(20) NOT NULL, -- 'FIXED', 'PERCENTAGE', 'TIERED'
    -- Fee calculation
    base_amount DECIMAL(15,4) NOT NULL, -- Amount fee is calculated on
    fee_rate DECIMAL(8,6), -- For percentage fees (0.029500 for 2.95%)
    fixed_fee DECIMAL(10,4), -- For fixed fees
    calculated_fee DECIMAL(15,4) NOT NULL,
    -- Fee details
    processor_name VARCHAR(50),
    processor_fee_id VARCHAR(100),
    fee_description TEXT,
    -- Settlement
    settled_amount DECIMAL(15,4),
    settled_at TIMESTAMP WITH TIME ZONE,
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL,
    -- Constraints
    CONSTRAINT payment_fees_amounts_check CHECK (base_amount >= 0 AND calculated_fee >= 0),
    CONSTRAINT payment_fees_rate_check CHECK (fee_rate IS NULL OR fee_rate >= 0)
);

-- 4. REFUND REQUESTS - Track all refund requests and processing
CREATE TABLE refund_requests (
    refund_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- Reference information
    original_transaction_id UUID NOT NULL REFERENCES payment_transactions(transaction_id),
    refund_transaction_id UUID REFERENCES payment_transactions(transaction_id), -- Created when processed
    -- Request details
    refund_reason VARCHAR(50) NOT NULL, -- 'CUSTOMER_REQUEST', 'DEFECTIVE_PRODUCT', 'FRAUD', 'DUPLICATE_CHARGE'
    refund_type VARCHAR(20) NOT NULL CHECK (refund_type IN ('FULL', 'PARTIAL')),
    requested_amount DECIMAL(15,4) NOT NULL CHECK (requested_amount > 0),
    currency_code CHAR(3) NOT NULL REFERENCES currencies(currency_code),
    -- Status and processing
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'PROCESSING', 'COMPLETED', 'FAILED')),
    status_changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    -- Approval workflow
    requested_by VARCHAR(100) NOT NULL,
    approved_by VARCHAR(100),
    approved_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    -- Processing details
    processed_at TIMESTAMP WITH TIME ZONE,
    processor_refund_id VARCHAR(100), -- External processor reference
    processing_fee DECIMAL(10,4) DEFAULT 0,
    -- Customer communication
    customer_notified_at TIMESTAMP WITH TIME ZONE,
    customer_notification_method VARCHAR(20), -- 'EMAIL', 'SMS', 'PHONE'
    -- Additional information
    internal_notes TEXT,
    customer_reason TEXT,
    supporting_documents TEXT[], -- File references
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by VARCHAR(100)
);

-- 5. FINANCIAL RECONCILIATION - Daily financial summaries
CREATE TABLE financial_reconciliation (
    reconciliation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- Period information
    reconciliation_date DATE NOT NULL,
    currency_code CHAR(3) NOT NULL REFERENCES currencies(currency_code),
    -- Transaction summaries
    total_transactions INTEGER NOT NULL DEFAULT 0,
    gross_sales_amount DECIMAL(15,4) NOT NULL DEFAULT 0,
    total_refunds_amount DECIMAL(15,4) NOT NULL DEFAULT 0,
    total_fees_amount DECIMAL(15,4) NOT NULL DEFAULT 0,
    total_tax_amount DECIMAL(15,4) NOT NULL DEFAULT 0,
    net_settlement_amount DECIMAL(15,4) GENERATED ALWAYS AS (gross_sales_amount - total_refunds_amount - total_fees_amount) STORED,
    -- Bank reconciliation
    expected_deposit_amount DECIMAL(15,4),
    actual_deposit_amount DECIMAL(15,4),
    variance_amount DECIMAL(15,4) GENERATED ALWAYS AS (COALESCE(actual_deposit_amount, 0) - COALESCE(expected_deposit_amount, 0)) STORED,
    -- Reconciliation status
    reconciliation_status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (reconciliation_status IN ('PENDING', 'IN_PROGRESS', 'RECONCILED', 'DISCREPANCY')),
    reconciled_by VARCHAR(100),
    reconciled_at TIMESTAMP WITH TIME ZONE,
    -- Discrepancy tracking
    discrepancy_notes TEXT,
    discrepancy_resolved_at TIMESTAMP WITH TIME ZONE,
    discrepancy_resolved_by VARCHAR(100),
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by VARCHAR(100),
    -- Constraints
    UNIQUE(reconciliation_date, currency_code)
);

-- =======================
-- AUDIT TABLES
-- =======================

-- Transaction audit log for compliance
CREATE TABLE payment_transaction_audit (
    audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_id UUID NOT NULL,
    -- Change tracking
    operation VARCHAR(10) NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    changed_fields JSONB, -- Fields that were changed
    old_values JSONB, -- Previous values
    new_values JSONB, -- New values
    -- Audit metadata
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(100) NOT NULL,
    change_reason VARCHAR(200),
    ip_address INET,
    user_agent TEXT
);

-- Refund request audit log
CREATE TABLE refund_request_audit (
    audit_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    refund_id UUID NOT NULL,
    -- Change tracking
    operation VARCHAR(10) NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    old_status VARCHAR(20),
    new_status VARCHAR(20),
    status_change_reason TEXT,
    -- Audit metadata
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(100) NOT NULL,
    ip_address INET
);

-- =======================
-- INDEXES FOR PERFORMANCE
-- =======================

-- Payment transactions indexes
CREATE INDEX CONCURRENTLY idx_payment_transactions_status ON payment_transactions(status_id);
CREATE INDEX CONCURRENTLY idx_payment_transactions_created_date ON payment_transactions(created_at);
CREATE INDEX CONCURRENTLY idx_payment_transactions_customer ON payment_transactions(customer_id) WHERE customer_id IS NOT NULL;
CREATE INDEX CONCURRENTLY idx_payment_transactions_order ON payment_transactions(order_id) WHERE order_id IS NOT NULL;
CREATE INDEX CONCURRENTLY idx_payment_transactions_external_id ON payment_transactions(external_transaction_id) WHERE external_transaction_id IS NOT NULL;
CREATE INDEX CONCURRENTLY idx_payment_transactions_processor ON payment_transactions(processor_name, processor_transaction_id);
CREATE INDEX CONCURRENTLY idx_payment_transactions_reconciliation ON payment_transactions(reconciled_at) WHERE reconciled_at IS NULL;
CREATE INDEX CONCURRENTLY idx_payment_transactions_settlement ON payment_transactions(settled_at);

-- Tax rates indexes
CREATE INDEX CONCURRENTLY idx_tax_rates_jurisdiction ON tax_rates(jurisdiction_code, effective_from, effective_to);
CREATE INDEX CONCURRENTLY idx_tax_rates_active ON tax_rates(effective_from, effective_to) WHERE effective_to IS NULL OR effective_to > CURRENT_DATE;
CREATE INDEX CONCURRENTLY idx_tax_rates_type_category ON tax_rates(tax_type, tax_category);

-- Refund requests indexes
CREATE INDEX CONCURRENTLY idx_refund_requests_status ON refund_requests(status, created_at);
CREATE INDEX CONCURRENTLY idx_refund_requests_original_transaction ON refund_requests(original_transaction_id);
CREATE INDEX CONCURRENTLY idx_refund_requests_created_date ON refund_requests(created_at);
CREATE INDEX CONCURRENTLY idx_refund_requests_approval ON refund_requests(status, approved_at) WHERE status = 'PENDING';

-- Payment fees indexes
CREATE INDEX CONCURRENTLY idx_payment_fees_transaction ON payment_fees(transaction_id);
CREATE INDEX CONCURRENTLY idx_payment_fees_type ON payment_fees(fee_type, created_at);
CREATE INDEX CONCURRENTLY idx_payment_fees_processor ON payment_fees(processor_name, settled_at);

-- Financial reconciliation indexes
CREATE INDEX CONCURRENTLY idx_financial_reconciliation_date ON financial_reconciliation(reconciliation_date);
CREATE INDEX CONCURRENTLY idx_financial_reconciliation_status ON financial_reconciliation(reconciliation_status, reconciliation_date);
CREATE INDEX CONCURRENTLY idx_financial_reconciliation_currency ON financial_reconciliation(currency_code, reconciliation_date);

-- Audit table indexes
CREATE INDEX CONCURRENTLY idx_payment_transaction_audit_transaction ON payment_transaction_audit(transaction_id, changed_at);
CREATE INDEX CONCURRENTLY idx_payment_transaction_audit_date ON payment_transaction_audit(changed_at);
CREATE INDEX CONCURRENTLY idx_refund_request_audit_refund ON refund_request_audit(refund_id, changed_at);

-- =======================
-- TRIGGERS FOR AUDIT LOGGING
-- =======================

-- Function to log payment transaction changes
CREATE OR REPLACE FUNCTION log_payment_transaction_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO payment_transaction_audit (
            transaction_id, operation, old_values, new_values, 
            changed_by, change_reason
        ) VALUES (
            NEW.transaction_id, 'UPDATE', 
            to_jsonb(OLD), to_jsonb(NEW),
            NEW.updated_by, 'Transaction updated'
        );
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO payment_transaction_audit (
            transaction_id, operation, new_values, 
            changed_by, change_reason
        ) VALUES (
            NEW.transaction_id, 'INSERT', 
            to_jsonb(NEW),
            NEW.created_by, 'Transaction created'
        );
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Function to log refund request changes
CREATE OR REPLACE FUNCTION log_refund_request_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO refund_request_audit (
            refund_id, operation, old_status, new_status,
            status_change_reason, changed_by
        ) VALUES (
            NEW.refund_id, 'UPDATE', OLD.status, NEW.status,
            'Status changed', NEW.updated_by
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER tr_payment_transactions_audit
    AFTER INSERT OR UPDATE ON payment_transactions
    FOR EACH ROW EXECUTE FUNCTION log_payment_transaction_changes();

CREATE TRIGGER tr_refund_requests_audit
    AFTER UPDATE ON refund_requests
    FOR EACH ROW EXECUTE FUNCTION log_refund_request_changes();

-- Update timestamp triggers
CREATE TRIGGER tr_tax_rates_updated_at
    BEFORE UPDATE ON tax_rates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_payment_transactions_updated_at
    BEFORE UPDATE ON payment_transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_refund_requests_updated_at
    BEFORE UPDATE ON refund_requests
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_financial_reconciliation_updated_at
    BEFORE UPDATE ON financial_reconciliation
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =======================
-- SAMPLE DATA INSERTION
-- =======================

-- Insert sample currencies
INSERT INTO currencies (currency_code, currency_name, symbol, decimal_places) VALUES
('USD', 'US Dollar', '$', 2),
('EUR', 'Euro', '€', 2),
('GBP', 'British Pound', '£', 2),
('CAD', 'Canadian Dollar', 'C$', 2),
('JPY', 'Japanese Yen', '¥', 0);

-- Insert sample payment methods
INSERT INTO payment_methods (method_code, method_name, requires_processing, supports_refunds) VALUES
('CARD', 'Credit/Debit Card', true, true),
('BANK_TRANSFER', 'Bank Transfer', true, true),
('DIGITAL_WALLET', 'Digital Wallet', true, true),
('CASH', 'Cash', false, false),
('CHECK', 'Check', true, true);

-- Insert sample transaction statuses
INSERT INTO transaction_statuses (status_code, status_name, is_final_status, is_success_status) VALUES
('PENDING', 'Pending', false, false),
('PROCESSING', 'Processing', false, false),
('AUTHORIZED', 'Authorized', false, false),
('COMPLETED', 'Completed', true, true),
('FAILED', 'Failed', true, false),
('CANCELLED', 'Cancelled', true, false),
('REFUNDED', 'Refunded', true, false),
('CHARGEBACK', 'Chargeback', true, false);

-- Insert sample tax rates
INSERT INTO tax_rates (jurisdiction_code, jurisdiction_name, tax_type, tax_category, rate_percentage, effective_from, created_by) VALUES
('US-CA', 'California, USA', 'SALES_TAX', 'STANDARD', 0.0875, '2024-01-01', 'system'),
('US-NY', 'New York, USA', 'SALES_TAX', 'STANDARD', 0.08, '2024-01-01', 'system'),
('GB', 'United Kingdom', 'VAT', 'STANDARD', 0.20, '2024-01-01', 'system'),
('DE', 'Germany', 'VAT', 'STANDARD', 0.19, '2024-01-01', 'system'),
('CA-ON', 'Ontario, Canada', 'HST', 'STANDARD', 0.13, '2024-01-01', 'system');

-- =======================
-- VIEWS FOR REPORTING
-- =======================

-- Daily transaction summary view
CREATE VIEW daily_transaction_summary AS
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
FROM payment_transactions 
WHERE status_id IN (SELECT status_id FROM transaction_statuses WHERE is_success_status = true)
GROUP BY DATE(created_at), currency_code, transaction_type
ORDER BY transaction_date DESC, currency_code, transaction_type;

-- Pending reconciliation view
CREATE VIEW pending_reconciliation_summary AS
SELECT 
    currency_code,
    COUNT(*) as unreconciled_transactions,
    SUM(gross_amount) as total_unreconciled_amount,
    MIN(created_at) as oldest_transaction,
    MAX(created_at) as newest_transaction
FROM payment_transactions 
WHERE reconciled_at IS NULL 
    AND status_id IN (SELECT status_id FROM transaction_statuses WHERE is_success_status = true)
GROUP BY currency_code
ORDER BY total_unreconciled_amount DESC;

-- Refund request summary view
CREATE VIEW refund_request_summary AS
SELECT 
    status,
    COUNT(*) as request_count,
    SUM(requested_amount) as total_requested_amount,
    AVG(requested_amount) as avg_requested_amount,
    currency_code,
    refund_reason
FROM refund_requests 
GROUP BY status, currency_code, refund_reason
ORDER BY status, total_requested_amount DESC;

-- =======================
-- STORED PROCEDURES
-- =======================

-- Function to get effective tax rate for jurisdiction and date
CREATE OR REPLACE FUNCTION get_effective_tax_rate(
    p_jurisdiction_code VARCHAR(10),
    p_tax_type VARCHAR(30),
    p_effective_date DATE DEFAULT CURRENT_DATE
) RETURNS DECIMAL(5,4) AS $$
DECLARE
    v_rate DECIMAL(5,4);
BEGIN
    SELECT rate_percentage
    INTO v_rate
    FROM tax_rates
    WHERE jurisdiction_code = p_jurisdiction_code
        AND tax_type = p_tax_type
        AND effective_from <= p_effective_date
        AND (effective_to IS NULL OR effective_to > p_effective_date)
    ORDER BY effective_from DESC
    LIMIT 1;
    
    RETURN COALESCE(v_rate, 0);
END;
$$ LANGUAGE plpgsql;

-- Function to calculate daily reconciliation
CREATE OR REPLACE FUNCTION calculate_daily_reconciliation(
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
    FROM payment_transactions pt
    JOIN transaction_statuses ts ON pt.status_id = ts.status_id
    WHERE DATE(pt.created_at) = p_reconciliation_date
        AND pt.currency_code = p_currency_code
        AND ts.is_success_status = true;

    -- Insert or update reconciliation record
    INSERT INTO financial_reconciliation (
        reconciliation_date, currency_code, total_transactions,
        gross_sales_amount, total_refunds_amount, total_fees_amount,
        total_tax_amount, created_by, updated_by
    ) VALUES (
        p_reconciliation_date, p_currency_code, v_total_transactions,
        v_gross_sales, v_total_refunds, v_total_fees,
        v_total_tax, 'system', 'system'
    )
    ON CONFLICT (reconciliation_date, currency_code)
    DO UPDATE SET
        total_transactions = EXCLUDED.total_transactions,
        gross_sales_amount = EXCLUDED.gross_sales_amount,
        total_refunds_amount = EXCLUDED.total_refunds_amount,
        total_fees_amount = EXCLUDED.total_fees_amount,
        total_tax_amount = EXCLUDED.total_tax_amount,
        updated_by = 'system',
        updated_at = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- =======================
-- COMMENTS FOR DOCUMENTATION
-- =======================

COMMENT ON TABLE tax_rates IS 'Jurisdiction-based tax configuration with version control and effective date ranges';
COMMENT ON TABLE payment_transactions IS 'Comprehensive transaction logging with status tracking, fee breakdown, and audit trail';
COMMENT ON TABLE payment_fees IS 'Detailed fee tracking per transaction with processor-specific information';
COMMENT ON TABLE refund_requests IS 'Complete refund request lifecycle management with approval workflow';
COMMENT ON TABLE financial_reconciliation IS 'Daily financial summaries for accounting reconciliation and variance analysis';

COMMENT ON COLUMN tax_rates.rate_percentage IS 'Tax rate as decimal (0.1950 = 19.50%)';
COMMENT ON COLUMN payment_transactions.net_amount IS 'Calculated field: gross_amount - tax_amount - fee_amount';
COMMENT ON COLUMN payment_transactions.risk_score IS 'Fraud risk score from 0.00 (low risk) to 1.00 (high risk)';
COMMENT ON COLUMN financial_reconciliation.variance_amount IS 'Calculated field: actual_deposit_amount - expected_deposit_amount';

-- Performance optimization note
COMMENT ON INDEX idx_payment_transactions_reconciliation IS 'Critical for identifying unreconciled transactions';
COMMENT ON INDEX idx_refund_requests_approval IS 'Partial index for pending approvals to improve workflow performance';

-- Schema creation complete
SELECT 'Financial Management Database Schema Created Successfully' as status;