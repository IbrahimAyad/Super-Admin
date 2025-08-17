// Temporary fix for broken RPC calls
// This file shows what needs to be fixed in the codebase

/**
 * Files that need updating:
 * 
 * 1. /src/lib/services/authService.ts
 *    - Line 672: log_login_attempt
 *    - Lines 707, 798, 821: login_attempts table access
 * 
 * 2. /src/lib/services/business.ts  
 *    - Line 266: transfer_guest_cart
 * 
 * 3. /src/hooks/useDashboardData.ts
 *    - Likely has get_recent_orders call
 */

// Example fix for authService.ts - wrap in try/catch:
export const fixAuthService = `
  // Instead of:
  const { data, error } = await supabase.rpc('log_login_attempt', {
    email,
    success
  });

  // Use:
  try {
    const { data, error } = await supabase.rpc('log_login_attempt', {
      email,
      success
    });
    if (error) {
      console.warn('log_login_attempt not available:', error);
      // Fallback: log to auth_logs directly
      await supabase.from('auth_logs').insert({
        user_email: email,
        action: 'login_attempt',
        success,
        metadata: { timestamp: new Date().toISOString() }
      });
    }
  } catch (e) {
    console.warn('Login attempt logging failed:', e);
  }
`;

// Example fix for business.ts - wrap in try/catch:
export const fixBusinessService = `
  // Instead of:
  const { data, error } = await supabase.rpc('transfer_guest_cart', {
    p_guest_id: guestId,
    p_user_id: userId
  });

  // Use:
  try {
    const { data, error } = await supabase.rpc('transfer_guest_cart', {
      p_guest_id: guestId,
      p_user_id: userId  
    });
    if (error) {
      console.warn('transfer_guest_cart not available:', error);
      // Fallback: manually transfer cart items
      await supabase
        .from('cart_items')
        .update({ user_id: userId, guest_id: null })
        .eq('guest_id', guestId);
    }
  } catch (e) {
    console.warn('Cart transfer failed:', e);
  }
`;

// Example fix for login_attempts table access:
export const fixLoginAttemptsAccess = `
  // Instead of:
  const { data, error } = await supabase
    .from('login_attempts')
    .select('*')
    .eq('email', email);

  // Use:
  try {
    // Use auth_logs table instead
    const { data, error } = await supabase
      .from('auth_logs')
      .select('*')
      .eq('user_email', email)
      .eq('action', 'login_attempt');
    
    if (error) {
      console.warn('Could not fetch login attempts:', error);
      return [];
    }
    return data;
  } catch (e) {
    console.warn('Login attempts query failed:', e);
    return [];
  }
`;