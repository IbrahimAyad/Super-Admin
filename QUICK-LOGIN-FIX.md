# 🚀 QUICK ADMIN LOGIN FIX

## Step 1: Run this SQL in Supabase
Go to your Supabase Dashboard → SQL Editor and run:

```sql
-- Create admin user in admin_users table
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
    permissions = '{"all": true}';

-- Create auth user with password
INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    'admin@kctmenswear.com',
    crypt('KCT@dmin2025!', gen_salt('bf')),
    NOW(),
    '{"provider": "email", "providers": ["email"]}',
    '{}',
    NOW(),
    NOW()
) ON CONFLICT (email) DO NOTHING;

-- Link them together
UPDATE admin_users
SET auth_user_id = (
    SELECT id FROM auth.users 
    WHERE email = 'admin@kctmenswear.com'
)
WHERE email = 'admin@kctmenswear.com';
```

## Step 2: Login to Admin Dashboard

1. **URL**: https://super-admin-ey00lcmtt-ibrahimayads-projects.vercel.app/
2. **Email**: admin@kctmenswear.com
3. **Password**: KCT@dmin2025!

## Step 3: If Still Loading...

Clear your browser cache:
- Chrome: Cmd+Shift+Delete → Clear browsing data
- Or try Incognito mode: Cmd+Shift+N

## Alternative: Quick Auth User Creation

If the SQL above doesn't work, use Supabase Dashboard:
1. Go to Authentication → Users
2. Click "Invite User"
3. Enter: admin@kctmenswear.com
4. Check your email and set password

## What You'll See Once Logged In:
- ✅ 274 products imported
- ✅ 399 variants with sizes
- ✅ 100% Stripe integration
- ✅ 262 product images
- ✅ All suits with proper sizing

## Still Having Issues?

Check browser console (F12) for specific errors and let me know!