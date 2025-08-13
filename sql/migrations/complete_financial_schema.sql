-- Complete Financial Management Database Schema
-- Production-ready schema for KCT Admin System
-- Extends existing financial schema with component-specific tables
-- Created: 2025-08-08

-- =======================
-- ADDITIONAL CONFIGURATION TABLES
-- =======================

-- Payment method configuration for admin settings
CREATE TABLE IF NOT EXISTS payment_method_configurations (
    config_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_method_id INTEGER NOT NULL REFERENCES payment_methods(method_id),
    -- Configuration settings
    is_enabled BOOLEAN DEFAULT true NOT NULL,
    display_order INTEGER DEFAULT 999 NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    -- Processor settings
    processor_name VARCHAR(50) NOT NULL, -- 'STRIPE', 'PAYPAL', 'SQUARE'
    processor_mode VARCHAR(20) DEFAULT 'live' CHECK (processor_mode IN ('test', 'live')),
    -- API credentials (encrypted)
    api_key_public TEXT,
    api_key_secret TEXT, -- Should be encrypted at application level
    webhook_secret TEXT, -- Should be encrypted at application level
    webhook_endpoint VARCHAR(500),
    -- Fee configuration
    fixed_fee DECIMAL(10,4) DEFAULT 0,
    percentage_fee DECIMAL(8,6) DEFAULT 0, -- 0.029 for 2.9%
    international_fee DECIMAL(8,6) DEFAULT 0,
    currency_conversion_fee DECIMAL(8,6) DEFAULT 0,
    -- Security settings
    requires_cvv BOOLEAN DEFAULT true,
    requires_avs BOOLEAN DEFAULT true,
    enables_3ds BOOLEAN DEFAULT false,
    fraud_detection_enabled BOOLEAN DEFAULT true,
    risk_threshold INTEGER DEFAULT 75 CHECK (risk_threshold >= 1 AND risk_threshold <= 100),
    -- Feature flags
    supports_apple_pay BOOLEAN DEFAULT false,
    supports_google_pay BOOLEAN DEFAULT false,
    supports_recurring BOOLEAN DEFAULT true,
    supports_saved_cards BOOLEAN DEFAULT true,
    -- Merchant identifiers
    merchant_id VARCHAR(100),
    merchant_account_id VARCHAR(100),
    -- Statistics tracking
    total_volume DECIMAL(15,4) DEFAULT 0,
    total_transactions INTEGER DEFAULT 0,
    total_fees DECIMAL(15,4) DEFAULT 0,
    last_transaction_date TIMESTAMP WITH TIME ZONE,
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by VARCHAR(100),
    version_number INTEGER DEFAULT 1 NOT NULL
);

-- Payment processor webhooks tracking
CREATE TABLE IF NOT EXISTS payment_webhooks (
    webhook_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- Webhook identification
    processor_name VARCHAR(50) NOT NULL,
    webhook_type VARCHAR(100) NOT NULL, -- 'payment.succeeded', 'charge.dispute.created', etc.
    external_webhook_id VARCHAR(100), -- Processor's webhook ID
    -- Request details
    received_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    http_method VARCHAR(10) DEFAULT 'POST',
    headers JSONB,
    payload JSONB NOT NULL,
    signature VARCHAR(500), -- Webhook signature for verification
    -- Processing status
    processing_status VARCHAR(20) DEFAULT 'pending' CHECK (processing_status IN ('pending', 'processing', 'processed', 'failed', 'ignored')),
    processed_at TIMESTAMP WITH TIME ZONE,
    processing_error TEXT,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    -- Related entities
    related_transaction_id UUID REFERENCES payment_transactions(transaction_id),
    related_refund_id UUID REFERENCES refund_requests(refund_id),
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by VARCHAR(100) DEFAULT 'system'
);

-- Customer payment methods (saved cards, etc.)
CREATE TABLE IF NOT EXISTS customer_payment_methods (
    customer_payment_method_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID NOT NULL, -- Reference to customers table
    payment_method_id INTEGER NOT NULL REFERENCES payment_methods(method_id),
    -- Payment method details
    processor_name VARCHAR(50) NOT NULL,
    processor_payment_method_id VARCHAR(100) NOT NULL, -- Stripe's pm_xxx, PayPal's billing agreement
    -- Card/account details (masked)
    last_four VARCHAR(4),
    brand VARCHAR(20), -- 'visa', 'mastercard', 'amex'
    exp_month INTEGER CHECK (exp_month >= 1 AND exp_month <= 12),
    exp_year INTEGER CHECK (exp_year >= EXTRACT(YEAR FROM CURRENT_DATE)),
    cardholder_name VARCHAR(100),
    -- Status and preferences
    is_default BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    -- Usage statistics
    times_used INTEGER DEFAULT 0,
    total_amount_charged DECIMAL(15,4) DEFAULT 0,
    last_used_at TIMESTAMP WITH TIME ZONE,
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tax jurisdiction mapping for automatic tax calculation
CREATE TABLE IF NOT EXISTS tax_jurisdiction_mapping (
    mapping_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    -- Geographic identifiers
    country_code CHAR(2) NOT NULL, -- ISO 3166-1 alpha-2
    state_province_code VARCHAR(10), -- State/province code
    postal_code_pattern VARCHAR(20), -- Regex pattern for postal codes
    city_name VARCHAR(100),
    -- Tax rate reference
    tax_rate_id UUID NOT NULL REFERENCES tax_rates(tax_rate_id),
    -- Priority for overlapping rules (higher number = higher priority)
    priority_order INTEGER DEFAULT 100,
    -- Geographic boundaries (for more precise matching)
    latitude_min DECIMAL(10,8),
    latitude_max DECIMAL(10,8),
    longitude_min DECIMAL(11,8),
    longitude_max DECIMAL(11,8),
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT true
);

-- Financial reports configuration
CREATE TABLE IF NOT EXISTS financial_report_templates (
    template_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_name VARCHAR(100) NOT NULL,
    template_type VARCHAR(50) NOT NULL, -- 'REVENUE', 'TAX', 'FEES', 'RECONCILIATION', 'CUSTOM'
    description TEXT,
    -- Report configuration
    query_definition JSONB NOT NULL, -- Stores query parameters and filters
    default_date_range VARCHAR(20) DEFAULT '30d', -- '7d', '30d', '90d', '1y', 'custom'
    default_currency VARCHAR(3) DEFAULT 'USD',
    default_grouping VARCHAR(20) DEFAULT 'daily', -- 'hourly', 'daily', 'weekly', 'monthly'
    -- Output configuration
    includes_charts BOOLEAN DEFAULT true,
    chart_types TEXT[], -- ['line', 'bar', 'pie']
    export_formats TEXT[] DEFAULT ARRAY['csv', 'pdf'], -- Available export formats
    -- Access control
    is_public BOOLEAN DEFAULT false,
    allowed_roles TEXT[] DEFAULT ARRAY['admin'], -- Roles that can access this report
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_by VARCHAR(100),
    is_active BOOLEAN DEFAULT true
);

-- =======================
-- ENHANCED EXISTING TABLES
-- =======================

-- Add webhook tracking to existing transactions table
ALTER TABLE payment_transactions 
ADD COLUMN IF NOT EXISTS webhook_id UUID REFERENCES payment_webhooks(webhook_id),
ADD COLUMN IF NOT EXISTS customer_payment_method_id UUID REFERENCES customer_payment_methods(customer_payment_method_id);

-- Add configuration tracking to refund requests
ALTER TABLE refund_requests
ADD COLUMN IF NOT EXISTS auto_approved BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS approval_rule_id UUID, -- Reference to approval rules (future feature)
ADD COLUMN IF NOT EXISTS customer_payment_method_id UUID REFERENCES customer_payment_methods(customer_payment_method_id);

-- =======================
-- PERFORMANCE INDEXES
-- =======================

-- Payment method configurations indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_payment_method_configs_enabled 
ON payment_method_configurations(is_enabled, display_order) WHERE is_enabled = true;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_payment_method_configs_processor 
ON payment_method_configurations(processor_name, processor_mode);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_payment_method_configs_stats 
ON payment_method_configurations(total_volume DESC, total_transactions DESC);

-- Webhook tracking indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_payment_webhooks_processor_type 
ON payment_webhooks(processor_name, webhook_type, received_at);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_payment_webhooks_status 
ON payment_webhooks(processing_status, received_at) WHERE processing_status = 'pending';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_payment_webhooks_retry 
ON payment_webhooks(retry_count, processing_status) WHERE processing_status = 'failed' AND retry_count < max_retries;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_payment_webhooks_external_id 
ON payment_webhooks(processor_name, external_webhook_id) WHERE external_webhook_id IS NOT NULL;

-- Customer payment methods indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_customer_payment_methods_customer 
ON customer_payment_methods(customer_id, is_active) WHERE is_active = true;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_customer_payment_methods_default 
ON customer_payment_methods(customer_id, is_default) WHERE is_default = true;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_customer_payment_methods_processor 
ON customer_payment_methods(processor_name, processor_payment_method_id);

-- Tax jurisdiction mapping indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tax_jurisdiction_country 
ON tax_jurisdiction_mapping(country_code, state_province_code, is_active) WHERE is_active = true;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tax_jurisdiction_postal 
ON tax_jurisdiction_mapping(country_code, postal_code_pattern, priority_order DESC) WHERE is_active = true;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tax_jurisdiction_priority 
ON tax_jurisdiction_mapping(priority_order DESC, tax_rate_id) WHERE is_active = true;

-- Financial report templates indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_financial_report_templates_type 
ON financial_report_templates(template_type, is_active) WHERE is_active = true;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_financial_report_templates_public 
ON financial_report_templates(is_public, template_type) WHERE is_public = true AND is_active = true;

-- =======================
-- UPDATED TIMESTAMP TRIGGERS
-- =======================

-- Add timestamp triggers for new tables
CREATE TRIGGER tr_payment_method_configurations_updated_at
    BEFORE UPDATE ON payment_method_configurations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_payment_webhooks_updated_at
    BEFORE UPDATE ON payment_webhooks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_customer_payment_methods_updated_at
    BEFORE UPDATE ON customer_payment_methods
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_financial_report_templates_updated_at
    BEFORE UPDATE ON financial_report_templates
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =======================
-- SAMPLE DATA FOR TESTING
-- =======================

-- Insert default payment method configurations
INSERT INTO payment_method_configurations (
    payment_method_id, display_name, description, processor_name,
    fixed_fee, percentage_fee, created_by
) VALUES 
-- Stripe configuration
((SELECT method_id FROM payment_methods WHERE method_code = 'CARD' LIMIT 1), 
 'Credit/Debit Cards via Stripe', 'Accept Visa, Mastercard, Amex, and other major cards', 
 'STRIPE', 0.30, 0.029, 'system'),
-- PayPal configuration
((SELECT method_id FROM payment_methods WHERE method_code = 'DIGITAL_WALLET' LIMIT 1), 
 'PayPal', 'Accept payments via PayPal accounts and cards', 
 'PAYPAL', 0.49, 0.029, 'system')
ON CONFLICT DO NOTHING;

-- Insert default financial report templates
INSERT INTO financial_report_templates (
    template_name, template_type, description, query_definition, created_by
) VALUES
('Revenue Summary', 'REVENUE', 'Daily, weekly, and monthly revenue analysis', 
 '{"metrics": ["gross_revenue", "net_revenue", "transaction_count"], "groupBy": "date", "filters": {"status": "completed"}}', 
 'system'),
('Tax Collection Report', 'TAX', 'Tax collected by jurisdiction and period', 
 '{"metrics": ["tax_amount"], "groupBy": ["date", "jurisdiction"], "filters": {"status": "completed"}}', 
 'system'),
('Payment Processing Fees', 'FEES', 'Breakdown of payment processing costs by method', 
 '{"metrics": ["fee_amount", "fee_percentage"], "groupBy": ["processor", "fee_type"], "filters": {}}', 
 'system'),
('Refund Analysis', 'REVENUE', 'Refund rates, reasons, and impact analysis', 
 '{"metrics": ["refund_amount", "refund_count", "refund_rate"], "groupBy": ["reason", "date"], "filters": {}}', 
 'system')
ON CONFLICT DO NOTHING;

-- Insert sample tax jurisdiction mappings for common regions
INSERT INTO tax_jurisdiction_mapping (
    country_code, state_province_code, tax_rate_id, priority_order, created_by
) VALUES
('US', 'CA', (SELECT tax_rate_id FROM tax_rates WHERE jurisdiction_code = 'US-CA' LIMIT 1), 100, 'system'),
('US', 'NY', (SELECT tax_rate_id FROM tax_rates WHERE jurisdiction_code = 'US-NY' LIMIT 1), 100, 'system'),
('GB', NULL, (SELECT tax_rate_id FROM tax_rates WHERE jurisdiction_code = 'GB' LIMIT 1), 100, 'system'),
('DE', NULL, (SELECT tax_rate_id FROM tax_rates WHERE jurisdiction_code = 'DE' LIMIT 1), 100, 'system'),
('CA', 'ON', (SELECT tax_rate_id FROM tax_rates WHERE jurisdiction_code = 'CA-ON' LIMIT 1), 100, 'system')
ON CONFLICT DO NOTHING;

-- =======================
-- COMMENTS FOR NEW TABLES
-- =======================

COMMENT ON TABLE payment_method_configurations IS 'Admin configurable payment method settings with processor credentials and fee structures';
COMMENT ON TABLE payment_webhooks IS 'Tracking and processing of payment processor webhooks for real-time transaction updates';
COMMENT ON TABLE customer_payment_methods IS 'Saved customer payment methods for faster checkout and recurring payments';
COMMENT ON TABLE tax_jurisdiction_mapping IS 'Geographic mapping for automatic tax rate determination based on customer location';
COMMENT ON TABLE financial_report_templates IS 'Configurable financial report definitions for dashboard and export functionality';

COMMENT ON COLUMN payment_method_configurations.api_key_secret IS 'Should be encrypted at application level before storage';
COMMENT ON COLUMN payment_method_configurations.risk_threshold IS 'Transactions above this score (1-100) will be flagged for review';
COMMENT ON COLUMN payment_webhooks.payload IS 'Full webhook payload from payment processor for debugging and reprocessing';
COMMENT ON COLUMN customer_payment_methods.last_four IS 'Last 4 digits of card number for customer identification';

SELECT 'Complete Financial Schema Created Successfully' as status,
       'All tables, indexes, and sample data have been configured' as details;