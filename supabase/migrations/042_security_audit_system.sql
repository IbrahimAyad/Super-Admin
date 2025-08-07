-- ========================================
-- COMPREHENSIVE SECURITY AUDIT SYSTEM
-- ========================================
-- This migration creates a complete security audit system with:
-- - Admin activity logging for SOX/GDPR compliance
-- - Session management with device fingerprinting
-- - Login history and failed authentication tracking
-- - Security settings management (2FA, password policies)
-- - Security event logging and monitoring
-- - Password history tracking
-- ========================================

-- ===========================================
-- 1. ADMIN ACTIVITY LOG TABLE
-- ===========================================
-- Tracks all admin actions for compliance and audit
CREATE TABLE IF NOT EXISTS admin_activity_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    admin_id UUID NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
    action_type VARCHAR(100) NOT NULL, -- 'CREATE', 'UPDATE', 'DELETE', 'VIEW', 'LOGIN', 'LOGOUT'
    resource_type VARCHAR(100) NOT NULL, -- 'product', 'order', 'customer', 'admin', 'settings'
    resource_id UUID, -- ID of the affected resource
    resource_name VARCHAR(255), -- Human-readable resource identifier
    action_details JSONB DEFAULT '{}', -- Detailed action information
    old_values JSONB, -- Previous values for UPDATE actions
    new_values JSONB, -- New values for CREATE/UPDATE actions
    ip_address INET,
    user_agent TEXT,
    session_id UUID,
    request_id VARCHAR(255), -- For correlating with application logs
    severity VARCHAR(20) DEFAULT 'INFO' CHECK (severity IN ('LOW', 'INFO', 'WARN', 'HIGH', 'CRITICAL')),
    compliance_flag BOOLEAN DEFAULT false, -- Mark for compliance reporting
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    
    -- Constraints
    CONSTRAINT chk_action_type CHECK (action_type ~ '^[A-Z_]+$'),
    CONSTRAINT chk_resource_type CHECK (resource_type ~ '^[a-z_]+$')
);

-- Performance indexes for activity log
CREATE INDEX idx_admin_activity_log_admin_id ON admin_activity_log(admin_id, created_at DESC);
CREATE INDEX idx_admin_activity_log_action_type ON admin_activity_log(action_type, created_at DESC);
CREATE INDEX idx_admin_activity_log_resource ON admin_activity_log(resource_type, resource_id);
CREATE INDEX idx_admin_activity_log_created_at ON admin_activity_log(created_at DESC);
CREATE INDEX idx_admin_activity_log_severity ON admin_activity_log(severity, created_at DESC);
CREATE INDEX idx_admin_activity_log_compliance ON admin_activity_log(compliance_flag, created_at DESC) WHERE compliance_flag = true;
CREATE INDEX idx_admin_activity_log_ip_address ON admin_activity_log(ip_address, created_at DESC);
CREATE INDEX idx_admin_activity_log_session_id ON admin_activity_log(session_id) WHERE session_id IS NOT NULL;

-- Partial indexes for common queries
CREATE INDEX idx_admin_activity_log_recent_actions ON admin_activity_log(admin_id, action_type, created_at DESC) 
    WHERE created_at > NOW() - INTERVAL '30 days';

-- ===========================================
-- 2. ADMIN SESSIONS TABLE
-- ===========================================
-- Tracks active admin sessions with device fingerprinting
CREATE TABLE IF NOT EXISTS admin_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    admin_id UUID NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
    session_token VARCHAR(512) NOT NULL UNIQUE,
    refresh_token VARCHAR(512) UNIQUE,
    device_fingerprint VARCHAR(512), -- Browser/device fingerprint
    device_info JSONB DEFAULT '{}', -- Device details (OS, browser, etc.)
    ip_address INET NOT NULL,
    geolocation JSONB, -- Country, region, city if available
    user_agent TEXT,
    login_method VARCHAR(50) DEFAULT 'password' CHECK (login_method IN ('password', '2fa', 'sso', 'recovery')),
    is_active BOOLEAN DEFAULT true,
    last_activity_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    ended_at TIMESTAMPTZ,
    end_reason VARCHAR(50) CHECK (end_reason IN ('logout', 'timeout', 'revoked', 'expired', 'security')),
    
    -- Security flags
    is_suspicious BOOLEAN DEFAULT false,
    security_score INTEGER DEFAULT 100 CHECK (security_score >= 0 AND security_score <= 100),
    risk_factors TEXT[], -- Array of risk factors
    
    -- Constraints
    CONSTRAINT chk_session_state CHECK (
        (is_active = true AND ended_at IS NULL AND end_reason IS NULL) OR
        (is_active = false AND ended_at IS NOT NULL AND end_reason IS NOT NULL)
    )
);

-- Performance indexes for sessions
CREATE INDEX idx_admin_sessions_admin_id ON admin_sessions(admin_id, is_active, last_activity_at DESC);
CREATE INDEX idx_admin_sessions_token ON admin_sessions(session_token) WHERE is_active = true;
CREATE INDEX idx_admin_sessions_refresh_token ON admin_sessions(refresh_token) WHERE refresh_token IS NOT NULL;
CREATE INDEX idx_admin_sessions_device ON admin_sessions(device_fingerprint, admin_id);
CREATE INDEX idx_admin_sessions_ip ON admin_sessions(ip_address, created_at DESC);
CREATE INDEX idx_admin_sessions_expires_at ON admin_sessions(expires_at) WHERE is_active = true;
CREATE INDEX idx_admin_sessions_suspicious ON admin_sessions(is_suspicious, security_score) WHERE is_suspicious = true;
CREATE INDEX idx_admin_sessions_active ON admin_sessions(is_active, last_activity_at DESC) WHERE is_active = true;

-- ===========================================
-- 3. ADMIN LOGIN HISTORY TABLE
-- ===========================================
-- Comprehensive login/logout tracking
CREATE TABLE IF NOT EXISTS admin_login_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    admin_id UUID REFERENCES admin_users(id) ON DELETE SET NULL, -- Allow NULL for failed logins
    username VARCHAR(255), -- Store username for failed login attempts
    event_type VARCHAR(20) NOT NULL CHECK (event_type IN ('LOGIN_SUCCESS', 'LOGIN_FAILED', 'LOGOUT', 'FORCED_LOGOUT')),
    session_id UUID REFERENCES admin_sessions(id) ON DELETE SET NULL,
    ip_address INET NOT NULL,
    user_agent TEXT,
    geolocation JSONB,
    device_fingerprint VARCHAR(512),
    
    -- Authentication details
    auth_method VARCHAR(50) DEFAULT 'password' CHECK (auth_method IN ('password', '2fa', 'sso', 'recovery')),
    failure_reason VARCHAR(100), -- For failed logins: 'invalid_password', 'account_locked', '2fa_failed', etc.
    two_factor_used BOOLEAN DEFAULT false,
    
    -- Security assessment
    risk_score INTEGER DEFAULT 0 CHECK (risk_score >= 0 AND risk_score <= 100),
    is_anomalous BOOLEAN DEFAULT false,
    anomaly_reasons TEXT[], -- Reasons for flagging as anomalous
    
    -- Timing
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    session_duration INTERVAL, -- For logout events
    
    -- Additional context
    metadata JSONB DEFAULT '{}'
);

-- Performance indexes for login history
CREATE INDEX idx_admin_login_history_admin_id ON admin_login_history(admin_id, created_at DESC) WHERE admin_id IS NOT NULL;
CREATE INDEX idx_admin_login_history_username ON admin_login_history(username, created_at DESC) WHERE username IS NOT NULL;
CREATE INDEX idx_admin_login_history_event_type ON admin_login_history(event_type, created_at DESC);
CREATE INDEX idx_admin_login_history_ip ON admin_login_history(ip_address, created_at DESC);
CREATE INDEX idx_admin_login_history_failures ON admin_login_history(ip_address, event_type, created_at DESC) 
    WHERE event_type = 'LOGIN_FAILED';
CREATE INDEX idx_admin_login_history_anomalous ON admin_login_history(is_anomalous, risk_score DESC) WHERE is_anomalous = true;
CREATE INDEX idx_admin_login_history_session ON admin_login_history(session_id) WHERE session_id IS NOT NULL;

-- ===========================================
-- 4. ADMIN SECURITY SETTINGS TABLE
-- ===========================================
-- Individual security settings per admin
CREATE TABLE IF NOT EXISTS admin_security_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    admin_id UUID NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE UNIQUE,
    
    -- 2FA Settings
    two_factor_enabled BOOLEAN DEFAULT false,
    two_factor_secret VARCHAR(32), -- Base32 encoded secret
    two_factor_backup_codes TEXT[], -- Encrypted backup codes
    two_factor_method VARCHAR(20) DEFAULT 'totp' CHECK (two_factor_method IN ('totp', 'sms', 'email')),
    two_factor_phone VARCHAR(20),
    two_factor_last_used TIMESTAMPTZ,
    
    -- Password Policy Settings
    password_expires_at TIMESTAMPTZ,
    password_change_required BOOLEAN DEFAULT false,
    password_last_changed TIMESTAMPTZ DEFAULT NOW(),
    failed_login_attempts INTEGER DEFAULT 0,
    account_locked_until TIMESTAMPTZ,
    lockout_reason VARCHAR(100),
    
    -- Session Security
    max_concurrent_sessions INTEGER DEFAULT 3,
    session_timeout_minutes INTEGER DEFAULT 480, -- 8 hours
    require_fresh_auth_for_sensitive BOOLEAN DEFAULT true,
    
    -- IP Restrictions
    allowed_ip_ranges INET[], -- CIDR ranges
    ip_whitelist_enabled BOOLEAN DEFAULT false,
    
    -- Security Preferences
    email_security_alerts BOOLEAN DEFAULT true,
    login_notification_enabled BOOLEAN DEFAULT true,
    suspicious_activity_alerts BOOLEAN DEFAULT true,
    
    -- Compliance Settings
    gdpr_consent_given BOOLEAN DEFAULT false,
    gdpr_consent_date TIMESTAMPTZ,
    data_retention_days INTEGER DEFAULT 2555, -- 7 years default
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    last_security_check TIMESTAMPTZ DEFAULT NOW()
);

-- Performance indexes for security settings
CREATE INDEX idx_admin_security_settings_admin_id ON admin_security_settings(admin_id);
CREATE INDEX idx_admin_security_settings_2fa ON admin_security_settings(two_factor_enabled, admin_id);
CREATE INDEX idx_admin_security_settings_locked ON admin_security_settings(account_locked_until) WHERE account_locked_until IS NOT NULL;
CREATE INDEX idx_admin_security_settings_password_expires ON admin_security_settings(password_expires_at) WHERE password_expires_at IS NOT NULL;

-- ===========================================
-- 5. SECURITY EVENTS TABLE
-- ===========================================
-- High-level security events and incidents
CREATE TABLE IF NOT EXISTS security_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_type VARCHAR(100) NOT NULL, -- 'BRUTE_FORCE', 'SUSPICIOUS_LOGIN', 'PRIVILEGE_ESCALATION', etc.
    severity VARCHAR(20) NOT NULL DEFAULT 'MEDIUM' CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    status VARCHAR(20) DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'INVESTIGATING', 'RESOLVED', 'FALSE_POSITIVE')),
    
    -- Event details
    title VARCHAR(255) NOT NULL,
    description TEXT,
    affected_admin_id UUID REFERENCES admin_users(id) ON DELETE SET NULL,
    source_ip INET,
    source_country VARCHAR(2), -- ISO country code
    
    -- Detection details
    detection_method VARCHAR(50) DEFAULT 'automated', -- 'automated', 'manual', 'external'
    detection_rules TEXT[], -- Rules that triggered the event
    confidence_score INTEGER CHECK (confidence_score >= 0 AND confidence_score <= 100),
    
    -- Event data
    event_data JSONB DEFAULT '{}',
    related_sessions UUID[],
    related_activities UUID[], -- References to admin_activity_log
    
    -- Response tracking
    assigned_to UUID REFERENCES admin_users(id) ON DELETE SET NULL,
    resolved_by UUID REFERENCES admin_users(id) ON DELETE SET NULL,
    resolution_notes TEXT,
    actions_taken TEXT[],
    
    -- Timestamps
    first_detected_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    last_updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Performance indexes for security events
CREATE INDEX idx_security_events_type_severity ON security_events(event_type, severity, first_detected_at DESC);
CREATE INDEX idx_security_events_status ON security_events(status, first_detected_at DESC) WHERE status != 'RESOLVED';
CREATE INDEX idx_security_events_admin ON security_events(affected_admin_id, first_detected_at DESC) WHERE affected_admin_id IS NOT NULL;
CREATE INDEX idx_security_events_ip ON security_events(source_ip, first_detected_at DESC);
CREATE INDEX idx_security_events_assigned ON security_events(assigned_to) WHERE assigned_to IS NOT NULL AND status != 'RESOLVED';
CREATE INDEX idx_security_events_confidence ON security_events(confidence_score DESC, first_detected_at DESC);

-- ===========================================
-- 6. ADMIN PASSWORD HISTORY TABLE
-- ===========================================
-- Prevents password reuse for enhanced security
CREATE TABLE IF NOT EXISTS admin_password_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    admin_id UUID NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
    password_hash VARCHAR(255) NOT NULL, -- Hashed password
    hash_algorithm VARCHAR(50) DEFAULT 'bcrypt',
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    created_by UUID REFERENCES admin_users(id), -- Who changed the password
    change_reason VARCHAR(100), -- 'routine', 'forced', 'reset', 'security'
    
    -- Prevent duplicate entries
    UNIQUE(admin_id, password_hash)
);

-- Performance indexes for password history
CREATE INDEX idx_admin_password_history_admin_id ON admin_password_history(admin_id, created_at DESC);
CREATE INDEX idx_admin_password_history_hash ON admin_password_history(password_hash); -- For duplicate checking

-- ===========================================
-- SECURITY FUNCTIONS
-- ===========================================

-- Function: Check failed login attempts
CREATE OR REPLACE FUNCTION check_failed_login_attempts(p_admin_id UUID, p_ip_address INET, p_time_window INTERVAL DEFAULT '1 hour')
RETURNS JSON AS $$
DECLARE
    user_failures INTEGER;
    ip_failures INTEGER;
    result JSON;
BEGIN
    -- Count failed attempts by user
    SELECT COUNT(*)
    INTO user_failures
    FROM admin_login_history
    WHERE admin_id = p_admin_id
      AND event_type = 'LOGIN_FAILED'
      AND created_at > NOW() - p_time_window;
    
    -- Count failed attempts by IP
    SELECT COUNT(*)
    INTO ip_failures
    FROM admin_login_history
    WHERE ip_address = p_ip_address
      AND event_type = 'LOGIN_FAILED'
      AND created_at > NOW() - p_time_window;
    
    result := json_build_object(
        'user_failures', user_failures,
        'ip_failures', ip_failures,
        'time_window_hours', EXTRACT(EPOCH FROM p_time_window) / 3600,
        'should_lock_user', user_failures >= 5,
        'should_block_ip', ip_failures >= 10
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Validate admin session
CREATE OR REPLACE FUNCTION validate_admin_session(p_session_token VARCHAR)
RETURNS JSON AS $$
DECLARE
    session_record admin_sessions%ROWTYPE;
    admin_record admin_users%ROWTYPE;
    result JSON;
BEGIN
    -- Get session details
    SELECT * INTO session_record
    FROM admin_sessions
    WHERE session_token = p_session_token
      AND is_active = true
      AND expires_at > NOW();
    
    IF NOT FOUND THEN
        RETURN json_build_object(
            'valid', false,
            'reason', 'session_not_found_or_expired'
        );
    END IF;
    
    -- Get admin details
    SELECT * INTO admin_record
    FROM admin_users
    WHERE id = session_record.admin_id
      AND is_active = true;
    
    IF NOT FOUND THEN
        -- Deactivate session
        UPDATE admin_sessions
        SET is_active = false, ended_at = NOW(), end_reason = 'security'
        WHERE id = session_record.id;
        
        RETURN json_build_object(
            'valid', false,
            'reason', 'admin_inactive'
        );
    END IF;
    
    -- Update last activity
    UPDATE admin_sessions
    SET last_activity_at = NOW()
    WHERE id = session_record.id;
    
    result := json_build_object(
        'valid', true,
        'admin_id', admin_record.id,
        'admin_role', admin_record.role,
        'session_id', session_record.id,
        'expires_at', session_record.expires_at,
        'security_score', session_record.security_score
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Check password history
CREATE OR REPLACE FUNCTION check_password_reuse(p_admin_id UUID, p_password_hash VARCHAR, p_history_limit INTEGER DEFAULT 12)
RETURNS BOOLEAN AS $$
DECLARE
    hash_exists BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1
        FROM admin_password_history
        WHERE admin_id = p_admin_id
          AND password_hash = p_password_hash
        ORDER BY created_at DESC
        LIMIT p_history_limit
    ) INTO hash_exists;
    
    RETURN hash_exists;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Create security event
CREATE OR REPLACE FUNCTION create_security_event(
    p_event_type VARCHAR,
    p_severity VARCHAR,
    p_title VARCHAR,
    p_description TEXT DEFAULT NULL,
    p_affected_admin_id UUID DEFAULT NULL,
    p_source_ip INET DEFAULT NULL,
    p_event_data JSONB DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
    event_id UUID;
BEGIN
    INSERT INTO security_events (
        event_type, severity, title, description,
        affected_admin_id, source_ip, event_data
    )
    VALUES (
        p_event_type, p_severity, p_title, p_description,
        p_affected_admin_id, p_source_ip, p_event_data
    )
    RETURNING id INTO event_id;
    
    -- Log to activity log if admin is involved
    IF p_affected_admin_id IS NOT NULL THEN
        INSERT INTO admin_activity_log (
            admin_id, action_type, resource_type, resource_id,
            action_details, severity, compliance_flag
        )
        VALUES (
            p_affected_admin_id, 'SECURITY_EVENT', 'security_event', event_id,
            json_build_object('event_type', p_event_type, 'title', p_title),
            p_severity, true
        );
    END IF;
    
    RETURN event_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Clean up old audit data
CREATE OR REPLACE FUNCTION cleanup_audit_data(p_retention_days INTEGER DEFAULT 2555) -- 7 years
RETURNS JSON AS $$
DECLARE
    cutoff_date TIMESTAMPTZ;
    deleted_counts JSON;
    activity_deleted INTEGER;
    login_deleted INTEGER;
    password_deleted INTEGER;
    session_deleted INTEGER;
BEGIN
    cutoff_date := NOW() - (p_retention_days || ' days')::INTERVAL;
    
    -- Clean up activity logs
    DELETE FROM admin_activity_log
    WHERE created_at < cutoff_date
      AND compliance_flag = false; -- Keep compliance-flagged records
    GET DIAGNOSTICS activity_deleted = ROW_COUNT;
    
    -- Clean up login history
    DELETE FROM admin_login_history
    WHERE created_at < cutoff_date;
    GET DIAGNOSTICS login_deleted = ROW_COUNT;
    
    -- Clean up old password history (keep last 12 per user)
    WITH password_to_delete AS (
        SELECT id
        FROM (
            SELECT id,
                   ROW_NUMBER() OVER (PARTITION BY admin_id ORDER BY created_at DESC) as rn
            FROM admin_password_history
        ) ranked
        WHERE rn > 12 OR created_at < cutoff_date
    )
    DELETE FROM admin_password_history
    WHERE id IN (SELECT id FROM password_to_delete);
    GET DIAGNOSTICS password_deleted = ROW_COUNT;
    
    -- Clean up ended sessions
    DELETE FROM admin_sessions
    WHERE is_active = false
      AND ended_at < cutoff_date;
    GET DIAGNOSTICS session_deleted = ROW_COUNT;
    
    deleted_counts := json_build_object(
        'activity_logs', activity_deleted,
        'login_history', login_deleted,
        'password_history', password_deleted,
        'ended_sessions', session_deleted,
        'retention_days', p_retention_days,
        'cutoff_date', cutoff_date
    );
    
    -- Log cleanup operation
    INSERT INTO system_logs (operation, details)
    VALUES ('audit_data_cleanup', deleted_counts);
    
    RETURN deleted_counts;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- AUDIT TRIGGERS
-- ===========================================

-- Generic audit trigger function
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
DECLARE
    admin_id_val UUID;
    old_data JSON;
    new_data JSON;
    action_type VARCHAR;
BEGIN
    -- Determine admin ID from context
    admin_id_val := COALESCE(
        NULLIF(current_setting('app.current_admin_id', true), ''),
        auth.uid()
    )::UUID;
    
    -- Skip if no admin context
    IF admin_id_val IS NULL THEN
        IF TG_OP = 'DELETE' THEN
            RETURN OLD;
        ELSE
            RETURN NEW;
        END IF;
    END IF;
    
    -- Determine action type
    IF TG_OP = 'INSERT' THEN
        action_type := 'CREATE';
        new_data := row_to_json(NEW);
        old_data := NULL;
    ELSIF TG_OP = 'UPDATE' THEN
        action_type := 'UPDATE';
        old_data := row_to_json(OLD);
        new_data := row_to_json(NEW);
    ELSIF TG_OP = 'DELETE' THEN
        action_type := 'DELETE';
        old_data := row_to_json(OLD);
        new_data := NULL;
    END IF;
    
    -- Insert audit log
    INSERT INTO admin_activity_log (
        admin_id,
        action_type,
        resource_type,
        resource_id,
        resource_name,
        old_values,
        new_values,
        action_details,
        compliance_flag
    )
    VALUES (
        admin_id_val,
        action_type,
        TG_TABLE_NAME,
        COALESCE((NEW).id, (OLD).id),
        COALESCE(
            (NEW).name,
            (NEW).title,
            (NEW).email,
            (OLD).name,
            (OLD).title,
            (OLD).email
        ),
        old_data,
        new_data,
        json_build_object(
            'table', TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
            'operation', TG_OP,
            'timestamp', NOW()
        ),
        true -- Mark as compliance-relevant
    );
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply audit triggers to sensitive tables
-- (Add to existing tables - modify as needed based on your schema)
-- CREATE TRIGGER audit_admin_users AFTER INSERT OR UPDATE OR DELETE ON admin_users
--     FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- CREATE TRIGGER audit_products AFTER INSERT OR UPDATE OR DELETE ON products
--     FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- CREATE TRIGGER audit_orders AFTER INSERT OR UPDATE OR DELETE ON orders
--     FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- ===========================================
-- ROW LEVEL SECURITY POLICIES
-- ===========================================

-- Enable RLS on all security tables
ALTER TABLE admin_activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_login_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_security_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE security_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_password_history ENABLE ROW LEVEL SECURITY;

-- Admin Activity Log Policies
CREATE POLICY "Super admins can view all activity logs" ON admin_activity_log
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_users
            WHERE user_id = auth.uid()
            AND role = 'super_admin'
            AND is_active = true
        )
    );

CREATE POLICY "Admins can view own activity logs" ON admin_activity_log
    FOR SELECT USING (
        admin_id IN (
            SELECT id FROM admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    );

CREATE POLICY "Service role can manage activity logs" ON admin_activity_log
    FOR ALL USING (auth.role() = 'service_role');

-- Admin Sessions Policies
CREATE POLICY "Admins can view own sessions" ON admin_sessions
    FOR SELECT USING (
        admin_id IN (
            SELECT id FROM admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    );

CREATE POLICY "Super admins can view all sessions" ON admin_sessions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_users
            WHERE user_id = auth.uid()
            AND role = 'super_admin'
            AND is_active = true
        )
    );

CREATE POLICY "Service role can manage sessions" ON admin_sessions
    FOR ALL USING (auth.role() = 'service_role');

-- Login History Policies
CREATE POLICY "Admins can view own login history" ON admin_login_history
    FOR SELECT USING (
        admin_id IN (
            SELECT id FROM admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    );

CREATE POLICY "Super admins can view all login history" ON admin_login_history
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_users
            WHERE user_id = auth.uid()
            AND role = 'super_admin'
            AND is_active = true
        )
    );

CREATE POLICY "Service role can manage login history" ON admin_login_history
    FOR ALL USING (auth.role() = 'service_role');

-- Security Settings Policies
CREATE POLICY "Admins can view own security settings" ON admin_security_settings
    FOR SELECT USING (
        admin_id IN (
            SELECT id FROM admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    );

CREATE POLICY "Admins can update own security settings" ON admin_security_settings
    FOR UPDATE USING (
        admin_id IN (
            SELECT id FROM admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    );

CREATE POLICY "Super admins can manage all security settings" ON admin_security_settings
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_users
            WHERE user_id = auth.uid()
            AND role = 'super_admin'
            AND is_active = true
        )
    );

CREATE POLICY "Service role can manage security settings" ON admin_security_settings
    FOR ALL USING (auth.role() = 'service_role');

-- Security Events Policies
CREATE POLICY "Super admins can view all security events" ON security_events
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_users
            WHERE user_id = auth.uid()
            AND role = 'super_admin'
            AND is_active = true
        )
    );

CREATE POLICY "Admins can view events affecting them" ON security_events
    FOR SELECT USING (
        affected_admin_id IN (
            SELECT id FROM admin_users
            WHERE user_id = auth.uid()
            AND is_active = true
        )
    );

CREATE POLICY "Service role can manage security events" ON security_events
    FOR ALL USING (auth.role() = 'service_role');

-- Password History Policies (most restrictive)
CREATE POLICY "Super admins can view password history" ON admin_password_history
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_users
            WHERE user_id = auth.uid()
            AND role = 'super_admin'
            AND is_active = true
        )
    );

CREATE POLICY "Service role can manage password history" ON admin_password_history
    FOR ALL USING (auth.role() = 'service_role');

-- ===========================================
-- GRANT PERMISSIONS
-- ===========================================

-- Grant permissions to authenticated users
GRANT SELECT ON admin_activity_log TO authenticated;
GRANT SELECT ON admin_sessions TO authenticated;
GRANT SELECT ON admin_login_history TO authenticated;
GRANT SELECT, UPDATE ON admin_security_settings TO authenticated;
GRANT SELECT ON security_events TO authenticated;

-- Grant full permissions to service role
GRANT ALL ON admin_activity_log TO service_role;
GRANT ALL ON admin_sessions TO service_role;
GRANT ALL ON admin_login_history TO service_role;
GRANT ALL ON admin_security_settings TO service_role;
GRANT ALL ON security_events TO service_role;
GRANT ALL ON admin_password_history TO service_role;

-- Grant function execution permissions
GRANT EXECUTE ON FUNCTION check_failed_login_attempts(UUID, INET, INTERVAL) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION validate_admin_session(VARCHAR) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION check_password_reuse(UUID, VARCHAR, INTEGER) TO service_role;
GRANT EXECUTE ON FUNCTION create_security_event(VARCHAR, VARCHAR, VARCHAR, TEXT, UUID, INET, JSONB) TO service_role;
GRANT EXECUTE ON FUNCTION cleanup_audit_data(INTEGER) TO service_role;

-- ===========================================
-- UPDATE TRIGGERS
-- ===========================================

-- Update triggers for timestamp management
CREATE TRIGGER update_admin_security_settings_updated_at
    BEFORE UPDATE ON admin_security_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_security_events_updated_at
    BEFORE UPDATE ON security_events
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ===========================================
-- INITIAL DATA AND CONFIGURATION
-- ===========================================

-- Insert initial log entry
INSERT INTO system_logs (operation, details)
VALUES ('security_audit_system_setup', json_build_object(
    'message', 'Security audit system tables and functions created',
    'tables_created', ARRAY[
        'admin_activity_log',
        'admin_sessions', 
        'admin_login_history',
        'admin_security_settings',
        'security_events',
        'admin_password_history'
    ],
    'version', '1.0.0',
    'compliance_ready', true,
    'created_at', NOW()
));

-- Create default security settings for existing admins
INSERT INTO admin_security_settings (admin_id)
SELECT id FROM admin_users
WHERE id NOT IN (SELECT admin_id FROM admin_security_settings);

-- ===========================================
-- PERFORMANCE OPTIMIZATION VIEWS
-- ===========================================

-- View for recent admin activity (last 30 days)
CREATE OR REPLACE VIEW admin_activity_recent AS
SELECT 
    aal.id,
    au.role as admin_role,
    COALESCE(au_profile.email, 'unknown') as admin_email,
    aal.action_type,
    aal.resource_type,
    aal.resource_name,
    aal.severity,
    aal.ip_address,
    aal.created_at
FROM admin_activity_log aal
JOIN admin_users au ON aal.admin_id = au.id
LEFT JOIN auth.users au_profile ON au.user_id = au_profile.id
WHERE aal.created_at > NOW() - INTERVAL '30 days'
ORDER BY aal.created_at DESC;

-- View for active admin sessions
CREATE OR REPLACE VIEW admin_sessions_active AS
SELECT 
    s.id,
    au.role as admin_role,
    COALESCE(au_profile.email, 'unknown') as admin_email,
    s.ip_address,
    s.device_info,
    s.last_activity_at,
    s.expires_at,
    s.security_score,
    s.is_suspicious,
    NOW() - s.last_activity_at as idle_duration
FROM admin_sessions s
JOIN admin_users au ON s.admin_id = au.id
LEFT JOIN auth.users au_profile ON au.user_id = au_profile.id
WHERE s.is_active = true
ORDER BY s.last_activity_at DESC;

-- View for security event dashboard
CREATE OR REPLACE VIEW security_events_dashboard AS
SELECT 
    event_type,
    severity,
    status,
    COUNT(*) as event_count,
    MAX(first_detected_at) as last_occurrence,
    AVG(confidence_score) as avg_confidence
FROM security_events
WHERE first_detected_at > NOW() - INTERVAL '7 days'
GROUP BY event_type, severity, status
ORDER BY 
    CASE severity 
        WHEN 'CRITICAL' THEN 1 
        WHEN 'HIGH' THEN 2 
        WHEN 'MEDIUM' THEN 3 
        WHEN 'LOW' THEN 4 
    END,
    event_count DESC;

-- ===========================================
-- COMMENTS FOR DOCUMENTATION
-- ===========================================

COMMENT ON TABLE admin_activity_log IS 'Comprehensive audit log of all admin actions for compliance and security monitoring';
COMMENT ON TABLE admin_sessions IS 'Active and historical admin sessions with device fingerprinting and security scoring';
COMMENT ON TABLE admin_login_history IS 'Login/logout events and failed authentication attempts with anomaly detection';
COMMENT ON TABLE admin_security_settings IS 'Individual security configuration per admin including 2FA and password policies';
COMMENT ON TABLE security_events IS 'High-level security incidents and events requiring investigation';
COMMENT ON TABLE admin_password_history IS 'Password history to prevent reuse and maintain security standards';

COMMENT ON FUNCTION check_failed_login_attempts IS 'Analyzes failed login attempts for brute force detection';
COMMENT ON FUNCTION validate_admin_session IS 'Validates and updates admin session activity';
COMMENT ON FUNCTION check_password_reuse IS 'Prevents password reuse by checking against history';
COMMENT ON FUNCTION create_security_event IS 'Creates security events with automatic activity logging';
COMMENT ON FUNCTION cleanup_audit_data IS 'Automated cleanup of old audit data with configurable retention';

-- End of security audit system migration