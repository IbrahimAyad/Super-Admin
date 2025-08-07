-- ========================================
-- SETUP SECURITY FOR EXISTING ADMINS
-- ========================================
-- This script initializes security settings for existing admin users
-- Run this AFTER applying the main security audit migration
-- ========================================

-- ===========================================
-- 1. CREATE SECURITY SETTINGS FOR EXISTING ADMINS
-- ===========================================

-- Create default security settings for any admin users that don't have them
INSERT INTO admin_security_settings (
    admin_id,
    two_factor_enabled,
    password_expires_at,
    password_change_required,
    password_last_changed,
    max_concurrent_sessions,
    session_timeout_minutes,
    require_fresh_auth_for_sensitive,
    email_security_alerts,
    login_notification_enabled,
    suspicious_activity_alerts,
    gdpr_consent_given,
    data_retention_days,
    created_at,
    updated_at
)
SELECT 
    au.id as admin_id,
    false as two_factor_enabled, -- Start with 2FA disabled
    CASE 
        WHEN au.role = 'super_admin' THEN NOW() + INTERVAL '90 days'
        ELSE NOW() + INTERVAL '180 days'
    END as password_expires_at,
    false as password_change_required, -- Don't force immediate change
    NOW() - INTERVAL '30 days' as password_last_changed, -- Assume recent change
    CASE 
        WHEN au.role = 'super_admin' THEN 2
        WHEN au.role = 'admin' THEN 3  
        ELSE 3
    END as max_concurrent_sessions,
    CASE 
        WHEN au.role = 'super_admin' THEN 240 -- 4 hours for super admins
        ELSE 480 -- 8 hours for regular admins
    END as session_timeout_minutes,
    CASE 
        WHEN au.role = 'super_admin' THEN true
        ELSE false
    END as require_fresh_auth_for_sensitive,
    true as email_security_alerts,
    true as login_notification_enabled,
    true as suspicious_activity_alerts,
    false as gdpr_consent_given, -- Will need manual consent
    2555 as data_retention_days, -- 7 years default
    NOW() as created_at,
    NOW() as updated_at
FROM admin_users au
WHERE au.id NOT IN (
    SELECT admin_id FROM admin_security_settings
)
AND au.is_active = true;

-- Get count of settings created
DO $$
DECLARE
    settings_created INTEGER;
BEGIN
    GET DIAGNOSTICS settings_created = ROW_COUNT;
    RAISE NOTICE 'Created security settings for % existing admin users', settings_created;
END $$;

-- ===========================================
-- 2. CREATE INITIAL PASSWORD HISTORY
-- ===========================================

-- Create placeholder password history entries for existing admins
-- This prevents them from reusing their current password immediately
INSERT INTO admin_password_history (
    admin_id,
    password_hash,
    hash_algorithm,
    created_at,
    change_reason
)
SELECT 
    au.id as admin_id,
    'placeholder_hash_' || au.id::text as password_hash,
    'placeholder' as hash_algorithm,
    NOW() - INTERVAL '30 days' as created_at,
    'initial_setup' as change_reason
FROM admin_users au
WHERE au.id NOT IN (
    SELECT admin_id FROM admin_password_history
)
AND au.is_active = true;

-- Log password history creation
DO $$
DECLARE
    history_created INTEGER;
BEGIN
    GET DIAGNOSTICS history_created = ROW_COUNT;
    RAISE NOTICE 'Created initial password history for % admin users', history_created;
END $$;

-- ===========================================
-- 3. CREATE INITIAL ACTIVITY LOG ENTRIES
-- ===========================================

-- Log the security system setup for each admin
INSERT INTO admin_activity_log (
    admin_id,
    action_type,
    resource_type,
    resource_name,
    action_details,
    severity,
    compliance_flag,
    created_at
)
SELECT 
    au.id as admin_id,
    'SECURITY_SETUP' as action_type,
    'admin_security' as resource_type,
    'Security Audit System' as resource_name,
    json_build_object(
        'setup_type', 'initial',
        'role', au.role,
        'features_enabled', json_build_object(
            'activity_logging', true,
            'session_tracking', true,
            'login_history', true,
            'security_events', true,
            'password_history', true
        )
    ) as action_details,
    'INFO' as severity,
    true as compliance_flag,
    NOW() as created_at
FROM admin_users au
WHERE au.is_active = true;

-- ===========================================
-- 4. SETUP MONITORING ALERTS
-- ===========================================

-- Create initial security events for system setup
INSERT INTO security_events (
    event_type,
    severity,
    status,
    title,
    description,
    detection_method,
    confidence_score,
    event_data,
    first_detected_at,
    created_at
)
VALUES (
    'SYSTEM_SETUP',
    'LOW',
    'RESOLVED',
    'Security Audit System Initialized',
    'Security audit system has been successfully deployed and configured for all admin users',
    'automated',
    100,
    json_build_object(
        'setup_components', ARRAY[
            'admin_activity_log',
            'admin_sessions',
            'admin_login_history', 
            'admin_security_settings',
            'security_events',
            'admin_password_history'
        ],
        'admin_count', (SELECT COUNT(*) FROM admin_users WHERE is_active = true),
        'deployment_date', NOW()
    ),
    NOW(),
    NOW()
);

-- ===========================================
-- 5. VALIDATE SETUP
-- ===========================================

-- Validate that all active admins have security settings
DO $$
DECLARE
    total_admins INTEGER;
    admins_with_settings INTEGER;
    missing_settings INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_admins
    FROM admin_users
    WHERE is_active = true;
    
    SELECT COUNT(*) INTO admins_with_settings
    FROM admin_users au
    JOIN admin_security_settings ass ON au.id = ass.admin_id
    WHERE au.is_active = true;
    
    missing_settings := total_admins - admins_with_settings;
    
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'SECURITY SETUP VALIDATION';
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'Total active admins: %', total_admins;
    RAISE NOTICE 'Admins with security settings: %', admins_with_settings;
    RAISE NOTICE 'Missing security settings: %', missing_settings;
    
    IF missing_settings = 0 THEN
        RAISE NOTICE '✅ All active admins have security settings';
    ELSE
        RAISE WARNING '⚠️  % admins missing security settings', missing_settings;
    END IF;
END $$;

-- ===========================================
-- 6. CONFIGURATION RECOMMENDATIONS
-- ===========================================

-- Display recommendations for each admin role
DO $$
DECLARE
    rec_cursor CURSOR FOR
        SELECT 
            au.id,
            COALESCE(auth_users.email, 'unknown') as email,
            au.role,
            ass.two_factor_enabled,
            ass.password_expires_at,
            ass.max_concurrent_sessions
        FROM admin_users au
        LEFT JOIN auth.users auth_users ON au.user_id = auth_users.id
        JOIN admin_security_settings ass ON au.id = ass.admin_id
        WHERE au.is_active = true
        ORDER BY 
            CASE au.role 
                WHEN 'super_admin' THEN 1
                WHEN 'admin' THEN 2
                ELSE 3
            END,
            auth_users.email;
    
    admin_record RECORD;
BEGIN
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'SECURITY CONFIGURATION RECOMMENDATIONS';
    RAISE NOTICE '===========================================';
    
    FOR admin_record IN rec_cursor LOOP
        RAISE NOTICE 'Admin: % (Role: %)', admin_record.email, admin_record.role;
        
        -- 2FA recommendations
        IF admin_record.role = 'super_admin' AND NOT admin_record.two_factor_enabled THEN
            RAISE NOTICE '  🔒 CRITICAL: Enable 2FA immediately for super admin';
        ELSIF NOT admin_record.two_factor_enabled THEN
            RAISE NOTICE '  🔐 RECOMMENDED: Enable 2FA for enhanced security';
        ELSE
            RAISE NOTICE '  ✅ 2FA enabled';
        END IF;
        
        -- Password expiry
        IF admin_record.password_expires_at < NOW() + INTERVAL '30 days' THEN
            RAISE NOTICE '  ⏰ Password expires soon: %', admin_record.password_expires_at;
        END IF;
        
        -- Session limits
        IF admin_record.role = 'super_admin' AND admin_record.max_concurrent_sessions > 2 THEN
            RAISE NOTICE '  ⚠️  Consider reducing concurrent sessions for super admin (current: %)', 
                        admin_record.max_concurrent_sessions;
        END IF;
        
        RAISE NOTICE '  '; -- Empty line for readability
    END LOOP;
END $$;

-- ===========================================
-- 7. NEXT STEPS DOCUMENTATION
-- ===========================================

INSERT INTO system_logs (operation, details)
VALUES ('security_setup_complete', json_build_object(
    'setup_date', NOW(),
    'next_steps', ARRAY[
        'Enable 2FA for super admins',
        'Review and customize password policies',
        'Set up monitoring dashboard for security events',
        'Configure email notifications for security alerts',
        'Schedule regular security audits',
        'Train admins on new security features'
    ],
    'configuration_files', ARRAY[
        '041_security_audit_system.sql',
        'security_management_queries.sql',
        'test_security_system.sql',
        'setup_security_for_existing_admins.sql'
    ],
    'monitoring_queries', ARRAY[
        'Check for suspicious login patterns',
        'Monitor failed authentication attempts',
        'Review admin activity logs',
        'Analyze session patterns'
    ]
));

RAISE NOTICE '===========================================';
RAISE NOTICE '✅ SECURITY SETUP COMPLETE';
RAISE NOTICE '===========================================';
RAISE NOTICE 'Next Steps:';
RAISE NOTICE '1. Enable 2FA for super admin accounts';
RAISE NOTICE '2. Review security_management_queries.sql for monitoring';
RAISE NOTICE '3. Run test_security_system.sql to validate installation';
RAISE NOTICE '4. Set up automated monitoring dashboards';
RAISE NOTICE '5. Configure security alert notifications';
RAISE NOTICE '===========================================';

-- Display final statistics
SELECT 
    'Security Setup Summary' as summary,
    COUNT(DISTINCT au.id) as total_active_admins,
    COUNT(DISTINCT ass.admin_id) as admins_with_security_settings,
    COUNT(DISTINCT aph.admin_id) as admins_with_password_history,
    COUNT(*) FILTER (WHERE ass.two_factor_enabled = true) as admins_with_2fa,
    COUNT(*) FILTER (WHERE au.role = 'super_admin') as super_admins,
    COUNT(*) FILTER (WHERE au.role = 'super_admin' AND ass.two_factor_enabled = true) as super_admins_with_2fa
FROM admin_users au
LEFT JOIN admin_security_settings ass ON au.id = ass.admin_id
LEFT JOIN admin_password_history aph ON au.id = aph.admin_id
WHERE au.is_active = true;