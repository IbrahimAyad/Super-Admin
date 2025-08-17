# 🔧 Database Functions & CDN URLs Fix Guide

## Date: 2025-08-17

## 📊 Summary of Issues Found

### Database Issues:
1. **`get_recent_orders()`** - Exists but returns wrong column type (varchar vs text)
2. **`log_login_attempt()`** - Function doesn't exist at all  
3. **`transfer_guest_cart()`** - Wrong parameter names
4. **`login_attempts` table** - Has RLS permission issues

### CDN URLs:
✅ You have 196 corrected CDN URLs properly organized on `https://cdn.kctmenswear.com/`

## 🚀 How to Fix Database Issues

### Step 1: Run the SQL Fix Script

1. Go to your Supabase Dashboard
2. Navigate to SQL Editor
3. Copy and paste the contents of `fix-database-functions.sql`
4. Click "Run" to execute

This will:
- Fix the `get_recent_orders()` return type
- Create the missing `log_login_attempt()` function
- Fix `transfer_guest_cart()` parameters
- Create a `login_attempts` view for compatibility
- Add proper RLS policies

### Step 2: Temporary Code Fix (Optional)

Until the database functions are fixed, you can add error handling to prevent crashes:

#### In `/src/lib/services/authService.ts` (line 672):
```typescript
// Wrap the log_login_attempt call
try {
  const { data, error } = await supabase.rpc('log_login_attempt', {
    email,
    success
  });
  if (error) {
    // Fallback to auth_logs table
    await supabase.from('auth_logs').insert({
      user_email: email,
      action: 'login_attempt',
      success,
      metadata: { timestamp: new Date().toISOString() }
    });
  }
} catch (e) {
  console.warn('Login logging failed:', e);
}
```

#### In `/src/lib/services/business.ts` (line 266):
```typescript
// Wrap the transfer_guest_cart call
try {
  const { data, error } = await supabase.rpc('transfer_guest_cart', {
    p_guest_id: guestId,
    p_user_id: userId
  });
  if (error) {
    // Fallback: manually transfer
    await supabase
      .from('cart_items')
      .update({ user_id: userId, guest_id: null })
      .eq('guest_id', guestId);
  }
} catch (e) {
  console.warn('Cart transfer failed:', e);
}
```

## 📸 CDN Image URLs Update

Your corrected CDN URLs are ready at `https://cdn.kctmenswear.com/`:

### Categories:
- **Blazers**: 8 images (prom collection)
- **Double-Breasted Suits**: 15 images
- **Men's Shirts**: 23 images (turtlenecks, collarless, moc neck)
- **Accessories - Vests**: 51 images (all colors)
- **Accessories - Suspenders**: 24 images
- **Stretch Suits**: 22 images
- **Regular Suits**: 18 images
- **Tuxedos**: 35 images

### To Import These URLs:

```sql
-- Example: Update a product with new CDN URL
UPDATE products
SET primary_image = 'https://cdn.kctmenswear.com/tuxedos/black-paisley-tuxedo/main.webp'
WHERE sku = 'TUX-BLACK-PAISLEY';

-- Or batch update from your URL list
-- You can create an import script using the CORRECTED_MASTER_CDN_URLS.txt file
```

## ✅ Testing After Fixes

1. **Test Authentication**:
   - Try logging in
   - Check console for any RPC errors
   - Verify auth logs are being created

2. **Test Cart Transfer**:
   - Add items as guest
   - Login and verify cart transfers

3. **Test Dashboard**:
   - Check if recent orders display
   - Verify no 400/404 errors in console

4. **Test Image Loading**:
   - Verify CDN images load properly
   - Check for any CORS issues

## 🎯 Expected Results

After applying these fixes:
- ✅ No more 400/404 RPC errors
- ✅ Login process works smoothly
- ✅ Guest cart transfers properly
- ✅ Dashboard loads recent orders
- ✅ All product images load from CDN

## 📝 Notes

- The database functions were missing because they were never created during initial setup
- These functions are being called by the auth system but don't exist
- The CDN URLs are now properly structured and ready to use
- Consider running these fixes in staging first if you have a staging environment

## 🚨 If Issues Persist

1. Check Supabase logs for any SQL errors
2. Verify RLS policies are enabled
3. Ensure auth.users table has proper permissions
4. Check if cart_items table exists with guest_id column

## 📂 Files Created

1. `fix-database-functions.sql` - SQL script to fix all database issues
2. `fix-broken-rpc-calls.ts` - Guide for code fixes
3. `DATABASE_AND_CDN_FIX_GUIDE.md` - This comprehensive guide
4. `CORRECTED_MASTER_CDN_URLS.txt` - Your 196 CDN image URLs

Run the SQL fix script first, then test your authentication flow!