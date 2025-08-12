-- Enhanced Authentication and Security Migration
-- Adds email verification, password history, security questions, and login tracking
-- Version: 1.0.0
-- Created: 2025-08-12

BEGIN;

-- Add email verification and security columns to user_profiles
DO $$
BEGIN
    -- Add email_verified flag
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'email_verified') THEN
        ALTER TABLE public.user_profiles ADD COLUMN email_verified BOOLEAN DEFAULT false;
    END IF;

    -- Add email_verification_token
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'email_verification_token') THEN
        ALTER TABLE public.user_profiles ADD COLUMN email_verification_token TEXT;
    END IF;

    -- Add email_verification_token_expires
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'email_verification_token_expires') THEN
        ALTER TABLE public.user_profiles ADD COLUMN email_verification_token_expires TIMESTAMPTZ;
    END IF;

    -- Add backup_email
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'backup_email') THEN
        ALTER TABLE public.user_profiles ADD COLUMN backup_email TEXT;
    END IF;

    -- Add backup_email_verified
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'backup_email_verified') THEN
        ALTER TABLE public.user_profiles ADD COLUMN backup_email_verified BOOLEAN DEFAULT false;
    END IF;

    -- Add security_questions
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'security_questions') THEN
        ALTER TABLE public.user_profiles ADD COLUMN security_questions JSONB DEFAULT '[]'::jsonb;
    END IF;

    -- Add account_locked_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'account_locked_at') THEN
        ALTER TABLE public.user_profiles ADD COLUMN account_locked_at TIMESTAMPTZ;
    END IF;

    -- Add account_locked_reason
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' AND table_name = 'user_profiles' AND column_name = 'account_locked_reason') THEN
        ALTER TABLE public.user_profiles ADD COLUMN account_locked_reason TEXT;
    END IF;
END $$;

-- Create password history table
CREATE TABLE IF NOT EXISTS public.password_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Create login attempts table
CREATE TABLE IF NOT EXISTS public.login_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    ip_address INET,
    user_agent TEXT,
    success BOOLEAN NOT NULL DEFAULT false,
    failure_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Create email verification logs table
CREATE TABLE IF NOT EXISTS public.email_verification_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    verification_type TEXT NOT NULL, -- 'signup', 'login', 'manual'
    token TEXT,
    success BOOLEAN NOT NULL DEFAULT false,
    failure_reason TEXT,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Create account recovery table
CREATE TABLE IF NOT EXISTS public.account_recovery (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    recovery_type TEXT NOT NULL, -- 'email', 'security_questions', 'backup_email'
    recovery_token TEXT,
    recovery_data JSONB,
    token_expires_at TIMESTAMPTZ,
    used_at TIMESTAMPTZ,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Create security events table
CREATE TABLE IF NOT EXISTS public.security_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL, -- 'login_success', 'login_failure', 'password_change', 'email_change', etc.
    event_data JSONB,
    risk_score INTEGER DEFAULT 0, -- 0-100 risk assessment
    ip_address INET,
    user_agent TEXT,
    location JSONB, -- geo location data
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Enable RLS on all tables
ALTER TABLE public.password_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.login_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.email_verification_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.account_recovery ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_events ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own password history" ON public.password_history
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own login attempts" ON public.login_attempts
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own email verification logs" ON public.email_verification_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own account recovery" ON public.account_recovery
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own security events" ON public.security_events
    FOR SELECT USING (auth.uid() = user_id);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_password_history_user_id ON public.password_history(user_id);
CREATE INDEX IF NOT EXISTS idx_password_history_created_at ON public.password_history(created_at);
CREATE INDEX IF NOT EXISTS idx_login_attempts_user_id ON public.login_attempts(user_id);
CREATE INDEX IF NOT EXISTS idx_login_attempts_email ON public.login_attempts(email);
CREATE INDEX IF NOT EXISTS idx_login_attempts_ip_address ON public.login_attempts(ip_address);
CREATE INDEX IF NOT EXISTS idx_login_attempts_created_at ON public.login_attempts(created_at);
CREATE INDEX IF NOT EXISTS idx_email_verification_user_id ON public.email_verification_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_email_verification_created_at ON public.email_verification_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_account_recovery_user_id ON public.account_recovery(user_id);
CREATE INDEX IF NOT EXISTS idx_account_recovery_token ON public.account_recovery(recovery_token);
CREATE INDEX IF NOT EXISTS idx_security_events_user_id ON public.security_events(user_id);
CREATE INDEX IF NOT EXISTS idx_security_events_type ON public.security_events(event_type);
CREATE INDEX IF NOT EXISTS idx_security_events_created_at ON public.security_events(created_at);

-- Create security functions
CREATE OR REPLACE FUNCTION public.log_login_attempt(
    p_user_id UUID,
    p_email TEXT,
    p_ip_address INET,
    p_user_agent TEXT,
    p_success BOOLEAN,
    p_failure_reason TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    attempt_id UUID;
BEGIN
    INSERT INTO public.login_attempts (
        user_id, email, ip_address, user_agent, success, failure_reason
    ) VALUES (
        p_user_id, p_email, p_ip_address, p_user_agent, p_success, p_failure_reason
    ) RETURNING id INTO attempt_id;
    
    RETURN attempt_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.log_security_event(
    p_user_id UUID,
    p_event_type TEXT,
    p_event_data JSONB DEFAULT NULL,
    p_risk_score INTEGER DEFAULT 0,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    event_id UUID;
BEGIN
    INSERT INTO public.security_events (
        user_id, event_type, event_data, risk_score, ip_address, user_agent
    ) VALUES (
        p_user_id, p_event_type, p_event_data, p_risk_score, p_ip_address, p_user_agent
    ) RETURNING id INTO event_id;
    
    RETURN event_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.check_password_history(
    p_user_id UUID,
    p_new_password_hash TEXT,
    p_history_count INTEGER DEFAULT 5
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Check if new password matches any of the last N passwords
    RETURN EXISTS (
        SELECT 1 FROM public.password_history
        WHERE user_id = p_user_id 
        AND password_hash = p_new_password_hash
        AND created_at > now() - INTERVAL '90 days'
        ORDER BY created_at DESC
        LIMIT p_history_count
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.add_password_to_history(
    p_user_id UUID,
    p_password_hash TEXT
)
RETURNS VOID AS $$
BEGIN
    -- Add new password to history
    INSERT INTO public.password_history (user_id, password_hash)
    VALUES (p_user_id, p_password_hash);
    
    -- Keep only last 10 passwords
    DELETE FROM public.password_history
    WHERE user_id = p_user_id
    AND id NOT IN (
        SELECT id FROM public.password_history
        WHERE user_id = p_user_id
        ORDER BY created_at DESC
        LIMIT 10
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.check_failed_login_attempts(
    p_user_id UUID DEFAULT NULL,
    p_email TEXT DEFAULT NULL,
    p_ip_address INET DEFAULT NULL,
    p_time_window INTERVAL DEFAULT INTERVAL '15 minutes',
    p_max_attempts INTEGER DEFAULT 5
)
RETURNS INTEGER AS $$
DECLARE
    failed_count INTEGER;
BEGIN
    -- Count failed attempts in the time window
    SELECT COUNT(*) INTO failed_count
    FROM public.login_attempts
    WHERE success = false
    AND created_at > now() - p_time_window
    AND (
        (p_user_id IS NOT NULL AND user_id = p_user_id)
        OR (p_email IS NOT NULL AND email = p_email)
        OR (p_ip_address IS NOT NULL AND ip_address = p_ip_address)
    );
    
    RETURN failed_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.generate_verification_token()
RETURNS TEXT AS $$
BEGIN
    RETURN encode(gen_random_bytes(32), 'hex');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.set_email_verification_token(
    p_user_id UUID,
    p_token TEXT DEFAULT NULL,
    p_expires_hours INTEGER DEFAULT 24
)
RETURNS TEXT AS $$
DECLARE
    token TEXT;
BEGIN
    token := COALESCE(p_token, generate_verification_token());
    
    UPDATE public.user_profiles
    SET 
        email_verification_token = token,
        email_verification_token_expires = now() + (p_expires_hours || ' hours')::interval,
        updated_at = now()
    WHERE id = p_user_id;
    
    RETURN token;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.verify_email_token(
    p_token TEXT
)
RETURNS UUID AS $$
DECLARE
    user_id UUID;
BEGIN
    -- Find and verify the token
    SELECT id INTO user_id
    FROM public.user_profiles
    WHERE email_verification_token = p_token
    AND email_verification_token_expires > now()
    AND email_verified = false;
    
    IF user_id IS NOT NULL THEN
        -- Mark email as verified
        UPDATE public.user_profiles
        SET 
            email_verified = true,
            email_verification_token = NULL,
            email_verification_token_expires = NULL,
            updated_at = now()
        WHERE id = user_id;
        
        -- Log the verification
        INSERT INTO public.email_verification_logs (
            user_id, email, verification_type, token, success
        ) SELECT 
            user_id, email, 'manual', p_token, true
        FROM public.user_profiles
        WHERE id = user_id;
    END IF;
    
    RETURN user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comments
COMMENT ON TABLE public.password_history IS 'Stores hashed passwords to prevent reuse';
COMMENT ON TABLE public.login_attempts IS 'Tracks all login attempts for security monitoring';
COMMENT ON TABLE public.email_verification_logs IS 'Logs all email verification attempts';
COMMENT ON TABLE public.account_recovery IS 'Manages account recovery tokens and processes';
COMMENT ON TABLE public.security_events IS 'Comprehensive security event logging';

COMMENT ON COLUMN public.user_profiles.email_verified IS 'Whether the user email address has been verified';
COMMENT ON COLUMN public.user_profiles.security_questions IS 'Encrypted security questions and answers for account recovery';
COMMENT ON COLUMN public.user_profiles.backup_email IS 'Secondary email for account recovery';

-- Create admin functions for security management
CREATE OR REPLACE FUNCTION public.get_user_security_status(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    security_status JSON;
BEGIN
    SELECT json_build_object(
        'user_id', p_user_id,
        'email_verified', up.email_verified,
        'backup_email_set', (up.backup_email IS NOT NULL),
        'backup_email_verified', up.backup_email_verified,
        'security_questions_set', (jsonb_array_length(up.security_questions) > 0),
        'account_locked', (up.account_locked_at IS NOT NULL),
        'recent_login_attempts', (
            SELECT COUNT(*) FROM public.login_attempts
            WHERE user_id = p_user_id AND created_at > now() - INTERVAL '24 hours'
        ),
        'failed_login_attempts', (
            SELECT COUNT(*) FROM public.login_attempts
            WHERE user_id = p_user_id AND success = false AND created_at > now() - INTERVAL '24 hours'
        ),
        'last_login', up.last_login_at,
        'password_last_changed', (
            SELECT MAX(created_at) FROM public.password_history WHERE user_id = p_user_id
        )
    ) INTO security_status
    FROM public.user_profiles up
    WHERE up.id = p_user_id;
    
    RETURN security_status;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;