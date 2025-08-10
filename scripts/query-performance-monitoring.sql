-- SQL script to set up query performance monitoring
-- Run this in your Supabase SQL Editor

-- Enable pg_stat_statements for query monitoring
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Create a table to log slow queries
CREATE TABLE IF NOT EXISTS slow_query_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  query TEXT NOT NULL,
  mean_exec_time NUMERIC(10,2) NOT NULL,
  calls BIGINT NOT NULL,
  total_exec_time NUMERIC(10,2) NOT NULL,
  rows_affected BIGINT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  logged_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for the slow query log
CREATE INDEX IF NOT EXISTS idx_slow_query_log_created_at ON slow_query_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_slow_query_log_mean_time ON slow_query_log(mean_exec_time DESC);

-- Function to capture slow queries
CREATE OR REPLACE FUNCTION capture_slow_queries(threshold_ms NUMERIC DEFAULT 100)
RETURNS TABLE(
  query_text TEXT,
  mean_time NUMERIC,
  call_count BIGINT,
  total_time NUMERIC,
  rows_returned BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.query,
    ROUND(s.mean_exec_time::NUMERIC, 2) as mean_time,
    s.calls,
    ROUND(s.total_exec_time::NUMERIC, 2) as total_time,
    s.rows
  FROM pg_stat_statements s
  WHERE s.mean_exec_time > threshold_ms
    AND s.calls > 5  -- Only queries called more than 5 times
  ORDER BY s.mean_exec_time DESC
  LIMIT 20;
END;
$$ LANGUAGE plpgsql;

-- Function to log slow queries to our table
CREATE OR REPLACE FUNCTION log_slow_queries(threshold_ms NUMERIC DEFAULT 100)
RETURNS INT AS $$
DECLARE
  query_record RECORD;
  inserted_count INT := 0;
BEGIN
  FOR query_record IN 
    SELECT * FROM capture_slow_queries(threshold_ms)
  LOOP
    INSERT INTO slow_query_log (
      query, 
      mean_exec_time, 
      calls, 
      total_exec_time, 
      rows_affected
    ) VALUES (
      query_record.query_text,
      query_record.mean_time,
      query_record.call_count,
      query_record.total_time,
      query_record.rows_returned
    )
    ON CONFLICT DO NOTHING;  -- Avoid duplicates if query already logged
    
    inserted_count := inserted_count + 1;
  END LOOP;
  
  RETURN inserted_count;
END;
$$ LANGUAGE plpgsql;

-- View for analyzing table sizes and bloat
CREATE OR REPLACE VIEW table_size_analysis AS
SELECT 
  schemaname,
  tablename,
  attname as column_name,
  n_distinct,
  correlation,
  most_common_vals,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
  pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) as index_size
FROM pg_stats
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- View for index usage analysis
CREATE OR REPLACE VIEW index_usage_analysis AS
SELECT 
  schemaname,
  tablename,
  indexname,
  idx_scan as index_scans,
  idx_tup_read as tuples_read,
  idx_tup_fetch as tuples_fetched,
  pg_size_pretty(pg_relation_size(indexrelid)) as index_size,
  CASE 
    WHEN idx_scan = 0 THEN 'UNUSED'
    WHEN idx_scan < 10 THEN 'RARELY_USED'
    WHEN idx_scan < 100 THEN 'MODERATELY_USED'
    ELSE 'FREQUENTLY_USED'
  END as usage_category
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

-- View for current database connections and activity
CREATE OR REPLACE VIEW connection_analysis AS
SELECT 
  datname as database,
  usename as username,
  state,
  COUNT(*) as connection_count,
  MAX(now() - query_start) as longest_query_duration,
  AVG(now() - query_start) as avg_query_duration
FROM pg_stat_activity
WHERE state IS NOT NULL
GROUP BY datname, usename, state
ORDER BY connection_count DESC;

-- View for lock analysis
CREATE OR REPLACE VIEW lock_analysis AS
SELECT 
  l.locktype,
  l.database,
  l.relation::regclass as table_name,
  l.mode,
  l.granted,
  a.usename,
  a.query,
  a.state,
  now() - a.query_start as query_duration
FROM pg_locks l
JOIN pg_stat_activity a ON l.pid = a.pid
WHERE l.database IS NOT NULL
ORDER BY query_duration DESC NULLS LAST;

-- Performance summary query
CREATE OR REPLACE FUNCTION performance_summary()
RETURNS TABLE(
  metric_name TEXT,
  metric_value TEXT,
  status TEXT
) AS $$
BEGIN
  RETURN QUERY
  WITH metrics AS (
    -- Slow query count
    SELECT 'Slow Queries (>100ms)' as name, 
           COUNT(*)::TEXT as value,
           CASE WHEN COUNT(*) > 10 THEN 'WARNING' ELSE 'OK' END as status
    FROM capture_slow_queries(100)
    
    UNION ALL
    
    -- Database size
    SELECT 'Database Size' as name,
           pg_size_pretty(pg_database_size(current_database())) as value,
           'INFO' as status
    
    UNION ALL
    
    -- Active connections
    SELECT 'Active Connections' as name,
           COUNT(*)::TEXT as value,
           CASE WHEN COUNT(*) > 50 THEN 'WARNING' ELSE 'OK' END as status
    FROM pg_stat_activity
    WHERE state = 'active'
    
    UNION ALL
    
    -- Unused indexes
    SELECT 'Unused Indexes' as name,
           COUNT(*)::TEXT as value,
           CASE WHEN COUNT(*) > 5 THEN 'WARNING' ELSE 'OK' END as status
    FROM index_usage_analysis
    WHERE usage_category = 'UNUSED'
    
    UNION ALL
    
    -- Cache hit ratio
    SELECT 'Cache Hit Ratio' as name,
           ROUND(
             (sum(heap_blks_hit) * 100.0) / 
             NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2
           )::TEXT || '%' as value,
           CASE 
             WHEN ROUND(
               (sum(heap_blks_hit) * 100.0) / 
               NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2
             ) < 95 THEN 'WARNING'
             ELSE 'OK' 
           END as status
    FROM pg_statio_user_tables
  )
  SELECT * FROM metrics;
END;
$$ LANGUAGE plpgsql;

-- Schedule automatic slow query logging (if you have pg_cron available)
-- SELECT cron.schedule('log-slow-queries', '*/5 * * * *', 'SELECT log_slow_queries(100);');

-- Sample queries to check performance:

-- Check current slow queries
SELECT * FROM capture_slow_queries(50) LIMIT 10;

-- Get performance summary
SELECT * FROM performance_summary();

-- Check table sizes
SELECT * FROM table_size_analysis LIMIT 10;

-- Check index usage
SELECT * FROM index_usage_analysis WHERE usage_category IN ('UNUSED', 'RARELY_USED') LIMIT 10;

-- Check current connections
SELECT * FROM connection_analysis;

-- Reset query statistics (use with caution!)
-- SELECT pg_stat_statements_reset();

-- Manual query to check specific product-related performance
SELECT 
  query,
  calls,
  ROUND(mean_exec_time::NUMERIC, 2) as avg_time_ms,
  ROUND(total_exec_time::NUMERIC, 2) as total_time_ms,
  rows
FROM pg_stat_statements 
WHERE query ILIKE '%product%'
ORDER BY mean_exec_time DESC
LIMIT 10;