-- CHECK ADMIN AUTHENTICATION STATUS

-- 1. Check if admin_users table exists and has data
SELECT 
    'Admin Users' as check_type,
    COUNT(*) as count,
    STRING_AGG(email, ', ') as emails
FROM admin_users
WHERE is_active = true;

-- 2. Check recent login attempts
SELECT 
    'Recent Logins' as activity,
    email,
    last_login,
    CASE 
        WHEN last_login > NOW() - INTERVAL '1 hour' THEN 'Recent'
        WHEN last_login > NOW() - INTERVAL '24 hours' THEN 'Today'
        ELSE 'Older'
    END as login_status
FROM admin_users
ORDER BY last_login DESC NULLS LAST
LIMIT 5;

-- 3. Check if there are any active sessions
SELECT 
    'Active Sessions' as check_type,
    COUNT(*) as active_count
FROM auth.sessions
WHERE expires_at > NOW();

-- 4. Create a test admin if none exist
DO $$
BEGIN
    -- Check if any admin exists
    IF NOT EXISTS (SELECT 1 FROM admin_users WHERE email = 'admin@kctmenswear.com') THEN
        INSERT INTO admin_users (
            email,
            role,
            permissions,
            is_active,
            created_at,
            updated_at
        ) VALUES (
            'admin@kctmenswear.com',
            'super_admin',
            '{"all": true}',
            true,
            NOW(),
            NOW()
        );
        RAISE NOTICE 'Test admin created: admin@kctmenswear.com';
    ELSE
        RAISE NOTICE 'Admin already exists: admin@kctmenswear.com';
    END IF;
END $$;

-- 5. Make sure the admin is linked to auth.users
UPDATE admin_users
SET auth_user_id = (
    SELECT id FROM auth.users 
    WHERE email = admin_users.email
    LIMIT 1
)
WHERE auth_user_id IS NULL
AND email IN (SELECT email FROM auth.users);

-- Final status
SELECT 
    'Ready Admins' as status,
    COUNT(*) as total,
    COUNT(CASE WHEN auth_user_id IS NOT NULL THEN 1 END) as linked_to_auth
FROM admin_users
WHERE is_active = true;