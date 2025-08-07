-- Add Two-Factor Authentication and Session Management to admin_users table
-- Created: 2025-08-07

-- Add 2FA fields to admin_users table
ALTER TABLE public.admin_users ADD COLUMN IF NOT EXISTS two_factor_enabled BOOLEAN DEFAULT false;
ALTER TABLE public.admin_users ADD COLUMN IF NOT EXISTS two_factor_secret TEXT;
ALTER TABLE public.admin_users ADD COLUMN IF NOT EXISTS backup_codes TEXT[];
ALTER TABLE public.admin_users ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ;
ALTER TABLE public.admin_users ADD COLUMN IF NOT EXISTS failed_login_attempts INTEGER DEFAULT 0;
ALTER TABLE public.admin_users ADD COLUMN IF NOT EXISTS account_locked_until TIMESTAMPTZ;
ALTER TABLE public.admin_users ADD COLUMN IF NOT EXISTS password_changed_at TIMESTAMPTZ;
ALTER TABLE public.admin_users ADD COLUMN IF NOT EXISTS password_history TEXT[];

-- Create admin_sessions table for session management
CREATE TABLE IF NOT EXISTS public.admin_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  admin_user_id UUID NOT NULL REFERENCES public.admin_users(id) ON DELETE CASCADE,
  session_token TEXT NOT NULL UNIQUE,
  device_info JSONB DEFAULT '{}',
  ip_address INET,
  user_agent TEXT,
  is_active BOOLEAN DEFAULT true,
  remember_me BOOLEAN DEFAULT false,
  last_activity_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Index for faster lookups
  UNIQUE(session_token)
);

-- Create admin_security_events table for audit logging
CREATE TABLE IF NOT EXISTS public.admin_security_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  admin_user_id UUID REFERENCES public.admin_users(id) ON DELETE SET NULL,
  event_type TEXT NOT NULL CHECK (event_type IN (
    'login_success', 'login_failure', 'login_2fa_success', 'login_2fa_failure',
    'logout', 'session_timeout', 'password_change', 'password_reset',
    '2fa_enabled', '2fa_disabled', 'backup_codes_generated',
    'account_locked', 'account_unlocked', 'suspicious_activity'
  )),
  event_data JSONB DEFAULT '{}',
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_admin_sessions_user_id ON public.admin_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_sessions_admin_user_id ON public.admin_sessions(admin_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_sessions_token ON public.admin_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_admin_sessions_active ON public.admin_sessions(is_active);
CREATE INDEX IF NOT EXISTS idx_admin_sessions_expires_at ON public.admin_sessions(expires_at);
CREATE INDEX IF NOT EXISTS idx_admin_sessions_last_activity ON public.admin_sessions(last_activity_at);

CREATE INDEX IF NOT EXISTS idx_admin_security_events_user_id ON public.admin_security_events(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_security_events_admin_user_id ON public.admin_security_events(admin_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_security_events_type ON public.admin_security_events(event_type);
CREATE INDEX IF NOT EXISTS idx_admin_security_events_created_at ON public.admin_security_events(created_at);

-- Enable RLS on new tables
ALTER TABLE public.admin_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_security_events ENABLE ROW LEVEL SECURITY;

-- RLS Policies for admin_sessions
-- Only authenticated users can view their own sessions
CREATE POLICY "Users can view own sessions" ON public.admin_sessions
  FOR SELECT
  USING (user_id = auth.uid());

-- Only authenticated users can insert their own sessions
CREATE POLICY "Users can create own sessions" ON public.admin_sessions
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Only authenticated users can update their own sessions
CREATE POLICY "Users can update own sessions" ON public.admin_sessions
  FOR UPDATE
  USING (user_id = auth.uid());

-- Only authenticated users can delete their own sessions
CREATE POLICY "Users can delete own sessions" ON public.admin_sessions
  FOR DELETE
  USING (user_id = auth.uid());

-- Super admins can view all sessions
CREATE POLICY "Super admins can view all sessions" ON public.admin_sessions
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE user_id = auth.uid()
      AND role = 'super_admin'
      AND is_active = true
    )
  );

-- RLS Policies for admin_security_events
-- Only super admins can view all security events
CREATE POLICY "Super admins can view all security events" ON public.admin_security_events
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE user_id = auth.uid()
      AND role = 'super_admin'
      AND is_active = true
    )
  );

-- Users can view their own security events
CREATE POLICY "Users can view own security events" ON public.admin_security_events
  FOR SELECT
  USING (user_id = auth.uid());

-- System can insert security events
CREATE POLICY "System can create security events" ON public.admin_security_events
  FOR INSERT
  WITH CHECK (true);

-- Grant necessary permissions
GRANT ALL ON public.admin_sessions TO authenticated;
GRANT ALL ON public.admin_sessions TO service_role;
GRANT ALL ON public.admin_security_events TO authenticated;
GRANT ALL ON public.admin_security_events TO service_role;

-- Create function to clean up expired sessions
CREATE OR REPLACE FUNCTION clean_expired_admin_sessions()
RETURNS void AS $$
BEGIN
  -- Delete expired sessions
  DELETE FROM public.admin_sessions 
  WHERE expires_at < NOW();
  
  -- Log cleanup
  INSERT INTO public.admin_security_events (event_type, event_data)
  VALUES ('session_cleanup', jsonb_build_object('cleaned_at', NOW()));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to handle session activity updates
CREATE OR REPLACE FUNCTION update_session_activity(session_token TEXT)
RETURNS boolean AS $$
BEGIN
  UPDATE public.admin_sessions 
  SET last_activity_at = NOW()
  WHERE session_token = $1 
  AND is_active = true 
  AND expires_at > NOW();
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to log security events
CREATE OR REPLACE FUNCTION log_admin_security_event(
  p_user_id UUID,
  p_admin_user_id UUID,
  p_event_type TEXT,
  p_event_data JSONB DEFAULT '{}',
  p_ip_address INET DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  event_id UUID;
BEGIN
  INSERT INTO public.admin_security_events (
    user_id, admin_user_id, event_type, event_data, ip_address, user_agent
  ) VALUES (
    p_user_id, p_admin_user_id, p_event_type, p_event_data, p_ip_address, p_user_agent
  ) RETURNING id INTO event_id;
  
  RETURN event_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to update admin_users updated_at when 2FA fields change
CREATE OR REPLACE FUNCTION update_admin_users_2fa_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.two_factor_enabled IS DISTINCT FROM NEW.two_factor_enabled OR
     OLD.two_factor_secret IS DISTINCT FROM NEW.two_factor_secret OR
     OLD.backup_codes IS DISTINCT FROM NEW.backup_codes THEN
    NEW.updated_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_admin_users_2fa_updated_at
  BEFORE UPDATE ON public.admin_users
  FOR EACH ROW
  EXECUTE FUNCTION update_admin_users_2fa_timestamp();

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION clean_expired_admin_sessions() TO authenticated;
GRANT EXECUTE ON FUNCTION clean_expired_admin_sessions() TO service_role;
GRANT EXECUTE ON FUNCTION update_session_activity(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION update_session_activity(TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION log_admin_security_event(UUID, UUID, TEXT, JSONB, INET, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION log_admin_security_event(UUID, UUID, TEXT, JSONB, INET, TEXT) TO service_role;

-- Comment on tables and important columns
COMMENT ON TABLE public.admin_sessions IS 'Active admin user sessions with device tracking and expiration';
COMMENT ON TABLE public.admin_security_events IS 'Audit log for admin security events and activities';
COMMENT ON COLUMN public.admin_users.two_factor_enabled IS 'Whether 2FA is enabled for this admin user';
COMMENT ON COLUMN public.admin_users.two_factor_secret IS 'Encrypted TOTP secret for 2FA';
COMMENT ON COLUMN public.admin_users.backup_codes IS 'One-time backup codes for 2FA recovery';
COMMENT ON COLUMN public.admin_users.failed_login_attempts IS 'Number of consecutive failed login attempts';
COMMENT ON COLUMN public.admin_users.account_locked_until IS 'Timestamp until which the account is locked';
COMMENT ON COLUMN public.admin_users.password_history IS 'Hashed previous passwords to prevent reuse';