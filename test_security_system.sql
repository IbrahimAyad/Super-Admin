-- ========================================
-- SECURITY AUDIT SYSTEM TESTS
-- ========================================
-- Comprehensive test suite to verify the security audit system
-- Run these tests after applying the migration to ensure everything works correctly
-- ========================================

-- ===========================================
-- 1. TABLE EXISTENCE AND STRUCTURE TESTS
-- ===========================================

-- Test 1: Verify all security tables exist
DO $$
DECLARE
    table_count INTEGER;
    expected_tables TEXT[] := ARRAY[
        'admin_activity_log',
        'admin_sessions',
        'admin_login_history', 
        'admin_security_settings',
        'security_events',
        'admin_password_history'
    ];
    missing_tables TEXT[] := '{}';
    table_name TEXT;
BEGIN
    FOREACH table_name IN ARRAY expected_tables
    LOOP
        SELECT COUNT(*)
        INTO table_count
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name = table_name;
          
        IF table_count = 0 THEN
            missing_tables := array_append(missing_tables, table_name);
        END IF;
    END LOOP;
    
    IF array_length(missing_tables, 1) > 0 THEN
        RAISE EXCEPTION 'Missing tables: %', array_to_string(missing_tables, ', ');
    ELSE
        RAISE NOTICE '✓ All security tables exist';
    END IF;
END $$;

-- Test 2: Verify indexes exist
DO $$
DECLARE
    index_count INTEGER;
    critical_indexes TEXT[] := ARRAY[
        'idx_admin_activity_log_admin_id',
        'idx_admin_sessions_admin_id',
        'idx_admin_login_history_admin_id',
        'idx_security_events_type_severity'
    ];
    missing_indexes TEXT[] := '{}';
    index_name TEXT;
BEGIN
    FOREACH index_name IN ARRAY critical_indexes
    LOOP
        SELECT COUNT(*)
        INTO index_count
        FROM pg_indexes
        WHERE schemaname = 'public'
          AND indexname = index_name;
          
        IF index_count = 0 THEN
            missing_indexes := array_append(missing_indexes, index_name);
        END IF;
    END LOOP;
    
    IF array_length(missing_indexes, 1) > 0 THEN
        RAISE EXCEPTION 'Missing indexes: %', array_to_string(missing_indexes, ', ');
    ELSE
        RAISE NOTICE '✓ All critical indexes exist';
    END IF;
END $$;

-- Test 3: Verify RLS is enabled
DO $$
DECLARE
    table_name TEXT;
    rls_enabled BOOLEAN;
    security_tables TEXT[] := ARRAY[
        'admin_activity_log',
        'admin_sessions',
        'admin_login_history',
        'admin_security_settings',
        'security_events',
        'admin_password_history'
    ];
BEGIN
    FOREACH table_name IN ARRAY security_tables
    LOOP
        SELECT relrowsecurity
        INTO rls_enabled
        FROM pg_class c
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE n.nspname = 'public'
          AND c.relname = table_name;
          
        IF NOT rls_enabled THEN
            RAISE EXCEPTION 'RLS not enabled on table: %', table_name;
        END IF;
    END LOOP;
    
    RAISE NOTICE '✓ RLS enabled on all security tables';
END $$;

-- ===========================================
-- 2. FUNCTION TESTS
-- ===========================================

-- Test 4: Test security functions exist and are callable
DO $$
DECLARE
    func_count INTEGER;
    security_functions TEXT[] := ARRAY[
        'check_failed_login_attempts',
        'validate_admin_session',
        'check_password_reuse',
        'create_security_event',
        'cleanup_audit_data'
    ];
    func_name TEXT;
BEGIN
    FOREACH func_name IN ARRAY security_functions
    LOOP
        SELECT COUNT(*)
        INTO func_count
        FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public'
          AND p.proname = func_name;
          
        IF func_count = 0 THEN
            RAISE EXCEPTION 'Security function missing: %', func_name;
        END IF;
    END LOOP;
    
    RAISE NOTICE '✓ All security functions exist';
END $$;

-- ===========================================
-- 3. DATA INSERTION TESTS
-- ===========================================

-- Test 5: Test basic data insertion (requires existing admin user)
DO $$
DECLARE
    test_admin_id UUID;
    test_session_id UUID;
    test_event_id UUID;
BEGIN
    -- Get first admin for testing
    SELECT id INTO test_admin_id FROM admin_users LIMIT 1;
    
    IF test_admin_id IS NULL THEN
        RAISE EXCEPTION 'No admin users found for testing. Create an admin user first.';
    END IF;
    
    -- Test admin_activity_log insertion
    INSERT INTO admin_activity_log (
        admin_id, action_type, resource_type, resource_name,
        action_details, ip_address
    ) VALUES (
        test_admin_id, 'TEST', 'test_resource', 'Test Resource',
        '{"test": true}', '127.0.0.1'
    );
    
    -- Test admin_sessions insertion
    INSERT INTO admin_sessions (
        admin_id, session_token, ip_address, expires_at
    ) VALUES (
        test_admin_id, 'test_session_' || gen_random_uuid()::text, 
        '127.0.0.1', NOW() + INTERVAL '1 hour'
    ) RETURNING id INTO test_session_id;
    
    -- Test admin_login_history insertion
    INSERT INTO admin_login_history (
        admin_id, event_type, ip_address, session_id
    ) VALUES (
        test_admin_id, 'LOGIN_SUCCESS', '127.0.0.1', test_session_id
    );
    
    -- Test security_events insertion using function
    SELECT create_security_event(
        'TEST_EVENT',
        'LOW',
        'Test security event',
        'This is a test event for validation',
        test_admin_id,
        '127.0.0.1'::inet,
        '{"test": true}'::jsonb
    ) INTO test_event_id;
    
    -- Test admin_password_history insertion
    INSERT INTO admin_password_history (
        admin_id, password_hash, change_reason
    ) VALUES (
        test_admin_id, 'test_hash_' || gen_random_uuid()::text, 'test'
    );
    
    RAISE NOTICE '✓ Basic data insertion tests passed';
    
    -- Cleanup test data
    DELETE FROM admin_activity_log WHERE resource_type = 'test_resource';
    DELETE FROM admin_sessions WHERE id = test_session_id;
    DELETE FROM admin_login_history WHERE session_id = test_session_id;
    DELETE FROM security_events WHERE id = test_event_id;
    DELETE FROM admin_password_history WHERE change_reason = 'test';
    
    RAISE NOTICE '✓ Test data cleaned up';
END $$;

-- ===========================================
-- 4. FUNCTION BEHAVIOR TESTS
-- ===========================================

-- Test 6: Test check_failed_login_attempts function
DO $$
DECLARE
    test_admin_id UUID;
    test_result JSON;
BEGIN
    SELECT id INTO test_admin_id FROM admin_users LIMIT 1;
    
    IF test_admin_id IS NULL THEN
        RAISE EXCEPTION 'No admin users found for testing';
    END IF;
    
    -- Insert test failed login attempts
    INSERT INTO admin_login_history (admin_id, event_type, ip_address, username)
    VALUES 
        (test_admin_id, 'LOGIN_FAILED', '192.168.1.100', 'test_user'),
        (test_admin_id, 'LOGIN_FAILED', '192.168.1.100', 'test_user'),
        (test_admin_id, 'LOGIN_FAILED', '192.168.1.101', 'test_user');
    
    -- Test the function
    SELECT check_failed_login_attempts(
        test_admin_id, 
        '192.168.1.100'::inet, 
        '1 hour'::interval
    ) INTO test_result;
    
    IF (test_result->>'user_failures')::integer >= 2 AND 
       (test_result->>'ip_failures')::integer >= 2 THEN
        RAISE NOTICE '✓ check_failed_login_attempts function working correctly';
    ELSE
        RAISE EXCEPTION 'check_failed_login_attempts function test failed: %', test_result;
    END IF;
    
    -- Cleanup
    DELETE FROM admin_login_history WHERE username = 'test_user';
END $$;

-- Test 7: Test password reuse function
DO $$
DECLARE
    test_admin_id UUID;
    test_hash VARCHAR := 'test_hash_' || gen_random_uuid()::text;
    reuse_result BOOLEAN;
BEGIN
    SELECT id INTO test_admin_id FROM admin_users LIMIT 1;
    
    -- Insert test password history
    INSERT INTO admin_password_history (admin_id, password_hash, change_reason)
    VALUES (test_admin_id, test_hash, 'test');
    
    -- Test reuse detection
    SELECT check_password_reuse(test_admin_id, test_hash, 12) INTO reuse_result;
    
    IF reuse_result THEN
        RAISE NOTICE '✓ check_password_reuse function working correctly';
    ELSE
        RAISE EXCEPTION 'check_password_reuse function should have detected reuse';
    END IF;
    
    -- Test non-reuse
    SELECT check_password_reuse(test_admin_id, 'different_hash', 12) INTO reuse_result;
    
    IF NOT reuse_result THEN
        RAISE NOTICE '✓ check_password_reuse function correctly allows new passwords';
    ELSE
        RAISE EXCEPTION 'check_password_reuse function incorrectly detected reuse';
    END IF;
    
    -- Cleanup
    DELETE FROM admin_password_history WHERE change_reason = 'test';
END $$;

-- Test 8: Test session validation function
DO $$
DECLARE
    test_admin_id UUID;
    test_session_token VARCHAR := 'test_token_' || gen_random_uuid()::text;
    test_session_id UUID;
    validation_result JSON;
BEGIN
    SELECT id INTO test_admin_id FROM admin_users WHERE is_active = true LIMIT 1;
    
    -- Create test session
    INSERT INTO admin_sessions (
        admin_id, session_token, ip_address, expires_at, is_active
    ) VALUES (
        test_admin_id, test_session_token, '127.0.0.1', 
        NOW() + INTERVAL '1 hour', true
    ) RETURNING id INTO test_session_id;
    
    -- Test validation
    SELECT validate_admin_session(test_session_token) INTO validation_result;
    
    IF (validation_result->>'valid')::boolean THEN
        RAISE NOTICE '✓ validate_admin_session function working correctly';
    ELSE
        RAISE EXCEPTION 'validate_admin_session function failed: %', validation_result;
    END IF;
    
    -- Test invalid session
    SELECT validate_admin_session('invalid_token') INTO validation_result;
    
    IF NOT (validation_result->>'valid')::boolean THEN
        RAISE NOTICE '✓ validate_admin_session correctly rejects invalid tokens';
    ELSE
        RAISE EXCEPTION 'validate_admin_session should reject invalid tokens';
    END IF;
    
    -- Cleanup
    DELETE FROM admin_sessions WHERE id = test_session_id;
END $$;

-- ===========================================
-- 5. TRIGGER TESTS
-- ===========================================

-- Test 9: Test updated_at triggers
DO $$
DECLARE
    test_admin_id UUID;
    test_settings_id UUID;
    old_updated_at TIMESTAMPTZ;
    new_updated_at TIMESTAMPTZ;
BEGIN
    SELECT id INTO test_admin_id FROM admin_users LIMIT 1;
    
    -- Test admin_security_settings trigger
    SELECT id, updated_at 
    INTO test_settings_id, old_updated_at
    FROM admin_security_settings 
    WHERE admin_id = test_admin_id;
    
    -- Wait a moment then update
    PERFORM pg_sleep(1);
    
    UPDATE admin_security_settings 
    SET email_security_alerts = NOT email_security_alerts
    WHERE id = test_settings_id;
    
    SELECT updated_at INTO new_updated_at
    FROM admin_security_settings
    WHERE id = test_settings_id;
    
    IF new_updated_at > old_updated_at THEN
        RAISE NOTICE '✓ updated_at trigger working correctly';
    ELSE
        RAISE EXCEPTION 'updated_at trigger not working';
    END IF;
END $$;

-- ===========================================
-- 6. PERFORMANCE TESTS
-- ===========================================

-- Test 10: Query performance test
DO $$
DECLARE
    start_time TIMESTAMPTZ;
    end_time TIMESTAMPTZ;
    duration INTERVAL;
BEGIN
    -- Test activity log query performance
    start_time := clock_timestamp();
    
    PERFORM COUNT(*)
    FROM admin_activity_log aal
    JOIN admin_users au ON aal.admin_id = au.id
    WHERE aal.created_at > NOW() - INTERVAL '30 days';
    
    end_time := clock_timestamp();
    duration := end_time - start_time;
    
    IF duration < INTERVAL '1 second' THEN
        RAISE NOTICE '✓ Activity log query performance acceptable: %', duration;
    ELSE
        RAISE WARNING 'Activity log query slow: %', duration;
    END IF;
    
    -- Test session query performance
    start_time := clock_timestamp();
    
    PERFORM COUNT(*)
    FROM admin_sessions s
    JOIN admin_users au ON s.admin_id = au.id
    WHERE s.is_active = true;
    
    end_time := clock_timestamp();
    duration := end_time - start_time;
    
    IF duration < INTERVAL '0.5 seconds' THEN
        RAISE NOTICE '✓ Session query performance acceptable: %', duration;
    ELSE
        RAISE WARNING 'Session query slow: %', duration;
    END IF;
END $$;

-- ===========================================
-- 7. SECURITY POLICY TESTS (Run as different roles)
-- ===========================================

-- Test 11: Test RLS policies (manual test - requires different user contexts)
/*
-- These tests need to be run with different user contexts
-- They're commented out as they require manual execution

-- Test as super admin (should see all data)
SET app.current_admin_id = 'super-admin-id';
SELECT COUNT(*) FROM admin_activity_log; -- Should return all records

-- Test as regular admin (should see limited data) 
SET app.current_admin_id = 'regular-admin-id';
SELECT COUNT(*) FROM admin_activity_log; -- Should return limited records

-- Test as unauthenticated (should see no data)
RESET app.current_admin_id;
SELECT COUNT(*) FROM admin_activity_log; -- Should return 0 or error
*/

-- ===========================================
-- 8. CLEANUP FUNCTION TEST
-- ===========================================

-- Test 12: Test cleanup function (safe test with short retention)
DO $$
DECLARE
    cleanup_result JSON;
    test_admin_id UUID;
BEGIN
    SELECT id INTO test_admin_id FROM admin_users LIMIT 1;
    
    -- Insert old test data
    INSERT INTO admin_activity_log (
        admin_id, action_type, resource_type, 
        created_at, compliance_flag
    ) VALUES (
        test_admin_id, 'TEST_OLD', 'test_cleanup',
        NOW() - INTERVAL '10 years', false
    );
    
    -- Run cleanup with very long retention (should not delete recent data)
    SELECT cleanup_audit_data(3650) INTO cleanup_result; -- 10 years
    
    IF cleanup_result->>'activity_logs' IS NOT NULL THEN
        RAISE NOTICE '✓ cleanup_audit_data function executed successfully: %', cleanup_result;
    ELSE
        RAISE EXCEPTION 'cleanup_audit_data function failed';
    END IF;
    
    -- Cleanup test data
    DELETE FROM admin_activity_log WHERE resource_type = 'test_cleanup';
END $$;

-- ===========================================
-- 9. VIEW TESTS
-- ===========================================

-- Test 13: Test security views
DO $$
DECLARE
    view_count INTEGER;
    security_views TEXT[] := ARRAY[
        'admin_activity_recent',
        'admin_sessions_active',
        'security_events_dashboard'
    ];
    view_name TEXT;
BEGIN
    FOREACH view_name IN ARRAY security_views
    LOOP
        SELECT COUNT(*)
        INTO view_count
        FROM information_schema.views
        WHERE table_schema = 'public'
          AND table_name = view_name;
          
        IF view_count = 0 THEN
            RAISE EXCEPTION 'Security view missing: %', view_name;
        END IF;
        
        -- Test that view is queryable
        EXECUTE 'SELECT COUNT(*) FROM ' || view_name;
    END LOOP;
    
    RAISE NOTICE '✓ All security views exist and are queryable';
END $$;

-- ===========================================
-- 10. FINAL VERIFICATION
-- ===========================================

-- Test 14: System health check
DO $$
DECLARE
    total_tables INTEGER;
    total_indexes INTEGER;
    total_functions INTEGER;
    total_policies INTEGER;
BEGIN
    -- Count security tables
    SELECT COUNT(*)
    INTO total_tables
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name IN (
          'admin_activity_log', 'admin_sessions', 'admin_login_history',
          'admin_security_settings', 'security_events', 'admin_password_history'
      );
    
    -- Count security indexes
    SELECT COUNT(*)
    INTO total_indexes
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename IN (
          'admin_activity_log', 'admin_sessions', 'admin_login_history',
          'admin_security_settings', 'security_events', 'admin_password_history'
      );
    
    -- Count security functions
    SELECT COUNT(*)
    INTO total_functions
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
      AND p.proname IN (
          'check_failed_login_attempts', 'validate_admin_session',
          'check_password_reuse', 'create_security_event', 'cleanup_audit_data'
      );
    
    -- Count RLS policies
    SELECT COUNT(*)
    INTO total_policies
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN (
          'admin_activity_log', 'admin_sessions', 'admin_login_history',
          'admin_security_settings', 'security_events', 'admin_password_history'
      );
    
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'SECURITY AUDIT SYSTEM HEALTH CHECK';
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'Security Tables: %/6', total_tables;
    RAISE NOTICE 'Security Indexes: %', total_indexes;
    RAISE NOTICE 'Security Functions: %/5', total_functions;
    RAISE NOTICE 'RLS Policies: %', total_policies;
    RAISE NOTICE '===========================================';
    
    IF total_tables = 6 AND total_functions = 5 THEN
        RAISE NOTICE '✅ SECURITY AUDIT SYSTEM FULLY OPERATIONAL';
    ELSE
        RAISE WARNING '⚠️  SECURITY AUDIT SYSTEM PARTIALLY CONFIGURED';
    END IF;
END $$;

-- ===========================================
-- PERFORMANCE BASELINE
-- ===========================================

-- Create baseline performance metrics
INSERT INTO system_logs (operation, details)
SELECT 
    'security_system_baseline',
    json_build_object(
        'test_date', NOW(),
        'table_sizes', (
            SELECT json_object_agg(
                tablename,
                pg_size_pretty(pg_total_relation_size('public.'||tablename))
            )
            FROM pg_tables
            WHERE tablename IN (
                'admin_activity_log', 'admin_sessions', 'admin_login_history',
                'admin_security_settings', 'security_events', 'admin_password_history'
            )
        ),
        'index_count', (
            SELECT COUNT(*)
            FROM pg_indexes
            WHERE tablename IN (
                'admin_activity_log', 'admin_sessions', 'admin_login_history',
                'admin_security_settings', 'security_events', 'admin_password_history'
            )
        )
    );

RAISE NOTICE '✅ ALL SECURITY AUDIT SYSTEM TESTS COMPLETED SUCCESSFULLY';
RAISE NOTICE 'Review any warnings above and check system_logs table for baseline metrics';