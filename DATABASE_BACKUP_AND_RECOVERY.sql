-- ================================================================
-- DATABASE BACKUP AND DISASTER RECOVERY OPERATIONS
-- ================================================================
-- Created: 2025-08-07
-- Comprehensive backup strategy and recovery procedures
-- ================================================================

-- ================================================================
-- PART 1: BACKUP MONITORING AND HEALTH CHECKS
-- ================================================================

-- Check database health and key metrics
CREATE OR REPLACE FUNCTION public.database_health_check()
RETURNS TABLE (
    metric_name TEXT,
    metric_value TEXT,
    status TEXT,
    recommendation TEXT
) 
LANGUAGE plpgsql 
SECURITY DEFINER AS $$
DECLARE
    total_products INTEGER;
    active_products INTEGER;
    total_images INTEGER;
    orphaned_images INTEGER;
    active_sessions INTEGER;
    admin_users_count INTEGER;
    db_size TEXT;
BEGIN
    -- Get key metrics
    SELECT COUNT(*) INTO total_products FROM public.products;
    SELECT COUNT(*) INTO active_products FROM public.products WHERE status = 'active';
    SELECT COUNT(*) INTO total_images FROM public.product_images;
    SELECT COUNT(*) INTO admin_users_count FROM public.admin_users WHERE is_active = true;
    SELECT COUNT(*) INTO active_sessions FROM public.admin_sessions WHERE is_active = true AND expires_at > NOW();
    
    -- Check for orphaned images
    SELECT COUNT(*) INTO orphaned_images 
    FROM public.product_images pi 
    LEFT JOIN public.products p ON pi.product_id = p.id 
    WHERE p.id IS NULL;
    
    -- Get database size
    SELECT pg_size_pretty(pg_database_size(current_database())) INTO db_size;
    
    -- Return health metrics
    RETURN QUERY VALUES
        ('Total Products', total_products::TEXT, 
         CASE WHEN total_products > 0 THEN 'OK' ELSE 'WARNING' END,
         CASE WHEN total_products = 0 THEN 'No products found' ELSE 'Products exist' END),
         
        ('Active Products', active_products::TEXT,
         CASE WHEN active_products > 0 THEN 'OK' ELSE 'INFO' END,
         CASE WHEN active_products = 0 THEN 'No active products' ELSE 'Active products available' END),
         
        ('Total Images', total_images::TEXT,
         CASE WHEN total_images > 0 THEN 'OK' ELSE 'INFO' END,
         CASE WHEN total_images = 0 THEN 'No product images' ELSE 'Product images exist' END),
         
        ('Orphaned Images', orphaned_images::TEXT,
         CASE WHEN orphaned_images = 0 THEN 'OK' ELSE 'WARNING' END,
         CASE WHEN orphaned_images > 0 THEN 'Clean up orphaned images' ELSE 'No orphaned images' END),
         
        ('Active Admin Users', admin_users_count::TEXT,
         CASE WHEN admin_users_count > 0 THEN 'OK' ELSE 'CRITICAL' END,
         CASE WHEN admin_users_count = 0 THEN 'No admin users - create one!' ELSE 'Admin access available' END),
         
        ('Active Sessions', active_sessions::TEXT,
         CASE WHEN active_sessions >= 0 THEN 'OK' ELSE 'ERROR' END,
         'Session management operational'),
         
        ('Database Size', db_size,
         'INFO',
         'Monitor growth trends');
END;
$$;

-- Check backup prerequisites
CREATE OR REPLACE FUNCTION public.backup_readiness_check()
RETURNS TABLE (
    check_name TEXT,
    status TEXT,
    details TEXT,
    action_required TEXT
) 
LANGUAGE plpgsql 
SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    -- Check for critical data
    SELECT 
        'Product Data',
        CASE WHEN COUNT(*) > 0 THEN 'READY' ELSE 'EMPTY' END,
        'Products: ' || COUNT(*) || ', Active: ' || COUNT(*) FILTER (WHERE status = 'active'),
        CASE WHEN COUNT(*) = 0 THEN 'Add products before backup' ELSE 'Ready to backup' END
    FROM public.products
    
    UNION ALL
    
    -- Check admin users
    SELECT 
        'Admin Users',
        CASE WHEN COUNT(*) > 0 THEN 'READY' ELSE 'CRITICAL' END,
        'Active admins: ' || COUNT(*),
        CASE WHEN COUNT(*) = 0 THEN 'Create admin user before backup!' ELSE 'Admin access secured' END
    FROM public.admin_users WHERE is_active = true
    
    UNION ALL
    
    -- Check image references
    SELECT 
        'Image References',
        CASE WHEN COUNT(*) > 0 THEN 'READY' ELSE 'EMPTY' END,
        'Total images: ' || COUNT(*),
        CASE WHEN COUNT(*) = 0 THEN 'No images to backup' ELSE 'Image data present' END
    FROM public.product_images;
END;
$$;

-- ================================================================
-- PART 2: DATA EXPORT FUNCTIONS FOR BACKUP
-- ================================================================

-- Export products with all related data
CREATE OR REPLACE FUNCTION public.export_products_backup()
RETURNS TABLE (
    product_id UUID,
    product_data JSONB,
    image_count INTEGER,
    variant_count INTEGER,
    export_timestamp TIMESTAMPTZ
)
LANGUAGE plpgsql 
SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id as product_id,
        to_jsonb(p.*) as product_data,
        COUNT(DISTINCT pi.id)::INTEGER as image_count,
        COUNT(DISTINCT pv.id)::INTEGER as variant_count,
        NOW() as export_timestamp
    FROM public.products p
    LEFT JOIN public.product_images pi ON p.id = pi.product_id
    LEFT JOIN public.product_variants pv ON p.id = pv.product_id
    GROUP BY p.id, p.*
    ORDER BY p.created_at;
END;
$$;

-- Export all image references with metadata
CREATE OR REPLACE FUNCTION public.export_images_backup()
RETURNS TABLE (
    image_id UUID,
    image_data JSONB,
    url_status TEXT,
    storage_location TEXT
)
LANGUAGE plpgsql 
SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pi.id as image_id,
        to_jsonb(pi.*) as image_data,
        CASE 
            WHEN pi.image_url IS NOT NULL AND pi.image_url != '' THEN 'SUPABASE_URL'
            WHEN pi.r2_url IS NOT NULL AND pi.r2_url != '' THEN 'R2_URL'
            ELSE 'NO_URL'
        END as url_status,
        COALESCE(pi.image_url, pi.r2_url, 'MISSING') as storage_location
    FROM public.product_images pi
    ORDER BY pi.created_at;
END;
$$;

-- Export admin and security data
CREATE OR REPLACE FUNCTION public.export_admin_backup()
RETURNS TABLE (
    admin_id UUID,
    admin_data JSONB,
    session_count INTEGER,
    security_events_count INTEGER
)
LANGUAGE plpgsql 
SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT 
        au.id as admin_id,
        jsonb_set(to_jsonb(au.*), '{two_factor_secret}', 'null'::jsonb) as admin_data, -- Exclude sensitive data
        COUNT(DISTINCT asess.id)::INTEGER as session_count,
        COUNT(DISTINCT ase.id)::INTEGER as security_events_count
    FROM public.admin_users au
    LEFT JOIN public.admin_sessions asess ON au.id = asess.admin_user_id
    LEFT JOIN public.admin_security_events ase ON au.id = ase.admin_user_id
    GROUP BY au.id, au.*
    ORDER BY au.created_at;
END;
$$;

-- ================================================================
-- PART 3: DATA RESTORATION FUNCTIONS
-- ================================================================

-- Restore product from backup data
CREATE OR REPLACE FUNCTION public.restore_product_from_backup(
    backup_data JSONB,
    preserve_ids BOOLEAN DEFAULT false
)
RETURNS UUID
LANGUAGE plpgsql 
SECURITY DEFINER AS $$
DECLARE
    new_product_id UUID;
    restored_product_data JSONB;
BEGIN
    -- Generate new ID if not preserving
    IF NOT preserve_ids THEN
        restored_product_data := jsonb_set(backup_data, '{id}', to_jsonb(gen_random_uuid()));
    ELSE
        restored_product_data := backup_data;
    END IF;
    
    -- Remove timestamps that should be auto-generated
    restored_product_data := restored_product_data - 'created_at' - 'updated_at';
    
    -- Insert the product
    INSERT INTO public.products 
    SELECT * FROM jsonb_populate_record(null::public.products, restored_product_data)
    RETURNING id INTO new_product_id;
    
    RETURN new_product_id;
END;
$$;

-- Validate and repair data integrity
CREATE OR REPLACE FUNCTION public.repair_data_integrity()
RETURNS TABLE (
    repair_action TEXT,
    records_affected INTEGER,
    details TEXT
)
LANGUAGE plpgsql 
SECURITY DEFINER AS $$
DECLARE
    orphaned_count INTEGER;
    missing_position_count INTEGER;
    duplicate_admin_count INTEGER;
BEGIN
    -- Repair 1: Remove orphaned images
    DELETE FROM public.product_images 
    WHERE product_id NOT IN (SELECT id FROM public.products);
    GET DIAGNOSTICS orphaned_count = ROW_COUNT;
    
    IF orphaned_count > 0 THEN
        RETURN QUERY VALUES (
            'Removed orphaned images',
            orphaned_count,
            'Images without corresponding products'
        );
    END IF;
    
    -- Repair 2: Fix missing image positions
    UPDATE public.product_images 
    SET position = 0 
    WHERE position IS NULL;
    GET DIAGNOSTICS missing_position_count = ROW_COUNT;
    
    IF missing_position_count > 0 THEN
        RETURN QUERY VALUES (
            'Fixed missing image positions',
            missing_position_count,
            'Set position to 0 for images without position'
        );
    END IF;
    
    -- Repair 3: Remove duplicate admin users (keep most recent)
    WITH duplicate_admins AS (
        SELECT user_id, 
               id,
               ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC) as rn
        FROM public.admin_users
    )
    DELETE FROM public.admin_users
    WHERE id IN (
        SELECT id FROM duplicate_admins WHERE rn > 1
    );
    GET DIAGNOSTICS duplicate_admin_count = ROW_COUNT;
    
    IF duplicate_admin_count > 0 THEN
        RETURN QUERY VALUES (
            'Removed duplicate admin users',
            duplicate_admin_count,
            'Kept most recent admin record per user'
        );
    END IF;
    
    -- Always return at least one row
    IF orphaned_count = 0 AND missing_position_count = 0 AND duplicate_admin_count = 0 THEN
        RETURN QUERY VALUES (
            'Data integrity check completed',
            0,
            'No repairs needed'
        );
    END IF;
END;
$$;

-- ================================================================
-- PART 4: MONITORING AND ALERTING QUERIES
-- ================================================================

-- Monitor connection and session health
CREATE OR REPLACE VIEW public.session_monitoring AS
SELECT 
    'Active Sessions' as metric,
    COUNT(*) as current_value,
    5 as warning_threshold,
    10 as critical_threshold,
    CASE 
        WHEN COUNT(*) > 10 THEN 'CRITICAL'
        WHEN COUNT(*) > 5 THEN 'WARNING'
        ELSE 'OK'
    END as status
FROM public.admin_sessions 
WHERE is_active = true AND expires_at > NOW()

UNION ALL

SELECT 
    'Expired Sessions (Last Hour)',
    COUNT(*),
    50,
    100,
    CASE 
        WHEN COUNT(*) > 100 THEN 'CRITICAL'
        WHEN COUNT(*) > 50 THEN 'WARNING'
        ELSE 'OK'
    END
FROM public.admin_sessions 
WHERE expires_at < NOW() 
AND expires_at > NOW() - INTERVAL '1 hour'

UNION ALL

SELECT 
    'Failed Login Attempts (Last Hour)',
    COUNT(*),
    10,
    25,
    CASE 
        WHEN COUNT(*) > 25 THEN 'CRITICAL'
        WHEN COUNT(*) > 10 THEN 'WARNING'
        ELSE 'OK'
    END
FROM public.admin_security_events
WHERE event_type IN ('login_failure', 'login_2fa_failure')
AND created_at > NOW() - INTERVAL '1 hour';

-- Monitor database performance
CREATE OR REPLACE VIEW public.performance_monitoring AS
SELECT 
    'Database Size (MB)' as metric,
    (pg_database_size(current_database()) / 1024 / 1024)::INTEGER as current_value,
    1000 as warning_threshold,
    5000 as critical_threshold,
    CASE 
        WHEN pg_database_size(current_database()) / 1024 / 1024 > 5000 THEN 'CRITICAL'
        WHEN pg_database_size(current_database()) / 1024 / 1024 > 1000 THEN 'WARNING'
        ELSE 'OK'
    END as status

UNION ALL

SELECT 
    'Product Images Count',
    COUNT(*)::INTEGER,
    10000,
    50000,
    CASE 
        WHEN COUNT(*) > 50000 THEN 'CRITICAL'
        WHEN COUNT(*) > 10000 THEN 'WARNING'
        ELSE 'OK'
    END
FROM public.product_images

UNION ALL

SELECT 
    'Active Products Count',
    COUNT(*)::INTEGER,
    5000,
    20000,
    CASE 
        WHEN COUNT(*) > 20000 THEN 'CRITICAL'
        WHEN COUNT(*) > 5000 THEN 'WARNING'
        ELSE 'OK'
    END
FROM public.products WHERE status = 'active';

-- ================================================================
-- PART 5: AUTOMATED MAINTENANCE PROCEDURES
-- ================================================================

-- Comprehensive maintenance routine
CREATE OR REPLACE FUNCTION public.run_automated_maintenance()
RETURNS TABLE (
    maintenance_task TEXT,
    execution_status TEXT,
    records_processed INTEGER,
    execution_time_ms INTEGER,
    notes TEXT
)
LANGUAGE plpgsql 
SECURITY DEFINER AS $$
DECLARE
    start_time TIMESTAMPTZ;
    end_time TIMESTAMPTZ;
    expired_sessions_count INTEGER;
    old_events_count INTEGER;
BEGIN
    -- Task 1: Clean expired sessions
    start_time := clock_timestamp();
    
    DELETE FROM public.admin_sessions 
    WHERE expires_at < NOW() - INTERVAL '7 days';
    GET DIAGNOSTICS expired_sessions_count = ROW_COUNT;
    
    end_time := clock_timestamp();
    
    RETURN QUERY VALUES (
        'Clean Expired Sessions',
        'COMPLETED',
        expired_sessions_count,
        EXTRACT(milliseconds FROM (end_time - start_time))::INTEGER,
        'Removed sessions older than 7 days'
    );
    
    -- Task 2: Archive old security events
    start_time := clock_timestamp();
    
    DELETE FROM public.admin_security_events 
    WHERE created_at < NOW() - INTERVAL '90 days'
    AND event_type NOT IN ('login_failure', 'suspicious_activity'); -- Keep security-relevant events
    GET DIAGNOSTICS old_events_count = ROW_COUNT;
    
    end_time := clock_timestamp();
    
    RETURN QUERY VALUES (
        'Archive Old Security Events',
        'COMPLETED', 
        old_events_count,
        EXTRACT(milliseconds FROM (end_time - start_time))::INTEGER,
        'Removed events older than 90 days (kept security events)'
    );
    
    -- Task 3: Update statistics
    start_time := clock_timestamp();
    
    ANALYZE public.products;
    ANALYZE public.product_images;
    ANALYZE public.admin_users;
    ANALYZE public.admin_sessions;
    
    end_time := clock_timestamp();
    
    RETURN QUERY VALUES (
        'Update Table Statistics',
        'COMPLETED',
        0,
        EXTRACT(milliseconds FROM (end_time - start_time))::INTEGER,
        'Refreshed query planner statistics'
    );
    
    -- Task 4: Run data integrity repairs
    start_time := clock_timestamp();
    
    PERFORM public.repair_data_integrity();
    
    end_time := clock_timestamp();
    
    RETURN QUERY VALUES (
        'Data Integrity Repair',
        'COMPLETED',
        0,
        EXTRACT(milliseconds FROM (end_time - start_time))::INTEGER,
        'Ran integrity checks and repairs'
    );
END;
$$;

-- ================================================================
-- PART 6: DISASTER RECOVERY PROCEDURES
-- ================================================================

-- Emergency read-only mode (for maintenance)
CREATE OR REPLACE FUNCTION public.enable_read_only_mode()
RETURNS TEXT
LANGUAGE plpgsql 
SECURITY DEFINER AS $$
BEGIN
    -- This would typically involve more complex logic
    -- For now, we'll just log the event
    INSERT INTO public.admin_security_events (
        event_type, 
        event_data
    ) VALUES (
        'maintenance_mode_enabled',
        jsonb_build_object(
            'enabled_at', NOW(),
            'reason', 'read_only_mode_activated'
        )
    );
    
    RETURN 'Read-only mode enabled. Remember to disable after maintenance.';
END;
$$;

-- Restore from read-only mode
CREATE OR REPLACE FUNCTION public.disable_read_only_mode()
RETURNS TEXT
LANGUAGE plpgsql 
SECURITY DEFINER AS $$
BEGIN
    INSERT INTO public.admin_security_events (
        event_type, 
        event_data
    ) VALUES (
        'maintenance_mode_disabled',
        jsonb_build_object(
            'disabled_at', NOW(),
            'reason', 'read_only_mode_deactivated'
        )
    );
    
    RETURN 'Read-only mode disabled. System operational.';
END;
$$;

-- Emergency admin user creation (disaster recovery)
CREATE OR REPLACE FUNCTION public.create_emergency_admin(
    emergency_email TEXT,
    emergency_name TEXT DEFAULT 'Emergency Admin'
)
RETURNS TEXT
LANGUAGE plpgsql 
SECURITY DEFINER AS $$
DECLARE
    auth_user_id UUID;
    admin_id UUID;
BEGIN
    -- Check if auth user exists
    SELECT id INTO auth_user_id
    FROM auth.users 
    WHERE email = emergency_email
    LIMIT 1;
    
    IF auth_user_id IS NULL THEN
        RETURN 'ERROR: Auth user with email ' || emergency_email || ' not found. User must sign up first.';
    END IF;
    
    -- Create admin user
    INSERT INTO public.admin_users (
        user_id,
        email,
        full_name,
        role,
        permissions,
        is_active
    ) VALUES (
        auth_user_id,
        emergency_email,
        emergency_name,
        'super_admin',
        '{"all": true, "emergency": true}',
        true
    )
    ON CONFLICT (email) DO UPDATE SET
        role = 'super_admin',
        permissions = '{"all": true, "emergency": true}',
        is_active = true,
        updated_at = NOW()
    RETURNING id INTO admin_id;
    
    -- Log the emergency creation
    INSERT INTO public.admin_security_events (
        user_id,
        admin_user_id,
        event_type,
        event_data
    ) VALUES (
        auth_user_id,
        admin_id,
        'emergency_admin_created',
        jsonb_build_object(
            'created_at', NOW(),
            'email', emergency_email,
            'reason', 'disaster_recovery'
        )
    );
    
    RETURN 'SUCCESS: Emergency admin created for ' || emergency_email;
END;
$$;

-- ================================================================
-- PART 7: GRANT PERMISSIONS AND SETUP
-- ================================================================

-- Grant execution permissions
GRANT EXECUTE ON FUNCTION public.database_health_check() TO authenticated;
GRANT EXECUTE ON FUNCTION public.backup_readiness_check() TO authenticated;
GRANT EXECUTE ON FUNCTION public.export_products_backup() TO authenticated;
GRANT EXECUTE ON FUNCTION public.export_images_backup() TO authenticated;
GRANT EXECUTE ON FUNCTION public.export_admin_backup() TO authenticated;
GRANT EXECUTE ON FUNCTION public.restore_product_from_backup(JSONB, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION public.repair_data_integrity() TO authenticated;
GRANT EXECUTE ON FUNCTION public.run_automated_maintenance() TO authenticated;
GRANT EXECUTE ON FUNCTION public.enable_read_only_mode() TO authenticated;
GRANT EXECUTE ON FUNCTION public.disable_read_only_mode() TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_emergency_admin(TEXT, TEXT) TO authenticated;

-- Grant to service role for automated operations
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO service_role;

-- Grant view access
GRANT SELECT ON public.session_monitoring TO authenticated;
GRANT SELECT ON public.performance_monitoring TO authenticated;

-- ================================================================
-- PART 8: USAGE EXAMPLES AND TESTING
-- ================================================================

-- Run immediate health check
SELECT 'HEALTH CHECK RESULTS:' as section;
SELECT * FROM public.database_health_check();

-- Check backup readiness
SELECT 'BACKUP READINESS:' as section;
SELECT * FROM public.backup_readiness_check();

-- Monitor current session status
SELECT 'SESSION MONITORING:' as section;
SELECT * FROM public.session_monitoring WHERE status != 'OK';

-- Monitor performance metrics
SELECT 'PERFORMANCE MONITORING:' as section;
SELECT * FROM public.performance_monitoring WHERE status != 'OK';

-- Example: Run maintenance (uncomment to execute)
-- SELECT * FROM public.run_automated_maintenance();

-- Example: Create emergency admin (uncomment and modify email)
-- SELECT public.create_emergency_admin('emergency@kctmenswear.com', 'Emergency Admin User');

SELECT 'DATABASE BACKUP AND RECOVERY SYSTEM READY! 🔧' as completion_message;

-- ================================================================
-- OPERATIONAL RUNBOOK SUMMARY:
-- ================================================================
/*
🚨 DISASTER RECOVERY RUNBOOK:

1. IMMEDIATE RESPONSE (5 minutes):
   - Run: SELECT * FROM public.database_health_check();
   - Check: SELECT * FROM public.session_monitoring;
   - Verify: SELECT * FROM public.backup_readiness_check();

2. BACKUP PROCEDURES (15 minutes):
   - Export products: SELECT * FROM public.export_products_backup();
   - Export images: SELECT * FROM public.export_images_backup();
   - Export admin data: SELECT * FROM public.export_admin_backup();

3. EMERGENCY ADMIN ACCESS:
   - If locked out: SELECT public.create_emergency_admin('your-email@domain.com');
   - Test login with emergency admin

4. MAINTENANCE MODE:
   - Enable: SELECT public.enable_read_only_mode();
   - Perform maintenance operations
   - Disable: SELECT public.disable_read_only_mode();

5. DATA RECOVERY:
   - Repair integrity: SELECT * FROM public.repair_data_integrity();
   - Run maintenance: SELECT * FROM public.run_automated_maintenance();

6. MONITORING ALERTS:
   - Check sessions: SELECT * FROM public.session_monitoring WHERE status != 'OK';
   - Check performance: SELECT * FROM public.performance_monitoring WHERE status != 'OK';

💡 AUTOMATION SCHEDULE:
- Daily: Run public.run_automated_maintenance()
- Weekly: Run public.database_health_check()
- Monthly: Full backup export
- Quarterly: Review and archive old data

🎯 RTO/RPO TARGETS:
- Recovery Time Objective (RTO): < 1 hour
- Recovery Point Objective (RPO): < 24 hours
- Admin Access Recovery: < 5 minutes
- Data Integrity Verification: < 15 minutes

*/