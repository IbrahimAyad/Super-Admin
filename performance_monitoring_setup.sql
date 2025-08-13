-- ============================================
-- COMPREHENSIVE PERFORMANCE MONITORING SETUP
-- Real-time database performance tracking for production
-- ============================================

-- SECTION 1: ENABLE REQUIRED EXTENSIONS
-- ============================================

-- Enable query statistics tracking
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Enable additional statistics
CREATE EXTENSION IF NOT EXISTS pg_stat_kcache;

-- ============================================
-- SECTION 2: PERFORMANCE MONITORING TABLES
-- ============================================

-- Query performance log
CREATE TABLE IF NOT EXISTS performance_query_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    query_hash TEXT NOT NULL,
    query_text TEXT NOT NULL,
    execution_time_ms NUMERIC(10,2) NOT NULL,
    rows_returned BIGINT DEFAULT 0,
    rows_affected BIGINT DEFAULT 0,
    table_names TEXT[] DEFAULT '{}',
    operation_type TEXT, -- SELECT, INSERT, UPDATE, DELETE
    user_role TEXT,
    database_name TEXT DEFAULT current_database(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Performance metrics
    buffer_cache_hits BIGINT DEFAULT 0,
    buffer_cache_misses BIGINT DEFAULT 0,
    temp_files_created INTEGER DEFAULT 0,
    temp_bytes_written BIGINT DEFAULT 0
);

-- Create indexes for query log
CREATE INDEX IF NOT EXISTS idx_perf_query_log_created_at ON performance_query_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_perf_query_log_exec_time ON performance_query_log(execution_time_ms DESC);
CREATE INDEX IF NOT EXISTS idx_perf_query_log_operation ON performance_query_log(operation_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_perf_query_log_tables ON performance_query_log USING gin(table_names);

-- Table performance metrics
CREATE TABLE IF NOT EXISTS performance_table_metrics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    table_name TEXT NOT NULL,
    schema_name TEXT NOT NULL DEFAULT 'public',
    
    -- Size metrics
    table_size_bytes BIGINT NOT NULL,
    index_size_bytes BIGINT NOT NULL,
    total_size_bytes BIGINT NOT NULL,
    row_count BIGINT NOT NULL,
    
    -- Access patterns
    seq_scans BIGINT DEFAULT 0,
    seq_tup_read BIGINT DEFAULT 0,
    idx_scans BIGINT DEFAULT 0,
    idx_tup_fetch BIGINT DEFAULT 0,
    
    -- Modification stats
    inserts BIGINT DEFAULT 0,
    updates BIGINT DEFAULT 0,
    deletes BIGINT DEFAULT 0,
    hot_updates BIGINT DEFAULT 0,
    
    -- Vacuum and analyze stats
    vacuum_count BIGINT DEFAULT 0,
    autovacuum_count BIGINT DEFAULT 0,
    analyze_count BIGINT DEFAULT 0,
    autoanalyze_count BIGINT DEFAULT 0,
    
    -- Timestamps
    last_vacuum TIMESTAMPTZ,
    last_autovacuum TIMESTAMPTZ,
    last_analyze TIMESTAMPTZ,
    last_autoanalyze TIMESTAMPTZ,
    collected_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for table metrics
CREATE INDEX IF NOT EXISTS idx_perf_table_metrics_table ON performance_table_metrics(schema_name, table_name);
CREATE INDEX IF NOT EXISTS idx_perf_table_metrics_collected ON performance_table_metrics(collected_at DESC);
CREATE INDEX IF NOT EXISTS idx_perf_table_metrics_size ON performance_table_metrics(total_size_bytes DESC);

-- Index performance metrics
CREATE TABLE IF NOT EXISTS performance_index_metrics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    index_name TEXT NOT NULL,
    table_name TEXT NOT NULL,
    schema_name TEXT NOT NULL DEFAULT 'public',
    
    -- Size and usage
    index_size_bytes BIGINT NOT NULL,
    scans BIGINT DEFAULT 0,
    tuples_read BIGINT DEFAULT 0,
    tuples_fetched BIGINT DEFAULT 0,
    
    -- Efficiency metrics
    scan_ratio NUMERIC(5,2) DEFAULT 0, -- scans / table scans
    fetch_ratio NUMERIC(5,2) DEFAULT 0, -- fetched / read
    
    -- Index definition
    index_definition TEXT,
    is_unique BOOLEAN DEFAULT FALSE,
    is_primary BOOLEAN DEFAULT FALSE,
    is_partial BOOLEAN DEFAULT FALSE,
    
    collected_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for index metrics
CREATE INDEX IF NOT EXISTS idx_perf_index_metrics_table ON performance_index_metrics(schema_name, table_name);
CREATE INDEX IF NOT EXISTS idx_perf_index_metrics_usage ON performance_index_metrics(scans DESC);
CREATE INDEX IF NOT EXISTS idx_perf_index_metrics_efficiency ON performance_index_metrics(scan_ratio DESC);

-- Database connection metrics
CREATE TABLE IF NOT EXISTS performance_connection_metrics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Connection counts
    total_connections INTEGER NOT NULL,
    active_connections INTEGER NOT NULL,
    idle_connections INTEGER NOT NULL,
    idle_in_transaction INTEGER NOT NULL,
    
    -- Connection by state
    connections_by_state JSONB DEFAULT '{}',
    connections_by_user JSONB DEFAULT '{}',
    connections_by_database JSONB DEFAULT '{}',
    
    -- Long-running queries
    longest_query_duration INTERVAL,
    queries_over_1min INTEGER DEFAULT 0,
    queries_over_5min INTEGER DEFAULT 0,
    
    collected_at TIMESTAMPTZ DEFAULT NOW()
);

-- System resource metrics
CREATE TABLE IF NOT EXISTS performance_system_metrics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Database size
    database_size_bytes BIGINT NOT NULL,
    
    -- Cache performance
    cache_hit_ratio NUMERIC(5,2) NOT NULL,
    buffer_cache_hit_ratio NUMERIC(5,2) NOT NULL,
    
    -- Transaction stats
    commits_per_second NUMERIC(10,2) DEFAULT 0,
    rollbacks_per_second NUMERIC(10,2) DEFAULT 0,
    
    -- Lock information
    total_locks INTEGER DEFAULT 0,
    granted_locks INTEGER DEFAULT 0,
    waiting_locks INTEGER DEFAULT 0,
    
    -- WAL and checkpoints
    checkpoint_write_time_ms NUMERIC(10,2) DEFAULT 0,
    checkpoint_sync_time_ms NUMERIC(10,2) DEFAULT 0,
    
    collected_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- SECTION 3: MONITORING FUNCTIONS
-- ============================================

-- Function to capture current slow queries
CREATE OR REPLACE FUNCTION capture_slow_queries_detailed(
    min_duration_ms NUMERIC DEFAULT 100,
    limit_results INTEGER DEFAULT 50
)
RETURNS TABLE (
    query_hash TEXT,
    query_text TEXT,
    calls BIGINT,
    total_time_ms NUMERIC,
    mean_time_ms NUMERIC,
    max_time_ms NUMERIC,
    rows_avg NUMERIC,
    cache_hit_ratio NUMERIC,
    temp_files BIGINT,
    temp_bytes BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        md5(pss.query) as query_hash,
        LEFT(pss.query, 200) as query_text,
        pss.calls,
        ROUND(pss.total_exec_time::NUMERIC, 2) as total_time_ms,
        ROUND(pss.mean_exec_time::NUMERIC, 2) as mean_time_ms,
        ROUND(pss.max_exec_time::NUMERIC, 2) as max_time_ms,
        ROUND((pss.rows::NUMERIC / GREATEST(pss.calls, 1)), 2) as rows_avg,
        ROUND(
            (GREATEST(pss.shared_blks_hit, 0)::NUMERIC / 
             GREATEST(pss.shared_blks_hit + pss.shared_blks_read, 1) * 100), 2
        ) as cache_hit_ratio,
        pss.temp_blks_written as temp_files,
        pss.temp_blks_written * 8192 as temp_bytes -- Assuming 8KB blocks
    FROM pg_stat_statements pss
    WHERE pss.mean_exec_time >= min_duration_ms
    AND pss.calls >= 3  -- Only queries called multiple times
    ORDER BY pss.mean_exec_time DESC
    LIMIT limit_results;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to collect table performance metrics
CREATE OR REPLACE FUNCTION collect_table_performance_metrics()
RETURNS INTEGER AS $$
DECLARE
    rec RECORD;
    inserted_count INTEGER := 0;
BEGIN
    -- Clear old metrics (keep last 7 days)
    DELETE FROM performance_table_metrics 
    WHERE collected_at < NOW() - INTERVAL '7 days';
    
    -- Collect current metrics for all user tables
    FOR rec IN
        SELECT 
            schemaname,
            tablename,
            pg_total_relation_size(schemaname||'.'||tablename) as total_size,
            pg_relation_size(schemaname||'.'||tablename) as table_size,
            pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename) as index_size,
            n_tup_ins,
            n_tup_upd,
            n_tup_del,
            n_tup_hot_upd,
            seq_scan,
            seq_tup_read,
            idx_scan,
            idx_tup_fetch,
            vacuum_count,
            autovacuum_count,
            analyze_count,
            autoanalyze_count,
            last_vacuum,
            last_autovacuum,
            last_analyze,
            last_autoanalyze,
            n_live_tup
        FROM pg_stat_user_tables
        WHERE schemaname = 'public'
    LOOP
        INSERT INTO performance_table_metrics (
            table_name,
            schema_name,
            table_size_bytes,
            index_size_bytes,
            total_size_bytes,
            row_count,
            seq_scans,
            seq_tup_read,
            idx_scans,
            idx_tup_fetch,
            inserts,
            updates,
            deletes,
            hot_updates,
            vacuum_count,
            autovacuum_count,
            analyze_count,
            autoanalyze_count,
            last_vacuum,
            last_autovacuum,
            last_analyze,
            last_autoanalyze
        ) VALUES (
            rec.tablename,
            rec.schemaname,
            rec.table_size,
            rec.index_size,
            rec.total_size,
            rec.n_live_tup,
            rec.seq_scan,
            rec.seq_tup_read,
            COALESCE(rec.idx_scan, 0),
            COALESCE(rec.idx_tup_fetch, 0),
            rec.n_tup_ins,
            rec.n_tup_upd,
            rec.n_tup_del,
            rec.n_tup_hot_upd,
            rec.vacuum_count,
            rec.autovacuum_count,
            rec.analyze_count,
            rec.autoanalyze_count,
            rec.last_vacuum,
            rec.last_autovacuum,
            rec.last_analyze,
            rec.last_autoanalyze
        );
        
        inserted_count := inserted_count + 1;
    END LOOP;
    
    RETURN inserted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to collect index performance metrics
CREATE OR REPLACE FUNCTION collect_index_performance_metrics()
RETURNS INTEGER AS $$
DECLARE
    rec RECORD;
    inserted_count INTEGER := 0;
BEGIN
    -- Clear old metrics
    DELETE FROM performance_index_metrics 
    WHERE collected_at < NOW() - INTERVAL '7 days';
    
    -- Collect current index metrics
    FOR rec IN
        SELECT 
            psi.schemaname,
            psi.relname as tablename,
            psi.indexrelname as indexname,
            pg_relation_size(psi.indexrelid) as index_size,
            psi.idx_scan,
            psi.idx_tup_read,
            psi.idx_tup_fetch,
            pg_get_indexdef(psi.indexrelid) as indexdef,
            i.indisunique,
            i.indisprimary,
            (pg_get_indexdef(psi.indexrelid) LIKE '%WHERE%') as is_partial,
            -- Calculate scan ratio
            CASE 
                WHEN pst.seq_scan + COALESCE(pst.idx_scan, 0) > 0 
                THEN (psi.idx_scan::NUMERIC / (pst.seq_scan + COALESCE(pst.idx_scan, 0)) * 100)
                ELSE 0 
            END as scan_ratio,
            -- Calculate fetch ratio
            CASE 
                WHEN psi.idx_tup_read > 0 
                THEN (psi.idx_tup_fetch::NUMERIC / psi.idx_tup_read * 100)
                ELSE 0 
            END as fetch_ratio
        FROM pg_stat_user_indexes psi
        JOIN pg_index i ON psi.indexrelid = i.indexrelid
        LEFT JOIN pg_stat_user_tables pst ON psi.schemaname = pst.schemaname 
            AND psi.relname = pst.relname
        WHERE psi.schemaname = 'public'
    LOOP
        INSERT INTO performance_index_metrics (
            index_name,
            table_name,
            schema_name,
            index_size_bytes,
            scans,
            tuples_read,
            tuples_fetched,
            scan_ratio,
            fetch_ratio,
            index_definition,
            is_unique,
            is_primary,
            is_partial
        ) VALUES (
            rec.indexname,
            rec.tablename,
            rec.schemaname,
            rec.index_size,
            rec.idx_scan,
            rec.idx_tup_read,
            rec.idx_tup_fetch,
            rec.scan_ratio,
            rec.fetch_ratio,
            rec.indexdef,
            rec.indisunique,
            rec.indisprimary,
            rec.is_partial
        );
        
        inserted_count := inserted_count + 1;
    END LOOP;
    
    RETURN inserted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to collect connection metrics
CREATE OR REPLACE FUNCTION collect_connection_metrics()
RETURNS VOID AS $$
DECLARE
    connections_by_state JSONB;
    connections_by_user JSONB;
    connections_by_db JSONB;
    total_conn INTEGER;
    active_conn INTEGER;
    idle_conn INTEGER;
    idle_in_tx INTEGER;
    longest_duration INTERVAL;
    queries_1min INTEGER;
    queries_5min INTEGER;
BEGIN
    -- Get connection counts by state
    SELECT json_object_agg(state, count)::JSONB INTO connections_by_state
    FROM (
        SELECT state, COUNT(*) as count
        FROM pg_stat_activity
        WHERE state IS NOT NULL
        GROUP BY state
    ) s;
    
    -- Get connection counts by user
    SELECT json_object_agg(usename, count)::JSONB INTO connections_by_user
    FROM (
        SELECT usename, COUNT(*) as count
        FROM pg_stat_activity
        WHERE usename IS NOT NULL
        GROUP BY usename
    ) u;
    
    -- Get connection counts by database
    SELECT json_object_agg(datname, count)::JSONB INTO connections_by_db
    FROM (
        SELECT datname, COUNT(*) as count
        FROM pg_stat_activity
        WHERE datname IS NOT NULL
        GROUP BY datname
    ) d;
    
    -- Get overall connection metrics
    SELECT 
        COUNT(*),
        COUNT(*) FILTER (WHERE state = 'active'),
        COUNT(*) FILTER (WHERE state = 'idle'),
        COUNT(*) FILTER (WHERE state = 'idle in transaction'),
        MAX(now() - query_start),
        COUNT(*) FILTER (WHERE now() - query_start > INTERVAL '1 minute'),
        COUNT(*) FILTER (WHERE now() - query_start > INTERVAL '5 minutes')
    INTO 
        total_conn, active_conn, idle_conn, idle_in_tx, 
        longest_duration, queries_1min, queries_5min
    FROM pg_stat_activity
    WHERE state IS NOT NULL;
    
    -- Insert metrics
    INSERT INTO performance_connection_metrics (
        total_connections,
        active_connections,
        idle_connections,
        idle_in_transaction,
        connections_by_state,
        connections_by_user,
        connections_by_database,
        longest_query_duration,
        queries_over_1min,
        queries_over_5min
    ) VALUES (
        total_conn,
        active_conn,
        idle_conn,
        idle_in_tx,
        connections_by_state,
        connections_by_user,
        connections_by_db,
        longest_duration,
        queries_1min,
        queries_5min
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to collect system metrics
CREATE OR REPLACE FUNCTION collect_system_metrics()
RETURNS VOID AS $$
DECLARE
    db_size BIGINT;
    cache_hit NUMERIC;
    buffer_cache_hit NUMERIC;
    commits_rate NUMERIC;
    rollbacks_rate NUMERIC;
    total_locks_count INTEGER;
    granted_locks_count INTEGER;
    waiting_locks_count INTEGER;
BEGIN
    -- Database size
    SELECT pg_database_size(current_database()) INTO db_size;
    
    -- Cache hit ratios
    SELECT 
        ROUND(
            (sum(heap_blks_hit) * 100.0) / 
            NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2
        )
    INTO cache_hit
    FROM pg_statio_user_tables;
    
    -- Buffer cache hit ratio
    SELECT 
        ROUND(
            (sum(heap_blks_hit) * 100.0) / 
            NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2
        )
    INTO buffer_cache_hit
    FROM pg_statio_user_tables;
    
    -- Transaction rates (simplified - would need baseline for accurate rates)
    SELECT 
        xact_commit / EXTRACT(EPOCH FROM (now() - stats_reset)),
        xact_rollback / EXTRACT(EPOCH FROM (now() - stats_reset))
    INTO commits_rate, rollbacks_rate
    FROM pg_stat_database 
    WHERE datname = current_database();
    
    -- Lock counts
    SELECT 
        COUNT(*),
        COUNT(*) FILTER (WHERE granted = true),
        COUNT(*) FILTER (WHERE granted = false)
    INTO total_locks_count, granted_locks_count, waiting_locks_count
    FROM pg_locks;
    
    -- Insert system metrics
    INSERT INTO performance_system_metrics (
        database_size_bytes,
        cache_hit_ratio,
        buffer_cache_hit_ratio,
        commits_per_second,
        rollbacks_per_second,
        total_locks,
        granted_locks,
        waiting_locks
    ) VALUES (
        db_size,
        COALESCE(cache_hit, 0),
        COALESCE(buffer_cache_hit, 0),
        COALESCE(commits_rate, 0),
        COALESCE(rollbacks_rate, 0),
        total_locks_count,
        granted_locks_count,
        waiting_locks_count
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SECTION 4: PERFORMANCE ANALYSIS VIEWS
-- ============================================

-- View for recent performance summary
CREATE OR REPLACE VIEW v_performance_summary AS
SELECT 
    'Database Size' as metric,
    pg_size_pretty(database_size_bytes) as current_value,
    LAG(pg_size_pretty(database_size_bytes)) OVER (ORDER BY collected_at) as previous_value,
    collected_at
FROM performance_system_metrics
WHERE collected_at >= NOW() - INTERVAL '24 hours'

UNION ALL

SELECT 
    'Cache Hit Ratio' as metric,
    cache_hit_ratio::TEXT || '%' as current_value,
    LAG(cache_hit_ratio::TEXT || '%') OVER (ORDER BY collected_at) as previous_value,
    collected_at
FROM performance_system_metrics
WHERE collected_at >= NOW() - INTERVAL '24 hours'

UNION ALL

SELECT 
    'Active Connections' as metric,
    active_connections::TEXT as current_value,
    LAG(active_connections::TEXT) OVER (ORDER BY collected_at) as previous_value,
    collected_at
FROM performance_connection_metrics
WHERE collected_at >= NOW() - INTERVAL '24 hours'

ORDER BY collected_at DESC, metric;

-- View for table performance analysis
CREATE OR REPLACE VIEW v_table_performance_analysis AS
SELECT 
    table_name,
    pg_size_pretty(total_size_bytes) as total_size,
    pg_size_pretty(table_size_bytes) as table_size,
    pg_size_pretty(index_size_bytes) as index_size,
    row_count,
    ROUND((index_size_bytes::NUMERIC / NULLIF(table_size_bytes, 0) * 100), 2) as index_ratio_pct,
    seq_scans,
    idx_scans,
    CASE 
        WHEN seq_scans + idx_scans > 0 
        THEN ROUND((idx_scans::NUMERIC / (seq_scans + idx_scans) * 100), 2)
        ELSE 0 
    END as index_usage_pct,
    inserts + updates + deletes as total_modifications,
    CASE 
        WHEN updates > 0 
        THEN ROUND((hot_updates::NUMERIC / updates * 100), 2)
        ELSE 0 
    END as hot_update_ratio_pct,
    collected_at
FROM performance_table_metrics
WHERE collected_at >= NOW() - INTERVAL '24 hours'
ORDER BY total_size_bytes DESC;

-- View for index effectiveness analysis
CREATE OR REPLACE VIEW v_index_effectiveness AS
SELECT 
    table_name,
    index_name,
    pg_size_pretty(index_size_bytes) as index_size,
    scans,
    CASE 
        WHEN scans = 0 THEN 'UNUSED'
        WHEN scans < 10 THEN 'LOW_USAGE'
        WHEN scans < 100 THEN 'MODERATE_USAGE'
        ELSE 'HIGH_USAGE'
    END as usage_category,
    scan_ratio,
    fetch_ratio,
    is_unique,
    is_primary,
    is_partial,
    collected_at
FROM performance_index_metrics
WHERE collected_at >= NOW() - INTERVAL '24 hours'
ORDER BY scans DESC;

-- View for slow query analysis
CREATE OR REPLACE VIEW v_slow_query_analysis AS
SELECT 
    LEFT(query_text, 100) as query_preview,
    execution_time_ms,
    rows_returned,
    operation_type,
    table_names,
    buffer_cache_hits,
    buffer_cache_misses,
    CASE 
        WHEN buffer_cache_hits + buffer_cache_misses > 0 
        THEN ROUND((buffer_cache_hits::NUMERIC / (buffer_cache_hits + buffer_cache_misses) * 100), 2)
        ELSE 0 
    END as cache_hit_ratio_pct,
    temp_files_created,
    pg_size_pretty(temp_bytes_written) as temp_data_written,
    created_at
FROM performance_query_log
WHERE created_at >= NOW() - INTERVAL '24 hours'
AND execution_time_ms > 100
ORDER BY execution_time_ms DESC;

-- ============================================
-- SECTION 5: AUTOMATED MONITORING PROCEDURES
-- ============================================

-- Main monitoring collection procedure
CREATE OR REPLACE FUNCTION run_performance_monitoring()
RETURNS TEXT AS $$
DECLARE
    table_metrics_count INTEGER;
    index_metrics_count INTEGER;
    result TEXT;
BEGIN
    -- Collect all performance metrics
    SELECT collect_table_performance_metrics() INTO table_metrics_count;
    SELECT collect_index_performance_metrics() INTO index_metrics_count;
    
    PERFORM collect_connection_metrics();
    PERFORM collect_system_metrics();
    
    -- Log slow queries from pg_stat_statements
    INSERT INTO performance_query_log (
        query_hash,
        query_text,
        execution_time_ms,
        rows_returned,
        operation_type,
        buffer_cache_hits,
        buffer_cache_misses,
        temp_files_created,
        temp_bytes_written
    )
    SELECT 
        md5(query),
        LEFT(query, 500),
        mean_exec_time,
        rows,
        CASE 
            WHEN query ILIKE 'SELECT%' THEN 'SELECT'
            WHEN query ILIKE 'INSERT%' THEN 'INSERT'
            WHEN query ILIKE 'UPDATE%' THEN 'UPDATE'
            WHEN query ILIKE 'DELETE%' THEN 'DELETE'
            ELSE 'OTHER'
        END,
        shared_blks_hit,
        shared_blks_read,
        temp_blks_written::INTEGER,
        temp_blks_written * 8192
    FROM pg_stat_statements
    WHERE mean_exec_time > 100
    AND calls >= 3
    ON CONFLICT DO NOTHING;
    
    result := format(
        'Performance monitoring completed: %s table metrics, %s index metrics collected at %s',
        table_metrics_count,
        index_metrics_count,
        NOW()::TEXT
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Performance health check function
CREATE OR REPLACE FUNCTION performance_health_check()
RETURNS TABLE (
    check_name TEXT,
    status TEXT,
    value TEXT,
    recommendation TEXT
) AS $$
BEGIN
    -- Cache hit ratio check
    RETURN QUERY
    SELECT 
        'Cache Hit Ratio'::TEXT,
        CASE 
            WHEN cache_hit_ratio >= 95 THEN 'GOOD'
            WHEN cache_hit_ratio >= 90 THEN 'WARNING'
            ELSE 'CRITICAL'
        END,
        cache_hit_ratio::TEXT || '%',
        CASE 
            WHEN cache_hit_ratio < 90 THEN 'Consider increasing shared_buffers or adding indexes'
            ELSE 'Cache performance is healthy'
        END
    FROM performance_system_metrics
    ORDER BY collected_at DESC
    LIMIT 1;
    
    -- Connection count check
    RETURN QUERY
    SELECT 
        'Active Connections'::TEXT,
        CASE 
            WHEN active_connections < 50 THEN 'GOOD'
            WHEN active_connections < 100 THEN 'WARNING'
            ELSE 'CRITICAL'
        END,
        active_connections::TEXT,
        CASE 
            WHEN active_connections >= 100 THEN 'High connection count - check for connection leaks'
            WHEN active_connections >= 50 THEN 'Monitor connection usage'
            ELSE 'Connection count is healthy'
        END
    FROM performance_connection_metrics
    ORDER BY collected_at DESC
    LIMIT 1;
    
    -- Unused indexes check
    RETURN QUERY
    SELECT 
        'Unused Indexes'::TEXT,
        CASE 
            WHEN COUNT(*) = 0 THEN 'GOOD'
            WHEN COUNT(*) <= 5 THEN 'WARNING'
            ELSE 'CRITICAL'
        END,
        COUNT(*)::TEXT,
        CASE 
            WHEN COUNT(*) > 5 THEN 'Consider dropping unused indexes to improve write performance'
            WHEN COUNT(*) > 0 THEN 'Review unused indexes'
            ELSE 'No unused indexes found'
        END
    FROM performance_index_metrics
    WHERE scans = 0
    AND collected_at >= NOW() - INTERVAL '24 hours';
    
    -- Large table scan check
    RETURN QUERY
    SELECT 
        'Large Table Scans'::TEXT,
        CASE 
            WHEN COUNT(*) = 0 THEN 'GOOD'
            WHEN COUNT(*) <= 3 THEN 'WARNING'
            ELSE 'CRITICAL'
        END,
        COUNT(*)::TEXT,
        CASE 
            WHEN COUNT(*) > 3 THEN 'Multiple tables doing sequential scans - add indexes'
            WHEN COUNT(*) > 0 THEN 'Some tables doing sequential scans'
            ELSE 'Index usage is optimal'
        END
    FROM performance_table_metrics
    WHERE seq_scans > idx_scans
    AND seq_scans > 100
    AND collected_at >= NOW() - INTERVAL '24 hours';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SECTION 6: CLEANUP AND MAINTENANCE
-- ============================================

-- Cleanup old performance data
CREATE OR REPLACE FUNCTION cleanup_performance_data(retention_days INTEGER DEFAULT 30)
RETURNS TEXT AS $$
DECLARE
    deleted_count INTEGER := 0;
    cutoff_date TIMESTAMPTZ;
BEGIN
    cutoff_date := NOW() - (retention_days || ' days')::INTERVAL;
    
    DELETE FROM performance_query_log WHERE created_at < cutoff_date;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    DELETE FROM performance_table_metrics WHERE collected_at < cutoff_date;
    DELETE FROM performance_index_metrics WHERE collected_at < cutoff_date;
    DELETE FROM performance_connection_metrics WHERE collected_at < cutoff_date;
    DELETE FROM performance_system_metrics WHERE collected_at < cutoff_date;
    
    RETURN format('Cleaned up %s old performance records older than %s days', 
                  deleted_count, retention_days);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- SECTION 7: SCHEDULING SETUP
-- ============================================

-- Note: These would be scheduled using pg_cron extension if available
-- Example scheduling commands (uncomment if pg_cron is installed):

-- Collect metrics every 5 minutes
-- SELECT cron.schedule('performance-monitoring', '*/5 * * * *', 'SELECT run_performance_monitoring();');

-- Cleanup old data daily
-- SELECT cron.schedule('performance-cleanup', '0 2 * * *', 'SELECT cleanup_performance_data(30);');

-- ============================================
-- SECTION 8: VALIDATION AND VERIFICATION
-- ============================================

-- Verify monitoring setup
SELECT 
    'Performance Monitoring Setup' as component,
    CASE 
        WHEN COUNT(*) >= 5 THEN 'SUCCESS'
        ELSE 'ERROR'
    END as status,
    'Created ' || COUNT(*) || ' monitoring tables' as details
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE 'performance_%';

-- Test monitoring functions
SELECT 'Monitoring Functions' as component,
    CASE 
        WHEN COUNT(*) >= 5 THEN 'SUCCESS'
        ELSE 'ERROR'
    END as status,
    'Created ' || COUNT(*) || ' monitoring functions' as details
FROM pg_proc 
WHERE proname LIKE '%performance%' OR proname LIKE '%monitoring%';

-- Initial data collection
SELECT run_performance_monitoring() as initial_collection_result;

-- Display setup summary
SELECT 
    'PERFORMANCE MONITORING SETUP COMPLETE' as title,
    '=========================================' as separator;

SELECT 'Tables Created' as metric, COUNT(*)::TEXT as value
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name LIKE 'performance_%';

SELECT 'Views Created' as metric, COUNT(*)::TEXT as value
FROM information_schema.views 
WHERE table_schema = 'public' AND table_name LIKE 'v_performance%';

SELECT 'Functions Created' as metric, COUNT(*)::TEXT as value
FROM pg_proc 
WHERE proname LIKE '%performance%' OR proname LIKE '%monitoring%';

-- Display initial health check
SELECT * FROM performance_health_check();