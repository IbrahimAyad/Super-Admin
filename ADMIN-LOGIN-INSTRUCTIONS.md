# Admin Dashboard Login Instructions

## 🔐 How to Access the Admin Dashboard

### Step 1: Make Sure You Have an Admin Account

Run this in your Supabase SQL Editor to check/create an admin:

```sql
-- Check if admin exists
SELECT email, role, is_active 
FROM admin_users 
WHERE is_active = true;

-- If no admin exists, create one
INSERT INTO admin_users (
    email,
    role,
    permissions,
    is_active,
    created_at,
    updated_at
) VALUES (
    'admin@kctmenswear.com',  -- Change this to your email
    'super_admin',
    '{"all": true}',
    true,
    NOW(),
    NOW()
) ON CONFLICT (email) DO NOTHING;
```

### Step 2: Create Auth User (if not exists)

Go to Supabase Dashboard → Authentication → Users
1. Click "Invite User" 
2. Enter the same email as above (admin@kctmenswear.com)
3. They'll receive an invite email to set password

OR create directly in SQL:

```sql
-- This creates a user with a temporary password
INSERT INTO auth.users (
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at
) VALUES (
    'admin@kctmenswear.com',
    crypt('TempPassword123!', gen_salt('bf')),  -- Change this password
    NOW(),
    NOW(),
    NOW()
) ON CONFLICT (email) DO NOTHING;

-- Link the auth user to admin_users
UPDATE admin_users
SET auth_user_id = (
    SELECT id FROM auth.users 
    WHERE email = admin_users.email
)
WHERE email = 'admin@kctmenswear.com';
```

### Step 3: Login to Admin Dashboard

1. Go to: https://super-admin-ey00lcmtt-ibrahimayads-projects.vercel.app/
2. Click "Login" or go to /login
3. Enter credentials:
   - Email: admin@kctmenswear.com
   - Password: (the one you set)

### Common Issues & Fixes:

**If "Loading dashboard..." persists:**
1. Check browser console for errors (F12)
2. Clear browser cache/cookies
3. Try incognito mode
4. Check if Supabase URL is correct in deployment

**If login fails:**
1. Verify the user exists in both `auth.users` and `admin_users`
2. Make sure `auth_user_id` is linked
3. Check that `is_active = true`

**Quick SQL Check:**
```sql
-- Verify admin setup
SELECT 
    au.email,
    au.role,
    au.is_active,
    au.auth_user_id,
    u.email as auth_email
FROM admin_users au
LEFT JOIN auth.users u ON u.id = au.auth_user_id
WHERE au.email = 'admin@kctmenswear.com';
```

## 🚀 Once Logged In:

You'll have access to:
- 274 products with complete data
- Order management
- Customer management  
- Inventory tracking
- Financial dashboard
- All products are ready for checkout with Stripe!

## Need Help?

If you still can't login, check:
1. Vercel deployment logs
2. Supabase logs (Dashboard → Logs → API)
3. Browser console for specific errors