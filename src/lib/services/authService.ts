/**
 * Enhanced Authentication Service
 * Handles email verification, password reset, account recovery, and security features
 * Version: 1.0.0
 * Created: 2025-08-12
 */

import { supabase } from '@/lib/supabase-client';
import { 
  sendEmailVerification, 
  sendPasswordReset, 
  sendAccountLocked, 
  sendSuspiciousActivity,
  sendPasswordChanged,
  sendBackupEmailVerification
} from './emailService';
import bcrypt from 'bcryptjs';

// Types
export interface LoginAttemptResult {
  success: boolean;
  user?: any;
  error?: string;
  requiresVerification?: boolean;
  accountLocked?: boolean;
  twoFactorRequired?: boolean;
}

export interface PasswordResetRequest {
  email: string;
  ipAddress?: string;
  userAgent?: string;
}

export interface SecurityQuestion {
  id: string;
  question: string;
  answer: string; // This should be hashed
}

export interface AccountRecoveryOptions {
  hasSecurityQuestions: boolean;
  hasBackupEmail: boolean;
  backupEmailVerified: boolean;
  twoFactorEnabled: boolean;
}

// Constants
const MAX_LOGIN_ATTEMPTS = 5;
const LOCKOUT_DURATION = 15 * 60 * 1000; // 15 minutes
const PASSWORD_RESET_EXPIRY = 60 * 60 * 1000; // 1 hour
const EMAIL_VERIFICATION_EXPIRY = 24 * 60 * 60 * 1000; // 24 hours

/**
 * Enhanced login with security checks
 */
export async function authenticateUser(
  email: string, 
  password: string, 
  ipAddress?: string, 
  userAgent?: string,
  rememberMe?: boolean
): Promise<LoginAttemptResult> {
  try {
    // Log the login attempt
    const attemptId = await logLoginAttempt(null, email, ipAddress, userAgent, false);

    // Check for failed attempts and lockout
    const failedAttempts = await checkFailedLoginAttempts(email, ipAddress);
    if (failedAttempts >= MAX_LOGIN_ATTEMPTS) {
      await logSecurityEvent(null, 'login_blocked', {
        reason: 'too_many_attempts',
        attempts: failedAttempts,
        email
      }, 80, ipAddress, userAgent);

      return {
        success: false,
        error: 'Account temporarily locked due to too many failed attempts. Please try again later.',
        accountLocked: true
      };
    }

    // Attempt Supabase authentication
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email,
      password
    });

    if (authError || !authData.user) {
      // Update failed attempt log
      await updateLoginAttemptResult(attemptId, false, authError?.message || 'Invalid credentials');
      
      // Log security event for failed login
      await logSecurityEvent(authData.user?.id || null, 'login_failed', {
        email,
        error: authError?.message
      }, 40, ipAddress, userAgent);

      return {
        success: false,
        error: authError?.message || 'Invalid credentials'
      };
    }

    const userId = authData.user.id;

    // Get user profile
    const { data: profile } = await supabase
      .from('user_profiles')
      .select('*')
      .eq('id', userId)
      .single();

    // Check if email is verified
    if (!profile?.email_verified && !authData.user.email_confirmed_at) {
      await logSecurityEvent(userId, 'login_unverified_email', { email }, 30, ipAddress, userAgent);
      
      return {
        success: false,
        error: 'Please verify your email address before logging in.',
        requiresVerification: true
      };
    }

    // Check if account is locked
    if (profile?.account_locked_at) {
      const lockoutTime = new Date(profile.account_locked_at).getTime();
      const now = Date.now();
      
      if (now - lockoutTime < LOCKOUT_DURATION) {
        await logSecurityEvent(userId, 'login_account_locked', {
          locked_at: profile.account_locked_at,
          reason: profile.account_locked_reason
        }, 90, ipAddress, userAgent);

        return {
          success: false,
          error: `Account is locked: ${profile.account_locked_reason}`,
          accountLocked: true
        };
      } else {
        // Auto-unlock after lockout period
        await unlockAccount(userId);
      }
    }

    // Check for suspicious activity
    await detectSuspiciousActivity(userId, email, ipAddress, userAgent);

    // Update successful login
    await updateLoginAttemptResult(attemptId, true);
    
    // Reset failed login attempts
    await resetFailedLoginAttempts(userId);
    
    // Update last login
    await supabase
      .from('user_profiles')
      .update({ last_login_at: new Date().toISOString() })
      .eq('id', userId);

    // Log successful login
    await logSecurityEvent(userId, 'login_success', {
      email,
      remember_me: rememberMe
    }, 0, ipAddress, userAgent);

    // Check if 2FA is required
    const twoFactorEnabled = profile?.security_questions && 
      Array.isArray(profile.security_questions) && 
      profile.security_questions.length > 0;

    if (twoFactorEnabled) {
      // Sign out temporarily for 2FA verification
      await supabase.auth.signOut();
      
      return {
        success: true,
        twoFactorRequired: true,
        user: { id: userId, email }
      };
    }

    return {
      success: true,
      user: authData.user
    };

  } catch (error) {
    console.error('Authentication error:', error);
    return {
      success: false,
      error: 'Authentication failed. Please try again.'
    };
  }
}

/**
 * Send email verification
 */
export async function sendEmailVerificationToken(userId: string, email: string, name?: string): Promise<boolean> {
  try {
    // Generate verification token
    const { data, error } = await supabase.rpc('set_email_verification_token', {
      p_user_id: userId,
      p_expires_hours: 24
    });

    if (error || !data) {
      console.error('Error generating verification token:', error);
      return false;
    }

    // Send email
    const emailSent = await sendEmailVerification(userId, email, data, name);
    
    // Log verification attempt
    await logEmailVerification(userId, email, 'manual', data, emailSent);

    return emailSent;
  } catch (error) {
    console.error('Error sending email verification:', error);
    return false;
  }
}

/**
 * Verify email token
 */
export async function verifyEmailToken(token: string): Promise<{ success: boolean; userId?: string; error?: string }> {
  try {
    const { data: userId, error } = await supabase.rpc('verify_email_token', {
      p_token: token
    });

    if (error || !userId) {
      return {
        success: false,
        error: 'Invalid or expired verification token'
      };
    }

    // Log successful verification
    await logSecurityEvent(userId, 'email_verified', { token }, 0);

    return {
      success: true,
      userId
    };
  } catch (error) {
    console.error('Error verifying email token:', error);
    return {
      success: false,
      error: 'Verification failed'
    };
  }
}

/**
 * Request password reset
 */
export async function requestPasswordReset(request: PasswordResetRequest): Promise<boolean> {
  try {
    // Check if user exists
    const { data: user } = await supabase
      .from('user_profiles')
      .select('id, email, full_name')
      .eq('email', request.email)
      .single();

    if (!user) {
      // Don't reveal if email exists - always return success
      return true;
    }

    // Generate reset token
    const resetToken = generateSecureToken();
    const expiresAt = new Date(Date.now() + PASSWORD_RESET_EXPIRY);

    // Store reset token
    const { error } = await supabase
      .from('account_recovery')
      .insert({
        user_id: user.id,
        recovery_type: 'email',
        recovery_token: resetToken,
        token_expires_at: expiresAt.toISOString(),
        ip_address: request.ipAddress,
        user_agent: request.userAgent
      });

    if (error) {
      console.error('Error storing reset token:', error);
      return false;
    }

    // Send reset email
    const emailSent = await sendPasswordReset(
      request.email, 
      resetToken, 
      user.full_name, 
      request.ipAddress
    );

    // Log password reset request
    await logSecurityEvent(user.id, 'password_reset_requested', {
      email: request.email
    }, 20, request.ipAddress, request.userAgent);

    return emailSent;
  } catch (error) {
    console.error('Error requesting password reset:', error);
    return false;
  }
}

/**
 * Reset password with token
 */
export async function resetPasswordWithToken(
  token: string, 
  newPassword: string,
  ipAddress?: string,
  userAgent?: string
): Promise<{ success: boolean; error?: string }> {
  try {
    // Verify token
    const { data: recovery } = await supabase
      .from('account_recovery')
      .select('*')
      .eq('recovery_token', token)
      .eq('recovery_type', 'email')
      .gt('token_expires_at', new Date().toISOString())
      .is('used_at', null)
      .single();

    if (!recovery) {
      return {
        success: false,
        error: 'Invalid or expired reset token'
      };
    }

    // Check password history
    const passwordHash = await bcrypt.hash(newPassword, 12);
    const { data: isReused } = await supabase.rpc('check_password_history', {
      p_user_id: recovery.user_id,
      p_new_password_hash: passwordHash,
      p_history_count: 5
    });

    if (isReused) {
      return {
        success: false,
        error: 'Cannot reuse recent passwords. Please choose a different password.'
      };
    }

    // Update password in Supabase Auth
    const { error: updateError } = await supabase.auth.admin.updateUserById(
      recovery.user_id,
      { password: newPassword }
    );

    if (updateError) {
      console.error('Error updating password:', updateError);
      return {
        success: false,
        error: 'Failed to update password'
      };
    }

    // Add password to history
    await supabase.rpc('add_password_to_history', {
      p_user_id: recovery.user_id,
      p_password_hash: passwordHash
    });

    // Mark token as used
    await supabase
      .from('account_recovery')
      .update({ used_at: new Date().toISOString() })
      .eq('id', recovery.id);

    // Get user info for notification
    const { data: profile } = await supabase
      .from('user_profiles')
      .select('email, full_name')
      .eq('id', recovery.user_id)
      .single();

    if (profile) {
      // Send password changed notification
      await sendPasswordChanged(profile.email, ipAddress || 'unknown', undefined, profile.full_name);
    }

    // Log password reset
    await logSecurityEvent(recovery.user_id, 'password_reset_completed', {
      email: profile?.email
    }, 10, ipAddress, userAgent);

    return { success: true };
  } catch (error) {
    console.error('Error resetting password:', error);
    return {
      success: false,
      error: 'Password reset failed'
    };
  }
}

/**
 * Set up security questions
 */
export async function setupSecurityQuestions(
  userId: string, 
  questions: SecurityQuestion[]
): Promise<boolean> {
  try {
    // Hash the answers
    const hashedQuestions = await Promise.all(
      questions.map(async (q) => ({
        id: q.id,
        question: q.question,
        answer: await bcrypt.hash(q.answer.toLowerCase().trim(), 10)
      }))
    );

    // Update user profile
    const { error } = await supabase
      .from('user_profiles')
      .update({
        security_questions: hashedQuestions,
        updated_at: new Date().toISOString()
      })
      .eq('id', userId);

    if (error) {
      console.error('Error setting security questions:', error);
      return false;
    }

    // Log security event
    await logSecurityEvent(userId, 'security_questions_set', {
      question_count: questions.length
    });

    return true;
  } catch (error) {
    console.error('Error setting up security questions:', error);
    return false;
  }
}

/**
 * Verify security questions
 */
export async function verifySecurityQuestions(
  email: string, 
  answers: { questionId: string; answer: string }[]
): Promise<{ success: boolean; userId?: string; error?: string }> {
  try {
    // Get user and security questions
    const { data: profile } = await supabase
      .from('user_profiles')
      .select('id, security_questions')
      .eq('email', email)
      .single();

    if (!profile || !profile.security_questions) {
      return {
        success: false,
        error: 'Security questions not set up for this account'
      };
    }

    const questions = profile.security_questions as SecurityQuestion[];
    
    // Verify all answers
    for (const answer of answers) {
      const question = questions.find(q => q.id === answer.questionId);
      if (!question) {
        return {
          success: false,
          error: 'Invalid security question'
        };
      }

      const isValid = await bcrypt.compare(
        answer.answer.toLowerCase().trim(),
        question.answer
      );

      if (!isValid) {
        // Log failed attempt
        await logSecurityEvent(profile.id, 'security_questions_failed', {
          question_id: answer.questionId
        }, 60);

        return {
          success: false,
          error: 'Incorrect answer to security question'
        };
      }
    }

    // Log successful verification
    await logSecurityEvent(profile.id, 'security_questions_verified');

    return {
      success: true,
      userId: profile.id
    };
  } catch (error) {
    console.error('Error verifying security questions:', error);
    return {
      success: false,
      error: 'Verification failed'
    };
  }
}

/**
 * Set backup email
 */
export async function setBackupEmail(
  userId: string, 
  backupEmail: string
): Promise<boolean> {
  try {
    // Generate verification token
    const verificationToken = generateSecureToken();

    // Update profile
    const { error } = await supabase
      .from('user_profiles')
      .update({
        backup_email: backupEmail,
        backup_email_verified: false,
        updated_at: new Date().toISOString()
      })
      .eq('id', userId);

    if (error) {
      console.error('Error setting backup email:', error);
      return false;
    }

    // Send verification email
    const emailSent = await sendBackupEmailVerification(backupEmail, verificationToken);

    // Log security event
    await logSecurityEvent(userId, 'backup_email_set', {
      backup_email: backupEmail
    });

    return emailSent;
  } catch (error) {
    console.error('Error setting backup email:', error);
    return false;
  }
}

/**
 * Lock account
 */
export async function lockAccount(
  userId: string, 
  reason: string, 
  details?: string
): Promise<boolean> {
  try {
    const { error } = await supabase
      .from('user_profiles')
      .update({
        account_locked_at: new Date().toISOString(),
        account_locked_reason: reason,
        updated_at: new Date().toISOString()
      })
      .eq('id', userId);

    if (error) {
      console.error('Error locking account:', error);
      return false;
    }

    // Get user info
    const { data: profile } = await supabase
      .from('user_profiles')
      .select('email, full_name')
      .eq('id', userId)
      .single();

    if (profile) {
      // Send account locked notification
      await sendAccountLocked(
        profile.email, 
        reason, 
        details || `Your account was locked for security reasons: ${reason}`,
        undefined,
        profile.full_name
      );
    }

    // Log security event
    await logSecurityEvent(userId, 'account_locked', {
      reason,
      details
    }, 100);

    return true;
  } catch (error) {
    console.error('Error locking account:', error);
    return false;
  }
}

/**
 * Unlock account
 */
export async function unlockAccount(userId: string): Promise<boolean> {
  try {
    const { error } = await supabase
      .from('user_profiles')
      .update({
        account_locked_at: null,
        account_locked_reason: null,
        updated_at: new Date().toISOString()
      })
      .eq('id', userId);

    if (error) {
      console.error('Error unlocking account:', error);
      return false;
    }

    // Log security event
    await logSecurityEvent(userId, 'account_unlocked');

    return true;
  } catch (error) {
    console.error('Error unlocking account:', error);
    return false;
  }
}

// Helper functions
async function logLoginAttempt(
  userId: string | null, 
  email: string, 
  ipAddress?: string, 
  userAgent?: string, 
  success: boolean = false,
  failureReason?: string
): Promise<string> {
  const { data } = await supabase.rpc('log_login_attempt', {
    p_user_id: userId,
    p_email: email,
    p_ip_address: ipAddress,
    p_user_agent: userAgent,
    p_success: success,
    p_failure_reason: failureReason
  });
  
  return data;
}

async function updateLoginAttemptResult(
  attemptId: string, 
  success: boolean, 
  failureReason?: string
): Promise<void> {
  await supabase
    .from('login_attempts')
    .update({ 
      success, 
      failure_reason: failureReason 
    })
    .eq('id', attemptId);
}

async function logSecurityEvent(
  userId: string | null,
  eventType: string,
  eventData?: any,
  riskScore: number = 0,
  ipAddress?: string,
  userAgent?: string
): Promise<void> {
  await supabase.rpc('log_security_event', {
    p_user_id: userId,
    p_event_type: eventType,
    p_event_data: eventData,
    p_risk_score: riskScore,
    p_ip_address: ipAddress,
    p_user_agent: userAgent
  });
}

async function logEmailVerification(
  userId: string,
  email: string,
  verificationType: string,
  token: string,
  success: boolean,
  failureReason?: string
): Promise<void> {
  await supabase
    .from('email_verification_logs')
    .insert({
      user_id: userId,
      email,
      verification_type: verificationType,
      token,
      success,
      failure_reason: failureReason
    });
}

async function checkFailedLoginAttempts(
  email: string, 
  ipAddress?: string
): Promise<number> {
  const { data } = await supabase.rpc('check_failed_login_attempts', {
    p_email: email,
    p_ip_address: ipAddress,
    p_time_window: '15 minutes',
    p_max_attempts: MAX_LOGIN_ATTEMPTS
  });
  
  return data || 0;
}

async function resetFailedLoginAttempts(userId: string): Promise<void> {
  // Clear recent failed attempts for this user
  await supabase
    .from('login_attempts')
    .delete()
    .eq('user_id', userId)
    .eq('success', false)
    .gte('created_at', new Date(Date.now() - LOCKOUT_DURATION).toISOString());
}

async function detectSuspiciousActivity(
  userId: string,
  email: string,
  ipAddress?: string,
  userAgent?: string
): Promise<void> {
  try {
    // Check for login from new location/device
    const { data: recentLogins } = await supabase
      .from('login_attempts')
      .select('ip_address, user_agent')
      .eq('user_id', userId)
      .eq('success', true)
      .gte('created_at', new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()) // Last 30 days
      .order('created_at', { ascending: false })
      .limit(10);

    const isNewIp = ipAddress && !recentLogins?.some(login => login.ip_address === ipAddress);
    const isNewDevice = userAgent && !recentLogins?.some(login => login.user_agent === userAgent);

    if (isNewIp || isNewDevice) {
      // Log suspicious activity
      await logSecurityEvent(userId, 'suspicious_login', {
        new_ip: isNewIp,
        new_device: isNewDevice,
        ip_address: ipAddress,
        user_agent: userAgent
      }, 50, ipAddress, userAgent);

      // Get user profile for notification
      const { data: profile } = await supabase
        .from('user_profiles')
        .select('full_name')
        .eq('id', userId)
        .single();

      // Send suspicious activity alert
      await sendSuspiciousActivity(
        email,
        'Login from new location or device',
        new Date(),
        ipAddress || 'unknown',
        userAgent,
        undefined, // location would need geolocation service
        profile?.full_name
      );
    }
  } catch (error) {
    console.error('Error detecting suspicious activity:', error);
  }
}

function generateSecureToken(): string {
  // Generate a cryptographically secure random token
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
}

/**
 * Get account recovery options
 */
export async function getAccountRecoveryOptions(email: string): Promise<AccountRecoveryOptions | null> {
  try {
    const { data: profile } = await supabase
      .from('user_profiles')
      .select('security_questions, backup_email, backup_email_verified')
      .eq('email', email)
      .single();

    if (!profile) {
      return null;
    }

    return {
      hasSecurityQuestions: Array.isArray(profile.security_questions) && profile.security_questions.length > 0,
      hasBackupEmail: Boolean(profile.backup_email),
      backupEmailVerified: Boolean(profile.backup_email_verified),
      twoFactorEnabled: false // Will be updated when 2FA is implemented
    };
  } catch (error) {
    console.error('Error getting recovery options:', error);
    return null;
  }
}

/**
 * Get user security status
 */
export async function getUserSecurityStatus(userId: string): Promise<any> {
  try {
    const { data } = await supabase.rpc('get_user_security_status', {
      p_user_id: userId
    });

    return data;
  } catch (error) {
    console.error('Error getting security status:', error);
    return null;
  }
}