-- Create application_logs table for production logging
CREATE TABLE IF NOT EXISTS application_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  level VARCHAR(10) NOT NULL CHECK (level IN ('debug', 'info', 'warn', 'error', 'fatal')),
  message TEXT NOT NULL,
  context JSONB,
  timestamp TIMESTAMPTZ NOT NULL,
  session_id VARCHAR(50),
  user_id UUID REFERENCES auth.users(id),
  environment VARCHAR(20),
  user_agent TEXT,
  url TEXT,
  stack_trace TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Indexes for efficient querying
  INDEX idx_logs_timestamp (timestamp DESC),
  INDEX idx_logs_level (level),
  INDEX idx_logs_user_id (user_id),
  INDEX idx_logs_session_id (session_id),
  INDEX idx_logs_level_timestamp (level, timestamp DESC)
);

-- Create index for searching messages
CREATE INDEX idx_logs_message_search ON application_logs USING gin(to_tsvector('english', message));

-- Create index for JSONB context queries
CREATE INDEX idx_logs_context ON application_logs USING gin(context);

-- Enable Row Level Security
ALTER TABLE application_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Only admins can read logs
CREATE POLICY "Admins can read all logs" ON application_logs
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.user_id = auth.uid()
    )
  );

-- Policy: Service role can insert logs
CREATE POLICY "Service role can insert logs" ON application_logs
  FOR INSERT
  TO service_role
  WITH CHECK (true);

-- Policy: Authenticated users can insert their own logs
CREATE POLICY "Users can insert their own logs" ON application_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid() OR user_id IS NULL
  );

-- Function to clean up old logs (older than 30 days)
CREATE OR REPLACE FUNCTION cleanup_old_logs()
RETURNS void AS $$
BEGIN
  DELETE FROM application_logs
  WHERE timestamp < NOW() - INTERVAL '30 days'
  AND level NOT IN ('error', 'fatal'); -- Keep errors longer
  
  -- Delete fatal/error logs older than 90 days
  DELETE FROM application_logs
  WHERE timestamp < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

-- Create a scheduled job to clean up logs daily (requires pg_cron extension)
-- Note: pg_cron needs to be enabled in Supabase dashboard
-- SELECT cron.schedule('cleanup-logs', '0 2 * * *', 'SELECT cleanup_old_logs();');

-- Function to get log statistics
CREATE OR REPLACE FUNCTION get_log_statistics(
  start_date TIMESTAMPTZ DEFAULT NOW() - INTERVAL '7 days',
  end_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE (
  log_level VARCHAR(10),
  count BIGINT,
  latest_timestamp TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    level as log_level,
    COUNT(*) as count,
    MAX(timestamp) as latest_timestamp
  FROM application_logs
  WHERE timestamp BETWEEN start_date AND end_date
  GROUP BY level
  ORDER BY 
    CASE level
      WHEN 'fatal' THEN 1
      WHEN 'error' THEN 2
      WHEN 'warn' THEN 3
      WHEN 'info' THEN 4
      WHEN 'debug' THEN 5
    END;
END;
$$ LANGUAGE plpgsql;

-- Function to get recent errors
CREATE OR REPLACE FUNCTION get_recent_errors(
  limit_count INT DEFAULT 10
)
RETURNS TABLE (
  id UUID,
  level VARCHAR(10),
  message TEXT,
  context JSONB,
  timestamp TIMESTAMPTZ,
  user_id UUID,
  url TEXT,
  stack_trace TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    l.id,
    l.level,
    l.message,
    l.context,
    l.timestamp,
    l.user_id,
    l.url,
    l.stack_trace
  FROM application_logs l
  WHERE l.level IN ('error', 'fatal')
  ORDER BY l.timestamp DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION get_log_statistics TO authenticated;
GRANT EXECUTE ON FUNCTION get_recent_errors TO authenticated;

-- Add comment to table
COMMENT ON TABLE application_logs IS 'Production application logs for monitoring and debugging';