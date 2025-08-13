-- Fix 2FA and Session Tables
-- Run this entire script in Supabase SQL Editor

-- Create admin_sessions table
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

-- Create admin_2fa_settings table
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

-- Create security_audit_logs table
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

-- Drop existing policies
DROP POLICY IF EXISTS "Users can manage their own sessions" ON public.admin_sessions;
DROP POLICY IF EXISTS "Users can view their own 2FA settings" ON public.admin_2fa_settings;
DROP POLICY IF EXISTS "Admin users can view audit logs" ON public.security_audit_logs;
DROP POLICY IF EXISTS "Service role full access sessions" ON public.admin_sessions;
DROP POLICY IF EXISTS "Service role full access 2fa" ON public.admin_2fa_settings;
DROP POLICY IF EXISTS "Service role full access audit" ON public.security_audit_logs;

-- Create RLS policies
CREATE POLICY "Users can manage their own sessions" ON public.admin_sessions
    FOR ALL USING (admin_user_id = auth.uid() OR auth.role() = 'service_role');

CREATE POLICY "Service role full access sessions" ON public.admin_sessions
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Users can view their own 2FA settings" ON public.admin_2fa_settings
    FOR ALL USING (admin_user_id = auth.uid() OR auth.role() = 'service_role');

CREATE POLICY "Service role full access 2fa" ON public.admin_2fa_settings
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Admin users can view audit logs" ON public.security_audit_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.admin_users 
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
        OR auth.role() = 'service_role'
    );

CREATE POLICY "Service role full access audit" ON public.security_audit_logs
    FOR ALL USING (auth.role() = 'service_role');

-- Grant permissions
GRANT ALL ON public.admin_sessions TO authenticated;
GRANT ALL ON public.admin_2fa_settings TO authenticated;
GRANT SELECT ON public.security_audit_logs TO authenticated;

-- Done
SELECT 'Tables created successfully' as status;