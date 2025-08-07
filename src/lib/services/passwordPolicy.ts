/**
 * PASSWORD POLICY AND ACCOUNT LOCKOUT SERVICE
 * Handles password validation, history tracking, and security policies
 * Created: 2025-08-07
 */

import { supabase } from '../supabase-client';
import CryptoJS from 'crypto-js';

export interface PasswordPolicyConfig {
  minLength: number;
  maxLength: number;
  requireUppercase: boolean;
  requireLowercase: boolean;
  requireNumbers: boolean;
  requireSpecialChars: boolean;
  prohibitCommonPasswords: boolean;
  prohibitPersonalInfo: boolean;
  maxRepeatingChars: number;
  historyLength: number; // Number of previous passwords to remember
  maxAge: number; // Maximum password age in days
  minAge: number; // Minimum time before password can be changed again (hours)
}

export interface AccountLockoutConfig {
  maxAttempts: number;
  lockoutDuration: number; // minutes
  attemptWindow: number; // minutes - window for counting attempts
  escalatingLockout: boolean; // Increase lockout time with repeated failures
}

export interface PasswordValidationResult {
  isValid: boolean;
  score: number; // 0-100
  violations: string[];
  suggestions: string[];
  strength: 'very-weak' | 'weak' | 'fair' | 'good' | 'strong';
}

export interface AccountStatus {
  isLocked: boolean;
  failedAttempts: number;
  lastFailedAttempt?: string;
  lockoutUntil?: string;
  lockoutReason?: string;
  nextAllowedPasswordChange?: string;
}

// Default password policy for admin accounts
const DEFAULT_PASSWORD_POLICY: PasswordPolicyConfig = {
  minLength: 12,
  maxLength: 128,
  requireUppercase: true,
  requireLowercase: true,
  requireNumbers: true,
  requireSpecialChars: true,
  prohibitCommonPasswords: true,
  prohibitPersonalInfo: true,
  maxRepeatingChars: 2,
  historyLength: 5,
  maxAge: 90, // 90 days
  minAge: 24, // 24 hours
};

// Default lockout policy
const DEFAULT_LOCKOUT_POLICY: AccountLockoutConfig = {
  maxAttempts: 5,
  lockoutDuration: 30, // 30 minutes
  attemptWindow: 15, // 15 minutes
  escalatingLockout: true,
};

// Common weak passwords (subset - in production use a comprehensive list)
const COMMON_PASSWORDS = [
  'password', '123456', 'password123', 'admin', 'qwerty', 'letmein',
  'welcome', 'monkey', '1234567890', 'abc123', 'password1', 'admin123',
  'administrator', 'root', 'test', 'guest', 'user', 'demo', 'temp',
  'password!', 'Password1', 'Admin123!', 'Welcome123', 'Qwerty123',
];

/**
 * Hash password for comparison (one-way hash)
 */
function hashPassword(password: string): string {
  return CryptoJS.SHA256(password).toString();
}

/**
 * Validate password against policy
 */
export function validatePassword(
  password: string,
  policy: Partial<PasswordPolicyConfig> = {},
  personalInfo: string[] = []
): PasswordValidationResult {
  const config = { ...DEFAULT_PASSWORD_POLICY, ...policy };
  const violations: string[] = [];
  const suggestions: string[] = [];
  let score = 0;

  // Length validation
  if (password.length < config.minLength) {
    violations.push(`Password must be at least ${config.minLength} characters long`);
    suggestions.push(`Add ${config.minLength - password.length} more characters`);
  } else {
    score += 20;
  }

  if (password.length > config.maxLength) {
    violations.push(`Password must not exceed ${config.maxLength} characters`);
  }

  // Character type requirements
  const hasUppercase = /[A-Z]/.test(password);
  const hasLowercase = /[a-z]/.test(password);
  const hasNumbers = /\d/.test(password);
  const hasSpecialChars = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password);

  if (config.requireUppercase && !hasUppercase) {
    violations.push('Password must contain at least one uppercase letter');
    suggestions.push('Add uppercase letters (A-Z)');
  } else if (hasUppercase) {
    score += 15;
  }

  if (config.requireLowercase && !hasLowercase) {
    violations.push('Password must contain at least one lowercase letter');
    suggestions.push('Add lowercase letters (a-z)');
  } else if (hasLowercase) {
    score += 15;
  }

  if (config.requireNumbers && !hasNumbers) {
    violations.push('Password must contain at least one number');
    suggestions.push('Add numbers (0-9)');
  } else if (hasNumbers) {
    score += 15;
  }

  if (config.requireSpecialChars && !hasSpecialChars) {
    violations.push('Password must contain at least one special character');
    suggestions.push('Add special characters (!@#$%^&*)');
  } else if (hasSpecialChars) {
    score += 15;
  }

  // Common password check
  if (config.prohibitCommonPasswords) {
    const isCommon = COMMON_PASSWORDS.some(common => 
      password.toLowerCase().includes(common.toLowerCase()) ||
      common.toLowerCase().includes(password.toLowerCase())
    );
    if (isCommon) {
      violations.push('Password is too common and easily guessable');
      suggestions.push('Use a more unique password');
      score -= 30;
    } else {
      score += 10;
    }
  }

  // Personal information check
  if (config.prohibitPersonalInfo && personalInfo.length > 0) {
    const containsPersonalInfo = personalInfo.some(info => 
      info.length > 2 && password.toLowerCase().includes(info.toLowerCase())
    );
    if (containsPersonalInfo) {
      violations.push('Password must not contain personal information');
      suggestions.push('Avoid using your name, email, or other personal details');
      score -= 20;
    } else {
      score += 10;
    }
  }

  // Repeating characters check
  if (hasExcessiveRepeating(password, config.maxRepeatingChars)) {
    violations.push(`Password must not have more than ${config.maxRepeatingChars} repeating characters`);
    suggestions.push('Reduce repeating characters');
    score -= 15;
  } else {
    score += 5;
  }

  // Additional scoring based on complexity
  const charTypes = [hasUppercase, hasLowercase, hasNumbers, hasSpecialChars].filter(Boolean).length;
  score += charTypes * 3;

  // Length bonus
  if (password.length >= 16) score += 10;
  if (password.length >= 20) score += 10;

  // Character variety bonus
  const uniqueChars = new Set(password).size;
  score += Math.min(10, uniqueChars / 2);

  // Entropy check (basic)
  const entropy = calculateEntropy(password);
  if (entropy > 60) score += 15;
  else if (entropy > 40) score += 10;
  else if (entropy > 20) score += 5;

  // Ensure score is within bounds
  score = Math.max(0, Math.min(100, score));

  // Determine strength level
  let strength: PasswordValidationResult['strength'];
  if (score < 20) strength = 'very-weak';
  else if (score < 40) strength = 'weak';
  else if (score < 60) strength = 'fair';
  else if (score < 80) strength = 'good';
  else strength = 'strong';

  // Add general suggestions if score is low
  if (score < 60) {
    suggestions.push('Consider using a longer password with mixed character types');
    suggestions.push('Avoid dictionary words and predictable patterns');
  }

  const isValid = violations.length === 0;

  return {
    isValid,
    score,
    violations,
    suggestions,
    strength,
  };
}

/**
 * Check for excessive repeating characters
 */
function hasExcessiveRepeating(password: string, maxRepeating: number): boolean {
  for (let i = 0; i < password.length - maxRepeating; i++) {
    const char = password[i];
    let count = 1;
    for (let j = i + 1; j < password.length && password[j] === char; j++) {
      count++;
      if (count > maxRepeating) {
        return true;
      }
    }
  }
  return false;
}

/**
 * Calculate password entropy (simplified)
 */
function calculateEntropy(password: string): number {
  let charsetSize = 0;
  
  if (/[a-z]/.test(password)) charsetSize += 26;
  if (/[A-Z]/.test(password)) charsetSize += 26;
  if (/\d/.test(password)) charsetSize += 10;
  if (/[^a-zA-Z0-9]/.test(password)) charsetSize += 32; // Approximate special chars
  
  return password.length * Math.log2(charsetSize);
}

/**
 * Check if password is in user's password history
 */
export async function isPasswordInHistory(
  userId: string,
  newPassword: string,
  historyLength: number = DEFAULT_PASSWORD_POLICY.historyLength
): Promise<boolean> {
  try {
    const { data: adminUser, error } = await supabase
      .from('admin_users')
      .select('password_history')
      .eq('user_id', userId)
      .single();

    if (error || !adminUser?.password_history) {
      return false;
    }

    const hashedPassword = hashPassword(newPassword);
    const history = adminUser.password_history as string[];
    
    // Check last N passwords
    const recentHistory = history.slice(-historyLength);
    return recentHistory.includes(hashedPassword);
  } catch (error) {
    console.error('Error checking password history:', error);
    return false;
  }
}

/**
 * Add password to user's history
 */
export async function addPasswordToHistory(
  userId: string,
  password: string,
  historyLength: number = DEFAULT_PASSWORD_POLICY.historyLength
): Promise<void> {
  try {
    const hashedPassword = hashPassword(password);
    
    // Get current history
    const { data: adminUser, error } = await supabase
      .from('admin_users')
      .select('password_history')
      .eq('user_id', userId)
      .single();

    let history: string[] = [];
    if (!error && adminUser?.password_history) {
      history = adminUser.password_history as string[];
    }

    // Add new password and limit history
    history.push(hashedPassword);
    if (history.length > historyLength) {
      history = history.slice(-historyLength);
    }

    // Update database
    await supabase
      .from('admin_users')
      .update({
        password_history: history,
        password_changed_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .eq('user_id', userId);
  } catch (error) {
    console.error('Error adding password to history:', error);
  }
}

/**
 * Check if password can be changed (minimum age check)
 */
export async function canChangePassword(
  userId: string,
  minAgeHours: number = DEFAULT_PASSWORD_POLICY.minAge
): Promise<{ canChange: boolean; nextAllowedChange?: Date }> {
  try {
    const { data: adminUser, error } = await supabase
      .from('admin_users')
      .select('password_changed_at')
      .eq('user_id', userId)
      .single();

    if (error || !adminUser?.password_changed_at) {
      return { canChange: true };
    }

    const lastChanged = new Date(adminUser.password_changed_at);
    const minChangeTime = new Date(lastChanged.getTime() + (minAgeHours * 60 * 60 * 1000));
    const now = new Date();

    if (now < minChangeTime) {
      return {
        canChange: false,
        nextAllowedChange: minChangeTime,
      };
    }

    return { canChange: true };
  } catch (error) {
    console.error('Error checking password change eligibility:', error);
    return { canChange: true };
  }
}

/**
 * Check if password has expired
 */
export async function isPasswordExpired(
  userId: string,
  maxAgeDays: number = DEFAULT_PASSWORD_POLICY.maxAge
): Promise<{ isExpired: boolean; expiresAt?: Date; daysRemaining?: number }> {
  try {
    const { data: adminUser, error } = await supabase
      .from('admin_users')
      .select('password_changed_at')
      .eq('user_id', userId)
      .single();

    if (error || !adminUser?.password_changed_at) {
      // If no password change date, consider it expired
      return { isExpired: true };
    }

    const lastChanged = new Date(adminUser.password_changed_at);
    const expiresAt = new Date(lastChanged.getTime() + (maxAgeDays * 24 * 60 * 60 * 1000));
    const now = new Date();
    
    const isExpired = now > expiresAt;
    const daysRemaining = Math.ceil((expiresAt.getTime() - now.getTime()) / (24 * 60 * 60 * 1000));

    return {
      isExpired,
      expiresAt,
      daysRemaining: isExpired ? 0 : daysRemaining,
    };
  } catch (error) {
    console.error('Error checking password expiry:', error);
    return { isExpired: false };
  }
}

/**
 * Get account lockout status
 */
export async function getAccountStatus(userId: string): Promise<AccountStatus> {
  try {
    const { data: adminUser, error } = await supabase
      .from('admin_users')
      .select('failed_login_attempts, account_locked_until, password_changed_at')
      .eq('user_id', userId)
      .single();

    if (error || !adminUser) {
      return {
        isLocked: false,
        failedAttempts: 0,
      };
    }

    const isLocked = adminUser.account_locked_until && 
                     new Date(adminUser.account_locked_until) > new Date();

    let nextAllowedPasswordChange;
    if (adminUser.password_changed_at) {
      const lastChanged = new Date(adminUser.password_changed_at);
      const minAge = DEFAULT_PASSWORD_POLICY.minAge * 60 * 60 * 1000;
      nextAllowedPasswordChange = new Date(lastChanged.getTime() + minAge).toISOString();
    }

    return {
      isLocked: !!isLocked,
      failedAttempts: adminUser.failed_login_attempts || 0,
      lockoutUntil: adminUser.account_locked_until,
      nextAllowedPasswordChange,
    };
  } catch (error) {
    console.error('Error getting account status:', error);
    return {
      isLocked: false,
      failedAttempts: 0,
    };
  }
}

/**
 * Handle failed login attempt with progressive lockout
 */
export async function handleFailedLoginAttempt(
  userId: string,
  config: Partial<AccountLockoutConfig> = {}
): Promise<{
  isLocked: boolean;
  attemptsRemaining: number;
  lockoutUntil?: Date;
}> {
  const lockoutConfig = { ...DEFAULT_LOCKOUT_POLICY, ...config };
  
  try {
    // Get current failed attempts
    const { data: adminUser, error } = await supabase
      .from('admin_users')
      .select('failed_login_attempts, account_locked_until')
      .eq('user_id', userId)
      .single();

    const currentAttempts = (adminUser?.failed_login_attempts || 0) + 1;
    const attemptsRemaining = Math.max(0, lockoutConfig.maxAttempts - currentAttempts);
    
    let updateData: any = {
      failed_login_attempts: currentAttempts,
      updated_at: new Date().toISOString(),
    };

    let isLocked = false;
    let lockoutUntil: Date | undefined;

    if (currentAttempts >= lockoutConfig.maxAttempts) {
      // Calculate lockout duration (escalating if enabled)
      let lockoutMinutes = lockoutConfig.lockoutDuration;
      
      if (lockoutConfig.escalatingLockout) {
        // Get number of previous lockouts
        const { data: securityEvents } = await supabase
          .from('admin_security_events')
          .select('id')
          .eq('user_id', userId)
          .eq('event_type', 'account_locked')
          .gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()); // Last 24 hours
        
        const previousLockouts = securityEvents?.length || 0;
        lockoutMinutes = lockoutConfig.lockoutDuration * Math.pow(2, previousLockouts); // Exponential backoff
        lockoutMinutes = Math.min(lockoutMinutes, 24 * 60); // Max 24 hours
      }

      lockoutUntil = new Date(Date.now() + lockoutMinutes * 60 * 1000);
      updateData.account_locked_until = lockoutUntil.toISOString();
      isLocked = true;

      // Log lockout event
      await supabase.rpc('log_admin_security_event', {
        p_user_id: userId,
        p_admin_user_id: null,
        p_event_type: 'account_locked',
        p_event_data: {
          failed_attempts: currentAttempts,
          lockout_duration: lockoutMinutes,
          locked_until: lockoutUntil.toISOString(),
        },
      });
    }

    // Update admin user record
    await supabase
      .from('admin_users')
      .update(updateData)
      .eq('user_id', userId);

    // Log failed login attempt
    await supabase.rpc('log_admin_security_event', {
      p_user_id: userId,
      p_admin_user_id: null,
      p_event_type: 'login_failure',
      p_event_data: {
        failed_attempts: currentAttempts,
        attempts_remaining: attemptsRemaining,
      },
    });

    return {
      isLocked,
      attemptsRemaining,
      lockoutUntil,
    };
  } catch (error) {
    console.error('Error handling failed login attempt:', error);
    return {
      isLocked: false,
      attemptsRemaining: 0,
    };
  }
}

/**
 * Reset failed login attempts (on successful login)
 */
export async function resetFailedLoginAttempts(userId: string): Promise<void> {
  try {
    await supabase
      .from('admin_users')
      .update({
        failed_login_attempts: 0,
        account_locked_until: null,
        last_login_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .eq('user_id', userId);
  } catch (error) {
    console.error('Error resetting failed login attempts:', error);
  }
}

/**
 * Manually unlock account (admin function)
 */
export async function unlockAccount(
  userId: string,
  unlockedBy: string
): Promise<{ success: boolean; error?: string }> {
  try {
    await supabase
      .from('admin_users')
      .update({
        failed_login_attempts: 0,
        account_locked_until: null,
        updated_at: new Date().toISOString(),
      })
      .eq('user_id', userId);

    // Log unlock event
    await supabase.rpc('log_admin_security_event', {
      p_user_id: userId,
      p_admin_user_id: null,
      p_event_type: 'account_unlocked',
      p_event_data: {
        unlocked_by: unlockedBy,
        unlocked_at: new Date().toISOString(),
      },
    });

    return { success: true };
  } catch (error) {
    console.error('Error unlocking account:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to unlock account',
    };
  }
}

/**
 * Change password with full validation
 */
export async function changePassword(
  userId: string,
  currentPassword: string,
  newPassword: string,
  personalInfo: string[] = [],
  policy: Partial<PasswordPolicyConfig> = {}
): Promise<{
  success: boolean;
  error?: string;
  validationResult?: PasswordValidationResult;
}> {
  try {
    // Validate new password
    const validation = validatePassword(newPassword, policy, personalInfo);
    if (!validation.isValid) {
      return {
        success: false,
        error: validation.violations.join('; '),
        validationResult: validation,
      };
    }

    // Check minimum password age
    const canChange = await canChangePassword(userId);
    if (!canChange.canChange) {
      return {
        success: false,
        error: `Password can only be changed after ${canChange.nextAllowedChange?.toLocaleString()}`,
        validationResult: validation,
      };
    }

    // Check password history
    const isInHistory = await isPasswordInHistory(userId, newPassword);
    if (isInHistory) {
      return {
        success: false,
        error: 'Password has been used recently. Please choose a different password.',
        validationResult: validation,
      };
    }

    // Verify current password with Supabase auth
    const { error: authError } = await supabase.auth.updateUser({
      password: newPassword,
    });

    if (authError) {
      return {
        success: false,
        error: 'Failed to update password: ' + authError.message,
        validationResult: validation,
      };
    }

    // Add password to history
    await addPasswordToHistory(userId, newPassword);

    // Log password change
    await supabase.rpc('log_admin_security_event', {
      p_user_id: userId,
      p_admin_user_id: null,
      p_event_type: 'password_change',
      p_event_data: {
        changed_at: new Date().toISOString(),
        strength_score: validation.score,
      },
    });

    return {
      success: true,
      validationResult: validation,
    };
  } catch (error) {
    console.error('Error changing password:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to change password',
    };
  }
}

/**
 * Generate strong password suggestions
 */
export function generatePasswordSuggestions(
  length: number = 16,
  personalInfo: string[] = []
): string[] {
  const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const lowercase = 'abcdefghijklmnopqrstuvwxyz';
  const numbers = '0123456789';
  const special = '!@#$%^&*()_+-=[]{}|;:,.<>?';
  
  const suggestions: string[] = [];
  
  for (let i = 0; i < 3; i++) {
    let password = '';
    const allChars = uppercase + lowercase + numbers + special;
    
    // Ensure at least one character from each category
    password += uppercase[Math.floor(Math.random() * uppercase.length)];
    password += lowercase[Math.floor(Math.random() * lowercase.length)];
    password += numbers[Math.floor(Math.random() * numbers.length)];
    password += special[Math.floor(Math.random() * special.length)];
    
    // Fill the rest randomly
    for (let j = password.length; j < length; j++) {
      password += allChars[Math.floor(Math.random() * allChars.length)];
    }
    
    // Shuffle the password
    password = password.split('').sort(() => Math.random() - 0.5).join('');
    
    // Validate to ensure it doesn't contain personal info
    const validation = validatePassword(password, DEFAULT_PASSWORD_POLICY, personalInfo);
    if (validation.isValid) {
      suggestions.push(password);
    } else {
      i--; // Try again
    }
  }
  
  return suggestions;
}