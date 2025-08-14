-- CREATE AUTH USER DIRECTLY
-- Use this if you want to create the auth user directly in SQL
-- instead of using the Supabase Dashboard

-- IMPORTANT: Change the password before running!
-- The default password is: KCT@dmin2025!

-- Create the auth user
INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    recovery_token,
    email_change_token_new,
    email_change
) VALUES (
    gen_random_uuid(),
    'admin@kctmenswear.com',
    crypt('KCT@dmin2025!', gen_salt('bf')), -- CHANGE THIS PASSWORD!
    NOW(),
    '{"provider": "email", "providers": ["email"]}',
    '{}',
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
) ON CONFLICT (email) DO NOTHING;

-- Link to admin_users
UPDATE admin_users
SET auth_user_id = (
    SELECT id FROM auth.users 
    WHERE email = 'admin@kctmenswear.com'
    LIMIT 1
)
WHERE email = 'admin@kctmenswear.com';

-- Verify the user was created and linked
SELECT 
    'Admin Setup Complete' as status,
    au.email,
    au.role,
    au.is_active,
    CASE 
        WHEN u.id IS NOT NULL THEN '✅ Auth user created'
        ELSE '❌ Auth user creation failed'
    END as auth_status,
    CASE 
        WHEN au.auth_user_id IS NOT NULL THEN '✅ Accounts linked'
        ELSE '❌ Accounts not linked'
    END as link_status
FROM admin_users au
LEFT JOIN auth.users u ON u.id = au.auth_user_id
WHERE au.email = 'admin@kctmenswear.com';

-- Show login instructions
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ ADMIN ACCOUNT CREATED';
    RAISE NOTICE '========================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Login credentials:';
    RAISE NOTICE '  Email: admin@kctmenswear.com';
    RAISE NOTICE '  Password: KCT@dmin2025!';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️ IMPORTANT: Change this password after first login!';
    RAISE NOTICE '';
    RAISE NOTICE 'Dashboard URL:';
    RAISE NOTICE 'https://super-admin-ey00lcmtt-ibrahimayads-projects.vercel.app/';
    RAISE NOTICE '';
    RAISE NOTICE '========================================';
END $$;