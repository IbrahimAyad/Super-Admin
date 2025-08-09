# Troubleshooting Guide

Common issues and solutions for the KCT Menswear Super Admin Dashboard.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Authentication Problems](#authentication-problems)
- [Database Errors](#database-errors)
- [Stripe Integration](#stripe-integration)
- [Email Issues](#email-issues)
- [Performance Problems](#performance-problems)
- [Deployment Issues](#deployment-issues)
- [Edge Functions](#edge-functions)
- [Common Error Messages](#common-error-messages)

## Installation Issues

### Node Version Errors

**Problem**: `EBADENGINE Unsupported engine` errors during npm install

**Solution**:
```bash
# Check current Node version
node --version

# Install Node 20+ using nvm
nvm install 20
nvm use 20

# Or using Homebrew
brew upgrade node

# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

### Missing Dependencies

**Problem**: Module not found errors

**Solution**:
```bash
# Clear npm cache
npm cache clean --force

# Remove node_modules and lockfile
rm -rf node_modules package-lock.json

# Reinstall
npm install

# If specific module is missing
npm install [module-name]
```

### Port Already in Use

**Problem**: `Port 8080 is already in use`

**Solution**:
```bash
# Find process using the port
lsof -i :8080

# Kill the process
kill -9 [PID]

# Or use a different port
npm run dev -- --port 3001
```

## Authentication Problems

### Cannot Log In

**Problem**: Login fails with valid credentials

**Checklist**:
1. Verify Supabase URL and anon key in `.env`
2. Check if user exists in auth.users table
3. Verify email is confirmed
4. Check RLS policies on admin_users table

**Solution**:
```sql
-- Check if user exists
SELECT * FROM auth.users WHERE email = 'your-email@example.com';

-- Check admin access
SELECT * FROM admin_users WHERE email = 'your-email@example.com';

-- Confirm email manually if needed
UPDATE auth.users 
SET email_confirmed_at = NOW() 
WHERE email = 'your-email@example.com';
```

### Session Expired

**Problem**: Constantly being logged out

**Solution**:
```javascript
// Check session in browser console
const { data: { session } } = await supabase.auth.getSession();
console.log('Session:', session);

// Refresh session manually
const { data, error } = await supabase.auth.refreshSession();
```

### Missing Admin Access

**Problem**: User can log in but sees "Access Denied"

**Solution**:
```sql
-- Add user to admin_users table
INSERT INTO admin_users (user_id, email, role, permissions, is_active)
SELECT id, email, 'admin', '["all"]'::jsonb, true
FROM auth.users
WHERE email = 'your-email@example.com';
```

## Database Errors

### RLS Policy Violations

**Problem**: `new row violates row-level security policy`

**Solution**:
```sql
-- Check RLS status
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';

-- View policies for a table
SELECT * FROM pg_policies 
WHERE tablename = 'your_table_name';

-- Temporarily disable RLS (development only!)
ALTER TABLE your_table_name DISABLE ROW LEVEL SECURITY;

-- Create proper policy
CREATE POLICY "Admin full access" ON your_table_name
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM admin_users 
    WHERE user_id = auth.uid() 
    AND is_active = true
  )
);
```

### Missing Tables

**Problem**: `relation "table_name" does not exist`

**Solution**:
```bash
# Run migrations in order
supabase db push

# Or run specific migration
supabase db execute -f supabase/migrations/001_create_admin_users.sql
```

### Foreign Key Violations

**Problem**: `violates foreign key constraint`

**Solution**:
```sql
-- Check foreign key relationships
SELECT
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY';

-- Fix orphaned records
DELETE FROM child_table 
WHERE parent_id NOT IN (SELECT id FROM parent_table);
```

## Stripe Integration

### Sync Timeout/Freezing

**Problem**: Stripe sync hangs or times out

**Solution**:
1. Reduce batch size to 3 or fewer products
2. Use dry run mode first
3. Check Stripe API status
4. Verify API keys are correct

```javascript
// Test Stripe connection
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY);
const products = await stripe.products.list({ limit: 1 });
console.log('Stripe connected:', products.data.length > 0);
```

### Missing Stripe Product IDs

**Problem**: Products not syncing to Stripe

**Solution**:
```sql
-- Check sync status
SELECT name, stripe_product_id, stripe_sync_status 
FROM products 
WHERE stripe_product_id IS NULL;

-- Check sync logs
SELECT * FROM stripe_sync_log 
WHERE status = 'failed' 
ORDER BY created_at DESC 
LIMIT 10;
```

### Webhook Failures

**Problem**: Stripe webhooks not being received

**Solution**:
1. Verify webhook endpoint URL in Stripe Dashboard
2. Check webhook signing secret
3. Ensure Edge Function is deployed
4. Check logs in Supabase Dashboard

```bash
# Test webhook locally
stripe listen --forward-to localhost:8080/api/stripe-webhook

# Trigger test event
stripe trigger payment_intent.succeeded
```

## Email Issues

### Emails Not Sending

**Problem**: Transactional emails not being delivered

**Checklist**:
1. Verify email service API key is set
2. Check Edge Function logs
3. Verify sender domain is authenticated
4. Check spam folders

**Solution**:
```bash
# Set email service key
supabase secrets set RESEND_API_KEY=your_key
# or
supabase secrets set SENDGRID_API_KEY=your_key

# Redeploy Edge Functions
supabase functions deploy
```

### Email Templates Not Found

**Problem**: `Template not found` error

**Solution**:
```sql
-- Check if templates exist
SELECT * FROM email_templates;

-- Insert default template
INSERT INTO email_templates (name, subject, body, variables)
VALUES (
  'order_confirmation',
  'Order Confirmation - {{order_number}}',
  'Thank you for your order...',
  '["order_number", "customer_name", "total"]'::jsonb
);
```

## Performance Problems

### Slow Page Load

**Problem**: Dashboard takes too long to load

**Solutions**:
1. **Enable caching**:
```javascript
// Add to React Query config
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000, // 5 minutes
      cacheTime: 10 * 60 * 1000, // 10 minutes
    },
  },
});
```

2. **Optimize queries**:
```sql
-- Add indexes
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX idx_products_category ON products(category);

-- Use pagination
SELECT * FROM orders 
ORDER BY created_at DESC 
LIMIT 50 OFFSET 0;
```

3. **Lazy load components**:
```javascript
const HeavyComponent = lazy(() => import('./HeavyComponent'));
```

### Memory Leaks

**Problem**: Browser becomes unresponsive over time

**Solution**:
```javascript
// Clean up subscriptions
useEffect(() => {
  const subscription = supabase
    .from('orders')
    .on('*', callback)
    .subscribe();

  return () => {
    subscription.unsubscribe();
  };
}, []);

// Clear intervals/timeouts
useEffect(() => {
  const timer = setInterval(fetchData, 5000);
  return () => clearInterval(timer);
}, []);
```

## Deployment Issues

### Build Failures

**Problem**: `npm run build` fails

**Common fixes**:
```bash
# Type errors
npm run typecheck

# Missing environment variables
cp .env.example .env
# Edit .env with your values

# Clear cache and rebuild
rm -rf dist node_modules
npm install
npm run build
```

### Environment Variables Not Working

**Problem**: `undefined` values in production

**Solution**:
1. Ensure variables start with `VITE_`
2. Rebuild after adding variables
3. Check hosting platform's env var settings

```javascript
// Debug environment variables
console.log('Env vars:', {
  supabaseUrl: import.meta.env.VITE_SUPABASE_URL,
  isDev: import.meta.env.DEV,
  isProd: import.meta.env.PROD,
});
```

### CORS Errors

**Problem**: `CORS policy` errors in production

**Solution**:
```typescript
// In Edge Function
const corsHeaders = {
  'Access-Control-Allow-Origin': '*', // Or specific domain
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// Return headers with response
return new Response(JSON.stringify(data), {
  headers: { ...corsHeaders, 'Content-Type': 'application/json' },
});
```

## Edge Functions

### Function Not Found

**Problem**: `Edge Function not found` error

**Solution**:
```bash
# List deployed functions
supabase functions list

# Deploy specific function
supabase functions deploy function-name

# Deploy all functions
supabase functions deploy
```

### Function Timeout

**Problem**: Edge Function times out

**Solution**:
1. Increase timeout in function config
2. Optimize function code
3. Use background jobs for long tasks

```typescript
// Add timeout handling
const controller = new AbortController();
const timeoutId = setTimeout(() => controller.abort(), 25000);

try {
  const response = await fetch(url, { signal: controller.signal });
  clearTimeout(timeoutId);
} catch (error) {
  if (error.name === 'AbortError') {
    console.log('Request timeout');
  }
}
```

### Secret Key Errors

**Problem**: `Missing required environment variable`

**Solution**:
```bash
# List current secrets
supabase secrets list

# Set missing secret
supabase secrets set KEY_NAME=value

# Set multiple secrets
supabase secrets set KEY1=value1 KEY2=value2
```

## Common Error Messages

### "Failed to fetch"

**Causes**:
- Network connectivity issues
- CORS problems
- Invalid API endpoint
- Server is down

**Solutions**:
1. Check network connection
2. Verify API URL is correct
3. Check browser console for details
4. Test API with curl/Postman

### "Invalid API key"

**Solution**:
```bash
# Verify keys match
echo $VITE_SUPABASE_ANON_KEY

# Check in Supabase Dashboard
# Settings > API > anon/public key
```

### "Rate limit exceeded"

**Solution**:
1. Implement request throttling
2. Use caching
3. Batch operations
4. Contact support for limit increase

```javascript
// Simple throttle
const throttle = (func, delay) => {
  let timeout;
  return (...args) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => func(...args), delay);
  };
};
```

### "Insufficient permissions"

**Solution**:
```sql
-- Check user permissions
SELECT * FROM admin_users 
WHERE user_id = auth.uid();

-- Grant permissions
UPDATE admin_users 
SET permissions = '["all"]'::jsonb 
WHERE user_id = 'user-uuid';
```

## Debug Tools

### Enable Debug Mode

```javascript
// Add to .env
VITE_DEBUG=true

// In code
if (import.meta.env.VITE_DEBUG) {
  console.log('Debug info:', data);
}
```

### Browser DevTools

```javascript
// Preserve logs
// Chrome: DevTools > Settings > Preserve log

// Monitor network
// Network tab > Filter by XHR/Fetch

// Check localStorage
localStorage.getItem('supabase.auth.token');
```

### Supabase Logs

```bash
# View function logs
supabase functions logs function-name

# View all logs
supabase logs
```

## Getting Help

### Before Asking for Help

1. Check this guide
2. Search [GitHub Issues](https://github.com/IbrahimAyad/Super-Admin/issues)
3. Check Supabase/Stripe status pages
4. Review recent commits for breaking changes

### When Asking for Help

Provide:
- Error message (full text)
- Browser console output
- Network tab screenshots
- Steps to reproduce
- Environment (OS, browser, Node version)
- Recent changes made

### Support Channels

- GitHub Issues: Bug reports and feature requests
- Email: support@kctmenswear.com
- Discord: Real-time help (if available)
- Stack Overflow: Tag with `kct-menswear`

## Prevention Tips

1. **Regular Backups**: Export database weekly
2. **Monitor Logs**: Check error logs daily
3. **Test in Staging**: Always test in staging first
4. **Version Control**: Commit working states
5. **Documentation**: Document custom changes
6. **Dependencies**: Keep dependencies updated
7. **Security**: Regular security audits

---

**Last Updated**: August 2025  
**Version**: 1.0.0