-- ========================================
-- SECURITY MANAGEMENT QUERIES
-- ========================================
-- Common queries for managing the security audit system
-- Use these queries for monitoring, analysis, and maintenance
-- ========================================

-- ===========================================
-- 1. SECURITY MONITORING QUERIES
-- ===========================================

-- Check for suspicious login patterns (last 24 hours)
WITH suspicious_logins AS (
    SELECT 
        ip_address,
        COUNT(*) as attempt_count,
        COUNT(DISTINCT admin_id) as unique_admins,
        COUNT(*) FILTER (WHERE event_type = 'LOGIN_FAILED') as failed_attempts,
        COUNT(*) FILTER (WHERE event_type = 'LOGIN_SUCCESS') as successful_attempts,
        array_agg(DISTINCT username) FILTER (WHERE username IS NOT NULL) as usernames_tried,
        MIN(created_at) as first_attempt,
        MAX(created_at) as last_attempt
    FROM admin_login_history
    WHERE created_at > NOW() - INTERVAL '24 hours'
    GROUP BY ip_address
    HAVING COUNT(*) > 10 OR COUNT(DISTINCT admin_id) > 3
)
SELECT 
    ip_address,
    attempt_count,
    unique_admins,
    failed_attempts,
    successful_attempts,
    ROUND((failed_attempts::numeric / attempt_count) * 100, 2) as failure_rate,
    usernames_tried,
    first_attempt,
    last_attempt,
    last_attempt - first_attempt as attack_duration
FROM suspicious_logins
ORDER BY attempt_count DESC, failure_rate DESC;

-- Find admins with multiple active sessions from different locations
SELECT 
    au.role,
    COALESCE(auth_users.email, 'unknown') as email,
    COUNT(*) as active_sessions,
    array_agg(DISTINCT s.ip_address::text) as ip_addresses,
    array_agg(DISTINCT s.geolocation->>'country') as countries,
    MIN(s.last_activity_at) as oldest_session,
    MAX(s.last_activity_at) as newest_session
FROM admin_sessions s
JOIN admin_users au ON s.admin_id = au.id
LEFT JOIN auth.users auth_users ON au.user_id = auth_users.id
WHERE s.is_active = true
GROUP BY au.id, au.role, auth_users.email
HAVING COUNT(*) > 1 
   AND array_length(array_agg(DISTINCT s.geolocation->>'country'), 1) > 1
ORDER BY active_sessions DESC;

-- Recent high-severity security events
SELECT 
    event_type,
    severity,
    title,
    description,
    COALESCE(auth_users.email, 'unknown') as affected_admin,
    source_ip,
    source_country,
    detection_method,
    confidence_score,
    status,
    first_detected_at
FROM security_events se
LEFT JOIN admin_users au ON se.affected_admin_id = au.id
LEFT JOIN auth.users auth_users ON au.user_id = auth_users.id
WHERE first_detected_at > NOW() - INTERVAL '7 days'
  AND severity IN ('HIGH', 'CRITICAL')
ORDER BY first_detected_at DESC;

-- Admin activity summary (last 30 days)
SELECT 
    COALESCE(auth_users.email, 'unknown') as admin_email,
    au.role,
    COUNT(*) as total_actions,
    COUNT(DISTINCT action_type) as unique_action_types,
    COUNT(*) FILTER (WHERE severity IN ('HIGH', 'CRITICAL')) as high_severity_actions,
    COUNT(*) FILTER (WHERE compliance_flag = true) as compliance_actions,
    MIN(created_at) as first_action,
    MAX(created_at) as last_action,
    COUNT(DISTINCT DATE(created_at)) as active_days
FROM admin_activity_log aal
JOIN admin_users au ON aal.admin_id = au.id
LEFT JOIN auth.users auth_users ON au.user_id = auth_users.id
WHERE aal.created_at > NOW() - INTERVAL '30 days'
GROUP BY au.id, auth_users.email, au.role
ORDER BY total_actions DESC;

-- ===========================================
-- 2. COMPLIANCE AND AUDIT QUERIES
-- ===========================================

-- GDPR Data Access Report - All data for a specific admin
-- Replace 'admin-uuid-here' with actual admin ID
/*
SELECT 
    'admin_activity_log' as table_name,
    COUNT(*) as record_count,
    MIN(created_at) as earliest_record,
    MAX(created_at) as latest_record
FROM admin_activity_log
WHERE admin_id = 'admin-uuid-here'
UNION ALL
SELECT 
    'admin_sessions' as table_name,
    COUNT(*) as record_count,
    MIN(created_at) as earliest_record,
    MAX(created_at) as latest_record
FROM admin_sessions
WHERE admin_id = 'admin-uuid-here'
UNION ALL
SELECT 
    'admin_login_history' as table_name,
    COUNT(*) as record_count,
    MIN(created_at) as earliest_record,
    MAX(created_at) as latest_record
FROM admin_login_history
WHERE admin_id = 'admin-uuid-here'
ORDER BY table_name;
*/

-- Compliance audit trail for sensitive operations
SELECT 
    COALESCE(auth_users.email, 'unknown') as admin_email,
    aal.action_type,
    aal.resource_type,
    aal.resource_name,
    aal.severity,
    aal.created_at,
    aal.ip_address,
    aal.action_details
FROM admin_activity_log aal
JOIN admin_users au ON aal.admin_id = au.id
LEFT JOIN auth.users auth_users ON au.user_id = auth_users.id
WHERE aal.compliance_flag = true
  AND aal.action_type IN ('DELETE', 'UPDATE')
  AND aal.resource_type IN ('customer', 'order', 'admin_users')
  AND aal.created_at > NOW() - INTERVAL '90 days'
ORDER BY aal.created_at DESC;

-- Password security compliance report
SELECT 
    COALESCE(auth_users.email, 'unknown') as admin_email,
    au.role,
    ass.two_factor_enabled,
    ass.password_last_changed,
    CASE 
        WHEN ass.password_expires_at IS NOT NULL 
        THEN ass.password_expires_at - NOW()
        ELSE NULL 
    END as password_expires_in,
    ass.failed_login_attempts,
    ass.account_locked_until,
    CASE
        WHEN ass.password_last_changed < NOW() - INTERVAL '90 days' THEN 'Password Aged'
        WHEN ass.failed_login_attempts >= 3 THEN 'Multiple Failures'
        WHEN NOT ass.two_factor_enabled AND au.role = 'super_admin' THEN '2FA Required'
        ELSE 'Compliant'
    END as compliance_status
FROM admin_security_settings ass
JOIN admin_users au ON ass.admin_id = au.id
LEFT JOIN auth.users auth_users ON au.user_id = auth_users.id
WHERE au.is_active = true
ORDER BY 
    CASE compliance_status 
        WHEN 'Compliant' THEN 3
        ELSE 1
    END,
    auth_users.email;

-- ===========================================
-- 3. SECURITY ANALYTICS QUERIES
-- ===========================================

-- Login pattern analysis by hour of day (last 30 days)
SELECT 
    EXTRACT(HOUR FROM created_at) as hour_of_day,
    COUNT(*) as total_logins,
    COUNT(*) FILTER (WHERE event_type = 'LOGIN_SUCCESS') as successful_logins,
    COUNT(*) FILTER (WHERE event_type = 'LOGIN_FAILED') as failed_logins,
    ROUND(
        (COUNT(*) FILTER (WHERE event_type = 'LOGIN_FAILED')::numeric / COUNT(*)) * 100, 
        2
    ) as failure_rate
FROM admin_login_history
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY EXTRACT(HOUR FROM created_at)
ORDER BY hour_of_day;

-- Geographic distribution of admin access
SELECT 
    COALESCE(geolocation->>'country', 'Unknown') as country,
    COUNT(*) as login_count,
    COUNT(DISTINCT admin_id) as unique_admins,
    MIN(created_at) as first_seen,
    MAX(created_at) as last_seen
FROM admin_login_history
WHERE created_at > NOW() - INTERVAL '30 days'
  AND event_type = 'LOGIN_SUCCESS'
GROUP BY geolocation->>'country'
ORDER BY login_count DESC;

-- Session duration analysis
SELECT 
    COALESCE(auth_users.email, 'unknown') as admin_email,
    COUNT(*) as session_count,
    AVG(session_duration) as avg_session_duration,
    MIN(session_duration) as min_session_duration,
    MAX(session_duration) as max_session_duration,
    COUNT(*) FILTER (WHERE session_duration > INTERVAL '8 hours') as long_sessions
FROM admin_login_history alh
JOIN admin_users au ON alh.admin_id = au.id
LEFT JOIN auth.users auth_users ON au.user_id = auth_users.id
WHERE event_type = 'LOGOUT'
  AND created_at > NOW() - INTERVAL '30 days'
  AND session_duration IS NOT NULL
GROUP BY au.id, auth_users.email
ORDER BY avg_session_duration DESC;

-- ===========================================
-- 4. MAINTENANCE QUERIES
-- ===========================================

-- Check audit table sizes and growth
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
    pg_stat_get_tuples_returned(c.oid) as rows_read,
    pg_stat_get_tuples_inserted(c.oid) as rows_inserted
FROM pg_tables pt
JOIN pg_class c ON c.relname = pt.tablename
WHERE tablename IN (
    'admin_activity_log',
    'admin_sessions', 
    'admin_login_history',
    'admin_security_settings',
    'security_events',
    'admin_password_history'
)
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Find old records eligible for cleanup
SELECT 
    'admin_activity_log' as table_name,
    COUNT(*) as total_records,
    COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '2555 days' AND compliance_flag = false) as eligible_cleanup,
    MIN(created_at) as oldest_record,
    MAX(created_at) as newest_record
FROM admin_activity_log
UNION ALL
SELECT 
    'admin_login_history' as table_name,
    COUNT(*) as total_records,
    COUNT(*) FILTER (WHERE created_at < NOW() - INTERVAL '2555 days') as eligible_cleanup,
    MIN(created_at) as oldest_record,
    MAX(created_at) as newest_record
FROM admin_login_history
UNION ALL
SELECT 
    'admin_sessions' as table_name,
    COUNT(*) as total_records,
    COUNT(*) FILTER (WHERE is_active = false AND ended_at < NOW() - INTERVAL '2555 days') as eligible_cleanup,
    MIN(created_at) as oldest_record,
    MAX(created_at) as newest_record
FROM admin_sessions
ORDER BY table_name;

-- Index usage statistics
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE tablename IN (
    'admin_activity_log',
    'admin_sessions', 
    'admin_login_history',
    'admin_security_settings',
    'security_events',
    'admin_password_history'
)
ORDER BY tablename, idx_scan DESC;

-- ===========================================
-- 5. SECURITY RESPONSE QUERIES
-- ===========================================

-- Lock admin account (replace with actual admin ID)
/*
UPDATE admin_security_settings
SET account_locked_until = NOW() + INTERVAL '1 hour',
    lockout_reason = 'Security incident response',
    failed_login_attempts = 0
WHERE admin_id = 'admin-uuid-here';
*/

-- Revoke all active sessions for an admin
/*
UPDATE admin_sessions
SET is_active = false,
    ended_at = NOW(),
    end_reason = 'security'
WHERE admin_id = 'admin-uuid-here'
  AND is_active = true;
*/

-- Create security event for incident response
/*
SELECT create_security_event(
    'ACCOUNT_COMPROMISE',
    'HIGH',
    'Suspected account compromise detected',
    'Multiple failed login attempts followed by successful login from different geographic location',
    'admin-uuid-here',
    '192.168.1.100'::inet,
    '{"detection_rules": ["geo_anomaly", "brute_force"], "risk_score": 85}'::jsonb
);
*/

-- Find all actions by admin in time range (for incident investigation)
/*
SELECT 
    action_type,
    resource_type,
    resource_name,
    action_details,
    ip_address,
    created_at
FROM admin_activity_log
WHERE admin_id = 'admin-uuid-here'
  AND created_at BETWEEN '2024-01-01' AND '2024-01-02'
ORDER BY created_at;
*/

-- ===========================================
-- 6. PERFORMANCE MONITORING
-- ===========================================

-- Check for slow security queries
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    rows,
    100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) AS hit_percent
FROM pg_stat_statements
WHERE query LIKE '%admin_activity_log%' 
   OR query LIKE '%admin_sessions%'
   OR query LIKE '%admin_login_history%'
   OR query LIKE '%security_events%'
ORDER BY mean_time DESC
LIMIT 10;

-- Monitor failed login attempts in real-time
-- (This query can be used in monitoring dashboards)
SELECT 
    ip_address,
    COUNT(*) as attempts_last_hour,
    COUNT(DISTINCT username) as unique_usernames,
    array_agg(username ORDER BY created_at DESC) as recent_usernames,
    MAX(created_at) as last_attempt
FROM admin_login_history
WHERE event_type = 'LOGIN_FAILED'
  AND created_at > NOW() - INTERVAL '1 hour'
GROUP BY ip_address
HAVING COUNT(*) >= 5
ORDER BY attempts_last_hour DESC;

-- ===========================================
-- EXAMPLE USAGE
-- ===========================================

-- To run manual cleanup (be careful in production):
-- SELECT cleanup_audit_data(2555); -- Keep 7 years of data

-- To check if an admin session is valid:
-- SELECT validate_admin_session('session-token-here');

-- To check failed login attempts:
-- SELECT check_failed_login_attempts('admin-uuid', '192.168.1.100'::inet, '1 hour'::interval);

-- To verify password isn't reused:
-- SELECT check_password_reuse('admin-uuid', 'hashed-password', 12);