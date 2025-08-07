-- Settings System Migration
-- Creates comprehensive settings infrastructure with security and audit logging

-- Create settings table
CREATE TABLE IF NOT EXISTS settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    key VARCHAR(255) NOT NULL UNIQUE,
    value JSONB NOT NULL,
    category VARCHAR(100) NOT NULL DEFAULT 'general',
    description TEXT,
    data_type VARCHAR(50) NOT NULL DEFAULT 'string', -- string, number, boolean, json, encrypted
    is_public BOOLEAN NOT NULL DEFAULT false,
    is_sensitive BOOLEAN NOT NULL DEFAULT false,
    validation_schema JSONB, -- JSON schema for validation
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id)
);

-- Create settings audit log
CREATE TABLE IF NOT EXISTS settings_audit_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    setting_key VARCHAR(255) NOT NULL,
    old_value JSONB,
    new_value JSONB,
    action VARCHAR(50) NOT NULL, -- insert, update, delete
    changed_by UUID REFERENCES auth.users(id),
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ip_address INET,
    user_agent TEXT
);

-- Create settings cache table for website sync
CREATE TABLE IF NOT EXISTS settings_cache (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    cache_key VARCHAR(255) NOT NULL UNIQUE,
    cache_data JSONB NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indices for performance
CREATE INDEX IF NOT EXISTS idx_settings_key ON settings(key);
CREATE INDEX IF NOT EXISTS idx_settings_category ON settings(category);
CREATE INDEX IF NOT EXISTS idx_settings_public ON settings(is_public);
CREATE INDEX IF NOT EXISTS idx_settings_updated_at ON settings(updated_at);
CREATE INDEX IF NOT EXISTS idx_settings_audit_log_key ON settings_audit_log(setting_key);
CREATE INDEX IF NOT EXISTS idx_settings_audit_log_changed_at ON settings_audit_log(changed_at);
CREATE INDEX IF NOT EXISTS idx_settings_cache_expires ON settings_cache(expires_at);

-- Enable RLS
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings_cache ENABLE ROW LEVEL SECURITY;

-- RLS Policies for settings table
DROP POLICY IF EXISTS "Admin users can manage all settings" ON settings;
CREATE POLICY "Admin users can manage all settings" ON settings
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE auth.uid() = user_id 
            AND role = 'admin'
        )
    );

DROP POLICY IF EXISTS "Public settings readable by all" ON settings;
CREATE POLICY "Public settings readable by all" ON settings
    FOR SELECT USING (is_public = true);

-- RLS Policies for audit log
DROP POLICY IF EXISTS "Admin users can read audit log" ON settings_audit_log;
CREATE POLICY "Admin users can read audit log" ON settings_audit_log
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE auth.uid() = user_id 
            AND role = 'admin'
        )
    );

DROP POLICY IF EXISTS "System can insert audit log" ON settings_audit_log;
CREATE POLICY "System can insert audit log" ON settings_audit_log
    FOR INSERT WITH CHECK (true);

-- RLS Policies for cache table
DROP POLICY IF EXISTS "Public cache readable by all" ON settings_cache;
CREATE POLICY "Public cache readable by all" ON settings_cache
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admin users can manage cache" ON settings_cache;
CREATE POLICY "Admin users can manage cache" ON settings_cache
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE auth.uid() = user_id 
            AND role = 'admin'
        )
    );

-- Create function to update settings with audit logging
CREATE OR REPLACE FUNCTION update_setting_with_audit(
    p_key VARCHAR(255),
    p_value JSONB,
    p_user_id UUID DEFAULT auth.uid(),
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
    old_record settings%ROWTYPE;
BEGIN
    -- Get old value for audit
    SELECT * INTO old_record FROM settings WHERE key = p_key;
    
    -- Update or insert setting
    INSERT INTO settings (key, value, updated_by, updated_at)
    VALUES (p_key, p_value, p_user_id, NOW())
    ON CONFLICT (key) 
    DO UPDATE SET 
        value = EXCLUDED.value,
        updated_by = EXCLUDED.updated_by,
        updated_at = EXCLUDED.updated_at;
    
    -- Log the change
    INSERT INTO settings_audit_log (
        setting_key, 
        old_value, 
        new_value, 
        action,
        changed_by,
        ip_address,
        user_agent
    ) VALUES (
        p_key,
        CASE WHEN old_record.key IS NOT NULL THEN old_record.value ELSE NULL END,
        p_value,
        CASE WHEN old_record.key IS NOT NULL THEN 'update' ELSE 'insert' END,
        p_user_id,
        p_ip_address,
        p_user_agent
    );
    
    -- Invalidate cache
    DELETE FROM settings_cache WHERE cache_key LIKE '%public_settings%';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to get public settings (cached)
CREATE OR REPLACE FUNCTION get_public_settings_cached()
RETURNS JSONB AS $$
DECLARE
    cached_data JSONB;
    cache_expires_at TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Try to get from cache first
    SELECT cache_data, expires_at 
    INTO cached_data, cache_expires_at
    FROM settings_cache 
    WHERE cache_key = 'public_settings' 
    AND expires_at > NOW();
    
    -- Return cached data if valid
    IF cached_data IS NOT NULL THEN
        RETURN cached_data;
    END IF;
    
    -- Build fresh data
    SELECT jsonb_object_agg(key, value) INTO cached_data
    FROM settings 
    WHERE is_public = true AND is_sensitive = false;
    
    -- Cache the result for 5 minutes
    INSERT INTO settings_cache (cache_key, cache_data, expires_at)
    VALUES ('public_settings', cached_data, NOW() + INTERVAL '5 minutes')
    ON CONFLICT (cache_key) 
    DO UPDATE SET 
        cache_data = EXCLUDED.cache_data,
        expires_at = EXCLUDED.expires_at,
        created_at = NOW();
    
    RETURN cached_data;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to validate settings based on schema
CREATE OR REPLACE FUNCTION validate_setting_value(
    p_key VARCHAR(255),
    p_value JSONB
) RETURNS BOOLEAN AS $$
DECLARE
    setting_record settings%ROWTYPE;
BEGIN
    SELECT * INTO setting_record FROM settings WHERE key = p_key;
    
    -- If no existing setting, allow any value
    IF setting_record.key IS NULL THEN
        RETURN true;
    END IF;
    
    -- Basic type validation
    CASE setting_record.data_type
        WHEN 'string' THEN
            IF jsonb_typeof(p_value) != 'string' THEN
                RETURN false;
            END IF;
        WHEN 'number' THEN
            IF jsonb_typeof(p_value) != 'number' THEN
                RETURN false;
            END IF;
        WHEN 'boolean' THEN
            IF jsonb_typeof(p_value) != 'boolean' THEN
                RETURN false;
            END IF;
        WHEN 'json' THEN
            IF jsonb_typeof(p_value) NOT IN ('object', 'array') THEN
                RETURN false;
            END IF;
    END CASE;
    
    -- TODO: Add JSON schema validation here if needed
    -- This would require a JSON schema validation extension
    
    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_settings_updated_at ON settings;
CREATE TRIGGER tr_settings_updated_at
    BEFORE UPDATE ON settings
    FOR EACH ROW
    EXECUTE FUNCTION update_settings_updated_at();

-- Insert default settings
INSERT INTO settings (key, value, category, description, data_type, is_public) VALUES
('site_name', '"KCT Menswear"', 'general', 'Site display name', 'string', true),
('site_tagline', '"Premium menswear for the modern gentleman"', 'general', 'Site tagline/description', 'string', true),
('currency', '"USD"', 'commerce', 'Default currency', 'string', true),
('tax_rate', '0.08', 'commerce', 'Default tax rate', 'number', false),
('free_shipping_threshold', '100', 'commerce', 'Minimum order for free shipping', 'number', true),
('maintenance_mode', 'false', 'system', 'Enable maintenance mode', 'boolean', true),
('max_cart_items', '50', 'commerce', 'Maximum items per cart', 'number', true),
('session_timeout', '30', 'security', 'Session timeout in minutes', 'number', false),
('email_notifications', 'true', 'notifications', 'Enable email notifications', 'boolean', false),
('analytics_enabled', 'true', 'analytics', 'Enable analytics tracking', 'boolean', true)
ON CONFLICT (key) DO NOTHING;

RAISE NOTICE 'Settings system created successfully with audit logging and caching!';