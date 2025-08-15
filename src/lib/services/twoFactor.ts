/**
 * TWO-FACTOR AUTHENTICATION SERVICE
 * Handles TOTP generation, verification, and backup codes
 * Created: 2025-08-07
 */

import { TOTP, Secret } from 'otpauth';
import * as QRCode from 'qrcode';
import CryptoJS from 'crypto-js';
import { supabase } from '../supabase-client';

// Configuration
const CONFIG = {
  issuer: 'KCT Menswear Admin',
  algorithm: 'SHA1' as const,
  digits: 6,
  period: 30,
  window: 1, // Allow 1 step before/after current time
  backupCodesCount: 10,
};

// Encryption key for storing 2FA secrets (in production, use environment variable)
const ENCRYPTION_KEY = import.meta.env.VITE_2FA_ENCRYPTION_KEY || 'kct-admin-2fa-key-2025';

export interface TwoFactorSetupData {
  secret: string;
  qrCodeUrl: string;
  backupCodes: string[];
  manualEntryKey: string;
}

export interface AdminUserSecurity {
  id: string;
  two_factor_enabled: boolean;
  failed_login_attempts: number;
  account_locked_until?: string;
  last_login_at?: string;
}

/**
 * Encrypt sensitive data before storing in database
 */
function encryptData(data: string): string {
  return CryptoJS.AES.encrypt(data, ENCRYPTION_KEY).toString();
}

/**
 * Decrypt sensitive data when retrieving from database
 */
function decryptData(encryptedData: string): string {
  const bytes = CryptoJS.AES.decrypt(encryptedData, ENCRYPTION_KEY);
  return bytes.toString(CryptoJS.enc.Utf8);
}

/**
 * Generate a secure random secret for TOTP
 */
export function generateTOTPSecret(): string {
  const secret = new Secret({ size: 32 });
  return secret.base32;
}

/**
 * Generate backup codes for 2FA recovery
 */
export function generateBackupCodes(count: number = CONFIG.backupCodesCount): string[] {
  const codes: string[] = [];
  for (let i = 0; i < count; i++) {
    // Generate 8-character alphanumeric code
    const code = Math.random().toString(36).substring(2, 10).toUpperCase();
    codes.push(code);
  }
  return codes;
}

/**
 * Create TOTP instance with the given secret
 */
function createTOTP(secret: string, userEmail: string): TOTP {
  return new TOTP({
    issuer: CONFIG.issuer,
    label: userEmail,
    algorithm: CONFIG.algorithm,
    digits: CONFIG.digits,
    period: CONFIG.period,
    secret: Secret.fromBase32(secret),
  });
}

/**
 * Generate QR code URL for 2FA setup
 */
export async function generateQRCode(secret: string, userEmail: string): Promise<string> {
  try {
    const totp = createTOTP(secret, userEmail);
    const otpAuthUrl = totp.toString();
    const qrCodeUrl = await QRCode.toDataURL(otpAuthUrl);
    return qrCodeUrl;
  } catch (error) {
    console.error('Error generating QR code:', error);
    throw new Error('Failed to generate QR code');
  }
}

/**
 * Verify TOTP token
 */
export function verifyTOTPToken(secret: string, token: string, userEmail: string): boolean {
  try {
    const totp = createTOTP(secret, userEmail);
    const delta = totp.validate({ token, window: CONFIG.window });
    return delta !== null;
  } catch (error) {
    console.error('Error verifying TOTP token:', error);
    return false;
  }
}

/**
 * Setup 2FA for an admin user
 */
export async function setupTwoFactor(userEmail: string): Promise<{
  success: boolean;
  data?: TwoFactorSetupData;
  error?: string;
}> {
  try {
    const secret = generateTOTPSecret();
    const backupCodes = generateBackupCodes();
    const qrCodeUrl = await generateQRCode(secret, userEmail);
    
    const setupData: TwoFactorSetupData = {
      secret,
      qrCodeUrl,
      backupCodes,
      manualEntryKey: secret,
    };

    return {
      success: true,
      data: setupData,
    };
  } catch (error) {
    console.error('Error setting up 2FA:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to setup 2FA',
    };
  }
}

/**
 * Enable 2FA for admin user in database
 */
export async function enableTwoFactor(
  userId: string,
  secret: string,
  backupCodes: string[],
  verificationToken: string,
  userEmail: string
): Promise<{ success: boolean; error?: string }> {
  try {
    // First verify the token
    if (!verifyTOTPToken(secret, verificationToken, userEmail)) {
      return {
        success: false,
        error: 'Invalid verification code',
      };
    }

    // Encrypt secret and backup codes
    const encryptedSecret = encryptData(secret);
    const encryptedBackupCodes = backupCodes.map(code => encryptData(code));

    // Update admin user record
    const { error } = await supabase
      .from('admin_users')
      .update({
        two_factor_enabled: true,
        two_factor_secret: encryptedSecret,
        backup_codes: encryptedBackupCodes,
        updated_at: new Date().toISOString(),
      })
      .eq('user_id', userId);

    if (error) throw error;

    // Log security event
    await supabase.rpc('log_admin_security_event', {
      p_user_id: userId,
      p_admin_user_id: null,
      p_event_type: '2fa_enabled',
      p_event_data: { enabled_at: new Date().toISOString() },
    });

    return { success: true };
  } catch (error) {
    console.error('Error enabling 2FA:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to enable 2FA',
    };
  }
}

/**
 * Disable 2FA for admin user
 */
export async function disableTwoFactor(
  userId: string,
  verificationToken?: string,
  backupCode?: string
): Promise<{ success: boolean; error?: string }> {
  try {
    // Get current user's 2FA data
    const { data: adminUser, error: fetchError } = await supabase
      .from('admin_users')
      .select('two_factor_secret, backup_codes, user_id')
      .eq('user_id', userId)
      .single();

    if (fetchError || !adminUser) {
      return {
        success: false,
        error: 'Admin user not found',
      };
    }

    let isValid = false;

    // Verify either TOTP token or backup code
    if (verificationToken && adminUser.two_factor_secret) {
      const decryptedSecret = decryptData(adminUser.two_factor_secret);
      const { data: userData } = await supabase.auth.getUser();
      const userEmail = userData.user?.email || '';
      isValid = verifyTOTPToken(decryptedSecret, verificationToken, userEmail);
    } else if (backupCode && adminUser.backup_codes) {
      isValid = await verifyBackupCode(userId, backupCode);
    }

    if (!isValid) {
      return {
        success: false,
        error: 'Invalid verification code or backup code',
      };
    }

    // Disable 2FA
    const { error } = await supabase
      .from('admin_users')
      .update({
        two_factor_enabled: false,
        two_factor_secret: null,
        backup_codes: null,
        updated_at: new Date().toISOString(),
      })
      .eq('user_id', userId);

    if (error) throw error;

    // Log security event
    await supabase.rpc('log_admin_security_event', {
      p_user_id: userId,
      p_admin_user_id: null,
      p_event_type: '2fa_disabled',
      p_event_data: { disabled_at: new Date().toISOString() },
    });

    return { success: true };
  } catch (error) {
    console.error('Error disabling 2FA:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to disable 2FA',
    };
  }
}

/**
 * Verify 2FA token during login
 */
export async function verifyTwoFactorLogin(
  userId: string,
  token: string
): Promise<{ success: boolean; error?: string }> {
  try {
    // Get user's 2FA secret
    const { data: adminUser, error } = await supabase
      .from('admin_users')
      .select('two_factor_secret, two_factor_enabled')
      .eq('user_id', userId)
      .single();

    if (error || !adminUser || !adminUser.two_factor_enabled) {
      return {
        success: false,
        error: '2FA not enabled for this user',
      };
    }

    // Decrypt secret
    const decryptedSecret = decryptData(adminUser.two_factor_secret);
    
    // Get user email for TOTP verification
    const { data: userData } = await supabase.auth.getUser();
    const userEmail = userData.user?.email || '';

    // Verify token
    const isValid = verifyTOTPToken(decryptedSecret, token, userEmail);

    if (isValid) {
      // Log successful 2FA
      await supabase.rpc('log_admin_security_event', {
        p_user_id: userId,
        p_admin_user_id: null,
        p_event_type: 'login_2fa_success',
        p_event_data: { verified_at: new Date().toISOString() },
      });

      return { success: true };
    } else {
      // Log failed 2FA attempt
      await supabase.rpc('log_admin_security_event', {
        p_user_id: userId,
        p_admin_user_id: null,
        p_event_type: 'login_2fa_failure',
        p_event_data: { failed_at: new Date().toISOString() },
      });

      return {
        success: false,
        error: 'Invalid 2FA code',
      };
    }
  } catch (error) {
    console.error('Error verifying 2FA login:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to verify 2FA',
    };
  }
}

/**
 * Verify backup code and mark as used
 */
export async function verifyBackupCode(
  userId: string,
  code: string
): Promise<boolean> {
  try {
    // Get user's backup codes
    const { data: adminUser, error } = await supabase
      .from('admin_users')
      .select('backup_codes')
      .eq('user_id', userId)
      .single();

    if (error || !adminUser || !adminUser.backup_codes) {
      return false;
    }

    // Decrypt and check backup codes
    const decryptedCodes = adminUser.backup_codes.map((encryptedCode: string) => 
      decryptData(encryptedCode)
    );

    const codeIndex = decryptedCodes.findIndex(backupCode => 
      backupCode.toUpperCase() === code.toUpperCase()
    );

    if (codeIndex === -1) {
      return false;
    }

    // Remove used backup code
    const remainingCodes = [...adminUser.backup_codes];
    remainingCodes.splice(codeIndex, 1);

    // Update database
    const { error: updateError } = await supabase
      .from('admin_users')
      .update({
        backup_codes: remainingCodes,
        updated_at: new Date().toISOString(),
      })
      .eq('user_id', userId);

    if (updateError) {
      console.error('Error updating backup codes:', updateError);
      return false;
    }

    // Log backup code usage
    await supabase.rpc('log_admin_security_event', {
      p_user_id: userId,
      p_admin_user_id: null,
      p_event_type: 'backup_code_used',
      p_event_data: { 
        used_at: new Date().toISOString(),
        remaining_codes: remainingCodes.length,
      },
    });

    return true;
  } catch (error) {
    console.error('Error verifying backup code:', error);
    return false;
  }
}

/**
 * Generate new backup codes (invalidates old ones)
 */
export async function regenerateBackupCodes(
  userId: string,
  verificationToken: string
): Promise<{
  success: boolean;
  backupCodes?: string[];
  error?: string;
}> {
  try {
    // Verify current 2FA token first
    const verifyResult = await verifyTwoFactorLogin(userId, verificationToken);
    if (!verifyResult.success) {
      return {
        success: false,
        error: 'Invalid verification code',
      };
    }

    // Generate new backup codes
    const newBackupCodes = generateBackupCodes();
    const encryptedCodes = newBackupCodes.map(code => encryptData(code));

    // Update database
    const { error } = await supabase
      .from('admin_users')
      .update({
        backup_codes: encryptedCodes,
        updated_at: new Date().toISOString(),
      })
      .eq('user_id', userId);

    if (error) throw error;

    // Log backup code regeneration
    await supabase.rpc('log_admin_security_event', {
      p_user_id: userId,
      p_admin_user_id: null,
      p_event_type: 'backup_codes_generated',
      p_event_data: { 
        generated_at: new Date().toISOString(),
        codes_count: newBackupCodes.length,
      },
    });

    return {
      success: true,
      backupCodes: newBackupCodes,
    };
  } catch (error) {
    console.error('Error regenerating backup codes:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to regenerate backup codes',
    };
  }
}

/**
 * Get admin user security status
 */
export async function getAdminSecurityStatus(userId: string): Promise<{
  success: boolean;
  data?: AdminUserSecurity;
  error?: string;
}> {
  try {
    const { data, error } = await supabase
      .from('admin_users')
      .select('id, two_factor_enabled, failed_login_attempts, account_locked_until, last_login_at')
      .eq('user_id', userId)
      .single();

    if (error) throw error;

    return {
      success: true,
      data: data as AdminUserSecurity,
    };
  } catch (error) {
    console.error('Error getting admin security status:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to get security status',
    };
  }
}

/**
 * Check if account is locked
 */
export function isAccountLocked(adminUser: AdminUserSecurity): boolean {
  if (!adminUser.account_locked_until) return false;
  return new Date(adminUser.account_locked_until) > new Date();
}

/**
 * Reset failed login attempts
 */
export async function resetFailedLoginAttempts(userId: string): Promise<void> {
  try {
    await supabase
      .from('admin_users')
      .update({
        failed_login_attempts: 0,
        account_locked_until: null,
        updated_at: new Date().toISOString(),
      })
      .eq('user_id', userId);
  } catch (error) {
    console.error('Error resetting failed login attempts:', error);
  }
}

/**
 * Increment failed login attempts and lock account if needed
 */
export async function handleFailedLogin(userId: string): Promise<{
  isLocked: boolean;
  attemptsRemaining: number;
}> {
  try {
    const { data: adminUser } = await supabase
      .from('admin_users')
      .select('failed_login_attempts')
      .eq('user_id', userId)
      .single();

    const currentAttempts = (adminUser?.failed_login_attempts || 0) + 1;
    const maxAttempts = 5; // Lock after 5 failed attempts
    const lockDurationMinutes = 30; // Lock for 30 minutes

    let updateData: any = {
      failed_login_attempts: currentAttempts,
      updated_at: new Date().toISOString(),
    };

    let isLocked = false;
    if (currentAttempts >= maxAttempts) {
      const lockUntil = new Date();
      lockUntil.setMinutes(lockUntil.getMinutes() + lockDurationMinutes);
      updateData.account_locked_until = lockUntil.toISOString();
      isLocked = true;

      // Log account lock
      await supabase.rpc('log_admin_security_event', {
        p_user_id: userId,
        p_admin_user_id: null,
        p_event_type: 'account_locked',
        p_event_data: {
          locked_at: new Date().toISOString(),
          failed_attempts: currentAttempts,
          lock_until: lockUntil.toISOString(),
        },
      });
    }

    await supabase
      .from('admin_users')
      .update(updateData)
      .eq('user_id', userId);

    return {
      isLocked,
      attemptsRemaining: Math.max(0, maxAttempts - currentAttempts),
    };
  } catch (error) {
    console.error('Error handling failed login:', error);
    return { isLocked: false, attemptsRemaining: 0 };
  }
}