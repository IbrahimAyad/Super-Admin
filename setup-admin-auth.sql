-- SETUP ADMIN AUTHENTICATION
-- Run this in Supabase SQL Editor to fix admin login

-- Step 1: Check current admin_users
SELECT 
    'Current Admin Users' as check_type,
    email,
    role,
    is_active,
    auth_user_id,
    created_at
FROM admin_users
ORDER BY created_at DESC;

-- Step 2: Create admin user if not exists
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
) ON CONFLICT (email) 
DO UPDATE SET
    is_active = true,
    role = 'super_admin',
    permissions = '{"all": true}',
    updated_at = NOW();

-- Step 3: Check if auth user exists
SELECT 
    'Auth User Status' as check_type,
    id,
    email,
    email_confirmed_at,
    created_at
FROM auth.users
WHERE email = 'admin@kctmenswear.com';

-- Step 4: Link auth user to admin_users
UPDATE admin_users
SET auth_user_id = (
    SELECT id FROM auth.users 
    WHERE email = admin_users.email
    LIMIT 1
)
WHERE email = 'admin@kctmenswear.com'
AND auth_user_id IS NULL;

-- Step 5: Verify the setup
SELECT 
    au.email,
    au.role,
    au.is_active,
    au.auth_user_id,
    u.email as auth_email,
    u.email_confirmed_at,
    CASE 
        WHEN u.id IS NOT NULL AND au.auth_user_id IS NOT NULL THEN '✅ Ready to login'
        WHEN u.id IS NOT NULL AND au.auth_user_id IS NULL THEN '⚠️ Need to link accounts'
        WHEN u.id IS NULL THEN '❌ Need to create auth user'
        ELSE '❓ Unknown status'
    END as status
FROM admin_users au
LEFT JOIN auth.users u ON u.id = au.auth_user_id
WHERE au.email = 'admin@kctmenswear.com';

-- Step 6: Show next steps
DO $$
DECLARE
    v_auth_exists BOOLEAN;
    v_is_linked BOOLEAN;
BEGIN
    -- Check if auth user exists
    SELECT EXISTS(
        SELECT 1 FROM auth.users WHERE email = 'admin@kctmenswear.com'
    ) INTO v_auth_exists;
    
    -- Check if properly linked
    SELECT EXISTS(
        SELECT 1 FROM admin_users 
        WHERE email = 'admin@kctmenswear.com' 
        AND auth_user_id IS NOT NULL
    ) INTO v_is_linked;
    
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'ADMIN SETUP STATUS';
    RAISE NOTICE '========================================';
    
    IF v_auth_exists AND v_is_linked THEN
        RAISE NOTICE '✅ Admin account is ready!';
        RAISE NOTICE '';
        RAISE NOTICE 'You can now login with:';
        RAISE NOTICE '  Email: admin@kctmenswear.com';
        RAISE NOTICE '  Password: [Use password reset if needed]';
    ELSIF v_auth_exists AND NOT v_is_linked THEN
        RAISE NOTICE '⚠️ Auth user exists but not linked';
        RAISE NOTICE 'Run the UPDATE statement above to link them';
    ELSE
        RAISE NOTICE '❌ Auth user does not exist';
        RAISE NOTICE '';
        RAISE NOTICE 'NEXT STEP:';
        RAISE NOTICE '1. Go to Supabase Dashboard → Authentication → Users';
        RAISE NOTICE '2. Click "Invite User"';
        RAISE NOTICE '3. Enter email: admin@kctmenswear.com';
        RAISE NOTICE '4. Check your email for the invite link';
        RAISE NOTICE '5. Set a password and confirm';
        RAISE NOTICE '6. Re-run this script to verify';
    END IF;
    
    RAISE NOTICE '========================================';
END $$;