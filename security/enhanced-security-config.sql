-- Enhanced Security Configuration for KCT Menswear E-commerce System
-- Production-ready security hardening and monitoring setup
-- Version: 1.0.0
-- Date: 2025-08-13

-- =============================================================================
-- 1. SECURITY AUDIT AND MONITORING TABLES
-- =============================================================================

-- Enhanced security events table for comprehensive monitoring
CREATE TABLE IF NOT EXISTS public.security_audit_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    event_type TEXT NOT NULL,
    severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    user_id UUID REFERENCES auth.users(id),
    admin_user_id UUID REFERENCES public.admin_users(id),
    ip_address INET,
    user_agent TEXT,
    location JSONB,
    event_data JSONB DEFAULT '{}',
    risk_score INTEGER DEFAULT 0 CHECK (risk_score >= 0 AND risk_score <= 100),
    automated_response TEXT,
    investigation_status TEXT DEFAULT 'new' CHECK (investigation_status IN ('new', 'investigating', 'resolved', 'false_positive')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    resolved_by UUID REFERENCES public.admin_users(id)
);

-- Security metrics aggregation table
CREATE TABLE IF NOT EXISTS public.security_metrics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    metric_type TEXT NOT NULL,
    metric_value DECIMAL NOT NULL,
    time_window TEXT NOT NULL, -- '1h', '24h', '7d', etc.
    dimensions JSONB DEFAULT '{}',
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Failed access attempts tracking
CREATE TABLE IF NOT EXISTS public.access_violations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    violation_type TEXT NOT NULL,
    resource_type TEXT NOT NULL,
    resource_id TEXT,
    user_identifier TEXT, -- email, IP, or user ID
    ip_address INET,
    user_agent TEXT,
    attempt_count INTEGER DEFAULT 1,
    first_attempt_at TIMESTAMPTZ DEFAULT NOW(),
    last_attempt_at TIMESTAMPTZ DEFAULT NOW(),
    blocked_until TIMESTAMPTZ,
    is_permanently_blocked BOOLEAN DEFAULT FALSE,
    notes TEXT
);

-- =============================================================================
-- 2. ENHANCED RLS POLICIES WITH SECURITY LOGGING
-- =============================================================================

-- Enable RLS on security tables
ALTER TABLE public.security_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.access_violations ENABLE ROW LEVEL SECURITY;

-- RLS policies for security audit log
CREATE POLICY "Super admins can view all security logs" ON public.security_audit_log
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.admin_users 
            WHERE id = auth.uid() 
            AND role = 'super_admin' 
            AND is_active = true
        )
    );

CREATE POLICY "Security admins can view security logs" ON public.security_audit_log
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.admin_users 
            WHERE id = auth.uid() 
            AND role IN ('super_admin', 'admin')
            AND permissions ? 'security.view'
            AND is_active = true
        )
    );

-- =============================================================================
-- 3. ADVANCED SECURITY FUNCTIONS
-- =============================================================================

-- Function to log security events with automatic risk assessment
CREATE OR REPLACE FUNCTION log_security_event(
    p_event_type TEXT,
    p_event_data JSONB DEFAULT '{}',
    p_user_id UUID DEFAULT NULL,
    p_admin_user_id UUID DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL,
    p_severity TEXT DEFAULT 'medium'
) RETURNS UUID AS $$
DECLARE
    v_event_id UUID;
    v_risk_score INTEGER;
    v_automated_response TEXT;
BEGIN
    -- Calculate risk score based on event type and context
    SELECT calculate_risk_score(p_event_type, p_event_data, p_ip_address) INTO v_risk_score;
    
    -- Determine automated response
    SELECT determine_automated_response(p_event_type, v_risk_score, p_event_data) INTO v_automated_response;
    
    -- Insert security event
    INSERT INTO public.security_audit_log (
        event_type, severity, user_id, admin_user_id, ip_address, 
        user_agent, event_data, risk_score, automated_response
    ) VALUES (
        p_event_type, p_severity, p_user_id, p_admin_user_id, p_ip_address,
        p_user_agent, p_event_data, v_risk_score, v_automated_response
    ) RETURNING id INTO v_event_id;
    
    -- Execute automated response if required
    IF v_automated_response IS NOT NULL THEN
        PERFORM execute_automated_response(v_automated_response, p_event_data);
    END IF;
    
    -- Update security metrics
    PERFORM update_security_metrics(p_event_type, v_risk_score);
    
    RETURN v_event_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Risk score calculation function
CREATE OR REPLACE FUNCTION calculate_risk_score(
    p_event_type TEXT,
    p_event_data JSONB,
    p_ip_address INET
) RETURNS INTEGER AS $$
DECLARE
    v_risk_score INTEGER := 0;
    v_is_known_bad_ip BOOLEAN;
    v_recent_violations INTEGER;
BEGIN
    -- Base risk scores by event type
    CASE p_event_type
        WHEN 'login_failure' THEN v_risk_score := 20;
        WHEN 'multiple_login_failures' THEN v_risk_score := 60;
        WHEN 'suspicious_login' THEN v_risk_score := 40;
        WHEN 'admin_privilege_escalation' THEN v_risk_score := 90;
        WHEN 'database_access_violation' THEN v_risk_score := 80;
        WHEN 'payment_fraud_attempt' THEN v_risk_score := 95;
        WHEN 'data_export_anomaly' THEN v_risk_score := 70;
        WHEN 'api_abuse' THEN v_risk_score := 50;
        WHEN 'injection_attempt' THEN v_risk_score := 85;
        ELSE v_risk_score := 30;
    END CASE;
    
    -- Check if IP is in known bad actors list
    SELECT EXISTS (
        SELECT 1 FROM public.access_violations 
        WHERE ip_address = p_ip_address 
        AND is_permanently_blocked = true
    ) INTO v_is_known_bad_ip;
    
    IF v_is_known_bad_ip THEN
        v_risk_score := v_risk_score + 30;
    END IF;
    
    -- Check for recent violations from same IP
    SELECT COUNT(*) FROM public.security_audit_log 
    WHERE ip_address = p_ip_address 
    AND created_at > NOW() - INTERVAL '1 hour'
    AND risk_score > 50
    INTO v_recent_violations;
    
    IF v_recent_violations > 5 THEN
        v_risk_score := v_risk_score + 20;
    END IF;
    
    -- Additional context-based risk factors
    IF p_event_data ? 'multiple_countries' AND (p_event_data->>'multiple_countries')::boolean THEN
        v_risk_score := v_risk_score + 25;
    END IF;
    
    IF p_event_data ? 'unusual_time' AND (p_event_data->>'unusual_time')::boolean THEN
        v_risk_score := v_risk_score + 15;
    END IF;
    
    -- Cap at 100
    RETURN LEAST(v_risk_score, 100);
END;
$$ LANGUAGE plpgsql;

-- Automated response determination function
CREATE OR REPLACE FUNCTION determine_automated_response(
    p_event_type TEXT,
    p_risk_score INTEGER,
    p_event_data JSONB
) RETURNS TEXT AS $$
BEGIN
    -- High-risk events get immediate response
    IF p_risk_score >= 80 THEN
        CASE p_event_type
            WHEN 'admin_privilege_escalation' THEN 
                RETURN 'block_user_immediate';
            WHEN 'payment_fraud_attempt' THEN 
                RETURN 'block_payment_and_notify';
            WHEN 'injection_attempt' THEN 
                RETURN 'block_ip_and_alert';
            WHEN 'database_access_violation' THEN 
                RETURN 'revoke_access_and_alert';
            ELSE 
                RETURN 'alert_security_team';
        END CASE;
    END IF;
    
    -- Medium-risk events get rate limiting
    IF p_risk_score >= 50 THEN
        RETURN 'apply_rate_limiting';
    END IF;
    
    -- Low-risk events just get logged
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Execute automated response function
CREATE OR REPLACE FUNCTION execute_automated_response(
    p_response_type TEXT,
    p_event_data JSONB
) RETURNS VOID AS $$
BEGIN
    CASE p_response_type
        WHEN 'block_user_immediate' THEN
            -- Block user account immediately
            IF p_event_data ? 'user_id' THEN
                UPDATE auth.users 
                SET banned_until = NOW() + INTERVAL '24 hours'
                WHERE id = (p_event_data->>'user_id')::UUID;
            END IF;
            
        WHEN 'block_payment_and_notify' THEN
            -- Block payment processing and notify
            -- Implementation depends on payment processor integration
            NULL;
            
        WHEN 'block_ip_and_alert' THEN
            -- Add IP to blocked list
            IF p_event_data ? 'ip_address' THEN
                INSERT INTO public.access_violations (
                    violation_type, resource_type, ip_address, 
                    is_permanently_blocked, notes
                ) VALUES (
                    'automated_block', 'ip_address', 
                    (p_event_data->>'ip_address')::INET,
                    true, 'Automatically blocked due to high-risk activity'
                ) ON CONFLICT (ip_address) DO UPDATE SET
                    is_permanently_blocked = true,
                    notes = 'Automatically blocked due to high-risk activity';
            END IF;
            
        WHEN 'apply_rate_limiting' THEN
            -- Apply temporary rate limiting
            NULL; -- Handled by application layer
            
        ELSE
            NULL;
    END CASE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update security metrics function
CREATE OR REPLACE FUNCTION update_security_metrics(
    p_event_type TEXT,
    p_risk_score INTEGER
) RETURNS VOID AS $$
BEGIN
    -- Update hourly metrics
    INSERT INTO public.security_metrics (metric_type, metric_value, time_window, dimensions)
    VALUES (
        'security_events_hourly',
        1,
        '1h',
        jsonb_build_object('event_type', p_event_type, 'risk_score_range', 
            CASE 
                WHEN p_risk_score >= 80 THEN 'high'
                WHEN p_risk_score >= 50 THEN 'medium'
                ELSE 'low'
            END
        )
    );
    
    -- Update daily risk score average
    INSERT INTO public.security_metrics (metric_type, metric_value, time_window, dimensions)
    VALUES (
        'average_risk_score_daily',
        p_risk_score,
        '24h',
        jsonb_build_object('event_type', p_event_type)
    );
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- 4. COMPREHENSIVE ACCESS CONTROL POLICIES
-- =============================================================================

-- Enhanced admin access control with session validation
CREATE OR REPLACE FUNCTION validate_admin_session(
    p_admin_user_id UUID,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_admin_user RECORD;
    v_session_valid BOOLEAN := FALSE;
    v_ip_allowed BOOLEAN := TRUE;
BEGIN
    -- Get admin user details
    SELECT * FROM public.admin_users 
    WHERE id = p_admin_user_id AND is_active = true
    INTO v_admin_user;
    
    -- Check if admin exists and is active
    IF v_admin_user IS NULL THEN
        PERFORM log_security_event(
            'admin_access_denied',
            jsonb_build_object('reason', 'user_not_found', 'admin_user_id', p_admin_user_id),
            NULL, p_admin_user_id, p_ip_address, p_user_agent, 'high'
        );
        RETURN FALSE;
    END IF;
    
    -- Check if account is locked
    IF v_admin_user.account_locked_until IS NOT NULL 
       AND v_admin_user.account_locked_until > NOW() THEN
        PERFORM log_security_event(
            'admin_access_denied',
            jsonb_build_object('reason', 'account_locked', 'locked_until', v_admin_user.account_locked_until),
            NULL, p_admin_user_id, p_ip_address, p_user_agent, 'medium'
        );
        RETURN FALSE;
    END IF;
    
    -- Check IP allowlist for super admins
    IF v_admin_user.role = 'super_admin' AND v_admin_user.allowed_ips IS NOT NULL THEN
        SELECT p_ip_address = ANY(v_admin_user.allowed_ips) INTO v_ip_allowed;
        
        IF NOT v_ip_allowed THEN
            PERFORM log_security_event(
                'admin_ip_violation',
                jsonb_build_object('ip_address', p_ip_address, 'allowed_ips', v_admin_user.allowed_ips),
                NULL, p_admin_user_id, p_ip_address, p_user_agent, 'high'
            );
            RETURN FALSE;
        END IF;
    END IF;
    
    -- Check session validity (if session management is implemented)
    SELECT EXISTS (
        SELECT 1 FROM public.admin_sessions 
        WHERE admin_user_id = p_admin_user_id 
        AND is_active = true 
        AND expires_at > NOW()
        AND (ip_address = p_ip_address OR ip_address IS NULL)
    ) INTO v_session_valid;
    
    IF NOT v_session_valid THEN
        PERFORM log_security_event(
            'admin_invalid_session',
            jsonb_build_object('admin_user_id', p_admin_user_id),
            NULL, p_admin_user_id, p_ip_address, p_user_agent, 'medium'
        );
        RETURN FALSE;
    END IF;
    
    -- Log successful admin access
    PERFORM log_security_event(
        'admin_access_granted',
        jsonb_build_object('role', v_admin_user.role),
        NULL, p_admin_user_id, p_ip_address, p_user_agent, 'low'
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- 5. DATA ENCRYPTION AND PRIVACY CONTROLS
-- =============================================================================

-- Function to encrypt sensitive data
CREATE OR REPLACE FUNCTION encrypt_sensitive_data(
    p_data TEXT,
    p_context TEXT DEFAULT 'general'
) RETURNS TEXT AS $$
DECLARE
    v_key TEXT;
BEGIN
    -- Get encryption key based on context
    -- In production, this should use proper key management
    v_key := current_setting('app.encryption_key', true);
    
    IF v_key IS NULL THEN
        RAISE EXCEPTION 'Encryption key not configured';
    END IF;
    
    -- Use pgcrypto for encryption
    RETURN encode(
        encrypt(p_data::bytea, v_key::bytea, 'aes'),
        'base64'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to decrypt sensitive data
CREATE OR REPLACE FUNCTION decrypt_sensitive_data(
    p_encrypted_data TEXT,
    p_context TEXT DEFAULT 'general'
) RETURNS TEXT AS $$
DECLARE
    v_key TEXT;
BEGIN
    -- Get encryption key based on context
    v_key := current_setting('app.encryption_key', true);
    
    IF v_key IS NULL THEN
        RAISE EXCEPTION 'Encryption key not configured';
    END IF;
    
    -- Use pgcrypto for decryption
    RETURN convert_from(
        decrypt(decode(p_encrypted_data, 'base64'), v_key::bytea, 'aes'),
        'UTF8'
    );
EXCEPTION
    WHEN OTHERS THEN
        -- Log decryption failure
        PERFORM log_security_event(
            'decryption_failure',
            jsonb_build_object('error', SQLERRM),
            auth.uid(), NULL, NULL, NULL, 'high'
        );
        RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- 6. SECURITY MONITORING VIEWS
-- =============================================================================

-- High-risk security events view
CREATE OR REPLACE VIEW security_dashboard_critical AS
SELECT 
    sal.id,
    sal.event_type,
    sal.severity,
    sal.risk_score,
    sal.ip_address,
    sal.user_agent,
    sal.event_data,
    sal.automated_response,
    sal.investigation_status,
    sal.created_at,
    au.email as admin_email,
    u.email as user_email
FROM public.security_audit_log sal
LEFT JOIN public.admin_users au ON sal.admin_user_id = au.id
LEFT JOIN auth.users u ON sal.user_id = u.id
WHERE sal.risk_score >= 70 
   OR sal.severity = 'critical'
ORDER BY sal.created_at DESC, sal.risk_score DESC;

-- Security metrics summary view
CREATE OR REPLACE VIEW security_metrics_summary AS
SELECT 
    metric_type,
    time_window,
    COUNT(*) as event_count,
    AVG(metric_value) as avg_value,
    MAX(metric_value) as max_value,
    MIN(recorded_at) as first_recorded,
    MAX(recorded_at) as last_recorded
FROM public.security_metrics
WHERE recorded_at > NOW() - INTERVAL '7 days'
GROUP BY metric_type, time_window
ORDER BY last_recorded DESC;

-- =============================================================================
-- 7. INDEXES FOR PERFORMANCE
-- =============================================================================

-- Security audit log indexes
CREATE INDEX IF NOT EXISTS idx_security_audit_log_created_at ON public.security_audit_log(created_at);
CREATE INDEX IF NOT EXISTS idx_security_audit_log_event_type ON public.security_audit_log(event_type);
CREATE INDEX IF NOT EXISTS idx_security_audit_log_risk_score ON public.security_audit_log(risk_score);
CREATE INDEX IF NOT EXISTS idx_security_audit_log_ip_address ON public.security_audit_log(ip_address);
CREATE INDEX IF NOT EXISTS idx_security_audit_log_user_id ON public.security_audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_security_audit_log_admin_user_id ON public.security_audit_log(admin_user_id);

-- Security metrics indexes
CREATE INDEX IF NOT EXISTS idx_security_metrics_recorded_at ON public.security_metrics(recorded_at);
CREATE INDEX IF NOT EXISTS idx_security_metrics_metric_type ON public.security_metrics(metric_type);

-- Access violations indexes  
CREATE INDEX IF NOT EXISTS idx_access_violations_ip_address ON public.access_violations(ip_address);
CREATE INDEX IF NOT EXISTS idx_access_violations_last_attempt ON public.access_violations(last_attempt_at);

-- =============================================================================
-- 8. SECURITY CONFIGURATION PARAMETERS
-- =============================================================================

-- Set secure configuration parameters
ALTER SYSTEM SET log_statement = 'all';
ALTER SYSTEM SET log_min_duration_statement = 1000; -- Log slow queries
ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM SET log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h ';

-- Select configuration to apply
SELECT pg_reload_conf();

COMMENT ON TABLE public.security_audit_log IS 'Comprehensive security event logging with automated response';
COMMENT ON TABLE public.security_metrics IS 'Aggregated security metrics for monitoring and alerting';
COMMENT ON TABLE public.access_violations IS 'Failed access attempts and blocking information';
COMMENT ON FUNCTION log_security_event IS 'Central function for logging security events with automated risk assessment';
COMMENT ON FUNCTION validate_admin_session IS 'Comprehensive admin session validation with security checks';

-- Grant permissions
GRANT SELECT ON public.security_dashboard_critical TO authenticated;
GRANT SELECT ON public.security_metrics_summary TO authenticated;