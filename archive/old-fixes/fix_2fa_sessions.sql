-- =====================================================
-- FIX 2FA AND SESSION TABLES
-- This creates the missing admin_sessions and related tables
-- =====================================================

-- Check current state
DO $$
BEGIN
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'Fixing 2FA and Session Management...';
    RAISE NOTICE '===========================================';
END $$;

-- Create admin_sessions table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.admin_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id UUID NOT NULL REFERENCES public.admin_users(id) ON DELETE CASCADE,
    session_token TEXT NOT NULL UNIQUE,
    ip_address INET,
    user_agent TEXT,
    device_fingerprint TEXT,
    last_activity TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create admin_2fa_settings table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.admin_2fa_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id UUID NOT NULL REFERENCES public.admin_users(id) ON DELETE CASCADE,
    secret_encrypted TEXT NOT NULL,
    backup_codes TEXT[],
    is_enabled BOOLEAN DEFAULT false,
    enabled_at TIMESTAMPTZ,
    last_used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(admin_user_id)
);

-- Create security_audit_logs table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.security_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type TEXT NOT NULL,
    event_category TEXT NOT NULL,
    severity TEXT CHECK (severity IN ('info', 'warning', 'error', 'critical')),
    user_id UUID,
    admin_user_id UUID REFERENCES public.admin_users(id),
    ip_address INET,
    user_agent TEXT,
    resource_type TEXT,
    resource_id TEXT,
    action TEXT,
    result TEXT,
    metadata JSONB DEFAULT '{}',
    error_details TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_admin_sessions_user ON public.admin_sessions(admin_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_sessions_token ON public.admin_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_admin_sessions_active ON public.admin_sessions(is_active, expires_at);
CREATE INDEX IF NOT EXISTS idx_admin_2fa_user ON public.admin_2fa_settings(admin_user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_event ON public.security_audit_logs(event_type, created_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON public.security_audit_logs(admin_user_id);

-- Enable RLS
ALTER TABLE public.admin_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_2fa_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_audit_logs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can manage their own sessions" ON public.admin_sessions;
DROP POLICY IF EXISTS "Users can view their own 2FA settings" ON public.admin_2fa_settings;
DROP POLICY IF EXISTS "Admin users can view audit logs" ON public.security_audit_logs;
DROP POLICY IF EXISTS "Service role full access sessions" ON public.admin_sessions;
DROP POLICY IF EXISTS "Service role full access 2fa" ON public.admin_2fa_settings;
DROP POLICY IF EXISTS "Service role full access audit" ON public.security_audit_logs;

-- Create RLS policies for admin_sessions
CREATE POLICY "Users can manage their own sessions" ON public.admin_sessions
    FOR ALL USING (
        admin_user_id = auth.uid()
        OR auth.role() = 'service_role'
    );

CREATE POLICY "Service role full access sessions" ON public.admin_sessions
    FOR ALL USING (auth.role() = 'service_role');

-- Create RLS policies for admin_2fa_settings
CREATE POLICY "Users can view their own 2FA settings" ON public.admin_2fa_settings
    FOR ALL USING (
        admin_user_id = auth.uid()
        OR auth.role() = 'service_role'
    );

CREATE POLICY "Service role full access 2fa" ON public.admin_2fa_settings
    FOR ALL USING (auth.role() = 'service_role');

-- Create RLS policies for security_audit_logs
CREATE POLICY "Admin users can view audit logs" ON public.security_audit_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.admin_users 
            WHERE id = auth.uid()
            AND role IN ('admin', 'super_admin')
        )
        OR auth.role() = 'service_role'
    );

CREATE POLICY "Service role full access audit" ON public.security_audit_logs
    FOR ALL USING (auth.role() = 'service_role');

-- Create function to clean up expired sessions
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS void AS $$
BEGIN
    UPDATE public.admin_sessions
    SET is_active = false
    WHERE expires_at < NOW() AND is_active = true;
    
    DELETE FROM public.admin_sessions
    WHERE expires_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT ALL ON public.admin_sessions TO authenticated;
GRANT ALL ON public.admin_2fa_settings TO authenticated;
GRANT SELECT ON public.security_audit_logs TO authenticated;

-- Verify the tables were created
DO $$
DECLARE
    v_sessions_exists BOOLEAN;
    v_2fa_exists BOOLEAN;
    v_audit_exists BOOLEAN;
BEGIN
    SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_sessions') INTO v_sessions_exists;
    SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'admin_2fa_settings') INTO v_2fa_exists;
    SELECT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'security_audit_logs') INTO v_audit_exists;
    
    RAISE NOTICE '';
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'STATUS REPORT';
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'admin_sessions table: %', CASE WHEN v_sessions_exists THEN '✅ Created' ELSE '❌ Failed' END;
    RAISE NOTICE 'admin_2fa_settings table: %', CASE WHEN v_2fa_exists THEN '✅ Created' ELSE '❌ Failed' END;
    RAISE NOTICE 'security_audit_logs table: %', CASE WHEN v_audit_exists THEN '✅ Created' ELSE '❌ Failed' END;
    RAISE NOTICE '===========================================';
    
    IF v_sessions_exists AND v_2fa_exists AND v_audit_exists THEN
        RAISE NOTICE '✅ SUCCESS: 2FA and Session Management is ready!';
        RAISE NOTICE '';
        RAISE NOTICE 'You can now log in to the admin panel.';
        RAISE NOTICE 'The 404 errors should be resolved.';
    ELSE
        RAISE NOTICE '❌ ERROR: Some tables failed to create.';
    END IF;
    
    RAISE NOTICE '===========================================';
END $$;