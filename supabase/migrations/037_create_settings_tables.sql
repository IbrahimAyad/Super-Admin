-- ============================================
-- Settings & Configuration System
-- Migration: 037_create_settings_tables.sql
-- ============================================
-- This migration creates comprehensive settings and configuration tables
-- for the KCT Menswear admin system.

-- ============================================
-- 1. SYSTEM_SETTINGS TABLE (Key-Value Store)
-- ============================================
CREATE TABLE IF NOT EXISTS public.system_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    category TEXT NOT NULL CHECK (category IN (
        'general', 'payment', 'shipping', 'tax', 'email', 'seo', 
        'analytics', 'social', 'security', 'maintenance', 'features'
    )),
    key TEXT NOT NULL,
    value JSONB NOT NULL,
    value_type TEXT NOT NULL CHECK (value_type IN (
        'string', 'number', 'boolean', 'object', 'array'
    )),
    description TEXT,
    is_public BOOLEAN DEFAULT false, -- if true, expose to website/frontend
    is_encrypted BOOLEAN DEFAULT false, -- for sensitive values
    validation_rules JSONB, -- JSON schema for value validation
    default_value JSONB,
    updated_by UUID REFERENCES auth.users(id),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure unique category-key combination
    UNIQUE(category, key),
    
    -- Indexes for performance
    INDEX idx_system_settings_category (category),
    INDEX idx_system_settings_key (key),
    INDEX idx_system_settings_is_public (is_public),
    INDEX idx_system_settings_updated_at (updated_at)
);

-- ============================================
-- 2. STORE_CONFIG TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.store_config (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    store_name TEXT NOT NULL,
    store_description TEXT,
    store_logo TEXT, -- URL to logo image
    store_favicon TEXT, -- URL to favicon
    contact_email TEXT NOT NULL,
    contact_phone TEXT,
    support_email TEXT,
    
    -- Address information
    address JSONB DEFAULT '{
        "line1": "",
        "line2": "",
        "city": "",
        "state": "",
        "postal_code": "",
        "country": "US"
    }'::jsonb,
    
    -- Business hours (by day of week)
    business_hours JSONB DEFAULT '{
        "monday": {"open": "09:00", "close": "18:00", "closed": false},
        "tuesday": {"open": "09:00", "close": "18:00", "closed": false},
        "wednesday": {"open": "09:00", "close": "18:00", "closed": false},
        "thursday": {"open": "09:00", "close": "18:00", "closed": false},
        "friday": {"open": "09:00", "close": "18:00", "closed": false},
        "saturday": {"open": "10:00", "close": "16:00", "closed": false},
        "sunday": {"open": "12:00", "close": "16:00", "closed": false}
    }'::jsonb,
    
    -- Social media links
    social_links JSONB DEFAULT '{
        "facebook": "",
        "instagram": "",
        "twitter": "",
        "youtube": "",
        "tiktok": "",
        "pinterest": ""
    }'::jsonb,
    
    -- SEO settings
    meta_title TEXT,
    meta_description TEXT,
    meta_keywords TEXT[],
    
    -- Legal information
    privacy_policy_url TEXT,
    terms_of_service_url TEXT,
    return_policy_url TEXT,
    
    -- Feature flags
    features JSONB DEFAULT '{
        "reviews_enabled": true,
        "wishlist_enabled": true,
        "loyalty_program": false,
        "gift_cards": false,
        "pre_orders": false,
        "backorders": false,
        "inventory_tracking": true,
        "multi_currency": false
    }'::jsonb,
    
    timezone TEXT DEFAULT 'America/New_York',
    currency_code TEXT DEFAULT 'USD',
    language_code TEXT DEFAULT 'en',
    
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Indexes
    INDEX idx_store_config_updated_at (updated_at)
);

-- ============================================
-- 3. PAYMENT_CONFIG TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.payment_config (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Stripe configuration
    stripe_public_key TEXT,
    stripe_secret_key_encrypted TEXT, -- Encrypted using pgcrypto
    stripe_webhook_secret_encrypted TEXT,
    
    -- PayPal configuration (for future use)
    paypal_client_id TEXT,
    paypal_client_secret_encrypted TEXT,
    
    -- Accepted payment methods
    accepted_methods JSONB DEFAULT '{
        "card": true,
        "apple_pay": true,
        "google_pay": true,
        "paypal": false,
        "bank_transfer": false,
        "cash_on_delivery": false
    }'::jsonb,
    
    -- Currency and pricing
    currency_code TEXT DEFAULT 'USD',
    currency_symbol TEXT DEFAULT '$',
    currency_position TEXT DEFAULT 'before' CHECK (currency_position IN ('before', 'after')),
    
    -- Fee configuration
    processing_fee_percent DECIMAL(5,4) DEFAULT 0.0290, -- 2.9%
    processing_fee_fixed DECIMAL(10,2) DEFAULT 0.30, -- $0.30
    
    -- Tax settings
    tax_inclusive_pricing BOOLEAN DEFAULT false,
    calculate_tax_at TEXT DEFAULT 'shipping' CHECK (calculate_tax_at IN ('billing', 'shipping')),
    
    -- Test mode
    test_mode BOOLEAN DEFAULT true,
    
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    INDEX idx_payment_config_updated_at (updated_at)
);

-- ============================================
-- 4. SHIPPING_ZONES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.shipping_zones (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    
    -- Geographic coverage
    countries TEXT[] DEFAULT ARRAY['US'], -- ISO country codes
    states TEXT[] DEFAULT '{}', -- State codes for specific countries
    zip_codes TEXT[] DEFAULT '{}', -- Specific ZIP/postal codes
    zip_code_ranges JSONB DEFAULT '[]', -- [{min: "10000", max: "19999"}]
    
    -- Zone settings
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    INDEX idx_shipping_zones_is_active (is_active),
    INDEX idx_shipping_zones_sort_order (sort_order)
);

-- ============================================
-- 5. SHIPPING_RATES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.shipping_rates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    zone_id UUID NOT NULL REFERENCES public.shipping_zones(id) ON DELETE CASCADE,
    
    -- Method details
    method_name TEXT NOT NULL, -- "Standard", "Express", "Overnight"
    method_code TEXT NOT NULL, -- "standard", "express", "overnight"
    description TEXT,
    
    -- Rate calculation
    rate_type TEXT NOT NULL DEFAULT 'flat' CHECK (rate_type IN ('flat', 'weight', 'price', 'item_count')),
    base_rate DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    per_item_rate DECIMAL(10,2) DEFAULT 0.00,
    per_weight_rate DECIMAL(10,2) DEFAULT 0.00, -- per lb/kg
    
    -- Conditions
    min_order_value DECIMAL(10,2) DEFAULT 0.00,
    max_order_value DECIMAL(10,2),
    free_shipping_threshold DECIMAL(10,2), -- Free shipping over this amount
    
    -- Delivery estimates
    min_delivery_days INTEGER DEFAULT 5,
    max_delivery_days INTEGER DEFAULT 7,
    
    -- Settings
    is_active BOOLEAN DEFAULT true,
    requires_signature BOOLEAN DEFAULT false,
    is_trackable BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure unique method per zone
    UNIQUE(zone_id, method_code),
    
    INDEX idx_shipping_rates_zone_id (zone_id),
    INDEX idx_shipping_rates_is_active (is_active),
    INDEX idx_shipping_rates_sort_order (sort_order)
);

-- ============================================
-- 6. TAX_RATES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.tax_rates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Geographic scope
    country_code TEXT NOT NULL DEFAULT 'US',
    state_code TEXT, -- State/province code
    region TEXT NOT NULL, -- Display name: "New York", "California", etc.
    zip_codes TEXT[] DEFAULT '{}', -- Specific ZIP codes if needed
    
    -- Tax details
    tax_name TEXT NOT NULL, -- "Sales Tax", "VAT", "GST"
    rate DECIMAL(7,4) NOT NULL, -- Tax rate (e.g., 0.0875 for 8.75%)
    
    -- Tax behavior
    is_inclusive BOOLEAN DEFAULT false, -- Price includes tax
    applies_to_shipping BOOLEAN DEFAULT false,
    applies_to_digital BOOLEAN DEFAULT true,
    
    -- Effective dates
    effective_from DATE DEFAULT CURRENT_DATE,
    effective_until DATE,
    
    -- Settings
    is_active BOOLEAN DEFAULT true,
    priority INTEGER DEFAULT 0, -- For multiple overlapping rates
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure no overlapping active rates for same region
    EXCLUDE USING gist (
        country_code WITH =,
        state_code WITH =,
        region WITH =,
        tsrange(effective_from, COALESCE(effective_until, '2099-12-31'::date)) WITH &&
    ) WHERE (is_active = true),
    
    INDEX idx_tax_rates_country_state (country_code, state_code),
    INDEX idx_tax_rates_region (region),
    INDEX idx_tax_rates_is_active (is_active),
    INDEX idx_tax_rates_effective_dates (effective_from, effective_until)
);

-- ============================================
-- 7. SETTINGS_AUDIT_LOG TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.settings_audit_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- What changed
    table_name TEXT NOT NULL,
    record_id UUID NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    
    -- Change details
    field_name TEXT, -- Specific field that changed (for UPDATE)
    old_value JSONB,
    new_value JSONB,
    
    -- Who changed it
    changed_by UUID REFERENCES auth.users(id),
    changed_by_admin UUID REFERENCES public.admin_users(id),
    ip_address INET,
    user_agent TEXT,
    
    -- When
    changed_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Additional context
    reason TEXT,
    metadata JSONB,
    
    INDEX idx_settings_audit_log_table_record (table_name, record_id),
    INDEX idx_settings_audit_log_changed_by (changed_by),
    INDEX idx_settings_audit_log_changed_at (changed_at)
);

-- ============================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.store_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shipping_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shipping_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tax_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings_audit_log ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES
-- ============================================

-- System Settings Policies
CREATE POLICY "Public can read public settings" ON public.system_settings
    FOR SELECT
    USING (is_public = true);

CREATE POLICY "Admins can read all settings" ON public.system_settings
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
            AND (permissions @> ARRAY['settings'] OR permissions @> ARRAY['all'])
        )
    );

CREATE POLICY "Admins can manage settings" ON public.system_settings
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
            AND (permissions @> ARRAY['settings'] OR permissions @> ARRAY['all'])
        )
    );

-- Store Config Policies  
CREATE POLICY "Public can read basic store config" ON public.store_config
    FOR SELECT
    USING (true); -- Most store config is public (name, hours, contact info)

CREATE POLICY "Admins can manage store config" ON public.store_config
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
            AND (permissions @> ARRAY['settings'] OR permissions @> ARRAY['all'])
        )
    );

-- Payment Config Policies (Highly Restricted)
CREATE POLICY "Only super admins can read payment config" ON public.payment_config
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND role = 'super_admin'
            AND is_active = true
        )
    );

CREATE POLICY "Only super admins can manage payment config" ON public.payment_config
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND role = 'super_admin'
            AND is_active = true
        )
    );

-- Shipping Zones & Rates Policies
CREATE POLICY "Public can read active shipping zones" ON public.shipping_zones
    FOR SELECT
    USING (is_active = true);

CREATE POLICY "Public can read active shipping rates" ON public.shipping_rates  
    FOR SELECT
    USING (
        is_active = true 
        AND EXISTS (
            SELECT 1 FROM public.shipping_zones 
            WHERE id = shipping_rates.zone_id 
            AND is_active = true
        )
    );

CREATE POLICY "Admins can manage shipping" ON public.shipping_zones
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
            AND (permissions @> ARRAY['shipping'] OR permissions @> ARRAY['all'])
        )
    );

CREATE POLICY "Admins can manage shipping rates" ON public.shipping_rates
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
            AND (permissions @> ARRAY['shipping'] OR permissions @> ARRAY['all'])
        )
    );

-- Tax Rates Policies
CREATE POLICY "Public can read active tax rates" ON public.tax_rates
    FOR SELECT
    USING (is_active = true AND effective_from <= CURRENT_DATE);

CREATE POLICY "Admins can manage tax rates" ON public.tax_rates
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
            AND (permissions @> ARRAY['tax'] OR permissions @> ARRAY['all'])
        )
    );

-- Audit Log Policies
CREATE POLICY "Admins can read audit logs" ON public.settings_audit_log
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
            AND (permissions @> ARRAY['settings'] OR permissions @> ARRAY['all'])
        )
    );

CREATE POLICY "System can insert audit logs" ON public.settings_audit_log
    FOR INSERT
    WITH CHECK (true);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to safely update encrypted payment keys
CREATE OR REPLACE FUNCTION public.update_payment_keys(
    p_stripe_secret_key TEXT DEFAULT NULL,
    p_stripe_webhook_secret TEXT DEFAULT NULL,
    p_paypal_client_secret TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    config_id UUID;
BEGIN
    -- Check admin permissions
    IF NOT EXISTS (
        SELECT 1 FROM public.admin_users
        WHERE user_id = auth.uid()
        AND role = 'super_admin'
        AND is_active = true
    ) THEN
        RAISE EXCEPTION 'Insufficient permissions to update payment keys';
    END IF;
    
    -- Get or create payment config
    SELECT id INTO config_id FROM public.payment_config LIMIT 1;
    
    IF config_id IS NULL THEN
        INSERT INTO public.payment_config (id) 
        VALUES (gen_random_uuid()) 
        RETURNING id INTO config_id;
    END IF;
    
    -- Update encrypted keys (using pgcrypto extension)
    UPDATE public.payment_config SET
        stripe_secret_key_encrypted = CASE 
            WHEN p_stripe_secret_key IS NOT NULL 
            THEN pgp_sym_encrypt(p_stripe_secret_key, current_setting('app.settings.encryption_key'))
            ELSE stripe_secret_key_encrypted 
        END,
        stripe_webhook_secret_encrypted = CASE 
            WHEN p_stripe_webhook_secret IS NOT NULL 
            THEN pgp_sym_encrypt(p_stripe_webhook_secret, current_setting('app.settings.encryption_key'))
            ELSE stripe_webhook_secret_encrypted 
        END,
        paypal_client_secret_encrypted = CASE 
            WHEN p_paypal_client_secret IS NOT NULL 
            THEN pgp_sym_encrypt(p_paypal_client_secret, current_setting('app.settings.encryption_key'))
            ELSE paypal_client_secret_encrypted 
        END,
        updated_at = NOW()
    WHERE id = config_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get decrypted payment keys (for authorized users only)
CREATE OR REPLACE FUNCTION public.get_payment_keys()
RETURNS TABLE(
    stripe_secret_key TEXT,
    stripe_webhook_secret TEXT,
    paypal_client_secret TEXT
) AS $$
BEGIN
    -- Check admin permissions
    IF NOT EXISTS (
        SELECT 1 FROM public.admin_users
        WHERE user_id = auth.uid()
        AND role = 'super_admin'
        AND is_active = true
    ) THEN
        RAISE EXCEPTION 'Insufficient permissions to decrypt payment keys';
    END IF;
    
    RETURN QUERY
    SELECT 
        CASE 
            WHEN pc.stripe_secret_key_encrypted IS NOT NULL 
            THEN pgp_sym_decrypt(pc.stripe_secret_key_encrypted, current_setting('app.settings.encryption_key'))
            ELSE NULL
        END,
        CASE 
            WHEN pc.stripe_webhook_secret_encrypted IS NOT NULL 
            THEN pgp_sym_decrypt(pc.stripe_webhook_secret_encrypted, current_setting('app.settings.encryption_key'))
            ELSE NULL
        END,
        CASE 
            WHEN pc.paypal_client_secret_encrypted IS NOT NULL 
            THEN pgp_sym_decrypt(pc.paypal_client_secret_encrypted, current_setting('app.settings.encryption_key'))
            ELSE NULL
        END
    FROM public.payment_config pc
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate shipping rate for order
CREATE OR REPLACE FUNCTION public.calculate_shipping_rate(
    p_zone_id UUID,
    p_method_code TEXT,
    p_order_total DECIMAL(10,2),
    p_order_weight DECIMAL(8,2) DEFAULT 0,
    p_item_count INTEGER DEFAULT 1
)
RETURNS DECIMAL(10,2) AS $$
DECLARE
    shipping_rate DECIMAL(10,2) := 0;
    rate_record RECORD;
BEGIN
    -- Get shipping rate configuration
    SELECT * INTO rate_record
    FROM public.shipping_rates sr
    JOIN public.shipping_zones sz ON sr.zone_id = sz.id
    WHERE sr.zone_id = p_zone_id 
    AND sr.method_code = p_method_code
    AND sr.is_active = true
    AND sz.is_active = true;
    
    IF NOT FOUND THEN
        RETURN NULL; -- No valid shipping rate found
    END IF;
    
    -- Check if order qualifies for free shipping
    IF rate_record.free_shipping_threshold IS NOT NULL 
        AND p_order_total >= rate_record.free_shipping_threshold THEN
        RETURN 0.00;
    END IF;
    
    -- Check minimum order value
    IF p_order_total < rate_record.min_order_value THEN
        RETURN NULL; -- Order doesn't meet minimum
    END IF;
    
    -- Check maximum order value
    IF rate_record.max_order_value IS NOT NULL 
        AND p_order_total > rate_record.max_order_value THEN
        RETURN NULL; -- Order exceeds maximum
    END IF;
    
    -- Calculate rate based on rate_type
    CASE rate_record.rate_type
        WHEN 'flat' THEN
            shipping_rate := rate_record.base_rate;
        WHEN 'weight' THEN
            shipping_rate := rate_record.base_rate + (rate_record.per_weight_rate * p_order_weight);
        WHEN 'price' THEN
            shipping_rate := rate_record.base_rate + (p_order_total * rate_record.per_item_rate / 100);
        WHEN 'item_count' THEN
            shipping_rate := rate_record.base_rate + (rate_record.per_item_rate * p_item_count);
        ELSE
            shipping_rate := rate_record.base_rate;
    END CASE;
    
    RETURN GREATEST(shipping_rate, 0); -- Ensure non-negative
END;
$$ LANGUAGE plpgsql;

-- Function to get applicable tax rate
CREATE OR REPLACE FUNCTION public.get_tax_rate(
    p_country_code TEXT DEFAULT 'US',
    p_state_code TEXT DEFAULT NULL,
    p_region TEXT DEFAULT NULL,
    p_zip_code TEXT DEFAULT NULL
)
RETURNS DECIMAL(7,4) AS $$
DECLARE
    tax_rate DECIMAL(7,4) := 0.0000;
BEGIN
    -- Find the most specific applicable tax rate
    SELECT tr.rate INTO tax_rate
    FROM public.tax_rates tr
    WHERE tr.country_code = p_country_code
    AND tr.is_active = true
    AND tr.effective_from <= CURRENT_DATE
    AND (tr.effective_until IS NULL OR tr.effective_until >= CURRENT_DATE)
    AND (
        -- Exact region match
        (p_region IS NOT NULL AND tr.region = p_region)
        OR
        -- State-level match when region not specified
        (p_state_code IS NOT NULL AND tr.state_code = p_state_code AND tr.region IS NULL)
        OR
        -- Country-level default
        (tr.state_code IS NULL AND tr.region IS NULL)
    )
    AND (
        -- ZIP code match if specified
        tr.zip_codes = '{}' 
        OR p_zip_code = ANY(tr.zip_codes)
        OR tr.zip_codes IS NULL
    )
    ORDER BY 
        -- Prioritize more specific matches
        CASE WHEN tr.zip_codes != '{}' AND p_zip_code = ANY(tr.zip_codes) THEN 1 ELSE 10 END,
        CASE WHEN tr.region IS NOT NULL THEN 2 ELSE 10 END,
        CASE WHEN tr.state_code IS NOT NULL THEN 3 ELSE 10 END,
        tr.priority DESC
    LIMIT 1;
    
    RETURN COALESCE(tax_rate, 0.0000);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger to update updated_at timestamps
CREATE OR REPLACE FUNCTION public.update_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all settings tables
CREATE TRIGGER update_system_settings_updated_at
    BEFORE UPDATE ON public.system_settings
    FOR EACH ROW EXECUTE FUNCTION public.update_settings_updated_at();

CREATE TRIGGER update_store_config_updated_at
    BEFORE UPDATE ON public.store_config
    FOR EACH ROW EXECUTE FUNCTION public.update_settings_updated_at();

CREATE TRIGGER update_payment_config_updated_at
    BEFORE UPDATE ON public.payment_config
    FOR EACH ROW EXECUTE FUNCTION public.update_settings_updated_at();

CREATE TRIGGER update_shipping_zones_updated_at
    BEFORE UPDATE ON public.shipping_zones
    FOR EACH ROW EXECUTE FUNCTION public.update_settings_updated_at();

CREATE TRIGGER update_shipping_rates_updated_at
    BEFORE UPDATE ON public.shipping_rates
    FOR EACH ROW EXECUTE FUNCTION public.update_settings_updated_at();

CREATE TRIGGER update_tax_rates_updated_at
    BEFORE UPDATE ON public.tax_rates
    FOR EACH ROW EXECUTE FUNCTION public.update_settings_updated_at();

-- Audit trigger function
CREATE OR REPLACE FUNCTION public.audit_settings_changes()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.settings_audit_log (
        table_name,
        record_id,
        action,
        old_value,
        new_value,
        changed_by,
        changed_by_admin,
        changed_at
    ) VALUES (
        TG_TABLE_NAME,
        COALESCE(NEW.id, OLD.id),
        TG_OP,
        CASE WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD) ELSE NULL END,
        CASE WHEN TG_OP != 'DELETE' THEN to_jsonb(NEW) ELSE NULL END,
        auth.uid(),
        (SELECT id FROM public.admin_users WHERE user_id = auth.uid()),
        NOW()
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply audit triggers
CREATE TRIGGER audit_system_settings_changes
    AFTER INSERT OR UPDATE OR DELETE ON public.system_settings
    FOR EACH ROW EXECUTE FUNCTION public.audit_settings_changes();

CREATE TRIGGER audit_payment_config_changes
    AFTER INSERT OR UPDATE OR DELETE ON public.payment_config
    FOR EACH ROW EXECUTE FUNCTION public.audit_settings_changes();

CREATE TRIGGER audit_shipping_zones_changes
    AFTER INSERT OR UPDATE OR DELETE ON public.shipping_zones
    FOR EACH ROW EXECUTE FUNCTION public.audit_settings_changes();

CREATE TRIGGER audit_shipping_rates_changes
    AFTER INSERT OR UPDATE OR DELETE ON public.shipping_rates
    FOR EACH ROW EXECUTE FUNCTION public.audit_settings_changes();

CREATE TRIGGER audit_tax_rates_changes
    AFTER INSERT OR UPDATE OR DELETE ON public.tax_rates
    FOR EACH ROW EXECUTE FUNCTION public.audit_settings_changes();

-- ============================================
-- SEED DATA
-- ============================================

-- Insert default store configuration
INSERT INTO public.store_config (
    store_name,
    store_description,
    contact_email,
    contact_phone,
    support_email,
    address,
    meta_title,
    meta_description
) VALUES (
    'KCT Menswear',
    'Premium menswear for the modern gentleman. Quality clothing, accessories, and style guidance.',
    'contact@kctmenswear.com',
    '+1 (555) 123-4567',
    'support@kctmenswear.com',
    '{
        "line1": "123 Fashion Ave",
        "line2": "Suite 100",
        "city": "New York",
        "state": "NY",
        "postal_code": "10001",
        "country": "US"
    }'::jsonb,
    'KCT Menswear - Premium Men''s Clothing & Accessories',
    'Shop premium menswear at KCT. Quality suits, shirts, accessories and more for the modern gentleman. Free shipping on orders over $100.'
) ON CONFLICT DO NOTHING;

-- Insert default system settings
INSERT INTO public.system_settings (category, key, value, value_type, description, is_public) VALUES
    ('general', 'site_title', '"KCT Menswear"', 'string', 'Website title shown in browser tab', true),
    ('general', 'site_tagline', '"Premium Menswear for the Modern Gentleman"', 'string', 'Site tagline/slogan', true),
    ('general', 'maintenance_mode', 'false', 'boolean', 'Enable maintenance mode to disable public access', false),
    ('general', 'default_currency', '"USD"', 'string', 'Default store currency', true),
    ('general', 'weight_unit', '"lbs"', 'string', 'Default weight unit (lbs or kg)', true),
    
    ('shipping', 'free_shipping_threshold', '100.00', 'number', 'Minimum order value for free shipping', true),
    ('shipping', 'default_shipping_days', '5', 'number', 'Default delivery estimate in days', true),
    ('shipping', 'same_day_cutoff_hour', '14', 'number', 'Hour (24h) after which orders ship next day', false),
    
    ('email', 'from_name', '"KCT Menswear"', 'string', 'Default sender name for emails', false),
    ('email', 'from_email', '"noreply@kctmenswear.com"', 'string', 'Default sender email address', false),
    ('email', 'support_email', '"support@kctmenswear.com"', 'string', 'Support email address', true),
    
    ('seo', 'google_analytics_id', '""', 'string', 'Google Analytics tracking ID', false),
    ('seo', 'facebook_pixel_id', '""', 'string', 'Facebook Pixel tracking ID', false),
    ('seo', 'google_tag_manager_id', '""', 'string', 'Google Tag Manager container ID', false),
    
    ('features', 'reviews_enabled', 'true', 'boolean', 'Enable product reviews and ratings', true),
    ('features', 'wishlist_enabled', 'true', 'boolean', 'Enable customer wishlists', true),
    ('features', 'loyalty_program', 'false', 'boolean', 'Enable loyalty points system', true),
    ('features', 'gift_cards_enabled', 'false', 'boolean', 'Enable gift card sales and redemption', true),
    ('features', 'inventory_tracking', 'true', 'boolean', 'Track inventory levels for products', false),
    
    ('security', 'session_timeout_minutes', '60', 'number', 'Admin session timeout in minutes', false),
    ('security', 'failed_login_attempts', '5', 'number', 'Max failed login attempts before lockout', false),
    ('security', 'lockout_duration_minutes', '30', 'number', 'Account lockout duration in minutes', false)
ON CONFLICT (category, key) DO NOTHING;

-- Insert default payment configuration
INSERT INTO public.payment_config (
    currency_code,
    currency_symbol,
    accepted_methods,
    test_mode
) VALUES (
    'USD',
    '$',
    '{
        "card": true,
        "apple_pay": true,
        "google_pay": true,
        "paypal": false,
        "bank_transfer": false,
        "cash_on_delivery": false
    }'::jsonb,
    true
) ON CONFLICT DO NOTHING;

-- Insert default shipping zones
INSERT INTO public.shipping_zones (name, description, countries) VALUES
    ('United States', 'Continental United States shipping', ARRAY['US']),
    ('International', 'International shipping to select countries', ARRAY['CA', 'GB', 'AU', 'DE', 'FR', 'IT', 'ES'])
ON CONFLICT (name) DO NOTHING;

-- Insert default shipping rates
WITH zone_ids AS (
    SELECT id, name FROM public.shipping_zones
)
INSERT INTO public.shipping_rates (
    zone_id, method_name, method_code, description, base_rate, 
    free_shipping_threshold, min_delivery_days, max_delivery_days
)
SELECT 
    zi.id,
    'Standard Shipping',
    'standard',
    'Standard ground shipping',
    7.99,
    100.00,
    5,
    7
FROM zone_ids zi WHERE zi.name = 'United States'
UNION ALL
SELECT 
    zi.id,
    'Express Shipping',
    'express', 
    'Expedited 2-3 day shipping',
    19.99,
    NULL,
    2,
    3
FROM zone_ids zi WHERE zi.name = 'United States'
UNION ALL
SELECT 
    zi.id,
    'International Standard',
    'international',
    'Standard international shipping',
    24.99,
    200.00,
    7,
    14
FROM zone_ids zi WHERE zi.name = 'International'
ON CONFLICT (zone_id, method_code) DO NOTHING;

-- Insert default tax rates for common US states
INSERT INTO public.tax_rates (country_code, state_code, region, tax_name, rate, is_active) VALUES
    ('US', 'NY', 'New York', 'Sales Tax', 0.0800, true),
    ('US', 'CA', 'California', 'Sales Tax', 0.0725, true),
    ('US', 'TX', 'Texas', 'Sales Tax', 0.0625, true),
    ('US', 'FL', 'Florida', 'Sales Tax', 0.0600, true),
    ('US', 'IL', 'Illinois', 'Sales Tax', 0.0625, true),
    ('US', 'PA', 'Pennsylvania', 'Sales Tax', 0.0600, true),
    ('US', 'OH', 'Ohio', 'Sales Tax', 0.0575, true),
    ('US', 'GA', 'Georgia', 'Sales Tax', 0.0400, true),
    ('US', 'NC', 'North Carolina', 'Sales Tax', 0.0475, true),
    ('US', 'MI', 'Michigan', 'Sales Tax', 0.0600, true)
ON CONFLICT DO NOTHING;

-- ============================================
-- GRANTS
-- ============================================
GRANT SELECT ON public.system_settings TO authenticated, anon;
GRANT ALL ON public.system_settings TO service_role;

GRANT SELECT ON public.store_config TO authenticated, anon;
GRANT ALL ON public.store_config TO service_role;

GRANT SELECT ON public.payment_config TO service_role; -- Highly restricted
GRANT ALL ON public.payment_config TO service_role;

GRANT SELECT ON public.shipping_zones TO authenticated, anon;
GRANT ALL ON public.shipping_zones TO authenticated, service_role;

GRANT SELECT ON public.shipping_rates TO authenticated, anon;
GRANT ALL ON public.shipping_rates TO authenticated, service_role;

GRANT SELECT ON public.tax_rates TO authenticated, anon;
GRANT ALL ON public.tax_rates TO authenticated, service_role;

GRANT SELECT ON public.settings_audit_log TO authenticated;
GRANT INSERT ON public.settings_audit_log TO authenticated, service_role;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION public.update_payment_keys(TEXT, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_payment_keys() TO authenticated;
GRANT EXECUTE ON FUNCTION public.calculate_shipping_rate(UUID, TEXT, DECIMAL, DECIMAL, INTEGER) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.get_tax_rate(TEXT, TEXT, TEXT, TEXT) TO authenticated, anon;

-- ============================================
-- VERIFICATION QUERY
-- ============================================
SELECT 
    'SETTINGS TABLES CREATED:' as info,
    schemaname,
    tablename,
    (SELECT COUNT(*) FROM pg_policies WHERE tablename = t.tablename) as policies_count,
    (SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_name LIKE '%' || t.tablename || '%') as triggers_count
FROM pg_tables t
WHERE schemaname = 'public'
AND tablename IN (
    'system_settings',
    'store_config', 
    'payment_config',
    'shipping_zones',
    'shipping_rates',
    'tax_rates',
    'settings_audit_log'
)
ORDER BY tablename;

-- Final verification of data
SELECT 'Seed data verification:' as info;
SELECT 'System settings count:' as type, COUNT(*) as count FROM public.system_settings;
SELECT 'Store configs count:' as type, COUNT(*) as count FROM public.store_config;
SELECT 'Payment configs count:' as type, COUNT(*) as count FROM public.payment_config;
SELECT 'Shipping zones count:' as type, COUNT(*) as count FROM public.shipping_zones;
SELECT 'Shipping rates count:' as type, COUNT(*) as count FROM public.shipping_rates;
SELECT 'Tax rates count:' as type, COUNT(*) as count FROM public.tax_rates;